import SwiftUI

// MARK: - Template Data (matches PC version)

struct GPTemplate: Identifiable {
    let id: String
    let name: String
    let icon: String
    let tag: String
    let tagColor: Color
    let description: String
}

let gpTemplates: [GPTemplate] = [
    // Systems
    GPTemplate(id: "ryozo", name: "りょうぞうシステム", icon: "🔴", tag: "ガード系", tagColor: .blue,
               description: "クローズドガードをメインに三角絞め・腕十字・スイープを狙う"),
    GPTemplate(id: "hiroki", name: "ひろきシステム", icon: "🕷️", tag: "スパイダー系", tagColor: .purple,
               description: "スパイダーガードからオモプラッタ・三角絞めを狙う"),
    GPTemplate(id: "noji", name: "のじシステム", icon: "🔺", tag: "潜り三角系", tagColor: .red,
               description: "ラッソー・スパイダーから潜り三角を狙う"),
    GPTemplate(id: "hamada", name: "ハマダユウキシステム", icon: "🔺", tag: "三角中心", tagColor: .orange,
               description: "良蔵ベース＋スパイダー三角・セット三角を武器にした三角中心"),
    GPTemplate(id: "awata", name: "アワタシステム", icon: "🛡️", tag: "手堅い系", tagColor: .green,
               description: "ラッソーSP→シンtoシン→クローズドで木村"),
    GPTemplate(id: "top-game", name: "トップゲームシステム", icon: "⬆️", tag: "トップ系", tagColor: .cyan,
               description: "テイクダウン→パスガード→サイドコントロール→マウント"),
    // Style
    GPTemplate(id: "back-taker", name: "バックテイカーシステム", icon: "🎯", tag: "バック系", tagColor: .indigo,
               description: "あらゆるポジションからバックテイクを狙い、RNCでフィニッシュ"),
    GPTemplate(id: "leg-locker", name: "レッグロッカーシステム", icon: "🦵", tag: "足関節系", tagColor: .red,
               description: "ノーギ特化。Kガード・Xガードからサドルでヒールフック"),
    GPTemplate(id: "half-guard", name: "ハーフガードシステム", icon: "🌓", tag: "ハーフ系", tagColor: .blue,
               description: "ニーシールド・ディープハーフからアンダーフックでスイープ"),
    // Pro models
    GPTemplate(id: "gordon", name: "ゴードン・ライアン", icon: "👑", tag: "GOAT", tagColor: .yellow,
               description: "パスガード→マウント→RNC。体系的なトップゲーム"),
    GPTemplate(id: "marcelo", name: "マルセロ・ガルシア", icon: "🦋", tag: "バタフライ", tagColor: .teal,
               description: "バタフライガード→アームドラッグ→バックテイク→RNC"),
    GPTemplate(id: "roger", name: "ロジャー・グレイシー", icon: "🥋", tag: "クラシック", tagColor: .brown,
               description: "クローズドガード→クロスチョーク→マウント。基本の極み"),
    GPTemplate(id: "mikey", name: "マイキー・ムスメシ", icon: "🦶", tag: "50/50", tagColor: .pink,
               description: "50/50→ヒールフック。足関節の革命児"),
    GPTemplate(id: "bernardo", name: "ベルナルド・ファリア", icon: "🐻", tag: "ディープハーフ", tagColor: .purple,
               description: "ディープハーフからのスイープ。体重差を無効化"),
    GPTemplate(id: "craig", name: "クレイグ・ジョーンズ", icon: "🇦🇺", tag: "レッグロック", tagColor: .red,
               description: "Zガード→SLX→サドル→インサイドヒール"),
    GPTemplate(id: "galvao", name: "アンドレ・ガルバン", icon: "💪", tag: "オールラウンド", tagColor: .orange,
               description: "テイクダウンもガードもパスも。万能型の王者"),
    GPTemplate(id: "tonon", name: "ギャリー・トノン", icon: "⚡", tag: "MMA対応", tagColor: .green,
               description: "レッグロック＋スクランブル。MMAにも対応する柔術"),
]

// MARK: - Game Plans View

struct GamePlansView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("テンプレート").tag(0)
                    Text("みんなの").tag(1)
                    Text("AI生成").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Group {
                    switch selectedTab {
                    case 0: templatesSection
                    case 1: communitySection
                    case 2: aiGenerateSection
                    default: EmptyView()
                    }
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle("ゲームプラン")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Templates

    private var templatesSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(gpTemplates) { tpl in
                    NavigationLink {
                        GamePlanDetailView(template: tpl)
                    } label: {
                        templateCard(tpl)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, 40)
        }
    }

    private func templateCard(_ tpl: GPTemplate) -> some View {
        HStack(spacing: 12) {
            Text(tpl.icon)
                .font(.title2)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tpl.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(1)
                    CategoryBadge(text: tpl.tag, color: tpl.tagColor)
                }
                Text(tpl.description)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Community

    private var communitySection: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.jfTextTertiary)
            Text("みんなのゲームプラン")
                .font(.title3.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Text("ログインすると他のユーザーが\n共有したゲームプランが見られます")
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)

            Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/game-plans")!) {
                Label("Webで見る", systemImage: "safari")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Spacer()
        }
    }

    // MARK: - AI Generate

    private var aiGenerateSection: some View {
        AIGamePlanView()
    }
}

// MARK: - Template Detail View

