import Foundation

/// Compile-time feature flags.
enum FeatureFlags {
    /// BLE hardware integrations (Polar H10 heart-rate sensors + BJJ wearable).
    ///
    /// OFF for App Store release: App Review (2026-06-09, Guideline 2.1) requires a
    /// demo video showing the app pairing with the physical hardware. Until that
    /// video is filmed and attached in App Store Connect, the hardware UI is hidden
    /// and CBCentralManager is never instantiated (so no Bluetooth permission prompt
    /// and no NSBluetoothAlwaysUsageDescription is needed in Info.plist).
    ///
    /// To re-enable: set this to `true` AND restore the
    /// `NSBluetoothAlwaysUsageDescription` key in JiuFlow/Info.plist
    /// (removing the key while CoreBluetooth is used crashes the app on first scan).
    static let bleHardwareEnabled = false
}
