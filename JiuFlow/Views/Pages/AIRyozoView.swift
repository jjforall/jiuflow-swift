import SwiftUI

struct AIRyozoView: View {
    @State private var question = ""
    @State private var messages: [(role: String, text: String)] = [
        ("assistant", "押忍！AI良蔵です。テクニック、戦略、練習メニュー、試合の準備——柔術のことなら何でも聞いてください。\n\n「やられない→コントロール→アタック」の順番を忘れずに！")
    ]
    @State private var isLoading = false
    @FocusState private var isFocused: Bool

    private let suggestions = [
        "クローズドガードから何を狙えばいい？",
        "白帯が最初に覚えるべき3つの技は？",
        "試合前の1週間の過ごし方は？",
        "ハーフガードからのスイープを教えて",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { i, msg in
                            messageBubble(msg.role, msg.text)
                                .id(i)
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

                        // Suggestions (only when few messages)
                        if messages.count <= 2 {
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
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }

            Divider().background(Color.jfBorder)

            // Input
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
        .background(Color.jfDarkBg)
        .navigationTitle("AI良蔵")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func messageBubble(_ role: String, _ text: String) -> some View {
        let isUser = role == "user"
        return HStack(alignment: .top, spacing: 8) {
            if !isUser {
                Text("🥋")
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(Color.jfRed.opacity(0.12))
                    .clipShape(Circle())
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : Color.jfTextPrimary)
                .lineSpacing(4)
                .padding(12)
                .background(isUser ? Color.jfRed : Color.jfCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if isUser { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 16)
    }

    private func send() async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        question = ""
        isFocused = false
        messages.append(("user", q))
        isLoading = true

        // Build prompt
        let systemPrompt = """
        あなたは「AI良蔵」——世界チャンピオン村田良蔵の柔術知識を持つAIアシスタントです。
        良蔵先生の哲学「やられない→コントロール→アタック」をベースに回答します。
        テクニック、戦略、練習メニュー、試合準備、ルール、歴史など柔術に関する全てに答えます。
        回答は簡潔で実践的に。具体的なテクニック名やドリル方法を含めてください。
        日本語で回答してください。
        """

        let chatMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ] + messages.map { ["role": $0.role, "content": $0.text] }

        // Try jiuflow-ssr API first
        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/ai-chat") else {
            messages.append(("assistant", "通信エラーが発生しました。"))
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
                messages.append(("assistant", reply))
            } else {
                // Fallback: local response
                messages.append(("assistant", localAnswer(q)))
            }
        } catch {
            messages.append(("assistant", localAnswer(q)))
        }
        isLoading = false
    }

    /// Simple local fallback when API is unavailable
    private func localAnswer(_ q: String) -> String {
        let lower = q.lowercased()
        if lower.contains("クローズドガード") {
            return "クローズドガードでは「まず姿勢を崩す」ことが最重要です。\n\n1. 相手の頭を下げる（オーバーフック or 袖引き）\n2. 角度をつける（足で腰をコントロール）\n3. 三角絞めor腕十字のコンビネーション\n\n良蔵先生のシステムでは「やられない姿勢」を作ってからアタックに移ります。焦って攻めないことが大切です。"
        } else if lower.contains("白帯") || lower.contains("初心者") || lower.contains("最初") {
            return "白帯が最初に覚えるべき3つ：\n\n1. **エビ（シュリンプ）** — 全エスケープの基礎動作\n2. **クローズドガード** — 最も安全な下のポジション\n3. **マウントエスケープ** — 最も危険な状況からの脱出\n\nこの3つができれば「やられない」が身につきます。攻めは後から！"
        } else if lower.contains("試合") || lower.contains("コンペ") {
            return "試合前の心構え：\n\n1. **ゲームプランを1つだけ決める** — あれもこれもはNG\n2. **最初の30秒を決めておく** — 引き込むか、テイクダウンか\n3. **タップを恐れない** — 負けは学び\n4. **前日は軽く動いて早く寝る**\n5. **水分と軽食を忘れずに**\n\nJiuFlowのゲームプランビルダーで事前に設計しておきましょう！"
        } else if lower.contains("ハーフガード") {
            return "ハーフガードのポイント：\n\n1. **絶対にフラットにならない** — 横向きを維持\n2. **アンダーフックを必ず取る** — 相手の脇下に腕を差す\n3. **ニーシールド** — 膝で距離を作る\n\nスイープの流れ：\nニーシールド → アンダーフック → ドッグファイト → バックテイク or スイープ"
        } else {
            return "良い質問ですね！柔術では「やられない→コントロール→アタック」の順番が大切です。\n\n具体的なテクニックについて知りたい場合は、ポジション名（クローズドガード、マウント、ハーフガードなど）を含めて質問してください。\n\nゲームプランの相談や練習メニューの提案もできますよ！"
        }
    }
}
