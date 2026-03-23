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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.jfGold.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.jfGold)
            }

            VStack(spacing: 8) {
                ProBadge(size: .medium)
                Text("プレミアム機能")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Text("\(feature)はプレミアムプランで利用できます")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            NavigationLink {
                SubscriptionView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                    Text("プランを見る")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(LinearGradient.jfGoldGradient)
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
                    .foregroundStyle(Color.jfGold)
                ProBadge(size: .small)
            }
        }
    }
}
