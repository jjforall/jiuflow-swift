import SwiftUI

struct PremiumGate<Content: View>: View {
    @EnvironmentObject var premium: PremiumManager
    let feature: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        if premium.isPremium {
            content()
        } else {
            lockedOverlay
        }
    }

    private var lockedOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.jfRed)
            Text("プレミアム機能")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
            Text("\(feature)はプレミアムプランで利用できます")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
            NavigationLink {
                SubscriptionView()
            } label: {
                Text("プランを見る")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard()
    }
}

// MARK: - Locked Video Card Overlay

struct LockedVideoOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                Text("プレミアム")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.jfRed.opacity(0.85))
                    .clipShape(Capsule())
            }
        }
    }
}
