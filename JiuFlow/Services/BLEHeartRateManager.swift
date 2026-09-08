import Combine
import Foundation
#if BLE_HARDWARE
import CoreBluetooth
#endif

// MARK: - BLE Heart Rate Manager
// Polar H10 / Wahoo TICKR など標準 BLE HR センサー 2台同時対応
// Heart Rate Service (0x180D) / Heart Rate Measurement (0x2A37)

struct HRDevice: Identifiable {
    let id: UUID          // CBPeripheral.identifier
    var name: String
    var bpm: Int?
    var isConnected: Bool = false
    var role: Role = .person1

    enum Role: String {
        case person1 = "自分"
        case person2 = "パートナー"
    }
}

#if BLE_HARDWARE

@MainActor
final class BLEHeartRateManager: NSObject, ObservableObject {

    // MARK: - Published

    @Published var devices: [UUID: HRDevice] = [:]
    @Published var isScanning = false
    @Published var scanResults: [CBPeripheral] = []  // not yet connected
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var errorMessage: String?

    // MARK: - Private

    private var centralManager: CBCentralManager?
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]

    nonisolated static let hrServiceUUID = CBUUID(string: "180D")
    nonisolated static let hrMeasurementUUID = CBUUID(string: "2A37")

    override init() {
        super.init()
        // Hardware gated for App Review — see FeatureFlags.bleHardwareEnabled.
        // Instantiating CBCentralManager triggers the Bluetooth permission prompt,
        // which requires NSBluetoothAlwaysUsageDescription in Info.plist.
        if FeatureFlags.bleHardwareEnabled {
            centralManager = CBCentralManager(delegate: self, queue: .main)
        }
    }

    // MARK: - Public API

    func startScan() {
        guard let centralManager, centralManager.state == .poweredOn else {
            errorMessage = "Bluetoothをオンにしてください"
            return
        }
        scanResults = []
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: [Self.hrServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        // 10秒で自動停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopScan()
        }
    }

    func stopScan() {
        centralManager?.stopScan()
        isScanning = false
    }

    func connect(_ peripheral: CBPeripheral, role: HRDevice.Role) {
        guard connectedPeripherals.count < 2 else {
            errorMessage = "最大2台まで接続できます"
            return
        }
        stopScan()
        let device = HRDevice(
            id: peripheral.identifier,
            name: peripheral.name ?? "HR センサー",
            role: role
        )
        devices[peripheral.identifier] = device
        connectedPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self
        centralManager?.connect(peripheral, options: nil)
    }

    func disconnect(_ id: UUID) {
        guard let peripheral = connectedPeripherals[id] else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
        connectedPeripherals.removeValue(forKey: id)
        devices.removeValue(forKey: id)
    }

    func disconnectAll() {
        for (_, peripheral) in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals = [:]
        devices = [:]
    }

    // MARK: - Computed

    var person1: HRDevice? { devices.values.first(where: { $0.role == .person1 }) }
    var person2: HRDevice? { devices.values.first(where: { $0.role == .person2 }) }
    var connectedCount: Int { devices.values.filter(\.isConnected).count }
}

// MARK: - CBCentralManagerDelegate

extension BLEHeartRateManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothState = central.state
            if central.state != .poweredOn {
                isScanning = false
                errorMessage = central.state == .poweredOff ? "Bluetoothをオンにしてください" : nil
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            guard !scanResults.contains(where: { $0.identifier == peripheral.identifier }),
                  !connectedPeripherals.keys.contains(peripheral.identifier) else { return }
            scanResults.append(peripheral)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            devices[peripheral.identifier]?.isConnected = true
            peripheral.discoverServices([Self.hrServiceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            devices[peripheral.identifier]?.isConnected = false
            devices[peripheral.identifier]?.bpm = nil
            connectedPeripherals.removeValue(forKey: peripheral.identifier)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            devices.removeValue(forKey: peripheral.identifier)
            connectedPeripherals.removeValue(forKey: peripheral.identifier)
            errorMessage = "接続失敗: \(peripheral.name ?? "デバイス")"
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEHeartRateManager: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == Self.hrServiceUUID {
            peripheral.discoverCharacteristics([Self.hrMeasurementUUID], for: service)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let chars = service.characteristics else { return }
        for char in chars where char.uuid == Self.hrMeasurementUUID {
            peripheral.setNotifyValue(true, for: char)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == Self.hrMeasurementUUID,
              let data = characteristic.value,
              !data.isEmpty else { return }

        let bpm = Self.parseHeartRate(data)
        Task { @MainActor in
            devices[peripheral.identifier]?.bpm = bpm
        }
    }

    nonisolated static func parseHeartRate(_ data: Data) -> Int {
        // BLE HR Measurement format (Bluetooth SIG spec):
        // Byte 0: Flags
        //   bit 0: 0 = uint8 HR, 1 = uint16 HR
        // Byte 1 (or 1-2): Heart rate value
        let flags = data[0]
        let isUInt16 = (flags & 0x01) != 0
        if isUInt16 && data.count >= 3 {
            return Int(data[1]) | (Int(data[2]) << 8)
        } else if data.count >= 2 {
            return Int(data[1])
        }
        return 0
    }
}

#else

// MARK: - App Store stub (BLE hardware removed — Guideline 2.1)
// CoreBluetooth is not imported/linked and CBCentralManager is never
// instantiated. Same public API surface so gated call sites still compile.

@MainActor
final class BLEHeartRateManager: NSObject, ObservableObject {

    @Published var devices: [UUID: HRDevice] = [:]
    @Published var isScanning = false
    @Published var errorMessage: String?

    var person1: HRDevice? { nil }
    var person2: HRDevice? { nil }
    var connectedCount: Int { 0 }

    func startScan() {}
    func stopScan() {}
    func disconnect(_ id: UUID) {}
    func disconnectAll() {}
}

#endif
