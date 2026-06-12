import CoreBluetooth
import Combine
import Foundation

// MARK: - GATT UUIDs
// Service: 4A574A30-0000-1000-8000-00805F9B34FB
// IMU:     4A574A30-0001-1000-8000-00805F9B34FB  (Notify, 5 bytes, 250ms)
//          [intensity, legacy_pos(0-3), scramble_lo, scramble_hi, bjj_pos(0-5)]
// Round:   4A574A30-0003-1000-8000-00805F9B34FB  (Indicate, JSON)

// MARK: - Models

struct RoundSummary: Codable, Identifiable, Equatable {
    var id             = UUID()
    let dur_s:            Int
    let avg_intensity:    Int
    let peak_intensity:   Int
    let scrambles:        Int
    let score:            Int
    let fatigue_index:    Int
    var recorded_at       = Date()

    enum CodingKeys: String, CodingKey {
        case dur_s, avg_intensity, peak_intensity, scrambles, score, fatigue_index
    }

    init(from decoder: Decoder) throws {
        let c          = try decoder.container(keyedBy: CodingKeys.self)
        id             = UUID()
        dur_s          = try c.decode(Int.self, forKey: .dur_s)
        avg_intensity  = try c.decode(Int.self, forKey: .avg_intensity)
        peak_intensity = (try? c.decode(Int.self, forKey: .peak_intensity)) ?? avg_intensity
        scrambles      = try c.decode(Int.self, forKey: .scrambles)
        score          = try c.decode(Int.self, forKey: .score)
        fatigue_index  = (try? c.decode(Int.self, forKey: .fatigue_index)) ?? 0
        recorded_at    = Date()
    }

    var durationString: String {
        String(format: "%d:%02d", dur_s / 60, dur_s % 60)
    }

    var label: String {
        switch score {
        case 0..<30:  return "軽め"
        case 30..<50: return "普通"
        case 50..<70: return "ハード"
        case 70..<85: return "激しい"
        default:      return "限界突破"
        }
    }

    var fatigueLabel: String {
        switch fatigue_index {
        case 0..<20:  return "維持"
        case 20..<45: return "やや低下"
        case 45..<70: return "疲労あり"
        default:      return "燃え尽き"
        }
    }

    var scoreColor: String {
        switch score {
        case 0..<30:  return "green"
        case 30..<50: return "blue"
        case 50..<70: return "orange"
        default:      return "red"
        }
    }
}

struct ImuLive {
    let intensity:     UInt8
    let position:      UInt8   // legacy: 0=unknown 1=standing 2=ground 3=scramble
    let scrambleScore: UInt16
    let bjjPosition:   UInt8?  // ML: 0=Guard 1=Half 2=Side 3=Mount 4=Back 5=Scramble
}

// MARK: - Manager

@MainActor
final class WearableManager: NSObject, ObservableObject {

    // MARK: Published — own device

    @Published var isConnected     = false
    @Published var isScanning      = false
    @Published var live:   ImuLive?        = nil
    @Published var latestRound: RoundSummary? = nil
    @Published var todayRounds: [RoundSummary] = []
    @Published var errorMessage: String?   = nil
    @Published var bluetoothState: CBManagerState = .unknown

    // MARK: Published — peer / multi-device

    @Published var hasPeer:      Bool      = false
    @Published var partnerLive:  ImuLive?  = nil
    @Published var isSparring:   Bool      = false

    // MARK: Computed

    var todayScore: Int {
        guard !todayRounds.isEmpty else { return 0 }
        return todayRounds.map(\.score).max() ?? 0
    }

    var todayTotalMinutes: Int {
        todayRounds.map(\.dur_s).reduce(0, +) / 60
    }

    var positionLabel: String {
        // Prefer ML position when available
        if let bjj = live?.bjjPosition {
            switch bjj {
            case 0: return "ガード"
            case 1: return "ハーフガード"
            case 2: return "サイドコントロール"
            case 3: return "マウント"
            case 4: return "バックコントロール"
            case 5: return "スクランブル!"
            default: return "---"
            }
        }
        switch live?.position {
        case 1: return "スタンド"
        case 2: return "グラウンド"
        case 3: return "スクランブル!"
        default: return "---"
        }
    }

    var intensityPercent: Double {
        Double(live?.intensity ?? 0) / 255.0
    }

    // MARK: GATT UUIDs

    nonisolated static let serviceUUID = CBUUID(string: "4A574A30-0000-1000-8000-00805F9B34FB")
    nonisolated static let imuUUID     = CBUUID(string: "4A574A30-0001-1000-8000-00805F9B34FB")
    nonisolated static let roundUUID   = CBUUID(string: "4A574A30-0003-1000-8000-00805F9B34FB")

    // MARK: Private — connection

    private var central:          CBCentralManager?
    private var peripheral:       CBPeripheral?
    private var peerPeripheral:   CBPeripheral?

    // MARK: Private — sparring correlation
    // 40 samples × 250ms = 10 second window for Pearson correlation

    private var ownHistory:     [Double] = []
    private var partnerHistory: [Double] = []
    private let corrWindow = 40

    override init() {
        super.init()
        // Hardware gated for App Review — see FeatureFlags.bleHardwareEnabled.
        if FeatureFlags.bleHardwareEnabled {
            central = CBCentralManager(delegate: self, queue: .main)
        }
    }

    // MARK: API

