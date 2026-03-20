import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var api: APIService
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("practice_reminder_hour") private var reminderHour = 19
    @AppStorage("preferred_language") private var preferredLanguage = "ja"

    private let languages = [
        ("ja", "日本語"),
        ("en", "English"),
        ("pt", "Portugues")
    ]

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Account
                if api.isLoggedIn {
                    accountSection
                }

                // Notifications
                notificationSection

                // Display
                displaySection

                // Data
                dataSection

                // About
                aboutSection

                // App info
                VStack(spacing: 4) {
                    Text("JiuFlow v\(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text("art.jiuflow.ios")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary.opacity(0.5))
                }
                .padding(.top, 12)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Account

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader("アカウント", icon: "person.circle.fill")

            if let user = api.currentUser {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.jfRedGradient)
                            .frame(width: 44, height: 44)
                        Text(String((user.display_name ?? user.email).prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.display_name ?? "ユーザー")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader("通知", icon: "bell.fill")

            Toggle(isOn: $notificationsEnabled) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.orange)
                    Text("練習リマインダー")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextPrimary)
                }
            }
            .tint(.jfRed)

            if notificationsEnabled {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text("リマインダー時刻")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Picker("", selection: $reminderHour) {
                        ForEach(6..<24, id: \.self) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .tint(Color.jfTextSecondary)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Display

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader("表示", icon: "paintbrush.fill")

            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.green)
                Text("言語")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Picker("", selection: $preferredLanguage) {
                    ForEach(languages, id: \.0) { lang in
                        Text(lang.1).tag(lang.0)
                    }
                }
                .tint(Color.jfTextSecondary)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader("データ", icon: "externaldrive.fill")

            Button {
                clearCache()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                    Text("キャッシュをクリア")
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader("JiuFlowについて", icon: "info.circle.fill")

            Link(destination: URL(string: "https://jiuflow.art/privacy")!) {
                settingsRow(icon: "hand.raised.fill", title: "プライバシーポリシー", color: .blue)
            }

            Link(destination: URL(string: "https://jiuflow.art/terms")!) {
                settingsRow(icon: "doc.text.fill", title: "利用規約", color: .purple)
            }

            Link(destination: URL(string: "https://jiuflow.art")!) {
                settingsRow(icon: "safari.fill", title: "公式サイト", color: .jfRed)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func settingSectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.jfRed)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
        }
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextPrimary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
    }

    private func clearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
}
