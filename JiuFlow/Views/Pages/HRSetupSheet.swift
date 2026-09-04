import SwiftUI
#if BLE_HARDWARE
import CoreBluetooth

// MARK: - HR Live Widget (during roll)

struct HRLiveWidget: View {
    @ObservedObject var hrManager: BLEHeartRateManager

    var body: some View {
        HStack(spacing: 16) {
            if let p1 = hrManager.person1 {
                hrCard(device: p1)
            }
            if let p2 = hrManager.person2 {
                hrCard(device: p2)
            }
        }
        .padding(.horizontal)
    }

    private func hrCard(device: HRDevice) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(heartColor(bpm: device.bpm))
                .font(.system(size: 14))
                .symbolEffect(.bounce, value: device.bpm)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.role.rawValue)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                if let bpm = device.bpm {
                    Text("\(bpm)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(heartColor(bpm: bpm))
                    + Text(" bpm")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextSecondary)
                } else {
                    Text(device.isConnected ? "---" : tr("切断"))
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.jfCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func heartColor(bpm: Int?) -> Color {
        guard let bpm else { return Color.jfTextTertiary }
        switch bpm {
        case ..<100: return .green
        case 100..<140: return .orange
        default: return .red
        }
    }
}

// MARK: - HR Setup Sheet

struct HRSetupSheet: View {
    @ObservedObject var hrManager: BLEHeartRateManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.jfDarkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Connected devices
                    if !hrManager.devices.isEmpty {
                        connectedSection
                    }

                    // Scan / scan results
                    scanSection
                }
            }
            .navigationTitle(tr("心拍センサー"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(tr("完了")) { dismiss() }
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .onAppear {
            if hrManager.bluetoothState == .poweredOn && hrManager.connectedCount < 2 {
                hrManager.startScan()
            }
        }
        .onDisappear {
            hrManager.stopScan()
        }
    }

    // MARK: - Connected

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("接続済み"))
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ForEach(Array(hrManager.devices.values), id: \.id) { device in
                connectedRow(device)
            }
        }
    }

    private func connectedRow(_ device: HRDevice) -> some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(device.isConnected ? .red : Color.jfTextTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(device.role.rawValue + (device.isConnected ? tr(" · 接続中") : tr(" · 切断")))
                    .font(.caption)
                    .foregroundStyle(device.isConnected ? .green : Color.jfTextTertiary)
            }

            Spacer()

            if let bpm = device.bpm {
                Text("\(bpm) bpm")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.red)
            }

            Button {
                hrManager.disconnect(device.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(12)
        .background(Color.jfCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Scan

    private var scanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(hrManager.isScanning ? tr("スキャン中...") : tr("デバイスを検索"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)

                Spacer()

                if hrManager.isScanning {
                    ProgressView()
                        .tint(Color.jfRed)
                        .scaleEffect(0.8)
                } else {
                    Button(tr("再スキャン")) {
                        hrManager.startScan()
                    }
                    .font(.caption)
                    .foregroundStyle(Color.jfRed)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            if hrManager.bluetoothState != .poweredOn {
                Text(tr("Bluetoothをオンにしてください"))
                    .font(.callout)
                    .foregroundStyle(Color.jfTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if hrManager.scanResults.isEmpty && !hrManager.isScanning {
                Text(tr("HR センサーが見つかりません\n(Polar H10 / Wahoo TICKR)"))
                    .font(.callout)
                    .foregroundStyle(Color.jfTextTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(hrManager.scanResults, id: \.identifier) { peripheral in
                    if !hrManager.devices.keys.contains(peripheral.identifier) {
                        scanResultRow(peripheral)
                    }
                }
            }

            if let error = hrManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
            }

            Spacer()

            // Tip
            VStack(spacing: 4) {
                Text(tr("対応センサー: Polar H10 / Wahoo TICKR / Garmin など"))
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                Text(tr("最大2台同時接続 · 動作中も計測可能"))
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 24)
        }
    }

    private func scanResultRow(_ peripheral: CBPeripheral) -> some View {
        HStack {
            Image(systemName: "sensor.fill")
                .foregroundStyle(Color.jfRed)

            Text(peripheral.name ?? tr("HR センサー"))
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)

            Spacer()

            // Role selector: person1 or person2
            let nextRole: HRDevice.Role = hrManager.person1 == nil ? .person1 : .person2
            Button {
                hrManager.connect(peripheral, role: nextRole)
            } label: {
                Text(nextRole.rawValue + "として接続")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.jfRed)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.jfCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

#else

// MARK: - App Store stubs (BLE hardware removed — Guideline 2.1)
// These views are unreachable at runtime (FeatureFlags.bleHardwareEnabled is
// false) but keep gated call sites compiling without CoreBluetooth.

struct HRLiveWidget: View {
    @ObservedObject var hrManager: BLEHeartRateManager
    var body: some View { EmptyView() }
}

struct HRSetupSheet: View {
    @ObservedObject var hrManager: BLEHeartRateManager
    var body: some View { EmptyView() }
}

#endif
