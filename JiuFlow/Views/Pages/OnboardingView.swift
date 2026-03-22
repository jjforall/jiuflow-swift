import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, desc: String, color: Color)] = [
        ("arrow.triangle.branch", "テクニックマップ",
         "柔術の全テクニックを「流れ」で可視化。\nポジション → アタック → エスケープの\n繋がりが一目でわかる。", .blue),
        ("checklist", "ゲームプランビルダー",
         "試合で使う動きを事前に設計。\n良蔵システムなど実績あるテンプレートから\n自分だけのプランを作ろう。", .purple),
        ("play.rectangle.fill", "教則動画ライブラリ",
         "世界チャンピオン村田良蔵監修。\n4K俯瞰撮影 + AI文字起こしで\nどこでも学べる。", .red),
        ("figure.martial.arts", "道場検索 & 予約",
         "全国の道場を検索。\nアプリ内でクラス予約まで完結。\n体験クラスもワンタップ。", .green),
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
