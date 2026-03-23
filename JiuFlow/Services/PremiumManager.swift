import SwiftUI

@MainActor
class PremiumManager: ObservableObject {
    @AppStorage("is_premium_user") private var stored: Bool = false
    @AppStorage("user_tier") var tier: String = "free" // "free", "pro", "blackbelt"

    @Published var isPremium: Bool = false

    init() {
        isPremium = stored || tier != "free"
    }

    var isFree: Bool { tier == "free" }
    var isPro: Bool { tier == "pro" || tier == "blackbelt" }
    var isBlackBelt: Bool { tier == "blackbelt" }

    // Limits per tier
    var videoLimit: Int { isFree ? 5 : 999999 }
    var practiceLimit: Int { isFree ? 3 : 999999 }
    var rollLimit: Int { isFree ? 3 : 999999 }
    var aiLimit: Int { isFree ? 3 : (isPro && !isBlackBelt ? 30 : 999999) }
    var gamePlanTemplateLimit: Int { isFree ? 3 : 999 }
    var gamePlanSaveLimit: Int { isFree ? 0 : (isBlackBelt ? 999999 : 5) }
    var canUseAIGamePlan: Bool { isBlackBelt }
    var canWatchLive: Bool { isBlackBelt }
    var canWatchArchive: Bool { isPro }
    var hasTournamentDiscount: Bool { isBlackBelt }
    var hasProBadge: Bool { isPro }
    var hasExclusiveChannel: Bool { isBlackBelt }
    var isAdFree: Bool { isPro }

    func unlock() {
        tier = "pro"
        isPremium = true
        stored = true
    }

    func unlockBlackBelt() {
        tier = "blackbelt"
        isPremium = true
        stored = true
    }

    func lock() {
        tier = "free"
        isPremium = false
        stored = false
    }

    func setTier(_ newTier: String) {
        tier = newTier
        isPremium = newTier != "free"
        stored = isPremium
    }
}
