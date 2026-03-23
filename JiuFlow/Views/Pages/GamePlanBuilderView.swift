import SwiftUI

// MARK: - Saved Game Plan Model

struct SavedGamePlan: Codable, Identifiable {
    let id: String
    var name: String
    var nodeIds: [String]
    let createdAt: Date

    var stepCount: Int { nodeIds.count }
}

// MARK: - Game Plan Builder View

struct GamePlanBuilderView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var langMgr: LanguageManager
    @State private var planName = ""
    @State private var selectedNodes: [String] = ["start"]
    @State private var savedPlans: [SavedGamePlan] = []
    @State private var showSaveSheet = false
    @State private var showSummaryCard = false
    @State private var showSavedPlans = false
    @State private var editingPlan: SavedGamePlan?

    private let storageKey = "saved_game_plans"

    // Current node is the last selected
    private var currentNodeId: String {
        selectedNodes.last ?? "start"
    }

    private var currentNode: FlowNode? {
        api.flowNodes.first { $0.id == currentNodeId }
    }

    // Outgoing edges from current node
    private var outEdges: [FlowEdge] {
        api.flowEdges.filter { $0.source_id == currentNodeId }
    }

    // Target nodes for outgoing edges
    private func targetNode(for edge: FlowEdge) -> FlowNode? {
        guard let targetId = edge.target_id else { return nil }
        return api.flowNodes.first { $0.id == targetId }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                headerSection
                chainVisualization
                nextStepsSection

                if selectedNodes.count > 1 {
                    actionButtons
                }

                if !savedPlans.isEmpty {
                    savedPlansSection
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(langMgr.t("ゲームプランを作る", en: "Build Game Plan"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            if api.flowNodes.isEmpty {
                await api.loadTechniqueFlow()
            }
            loadSavedPlans()
        }
        .sheet(isPresented: $showSaveSheet) {
            saveSheet
        }
        .sheet(isPresented: $showSummaryCard) {
            summaryCardSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 32))
                .foregroundStyle(.purple)
            Text(langMgr.t("自分だけのゲームプランを組み立てよう", en: "Build your own game plan"))
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
            Text(langMgr.t("スタートから順に次のステップを選んでいきます", en: "Select next steps from the start position"))
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Chain Visualization

    private var chainVisualization: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text(langMgr.t("ゲームプラン", en: "Game Plan"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                Spacer()
                Text("\(selectedNodes.count) \(langMgr.t("ステップ", en: "steps"))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(.bottom, 10)

            ForEach(Array(selectedNodes.enumerated()), id: \.offset) { index, nodeId in
                let node = api.flowNodes.first { $0.id == nodeId }
                HStack(spacing: 10) {
                    // Connector line + dot
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(Color.purple.opacity(0.4))
                                .frame(width: 2, height: 12)
                        }
                        Circle()
                            .fill(index == selectedNodes.count - 1 ? Color.purple : Color.purple.opacity(0.6))
                            .frame(width: 10, height: 10)
                        if index < selectedNodes.count - 1 {
                            Rectangle()
                                .fill(Color.purple.opacity(0.4))
                                .frame(width: 2, height: 12)
                        }
                    }

                    // Node label
                    HStack(spacing: 6) {
                        Text(node?.label ?? nodeId)
                            .font(.caption.bold())
                            .foregroundStyle(
                                index == selectedNodes.count - 1
                                    ? Color.jfTextPrimary
                                    : Color.jfTextSecondary
                            )
                        if let nodeType = node?.node_type {
                            Text(nodeTypeLabel(nodeType))
                                .font(.system(size: 9))
                                .foregroundStyle(nodeTypeColor(nodeType))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(nodeTypeColor(nodeType).opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        if index > 0 {
                            Button {
                                // Remove this node and all after it
                                selectedNodes = Array(selectedNodes.prefix(index))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Next Steps

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(langMgr.t("次のステップを選ぶ", en: "Choose next step"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }

            if outEdges.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(langMgr.t("ゴール！ここがフィニッシュです", en: "Goal! This is the finish"))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                }
                .padding(12)
                .glassCard()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(outEdges) { edge in
                        if let target = targetNode(for: edge) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedNodes.append(target.id)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(nodeTypeColor(target.node_type ?? "").opacity(0.12))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: nodeTypeIcon(target.node_type ?? ""))
                                            .font(.caption)
                                            .foregroundStyle(nodeTypeColor(target.node_type ?? ""))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(target.label ?? target.id)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.jfTextPrimary)
                                        if let edgeLabel = edge.label, !edgeLabel.isEmpty {
                                            Text(edgeLabel)
                                                .font(.caption2)
                                                .foregroundStyle(Color.jfTextTertiary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.blue)
                                }
                                .padding(10)
                                .glassCard(cornerRadius: 12)
                            }
                            .disabled(selectedNodes.contains(target.id))
                            .opacity(selectedNodes.contains(target.id) ? 0.4 : 1)
                        }
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            // Save button
            Button {
                showSaveSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text(langMgr.t("保存する", en: "Save Plan"))
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Summary card button
            if selectedNodes.count >= 3 {
                Button {
                    showSummaryCard = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.fill")
                        Text(langMgr.t("試合前カード", en: "Pre-match Card"))
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            // Reset button
            Button {
                withAnimation {
                    selectedNodes = ["start"]
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text(langMgr.t("リセット", en: "Reset"))
                        .font(.caption.bold())
                }
                .foregroundStyle(Color.jfTextTertiary)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Saved Plans Section

    private var savedPlansSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(langMgr.t("保存したプラン", en: "Saved Plans"))
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                Spacer()
                Text("\(savedPlans.count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.jfTextTertiary)
            }

            ForEach(savedPlans) { plan in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("\(plan.stepCount) \(langMgr.t("ステップ", en: "steps")) \u{00B7} \(plan.createdAt.formatted(.dateTime.month().day()))")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    Spacer()
                    // Load
                    Button {
                        withAnimation {
                            selectedNodes = plan.nodeIds
                        }
                    } label: {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    // Delete
                    Button {
                        withAnimation {
                            savedPlans.removeAll { $0.id == plan.id }
                            persistPlans()
                        }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red.opacity(0.6))
                    }
                }
                .padding(10)
                .glassCard(cornerRadius: 12)
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Save Sheet

    private var saveSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(langMgr.t("ゲームプランを保存", en: "Save Game Plan"))
                    .font(.title3.bold())
                    .foregroundStyle(Color.jfTextPrimary)

                TextField(
                    langMgr.t("プラン名を入力", en: "Enter plan name"),
                    text: $planName
                )
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

                // Preview of the chain
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(selectedNodes.enumerated()), id: \.offset) { i, nodeId in
                        let node = api.flowNodes.first { $0.id == nodeId }
                        HStack(spacing: 6) {
                            Text("\(i + 1).")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.purple)
                            Text(node?.label ?? nodeId)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextSecondary)
                        }
                    }
                }
                .padding(.horizontal)

                Button {
                    savePlan()
                    showSaveSheet = false
                } label: {
                    Text(langMgr.t("保存", en: "Save"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(planName.isEmpty
                            ? AnyShapeStyle(Color.white.opacity(0.1))
                            : AnyShapeStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(planName.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .background(Color.jfDarkBg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(langMgr.t("閉じる", en: "Close")) {
                        showSaveSheet = false
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Summary Card Sheet

    private var summaryCardSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Card
                VStack(spacing: 16) {
                    Text(langMgr.t("試合前カード", en: "Pre-match Card"))
                        .font(.caption.bold())
                        .foregroundStyle(.orange)

                    // Top 3 steps
                    let topSteps = Array(selectedNodes.prefix(4).dropFirst()) // skip "start", take 3
                    ForEach(Array(topSteps.enumerated()), id: \.offset) { i, nodeId in
                        let node = api.flowNodes.first { $0.id == nodeId }
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(stepColor(i).opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Text("\(i + 1)")
                                    .font(.headline.bold())
                                    .foregroundStyle(stepColor(i))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(node?.label ?? nodeId)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.jfTextPrimary)
                                if let desc = node?.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption2)
                                        .foregroundStyle(Color.jfTextTertiary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                    }

                    if selectedNodes.count > 4 {
                        Text("+ \(selectedNodes.count - 4) \(langMgr.t("ステップ", en: "more steps"))")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.08), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .padding(20)

                Text(langMgr.t("試合前にこのカードを見返そう！", en: "Review this card before your match!"))
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)

                Spacer()
            }
            .background(Color.jfDarkBg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(langMgr.t("閉じる", en: "Close")) {
                        showSummaryCard = false
                    }
                    .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func stepColor(_ index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .purple
        case 2: return .red
        default: return .orange
        }
    }

    private func nodeTypeLabel(_ type: String) -> String {
        switch type {
        case "start": return langMgr.t("開始", en: "Start")
        case "decision": return langMgr.t("判断", en: "Decision")
        case "action": return langMgr.t("アクション", en: "Action")
        case "position": return langMgr.t("ポジション", en: "Position")
        case "submission": return langMgr.t("極め", en: "Submission")
        default: return type
        }
    }

    private func nodeTypeColor(_ type: String) -> Color {
        switch type {
        case "start": return .green
        case "decision": return .yellow
        case "action": return .blue
        case "position": return .purple
        case "submission": return .red
        default: return .gray
        }
    }

    private func nodeTypeIcon(_ type: String) -> String {
        switch type {
        case "start": return "play.fill"
        case "decision": return "questionmark.circle.fill"
        case "action": return "figure.martial.arts"
        case "position": return "person.fill"
        case "submission": return "bolt.fill"
        default: return "circle.fill"
        }
    }

    // MARK: - Persistence

    private func loadSavedPlans() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let plans = try? JSONDecoder().decode([SavedGamePlan].self, from: data) else {
            return
        }
        savedPlans = plans.sorted { $0.createdAt > $1.createdAt }
    }

    private func savePlan() {
        let plan = SavedGamePlan(
            id: UUID().uuidString,
            name: planName.isEmpty ? "My Plan" : planName,
            nodeIds: selectedNodes,
            createdAt: Date()
        )
        savedPlans.insert(plan, at: 0)
        persistPlans()
        planName = ""
    }

    private func persistPlans() {
        if let data = try? JSONEncoder().encode(savedPlans) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
