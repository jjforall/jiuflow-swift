import SwiftUI

struct ForumView: View {
    @EnvironmentObject var api: APIService
    @State private var showNewThread = false
    @State private var selectedCategory: String?

    private let categories = [
        ("general", tr("一般")),
        ("technique", tr("テクニック")),
        ("tournament", tr("大会")),
        ("dojo", tr("道場")),
        ("gear", tr("道具"))
    ]

    private var filteredThreads: [ForumThread] {
        guard let cat = selectedCategory else { return api.forumThreads }
        return api.forumThreads.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.forumThreads.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { _ in SkeletonCard(height: 80) }
                    }
                    .padding()
                } else if api.forumThreads.isEmpty {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: tr("まだ投稿がありません"),
                        message: tr("最初のトピックを作成してみましょう"),
                        actionTitle: tr("新しいトピック")
                    ) {
                        showNewThread = true
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Category filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(title: tr("すべて"), isSelected: selectedCategory == nil) {
                                        selectedCategory = nil
                                    }
                                    ForEach(categories, id: \.0) { cat in
                                        FilterChip(title: cat.1, isSelected: selectedCategory == cat.0) {
                                            selectedCategory = cat.0
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 4)

                            // Threads
                            LazyVStack(spacing: 10) {
                                ForEach(filteredThreads) { thread in
                                    NavigationLink {
                                        ForumThreadDetailView(thread: thread)
                                    } label: {
                                        ForumThreadRow(thread: thread)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle(tr("コミュニティ"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewThread = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.jfRed)
                    }
                }
            }
            .task {
                await api.loadForumThreads()
            }
            .refreshable {
                await api.loadForumThreads()
            }
            .sheet(isPresented: $showNewThread) {
                NavigationStack {
                    NewThreadView()
                        .environmentObject(api)
                }
            }
        }
    }
}

// MARK: - Forum Thread Row

struct ForumThreadRow: View {
    let thread: ForumThread

    private var categoryColor: Color {
        switch thread.category {
        case "technique": return .blue
        case "tournament": return .orange
        case "dojo": return .green
        case "gear": return .purple
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if thread.is_pinned == true {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                CategoryBadge(text: thread.categoryLabel, color: categoryColor)
                Spacer()
                Text(thread.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            Text(thread.displayTitle)
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                if let name = thread.display_name {
                    Label(name, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                if let replies = thread.reply_count, replies > 0 {
                    Label("\(replies)", systemImage: "bubble.left.fill")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(14)
        .glassCard()
    }
}

// MARK: - Forum Thread Detail

struct ForumThreadDetailView: View {
    let thread: ForumThread
    @EnvironmentObject var api: APIService
    @State private var replies: [ForumReply] = []
    @State private var isLoadingReplies = true
    @State private var replyText = ""
    @State private var isReplying = false
    @State private var replyResult: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    CategoryBadge(text: thread.categoryLabel)
                    if thread.is_pinned == true {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Text(thread.relativeDate)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                Text(thread.displayTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Color.jfTextPrimary)

                if let name = thread.display_name {
                    Label(name, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                }

                Divider().background(Color.jfBorder)

                Text(thread.body ?? "")
                    .font(.body)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(6)

                repliesSection
                replySection
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadReplies() }
    }

    @ViewBuilder
    private var repliesSection: some View {
        if isLoadingReplies {
            ProgressView().frame(maxWidth: .infinity)
        } else if !replies.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("返信 \(replies.count)件")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)

                ForEach(replies) { reply in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(reply.display_name ?? tr("名無し"), systemImage: "person.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextSecondary)
                            Spacer()
                            Text(reply.relativeDate)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Text(reply.body)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                            .lineSpacing(4)
                    }
                    .padding(12)
                    .glassCard()
                }
            }
            .padding(.top, 8)
        }
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !api.isLoggedIn {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(tr("返信するにはログインが必要です"))
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .glassCard()
            } else {
                Text(tr("返信する"))
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)

                TextEditor(text: $replyText)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await sendReply() }
                } label: {
                    HStack {
                        if isReplying { ProgressView().tint(.white).scaleEffect(0.7) }
                        Text(isReplying ? tr("送信中...") : tr("返信する"))
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(replyText.isEmpty || isReplying ? Color.gray.opacity(0.4) : Color.jfRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(replyText.isEmpty || isReplying)

                if let result = replyResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.top, 8)
    }

    private func loadReplies() async {
        isLoadingReplies = true
        guard let url = URL(string: "\(api.baseURL)/api/v1/forum/threads/\(thread.id)/replies") else {
            isLoadingReplies = false
            return
        }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let t = api.authToken { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let decoded = try JSONDecoder().decode(ForumRepliesResponse.self, from: data)
            replies = decoded.replies
        } catch {
            replies = []
        }
        isLoadingReplies = false
    }

    private func sendReply() async {
        isReplying = true
        guard let url = URL(string: "\(api.baseURL)/api/v1/forum/threads/\(thread.id)/replies") else {
            isReplying = false
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = api.authToken { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let payload = ["body": replyText]
        req.httpBody = try? JSONEncoder().encode(payload)
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                replyResult = tr("返信しました！")
                replyText = ""
                await loadReplies()
            } else {
                replyResult = tr("送信に失敗しました")
            }
        } catch {
            replyResult = tr("通信エラー")
        }
        isReplying = false
    }
}

// MARK: - New Thread View

struct NewThreadView: View {
    @EnvironmentObject var api: APIService
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var body_ = ""
    @State private var category = "general"
    @State private var isSubmitting = false

    private let categories = [
        ("general", tr("一般")),
        ("technique", tr("テクニック")),
        ("tournament", tr("大会")),
        ("dojo", tr("道場")),
        ("gear", tr("道具"))
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                categorySection
                titleSection
                bodySection
                submitButton
            }
            .padding(16)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(tr("新しいトピック"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(tr("キャンセル")) { dismiss() }
                    .foregroundStyle(Color.jfTextSecondary)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("カテゴリ"))
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(categories, id: \.0) { cat in
                    Button {
                        category = cat.0
                    } label: {
                        Text(cat.1)
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(category == cat.0 ? Color.jfRed : Color.jfCardBg)
                            .foregroundStyle(category == cat.0 ? .white : Color.jfTextSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("タイトル"))
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            TextField(tr("トピックのタイトル"), text: $title)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .glassCard()
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("本文"))
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            TextEditor(text: $body_)
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .glassCard()
    }

    private var submitButton: some View {
        let canSubmit = !title.isEmpty && !body_.isEmpty && !isSubmitting
        return Button {
            Task {
                isSubmitting = true
                let success = await api.createForumThread(title: title, body: body_, category: category)
                isSubmitting = false
                if success { dismiss() }
            }
        } label: {
            HStack {
                if isSubmitting { ProgressView().tint(.white) }
                Text(isSubmitting ? tr("投稿中...") : tr("投稿する"))
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSubmit ? Color.jfRed : Color.gray.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSubmit)
    }
}
