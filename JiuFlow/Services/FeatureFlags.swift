import Foundation

/// Compile-time feature flags.
enum FeatureFlags {
    /// BLE hardware integrations (Polar H10 heart-rate sensors + BJJ wearable).
    ///
    /// REMOVED from App Store builds: App Review (Guideline 2.1, 2026-06-09 and
    /// 2026-07-06) requires a demo video showing the app pairing with the physical
    /// hardware. The feature is compiled out entirely — CoreBluetooth is never
    /// imported or linked, CBCentralManager is never instantiated, no Bluetooth
    /// permission prompt appears, and Info.plist has no
    /// NSBluetoothAlwaysUsageDescription.
    ///
    /// To re-enable for internal builds:
    ///   1. Add `BLE_HARDWARE` to SWIFT_ACTIVE_COMPILATION_CONDITIONS.
    ///   2. Restore `NSBluetoothAlwaysUsageDescription` in JiuFlow/Info.plist
    ///      (missing key while CoreBluetooth scans crashes the app).
    #if BLE_HARDWARE
    static let bleHardwareEnabled = true
    #else
    static let bleHardwareEnabled = false
    #endif
}
