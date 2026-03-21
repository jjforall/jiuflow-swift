import SwiftUI

struct ForumView: View {
    @EnvironmentObject var api: APIService
    @State private var showNewThread = false
    @State private var selectedCategory: String?

    private let categories = [
        ("general", "一般"),
        ("technique", "テクニック"),
        ("tournament", "大会"),
        ("dojo", "道場"),
        ("gear", "道具")
    ]

    private var filteredThreads: [ForumThread] {
        guard let cat = selectedCategory else { return api.forumThreads }
        return api.forumThreads.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.forumThreads.isEmpty && !api.isLoading {
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: "まだ投稿がありません",
                        message: "最初のトピックを作成してみましょう",
                        actionTitle: "新しいトピック"
                    ) {
                        showNewThread = true
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Category filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(title: "すべて", isSelected: selectedCategory == nil) {
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
            .navigationTitle("コミュニティ")
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

                if let id = Optional(thread.id) {
                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/community/thread/\(id)")!) {
                        Label("Webで返信を見る", systemImage: "safari")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
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
        ("general", "一般"),
        ("technique", "テクニック"),
        ("tournament", "大会"),
        ("dojo", "道場"),
        ("gear", "道具")
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
        .navigationTitle("新しいトピック")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
                    .foregroundStyle(Color.jfTextSecondary)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ")
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
            Text("タイトル")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            TextField("トピックのタイトル", text: $title)
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
            Text("本文")
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
                Text(isSubmitting ? "投稿中..." : "投稿する")
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
