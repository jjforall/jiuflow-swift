import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, desc: String, color: Color)] = [
        ("bolt.shield.fill", "最短で勝てる柔術",
         "グレイシー直系 × モダン競技特化。\n運動音痴でも勝てるシステムを\n世界チャンピオン村田良蔵が監修。", .jfRed),
        ("arrow.triangle.branch", "技の「流れ」で学ぶ",
         "バラバラのテクニックではなく\n「この技の次は何？」を可視化。\nゲームプランで試合を設計しよう。", .blue),
        ("shield.checkered", "安全で長く続けられる",
         "「やられない → コントロール → アタック」\nの順番だから怪我しにくい。\n40代、50代でも強くなれる。", .green),
        ("chart.line.uptrend.xyaxis", "データで上達を加速",
         "練習記録・ロール分析・AIコーチが\nあなたの弱点を見つけて\n今週やるべきドリルを提案。", .purple),
    ]

    var body: some View {
        ZStack {
            Color.jfDarkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("スキップ") { onComplete() }
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                        .padding()
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(page.color.opacity(0.1))
                                    .frame(width: 140, height: 140)
                                Circle()
                                    .fill(page.color.opacity(0.05))
                                    .frame(width: 200, height: 200)
                                Image(systemName: page.icon)
                                    .font(.system(size: 56))
                                    .foregroundStyle(page.color)
                            }

                            Text(page.title)
                                .font(.title.bold())
                                .foregroundStyle(Color.jfTextPrimary)

                            Text(page.desc)
                                .font(.body)
                                .foregroundStyle(Color.jfTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.jfRed : Color.jfBorder)
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "次へ" : "はじめる")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