struct GamePlanDetailView: View {
    let template: GPTemplate

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                VStack(spacing: 12) {
                    Text(template.icon)
                        .font(.system(size: 64))
                    Text(template.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    CategoryBadge(text: template.tag, color: template.tagColor)
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 20)

                // Actions
                VStack(spacing: 12) {
                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/game-plans/view/\(template.id)")!) {
                        Label("詳細を見る", systemImage: "eye.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/game-plans/builder/template/\(template.id)")!) {
                        Label("このテンプレートで編集", systemImage: "pencil")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.jfRed.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AI Game Plan View

struct AIGamePlanView: View {
    @State private var inputText = ""
    @State private var isGenerating = false
    @State private var streamOutput = ""
    @State private var generatedPlan: GeneratedPlan?
    @State private var errorMessage: String?

    private let presets = [
        "クローズドガードが得意で三角絞めをメインに使いたい",
        "ハーフガードからのスイープとバックテイク",
        "レッグロック中心のノーギシステム",
        "スパイダーガードとラッソーが好き",
        "テイクダウンからパスガードでトップを取りたい",
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                aiHeader
                presetButtons
                inputSection
                if isGenerating { progressSection }
                if let plan = generatedPlan { resultSection(plan) }
                if let err = errorMessage { errorSection(err) }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header

    private var aiHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.purple)
            Text("AIゲームプラン生成")
                .font(.title3.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Text("得意な技やポジションを入力すると\nAIがあなた専用のゲームプランを作成します")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Presets

    private var presetButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("例文から選ぶ")
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)

            FlowLayout(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        inputText = preset
                    } label: {
                        Text(preset)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.jfCardBg)
                            .foregroundStyle(Color.jfTextSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.jfBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("あなたの得意技・好きなポジション")
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)

            TextEditor(text: $inputText)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.jfBorder, lineWidth: 1)
                )

            Button {
                Task { await generate() }
            } label: {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isGenerating ? "生成中..." : "ゲームプランを生成")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Group {
                        if inputText.isEmpty || isGenerating {
                            Color.gray.opacity(0.4)
                        } else {
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(inputText.isEmpty || isGenerating)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ProgressView().tint(.purple)
                Text("AIが考え中...")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
            }

            if !streamOutput.isEmpty {
                Text(streamOutput)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(streamOutput.count)文字")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(12)
        .glassCard()
    }

    // MARK: - Result

    private func resultSection(_ plan: GeneratedPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(plan.name)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            if !plan.description.isEmpty {
                Text(plan.description)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            // Positions
            if !plan.positions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ポジション")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ForEach(plan.positions, id: \.self) { pos in
                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(.purple)
                            Text(pos)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                    }
                }
            }

            // Submissions
            if !plan.submissions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("サブミッション")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ForEach(plan.submissions, id: \.self) { sub in
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                    }
                }
            }

            // Principles
            if !plan.principles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("原則")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ForEach(plan.principles, id: \.self) { p in
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                            Text(p)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextPrimary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Error

    private func errorSection(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
            Text(msg)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .padding(12)
        .glassCard()
    }

    // MARK: - Generate

    private func generate() async {
        isGenerating = true
        streamOutput = ""
        generatedPlan = nil
        errorMessage = nil

        let systemPrompt = """
        あなたはブラジリアン柔術のゲームプラン作成エキスパートです。
        ユーザーの得意技やポジションの情報を元に、試合用のゲームプランをJSON形式で生成してください。
        ツールは使わないでください。JSONのみを出力してください。

        出力フォーマット:
        {
          "name": "システム名",
          "description": "1行の説明",
          "principles": ["原則1", "原則2", "原則3"],
          "positions": ["メインポジション1", "メインポジション2", ...],
          "submissions": ["技1", "技2", ...],
          "transitions": ["移行1→移行2", ...],
          "defenseNotes": ["防御注意点1", ...]
        }
        """

        let message = "以下の情報を元にゲームプランを作成してください:\n\n\(inputText)"
        let sessionId = "api:jiuflow-ai-\(Int.random(in: 100000...999999))"

        guard let url = URL(string: "https://chatweb.ai/api/v1/chat/stream") else {
            errorMessage = "URLエラー"
            isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "message": message,
            "session_id": sessionId,
            "channel": "jiuflow",
            "custom_system_prompt": systemPrompt,
            "device": "ios"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                errorMessage = "サーバーエラー"
                isGenerating = false
                return
            }

            var fullText = ""
            for try await line in bytes.lines {
                if line.hasPrefix("data: ") {
                    let jsonStr = String(line.dropFirst(6))
                    if let data = jsonStr.data(using: .utf8),
                       let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = event["content"] as? String {
                        fullText += content
                        streamOutput = fullText
                    }
                }
            }

            // Parse JSON from response
            if let plan = parseGamePlan(fullText) {
                generatedPlan = plan
            } else {
                errorMessage = "プランの解析に失敗しました"
            }
        } catch {
            errorMessage = "通信エラー: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    private func parseGamePlan(_ text: String) -> GeneratedPlan? {
        // Extract JSON from markdown code blocks if present
        var json = text
        if let start = json.range(of: "```json") ?? json.range(of: "```") {
            json = String(json[start.upperBound...])
            if let end = json.range(of: "```") {
                json = String(json[..<end.lowerBound])
            }
        }
        json = json.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return GeneratedPlan(
            name: obj["name"] as? String ?? "AIゲームプラン",
            description: obj["description"] as? String ?? "",
            principles: obj["principles"] as? [String] ?? [],
            positions: obj["positions"] as? [String] ?? [],
            submissions: obj["submissions"] as? [String] ?? [],
            transitions: obj["transitions"] as? [String] ?? [],
            defenseNotes: obj["defenseNotes"] as? [String] ?? []
        )
    }
}

// MARK: - Generated Plan Model

struct GeneratedPlan {
    let name: String
    let description: String
    let principles: [String]
    let positions: [String]
    let submissions: [String]
    let transitions: [String]
    let defenseNotes: [String]
}

// MARK: - Flow Layout (for preset buttons)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
