import SwiftUI

@MainActor
class PremiumManager: ObservableObject {
    @Published var isPremium: Bool = false
    @AppStorage("is_premium_user") private var stored: Bool = false

    init() { isPremium = stored }

    func unlock() { isPremium = true; stored = true }
    func lock() { isPremium = false; stored = false }
}