    func startScan() {
        guard let central, central.state == .poweredOn else { return }
        isScanning = true
        errorMessage = nil
        central.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            self?.stopScan()
        }
    }

    func stopScan() {
        central?.stopScan()
        isScanning = false
    }

    func uploadRound(_ round: RoundSummary, token: String) {
        guard let url = URL(string: "https://jiuflow.com/api/v1/wearable/rounds") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)",    forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONEncoder().encode(round)
        URLSession.shared.dataTask(with: req) { _, _, _ in }.resume()
    }

    // MARK: - Private helpers

    private func startPeerScan() {
        guard let central, central.state == .poweredOn, !isScanning, peerPeripheral == nil else { return }
        central.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            guard let self, self.peerPeripheral == nil else { return }
            self.central?.stopScan()
        }
    }

    private func pushOwn(intensity: UInt8) {
        ownHistory.append(Double(intensity))
        if ownHistory.count > corrWindow { ownHistory.removeFirst() }
        updateSparring()
    }

    private func pushPartner(intensity: UInt8) {
        partnerHistory.append(Double(intensity))
        if partnerHistory.count > corrWindow { partnerHistory.removeFirst() }
        updateSparring()
    }

    private func updateSparring() {
        guard ownHistory.count == corrWindow,
              partnerHistory.count == corrWindow else {
            isSparring = false
            return
        }
        // ML position: 0-4 = ground types, 5 = scramble → ground if < 5
        // Legacy position: 2 = ground only
        let ownGround: Bool = {
            if let bjj = live?.bjjPosition { return bjj < 5 }
            return live?.position == 2
        }()
        let partnerGround: Bool = {
            if let bjj = partnerLive?.bjjPosition { return bjj < 5 }
            return partnerLive?.position == 2
        }()
        guard ownGround, partnerGround else {
            isSparring = false
            return
        }
        let r = pearson(ownHistory, partnerHistory)
        isSparring = r > 0.65
    }

    private func pearson(_ x: [Double], _ y: [Double]) -> Double {
        let n  = Double(x.count)
        let xm = x.reduce(0, +) / n
        let ym = y.reduce(0, +) / n
        let cov = zip(x, y).map { ($0 - xm) * ($1 - ym) }.reduce(0, +) / n
        let xs  = sqrt(x.map { ($0 - xm) * ($0 - xm) }.reduce(0, +) / n)
        let ys  = sqrt(y.map { ($0 - ym) * ($0 - ym) }.reduce(0, +) / n)
        return (xs > 3.0 && ys > 3.0) ? cov / (xs * ys) : 0
    }
}

// MARK: - CBCentralManagerDelegate

extension WearableManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            bluetoothState = central.state
            if central.state == .poweredOn { startScan() }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi: NSNumber
    ) {
        Task { @MainActor in
            if self.peripheral == nil {
                // Primary: own wearable
                stopScan()
                self.peripheral = peripheral
                peripheral.delegate = self
                central.connect(peripheral, options: nil)
            } else if self.peerPeripheral == nil,
                      peripheral.identifier != self.peripheral!.identifier {
                // Secondary: sparring partner's device
                self.peerPeripheral = peripheral
                peripheral.delegate = self
                central.connect(peripheral, options: nil)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            let isOwn = peripheral.identifier == self.peripheral?.identifier
            if isOwn {
                isConnected  = true
                errorMessage = nil
                peripheral.discoverServices([Self.serviceUUID])
                // Scan for partner 3s after own device connects
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.startPeerScan()
                }
            } else {
                hasPeer = true
                peripheral.discoverServices([Self.serviceUUID])
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
    ) {
        Task { @MainActor in
            let isOwn = peripheral.identifier == self.peripheral?.identifier
            if isOwn {
                isConnected = false
                live        = nil
                self.peripheral = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                    self?.startScan()
                }
            } else {
                peerPeripheral  = nil
                partnerLive     = nil
                hasPeer         = false
                isSparring      = false
                partnerHistory.removeAll()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral, error: Error?
    ) {
        Task { @MainActor in
            let isOwn = peripheral.identifier == self.peripheral?.identifier
            if isOwn {
                self.peripheral = nil
                startScan()
            } else {
                self.peerPeripheral = nil
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension WearableManager: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for svc in services where svc.uuid == Self.serviceUUID {
            peripheral.discoverCharacteristics([Self.imuUUID, Self.roundUUID], for: svc)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService, error: Error?
    ) {
        service.characteristics?.forEach { char in
            if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic, error: Error?
    ) {
        guard let data = characteristic.value, !data.isEmpty else { return }

        let pid = peripheral.identifier

        switch characteristic.uuid {
        case Self.imuUUID:
            guard data.count >= 4 else { return }
            let bjjPos: UInt8? = data.count >= 5 ? data[4] : nil
            let imuData = ImuLive(
                intensity:     data[0],
                position:      data[1],
                scrambleScore: UInt16(data[2]) | (UInt16(data[3]) << 8),
                bjjPosition:   bjjPos
            )
            Task { @MainActor in
                if pid == self.peripheral?.identifier {
                    self.live = imuData
                    self.pushOwn(intensity: imuData.intensity)
                } else {
                    self.partnerLive = imuData
                    self.pushPartner(intensity: imuData.intensity)
                }
            }

        case Self.roundUUID:
            if let summary = try? JSONDecoder().decode(RoundSummary.self, from: data) {
                Task { @MainActor in
                    // Only record own device rounds
                    if pid == self.peripheral?.identifier {
                        self.latestRound = summary
                        self.todayRounds.insert(summary, at: 0)
                    }
                }
            }

        default: break
        }
    }
}
