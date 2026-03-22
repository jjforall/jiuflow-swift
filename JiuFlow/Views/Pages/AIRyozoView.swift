import SwiftUI

// MARK: - Chat Models

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: String
    let text: String

    init(role: String, text: String) {
        self.id = UUID().uuidString
        self.role = role
        self.text = text
    }
}

struct ChatSession: Codable, Identifiable {
    let id: String
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    init(title: String = "新しい会話") {
        self.id = UUID().uuidString
        self.title = title
        self.messages = [
            ChatMessage(role: "assistant", text: "押忍！AI良蔵です。テクニック、戦略、練習メニュー、試合の準備——柔術のことなら何でも聞いてください。")
        ]
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Chat Store

@MainActor
class ChatStore: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: String?
    private let key = "ai_ryozo_sessions"

    var currentSession: ChatSession? {
        sessions.first { $0.id == currentSessionId }
    }

    init() { load() }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else { return }
        sessions = decoded.sorted { $0.updatedAt > $1.updatedAt }
        if currentSessionId == nil { currentSessionId = sessions.first?.id }
    }

    func save() {
        if let data = try? JSONEncoder().encode(sessions) { UserDefaults.standard.set(data, forKey: key) }
    }

    func newSession() -> String {
        let session = ChatSession()
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        save()
        return session.id
    }

    func addMessage(_ msg: ChatMessage) {
        guard let i = sessions.firstIndex(where: { $0.id == currentSessionId }) else { return }
        sessions[i].messages.append(msg)
        sessions[i].updatedAt = Date()
        // Auto-title from first user message
        if sessions[i].title == "新しい会話", msg.role == "user" {
            sessions[i].title = String(msg.text.prefix(30))
        }
        save()
    }

    func deleteSession(_ id: String) {
        sessions.removeAll { $0.id == id }
        if currentSessionId == id { currentSessionId = sessions.first?.id }
        save()
    }
}

// MARK: - Main View

struct AIRyozoView: View {
    @EnvironmentObject var premium: PremiumManager
    @StateObject private var store = ChatStore()
    @State private var showHistory = false
    @State private var askRealRyozoSheet: String?

