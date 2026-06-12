import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var api: APIService
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("practice_reminder_hour") private var reminderHour = 18
    @EnvironmentObject var lang: LanguageManager

    // Account deletion (App Store Guideline 5.1.1(v))
    @State private var showDeleteConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?

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

            Divider().background(Color.jfBorder)

            // Account deletion (required by App Store Guideline 5.1.1(v))
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 10) {
                    if isDeletingAccount {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundStyle(.red)
                    }
                    Text(lang.t("アカウントを削除", en: "Delete Account"))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Spacer()
                }
            }
            .disabled(isDeletingAccount)

            if let error = deleteErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .glassCard()
        .confirmationDialog(
            lang.t("アカウントを削除しますか？", en: "Delete your account?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(lang.t("完全に削除する", en: "Delete Permanently"), role: .destructive) {
                Task { await performAccountDeletion() }
            }
            Button(lang.t("キャンセル", en: "Cancel"), role: .cancel) {}
        } message: {
            Text(lang.t(
                "アカウントと練習記録・購読情報などすべてのデータが完全に削除されます。この操作は取り消せません。",
                en: "Your account and all data (practice records, subscription info, etc.) will be permanently deleted. This cannot be undone."
            ))
        }
    }

    private func performAccountDeletion() async {
        isDeletingAccount = true
        deleteErrorMessage = nil
        let result = await api.deleteAccount()
        isDeletingAccount = false
        if !result.success {
            deleteErrorMessage = result.message
        }
        // On success api.deleteAccount() logs out locally,
        // so the account section disappears automatically.
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
            .onChange(of: notificationsEnabled) { _, enabled in
                if enabled {
                    schedulePracticeReminder(hour: reminderHour)
                } else {
                    cancelPracticeReminder()
                }
            }

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
                    .onChange(of: reminderHour) { _, newHour in
                        if notificationsEnabled {
                            schedulePracticeReminder(hour: newHour)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Display

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingSectionHeader(lang.t("表示", en: "Display"), icon: "paintbrush.fill")

            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.green)
                Text(lang.t("言語", en: "Language"))
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Picker("", selection: $lang.current) {
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

            Link(destination: URL(string: "https://jiuflow.com/privacy")!) {
                settingsRow(icon: "hand.raised.fill", title: "プライバシーポリシー", color: .blue)
            }

            Link(destination: URL(string: "https://jiuflow.com/terms")!) {
                settingsRow(icon: "doc.text.fill", title: "利用規約", color: .purple)
            }

            Link(destination: URL(string: "https://jiuflow.com")!) {
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

    private func schedulePracticeReminder(hour: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["practice_reminder"])
            let content = UNMutableNotificationContent()
            content.title = "練習の時間です！"
            content.body = "今日の柔術練習を記録しましょう 🥋"
            content.sound = .default
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "practice_reminder", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelPracticeReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["practice_reminder"])
    }
}
