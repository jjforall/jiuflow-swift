import SwiftUI

struct MyPageTab: View {
    @EnvironmentObject var api: APIService
    @State private var email = ""
    @State private var isSending = false
    @State private var resultMessage: String?
    @State private var isError = false
    @State private var showSuccessAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                if api.isLoggedIn {
                    loggedInView
                } else {
                    loginView
                }
            }
            .background(Color.jfDarkBg)
            .scrollContentBackground(.hidden)
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Login View

    private var loginView: some View {
        VStack(spacing: 0) {
            // Hero area
            ZStack {
                RadialGradient(
                    colors: [Color.jfRed.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 180
                )

                VStack(spacing: 14) {
                    // App icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient.jfRedGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "figure.martial.arts")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .jfRed.opacity(0.3), radius: 20)
                    .padding(.top, 32)

                    Text("JiuFlowで\n柔術を加速させよう")
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("テクニックの進捗管理、お気に入り動画の保存、\n練習日記など全ての機能が使えます")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 28)

            // Login form
            VStack(spacing: 16) {
                // Email input
                VStack(alignment: .leading, spacing: 6) {
                    Text("メールアドレス")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)

                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isSending)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.jfBorder, lineWidth: 1)
                        )
                        .foregroundStyle(Color.jfTextPrimary)
                }

                // Login button
                Button {
                    Task {
                        await sendMagicLink()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "envelope.fill")
                        }
                        Text(isSending ? "送信中..." : "マジックリンクでログイン")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Group {
                            if email.isEmpty || isSending {
                                Color.gray.opacity(0.4)
                            } else {
                                LinearGradient.jfRedGradient
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(email.isEmpty || isSending)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isSending)

                // Result message
                if let message = resultMessage {
                    VStack(spacing: 12) {
                        if !isError && showSuccessAnimation {
                            // Pulsing email animation
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(showSuccessAnimation ? 1.2 : 0.8)
                                    .opacity(showSuccessAnimation ? 0.3 : 0.8)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showSuccessAnimation)

                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 60, height: 60)

                                Image(systemName: "envelope.open.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.green)
                                    .scaleEffect(showSuccessAnimation ? 1.1 : 0.9)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showSuccessAnimation)
                            }
                            .padding(.top, 8)
                            .transition(.scale.combined(with: .opacity))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .font(.subheadline)
                            Text(message)
                                .font(.subheadline)
                        }
                        .foregroundStyle(isError ? .red : .green)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            (isError ? Color.red : Color.green).opacity(0.1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Open mail app
                if !isError && showSuccessAnimation {
                    Button {
                        if let url = URL(string: "message://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("メールアプリを開く", systemImage: "envelope.open.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Subtext
                Text("パスワード不要。メールに届くリンクをタップするだけ。")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            // Divider
            HStack {
                Rectangle()
                    .fill(Color.jfBorder)
                    .frame(height: 1)
                Text("できること")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                Rectangle()
                    .fill(Color.jfBorder)
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)

            // Features
            VStack(spacing: 12) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "進捗トラッキング", desc: "テクニック習得の進捗を可視化", color: .blue)
                FeatureRow(icon: "heart.fill", title: "お気に入り", desc: "動画やテクニックをブックマーク", color: .pink)
                FeatureRow(icon: "trophy.fill", title: "ゲームプラン", desc: "試合用の戦略を作成・管理", color: .orange)
                FeatureRow(icon: "calendar", title: "練習日記", desc: "トレーニングの記録と振り返り", color: .green)
            }
            .padding(.horizontal, 24)

            // Social proof
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.caption)
                Text("1,000+ 柔術家が利用中")
                    .font(.caption.bold())
            }
            .foregroundStyle(Color.jfTextTertiary)
            .padding(.top, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Logged In View

    private var loggedInView: some View {
        VStack(spacing: 24) {
            // Profile header
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.jfRedGradient)
                        .frame(width: 80, height: 80)
                    Text(String((api.currentUser?.display_name ?? api.currentUser?.email ?? "?").prefix(1)).uppercased())
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .shadow(color: .jfRed.opacity(0.3), radius: 16)
                .padding(.top, 20)

                Text(api.currentUser?.display_name ?? "ようこそ!")
                    .font(.title2.bold())
                    .foregroundStyle(Color.jfTextPrimary)

                Text(api.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            // Quick stats / encouraging prompt
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DashboardStat(icon: "flame.fill", value: "--", label: "連続日数", color: .orange)
                    DashboardStat(icon: "figure.martial.arts", value: "--", label: "テクニック", color: .jfRed)
                    DashboardStat(icon: "heart.fill", value: "--", label: "お気に入り", color: .pink)
                }

                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("練習を記録して連続記録を作ろう!")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 12)
            }
            .padding(.horizontal)

            // Menu items
            VStack(spacing: 10) {
                NavigationLink {
                    PracticeProgressView()
                        .environmentObject(api)
                } label: {
                    MenuRow(icon: "chart.line.uptrend.xyaxis", title: "練習の進捗", color: .blue)
                }

                NavigationLink {
                    FavoritesView()
                        .environmentObject(api)
                } label: {
                    MenuRow(icon: "heart.fill", title: "お気に入り", color: .pink)
                }

                NavigationLink {
                    PracticeJournalView()
                } label: {
                    MenuRow(icon: "calendar", title: "練習日記", color: .green)
                }

                NavigationLink {
                    RollJournalView()
                } label: {
                    MenuRow(icon: "sportscourt", title: "ロール記録", color: .orange)
                }

                NavigationLink {
                    RollTimerView()
                } label: {
                    MenuRow(icon: "timer", title: "ロールタイマー", color: .red)
                }

                NavigationLink {
                    WeightTrackerView()
                } label: {
                    MenuRow(icon: "scalemass.fill", title: "体重管理", color: .mint)
                }

                NavigationLink {
                    AICoachView()
                } label: {
                    MenuRow(icon: "brain.head.profile", title: "AIコーチ分析", color: .blue)
                }

                NavigationLink {
                    StatusShareView()
                } label: {
                    MenuRow(icon: "square.and.arrow.up", title: "ステータスシェア", color: .pink)
                }

                NavigationLink {
                    RoadmapView()
                } label: {
                    MenuRow(icon: "chart.bar.fill", title: "ロードマップ", color: .purple)
                }

                NavigationLink {
                    SubscriptionView()
                        .environmentObject(api)
                } label: {
                    MenuRow(icon: "creditcard.fill", title: "サブスクリプション", color: .yellow)
                }

                NavigationLink {
                    ProfileEditView()
                        .environmentObject(api)
                } label: {
                    MenuRow(icon: "pencil.circle.fill", title: "プロフィール編集", color: .cyan)
                }

                NavigationLink {
                    SettingsView()
                        .environmentObject(api)
                } label: {
                    MenuRow(icon: "gearshape.fill", title: "設定", color: .gray)
                }
            }
            .padding(.horizontal)

            // Logout
            Button {
                api.logout()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("ログアウト")
                }
                .font(.subheadline)
                .foregroundStyle(.red)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: api.isLoggedIn)

            Spacer(minLength: 40)
        }
    }

    // MARK: - Actions

    private func sendMagicLink() async {
        isSending = true
        resultMessage = nil
        isError = false
        showSuccessAnimation = false

        let result = await api.sendMagicLink(email: email)
        withAnimation(.spring(response: 0.4)) {
            resultMessage = result.message
            isError = !result.success
            if result.success {
                showSuccessAnimation = true
            }
        }
        isSending = false
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    var color: Color = .jfRed

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            Spacer()
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}

// MARK: - Dashboard Stat

struct DashboardStat: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .jfRed

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
    }
}

// MARK: - Menu Row

struct MenuRow: View {
    let icon: String
    let title: String
    var color: Color = .jfRed

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.jfTextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}