    var body: some View {
        Group {
            if premium.isPremium {
                mainContent
            } else {
                ScrollView {
                    PremiumGate(feature: "AI良蔵") {
                        EmptyView()
                    }
                    .padding(16)
                }
                .background(Color.jfDarkBg)
            }
        }
        .navigationTitle("AI良蔵")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var mainContent: some View {
        ZStack(alignment: .leading) {
            // Chat view
            chatView
                .onAppear {
                    if store.sessions.isEmpty { let _ = store.newSession() }
                    else if store.currentSessionId == nil { store.currentSessionId = store.sessions.first?.id }
                }

            // History overlay
            if showHistory {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showHistory = false } }

                historyPanel
                    .transition(.move(edge: .leading))
            }
        }
        .sheet(item: Binding(
            get: { askRealRyozoSheet.map { AskRyozoItem(text: $0) } },
            set: { askRealRyozoSheet = $0?.text }
        )) { item in
            AskRealRyozoSheet(aiResponse: item.text)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.spring(response: 0.3)) { showHistory.toggle() }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let _ = store.newSession()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
    }

    // MARK: - History Panel

    private var historyPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("履歴")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Button {
                    let _ = store.newSession()
                    withAnimation { showHistory = false }
                } label: {
                    Label("新規", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfRed)
                }
            }
            .padding(16)

            Divider().background(Color.jfBorder)

            // Session list
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(store.sessions) { session in
                        sessionRow(session)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 280)
        .background(Color(uiColor: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        let isCurrent = session.id == store.currentSessionId
        let df = DateFormatter()
        df.locale = Locale(identifier: "ja_JP")
        df.dateFormat = "M/d HH:mm"

        return Button {
            store.currentSessionId = session.id
            withAnimation { showHistory = false }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(isCurrent ? Color.jfRed : Color.jfTextPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(df.string(from: session.updatedAt))
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                        Text("(\(session.messages.count)件)")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
                Spacer()
                if isCurrent {
                    Circle().fill(Color.jfRed).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isCurrent ? Color.jfRed.opacity(0.08) : Color.clear)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.deleteSession(session.id)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Chat View

    private var chatView: some View {
        VStack(spacing: 0) {
            if let session = store.currentSession {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(session.messages) { msg in
                                messageBubble(msg)
                            }

                            if isLoading {
                                HStack(spacing: 8) {
                                    ProgressView().tint(Color.jfRed).scaleEffect(0.7)
                                    Text("考え中...")
                                        .font(.caption)
                                        .foregroundStyle(Color.jfTextTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .id("loading")
                            }

                            // Suggestions
                            if session.messages.count <= 2 {
                                suggestionsView
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: session.messages.count) { _, _ in
                        if let last = session.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            } else {
                Spacer()
                Text("新しい会話を始めましょう")
                    .foregroundStyle(Color.jfTextTertiary)
                Spacer()
            }

            Divider().background(Color.jfBorder)
            inputBar
        }
        .background(Color.jfDarkBg)
    }

    @State private var question = ""
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    private let suggestions = [
        "クローズドガードから何を狙えばいい？",
        "白帯が最初に覚えるべき3つの技は？",
        "試合前の1週間の過ごし方は？",
        "ハーフガードからのスイープを教えて",
    ]

    private var suggestionsView: some View {
        VStack(spacing: 8) {
            Text("こんな質問ができます")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
            ForEach(suggestions, id: \.self) { s in
                Button {
                    question = s
                    Task { await send() }
                } label: {
                    Text(s)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("質問を入力...", text: $question, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isFocused)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(question.isEmpty || isLoading ? Color.jfTextTertiary : Color.jfRed)
            }
            .disabled(question.isEmpty || isLoading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.jfDarkBg)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == "user"
        return HStack(alignment: .top, spacing: 8) {
            if !isUser {
                Text("🥋")
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(Color.jfRed.opacity(0.12))
                    .clipShape(Circle())
            }

            Text(msg.text)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : Color.jfTextPrimary)
                .lineSpacing(4)
                .padding(12)
                .background(isUser ? Color.jfRed : Color.jfCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .textSelection(.enabled)

            if isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 16)

        // "Ask real Ryozo" button after AI responses
        if !isUser {
            Button {
                askRealRyozoSheet = msg.text
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.wave.2")
                        .font(.caption2)
                    Text("良蔵先生に直接聞く")
                        .font(.caption2)
                }
                .foregroundStyle(Color.jfTextTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 56)
        }
    }

    // MARK: - Send

    private func send() async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        // Ensure we have a session
        if store.currentSessionId == nil { let _ = store.newSession() }

        question = ""
        isFocused = false
        store.addMessage(ChatMessage(role: "user", text: q))
        isLoading = true

        let systemPrompt = """
        あなたは「AI良蔵」——世界チャンピオン村田良蔵の柔術知識を持つAIアシスタントです。
        良蔵先生の哲学「やられない→コントロール→アタック」をベースに回答します。
        テクニック、戦略、練習メニュー、試合準備、ルール、歴史など柔術に関する全てに答えます。
        回答は簡潔で実践的に。具体的なテクニック名やドリル方法を含めてください。
        日本語で回答してください。
        """

        let msgs = store.currentSession?.messages ?? []
        let chatMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ] + msgs.map { ["role": $0.role, "content": $0.text] }

        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/ai-chat") else {
            store.addMessage(ChatMessage(role: "assistant", text: "通信エラー"))
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let body: [String: Any] = ["messages": chatMessages]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reply = json["reply"] as? String {
                store.addMessage(ChatMessage(role: "assistant", text: reply))
            } else {
                store.addMessage(ChatMessage(role: "assistant", text: localAnswer(q)))
            }
        } catch {
            store.addMessage(ChatMessage(role: "assistant", text: localAnswer(q)))
        }
        isLoading = false
    }

}

// MARK: - Ask Real Ryozo Sheet

struct AskRyozoItem: Identifiable {
    let id = UUID()
    let text: String
}

struct AskRealRyozoSheet: View {
    let aiResponse: String
    @State private var userQuestion = ""
    @State private var sent = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // AI response preview
                VStack(alignment: .leading, spacing: 6) {
                    Text("AIの回答")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(aiResponse)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineLimit(4)
                        .padding(10)
                        .background(Color.jfCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // User's question to Ryozo
                VStack(alignment: .leading, spacing: 6) {
                    Text("良蔵先生への質問")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    TextEditor(text: $userQuestion)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .background(Color.jfCardBg)
                        .foregroundStyle(Color.jfTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if sent {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("送信しました！良蔵先生から回答があれば通知でお知らせします。")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Button {
                        Task { await sendToRyozo() }
                    } label: {
                        Text("良蔵先生に送信")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                            Group {
                                if userQuestion.isEmpty { Color.gray.opacity(0.4) }
                                else { LinearGradient.jfRedGradient }
                            }
                        )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(userQuestion.isEmpty)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.jfDarkBg)
            .navigationTitle("良蔵先生に聞く")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
    }

    private func sendToRyozo() async {
        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/ask-ryozo") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "question": userQuestion,
            "ai_response": String(aiResponse.prefix(500))
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let _ = try? await URLSession.shared.data(for: req)
        sent = true
    }
}

// MARK: - Local Answers

extension AIRyozoView {
    func localAnswer(_ q: String) -> String {
        let lower = q.lowercased()
        if lower.contains("クローズドガード") {
            return "クローズドガードでは「まず姿勢を崩す」ことが最重要です。\n\n1. 相手の頭を下げる（オーバーフック or 袖引き）\n2. 角度をつける（足で腰をコントロール）\n3. 三角絞めor腕十字のコンビネーション\n\n良蔵先生のシステムでは「やられない姿勢」を作ってからアタックに移ります。"
        } else if lower.contains("白帯") || lower.contains("初心者") || lower.contains("最初") {
            return "白帯が最初に覚えるべき3つ：\n\n1. エビ（シュリンプ） — 全エスケープの基礎\n2. クローズドガード — 最も安全な下のポジション\n3. マウントエスケープ — 最も危険な状況からの脱出\n\nこの3つで「やられない」が身につきます。"
        } else if lower.contains("試合") || lower.contains("コンペ") {
            return "試合前の心構え：\n\n1. ゲームプランを1つだけ決める\n2. 最初の30秒を決めておく\n3. タップを恐れない — 負けは学び\n4. 前日は軽く動いて早く寝る\n5. 水分と軽食を忘れずに"
        } else if lower.contains("ハーフガード") {
            return "ハーフガードのポイント：\n\n1. 絶対にフラットにならない — 横向き維持\n2. アンダーフックを必ず取る\n3. ニーシールドで距離を作る\n\nスイープ：ニーシールド → アンダーフック → ドッグファイト → バックテイク or スイープ"
        } else {
            return "良い質問ですね！「やられない→コントロール→アタック」の順番が大切です。\n\nポジション名（クローズドガード、マウント、ハーフガードなど）を含めて質問すると、より具体的にお答えできます。"
        }
    }
}
