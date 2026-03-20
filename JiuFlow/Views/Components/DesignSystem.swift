import SwiftUI

// MARK: - Color System

extension Color {
    static let jfRed = Color(red: 0.86, green: 0.15, blue: 0.15) // #DC2626
    static let jfOrange = Color(red: 0.92, green: 0.40, blue: 0.15)
    static let jfDarkBg = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let jfCardBg = Color(red: 0.067, green: 0.067, blue: 0.067) // #111111
    static let jfCardBgLight = Color(white: 0.1)
    static let jfTextPrimary = Color.white
    static let jfTextSecondary = Color.white.opacity(0.7)
    static let jfTextTertiary = Color.white.opacity(0.45)
    static let jfBorder = Color.white.opacity(0.08)
}

// MARK: - Gradient Presets

extension LinearGradient {
    static let jfRedGradient = LinearGradient(
        colors: [Color.jfRed, Color.jfOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let jfHeroGradient = LinearGradient(
        colors: [Color.black, Color(red: 0.12, green: 0.02, blue: 0.02), Color.black],
        startPoint: .top,
        endPoint: .bottom
    )

    static let jfCardOverlay = LinearGradient(
        colors: [.clear, .black.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Shimmer View

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.15),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.15)
            ],
            startPoint: .init(x: phase - 0.5, y: 0.5),
            endPoint: .init(x: phase + 0.5, y: 0.5)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var height: CGFloat = 120

    var body: some View {
        ShimmerView()
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var showMore: Bool = false
    var onMore: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfRed)
            }
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.jfTextPrimary)

            Spacer()

            if showMore {
                Button {
                    onMore?()
                } label: {
                    HStack(spacing: 4) {
                        Text("もっと見る")
                            .font(.caption.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.jfBorder, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let text: String
    var color: Color = .jfRed

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var message: String = "読み込み中"

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.jfRed)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.jfDarkBg)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(Color.jfTextTertiary)
                .padding(.bottom, 8)

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Quick Action Button

struct QuickAction: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextSecondary)
        }
    }
}
