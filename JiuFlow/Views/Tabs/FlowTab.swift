import SwiftUI

// MARK: - Game Plan Definitions (maps system names to flow node IDs)

struct GamePlanRoute: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let description: String
    let nodeIds: [String] // ordered path through the flow
}

let gamePlanRoutes: [GamePlanRoute] = [
    GamePlanRoute(
        id: "ryozo",
        name: "良蔵システム",
        icon: "brain.head.profile",
        color: .purple,
        description: "基本を極める。クローズドガード→崩し→極めの王道ルート。",
        nodeIds: ["start", "d_stance", "d_pull_type", "a_pull", "d_guard", "p_closed",
                  "d_cg_opp", "d_cg_sub", "d_cg_sweep"]
    ),
    GamePlanRoute(
        id: "ryozo_half",
        name: "良蔵システム (ハーフガード)",
        icon: "shield.lefthalf.filled",
        color: .blue,
        description: "ハーフガードから復活→スイープ→トップの流れ。大人の柔術の真髄。",
        nodeIds: ["start", "d_stance", "p_half", "d_hg_uf", "p_knee_shield",
                  "p_deep", "d_deep"]
    ),
    GamePlanRoute(
        id: "takedown",
        name: "テイクダウン重視",
        icon: "arrow.down.circle",
        color: .green,
        description: "立ちで勝負→テイクダウン→トップコントロール→極め。",
        nodeIds: ["start", "d_stance", "d_td_type", "a_double", "a_single",
                  "d_td_result", "d_pass_type", "d_side_attack", "d_mount_attack"]
    ),
    GamePlanRoute(
        id: "berimbolo",
        name: "ベリンボロ系",
        icon: "arrow.triangle.2.circlepath",
        color: .orange,
        description: "DLR引き込み→ベリンボロ→バックテイク。モダン柔術の代表。",
        nodeIds: ["start", "d_stance", "d_pull_type", "d_guard", "p_dlr",
                  "d_dlr_st", "d_beri", "d_back_attack"]
    ),
    GamePlanRoute(
        id: "leglock",
        name: "足関節ハンター",
        icon: "figure.walk",
        color: .red,
        description: "SLX→サドル→ヒールフック。ダナハーシステムの真髄。",
        nodeIds: ["start", "d_stance", "d_pull_type", "d_guard", "p_slx",
                  "d_slx", "p_saddle", "d_ll", "p_5050", "d_ll_50"]
    ),
    GamePlanRoute(
        id: "butterfly",
        name: "バタフライスイーパー",
        icon: "leaf.fill",
        color: .teal,
        description: "バタフライガード→スイープ→トップ。マルセロ・ガルシアスタイル。",
        nodeIds: ["start", "d_stance", "d_pull_type", "d_guard", "p_butterfly",
                  "d_bf_arm", "d_pass_type", "d_side_attack"]
    ),
]

// MARK: - Flow Tab (Main Tab)

struct FlowTab: View {
    @EnvironmentObject var api: APIService
    @State private var selectedPlan: GamePlanRoute?
    @State private var showPlanPicker = false
    @State private var currentNodeId: String = "start"
    @State private var breadcrumb: [String] = []
    @State private var viewMode: Int = 0  // 0=step, 1=overview

    private var currentNode: FlowNode? {
        api.flowNodes.first { $0.id == currentNodeId }
    }

    private var outEdges: [FlowEdge] {
        api.flowEdges.filter { $0.source_id == currentNodeId }
    }

    private var planNodeSet: Set<String> {
        Set(selectedPlan?.nodeIds ?? [])
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("表示", selection: $viewMode) {
                    Text("ステップ").tag(0)
                    Text("全体図").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                // Content — both use same flow_nodes/flow_edges DB
                if viewMode == 0 {
                    flowContent
                } else {
                    TechniqueVisualGraphView()
                        .environmentObject(api)
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle("フロー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPlanPicker = true
                    } label: {
                        Image(systemName: "map.fill")
                            .foregroundStyle(selectedPlan != nil ? Color.jfRed : Color.jfTextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showPlanPicker) {
                planPickerSheet
            }
            .task {
                if api.flowNodes.isEmpty { await api.loadTechniqueFlow() }
                if api.videos.isEmpty { await api.loadVideos() }
            }
        }
    }

    // MARK: - Flow Content

    private var flowContent: some View {
        Group {
            if api.isLoading && api.flowNodes.isEmpty {
                VStack(spacing: 14) {
                    SkeletonCard(height: 200)
                    SkeletonCard(height: 80)
                    SkeletonCard(height: 80)
                    SkeletonCard(height: 80)
                }
                .padding()
            } else {
                flowScrollContent
            }
        }
    }

    private var flowScrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                planSelectorBar

                if let plan = selectedPlan {
                    activePlanBanner(plan)
                }

                if !breadcrumb.isEmpty {
                    breadcrumbBar
                }

                if let node = currentNode {
                    currentNodeHero(node)
                }

                if !outEdges.isEmpty {
                    pathsSection
                } else if currentNode != nil {
                    deadEndView
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Map Content (Technique Tree)

    // MARK: - Plan Selector Bar

    private var planSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Free" mode
                Button {
                    withAnimation { selectedPlan = nil }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text("自由探索")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedPlan == nil ? Color.jfRed : Color.jfCardBg)
                    .foregroundStyle(selectedPlan == nil ? .white : Color.jfTextSecondary)
                    .clipShape(Capsule())
                }

                ForEach(gamePlanRoutes) { plan in
                    Button {
                        withAnimation {
                            selectedPlan = plan
                            currentNodeId = plan.nodeIds.first ?? "start"
                            breadcrumb = []
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: plan.icon)
                                .font(.caption2)
                            Text(plan.name)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedPlan?.id == plan.id ? plan.color : Color.jfCardBg)
                        .foregroundStyle(selectedPlan?.id == plan.id ? .white : Color.jfTextSecondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Active Plan Banner

    private func activePlanBanner(_ plan: GamePlanRoute) -> some View {
        HStack(spacing: 10) {
            Image(systemName: plan.icon)
                .font(.body)
                .foregroundStyle(plan.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(plan.description)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Progress indicator
            let currentIdx = plan.nodeIds.firstIndex(of: currentNodeId) ?? 0
            Text("\(currentIdx + 1)/\(plan.nodeIds.count)")
                .font(.caption2.bold().monospacedDigit())
                .foregroundStyle(plan.color)
        }
        .padding(10)
        .background(plan.color.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(plan.color)
                .frame(height: 2),
            alignment: .bottom
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Breadcrumb

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button {
                    navigateTo(selectedPlan?.nodeIds.first ?? "start")
                    breadcrumb = []
                } label: {
                    Image(systemName: "house.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                ForEach(Array(breadcrumb.enumerated()), id: \.offset) { index, nodeId in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.jfTextTertiary.opacity(0.4))

                    if let node = api.flowNodes.first(where: { $0.id == nodeId }) {
                        Button {
                            navigateTo(nodeId)
                            breadcrumb = Array(breadcrumb.prefix(index))
                        } label: {
                            Text(node.label ?? node.id)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.jfTextTertiary.opacity(0.4))

                if let node = currentNode {
                    Text(node.label ?? node.id)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.jfRed)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Current Node Hero

    private func currentNodeHero(_ node: FlowNode) -> some View {
        let isOnPlan = planNodeSet.contains(node.id)
        let planColor = selectedPlan?.color ?? Color.jfRed

        return VStack(spacing: 16) {
            // Type icon
            ZStack {
                Circle()
                    .fill((isOnPlan ? planColor : nodeColor(node.node_type)).opacity(0.15))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(isOnPlan ? planColor : nodeColor(node.node_type), lineWidth: 2.5)
                    .frame(width: 80, height: 80)
                PositionIcon(nodeId: node.id, nodeType: node.node_type, size: 50)
            }
            .shadow(color: (isOnPlan ? planColor : nodeColor(node.node_type)).opacity(0.3), radius: 12)

            // Plan step indicator
            if isOnPlan, let plan = selectedPlan,
               let idx = plan.nodeIds.firstIndex(of: node.id) {
                HStack(spacing: 4) {
                    ForEach(0..<plan.nodeIds.count, id: \.self) { i in
                        Circle()
                            .fill(i <= idx ? planColor : Color.jfBorder)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Text(node.label ?? node.id)
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .multilineTextAlignment(.center)

            CategoryBadge(text: nodeTypeLabel(node.node_type), color: nodeColor(node.node_type))

            // Description
            if let desc = node.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            // Tips
            if let tips = node.tips, !tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("指導者の考え方")
                            .font(.caption.bold())
                            .foregroundStyle(.yellow)
                    }
                    Text(tips)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineSpacing(4)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                )
            }

            // Video link (in-app) — match by ID, video_url, or title
            let linkedVideo = findVideo(node.video_url, title: node.video_title)
            if let video = linkedVideo {
                NavigationLink {
                    VideoDetailView(video: video, baseURL: api.baseURL)
                } label: {
                    videoLinkRow(title: video.displayTitle, subtitle: "教則動画")
                }
            }

            // Matched videos from library
            let matched = matchingVideos(for: node)
            if !matched.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("関連動画")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ForEach(matched) { video in
                        NavigationLink {
                            VideoDetailView(video: video, baseURL: api.baseURL)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(Color.jfRed)
                                Text(video.displayTitle)
                                    .font(.caption)
                                    .foregroundStyle(Color.jfTextPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }
                }
                .padding(10)
                .glassCard(cornerRadius: 12)
            }
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .id(node.id)
    }

    private func videoLinkRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.jfRed.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "play.fill")
                    .foregroundStyle(Color.jfRed)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(10)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Paths Section

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfRed)
                Text("次の展開")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Text("\(outEdges.count)通り")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // If plan is active, show recommended path first
            let sortedEdges = sortEdgesForPlan(outEdges)

            ForEach(sortedEdges) { edge in
                if let targetId = edge.target_id,
                   let target = api.flowNodes.first(where: { $0.id == targetId }) {
                    pathButton(edge: edge, target: target)
                }
            }
        }
    }

    private func sortEdgesForPlan(_ edges: [FlowEdge]) -> [FlowEdge] {
        guard selectedPlan != nil else { return edges }
        return edges.sorted { a, b in
            let aOnPlan = planNodeSet.contains(a.target_id ?? "")
            let bOnPlan = planNodeSet.contains(b.target_id ?? "")
            if aOnPlan != bOnPlan { return aOnPlan }
            return false
        }
    }

    private func pathButton(edge: FlowEdge, target: FlowNode) -> some View {
        let isOnPlan = planNodeSet.contains(target.id)
        let planColor = selectedPlan?.color ?? Color.jfRed

        return Button {
            breadcrumb.append(currentNodeId)
            navigateTo(target.id)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((isOnPlan ? planColor : nodeColor(target.node_type)).opacity(0.15))
                        .frame(width: 44, height: 44)
                    PositionIcon(nodeId: target.id, nodeType: target.node_type, size: 32)
                }

                VStack(alignment: .leading, spacing: 3) {
                    if let edgeLabel = edge.label, !edgeLabel.isEmpty {
                        Text(edgeLabel)
                            .font(.caption)
                            .foregroundStyle(edgeLabelColor(edge.category))
                    }

                    Text(target.label ?? target.id)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(nodeTypeLabel(target.node_type))
                            .font(.caption2)
                            .foregroundStyle(nodeColor(target.node_type))

                        if isOnPlan {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text(selectedPlan?.name ?? "")
                                    .font(.caption2)
                            }
                            .foregroundStyle(planColor)
                        }

                        if target.video_url != nil || target.description != nil {
                            Image(systemName: "doc.text.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(isOnPlan ? planColor : Color.jfTextTertiary)
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isOnPlan ? planColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
            .glassCard(cornerRadius: 14)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Dead End

    private var deadEndView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("ここが終点です")
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            Button {
                navigateTo(selectedPlan?.nodeIds.first ?? "start")
                breadcrumb = []
            } label: {
                Label("最初からやり直す", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfRed)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.jfRed.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 32)
    }

    // MARK: - Plan Picker Sheet

    private var planPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Free mode
                    Button {
                        selectedPlan = nil
                        currentNodeId = "start"
                        breadcrumb = []
                        showPlanPicker = false
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.gray.opacity(0.12))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.title3)
                                    .foregroundStyle(.gray)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("自由探索")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.jfTextPrimary)
                                Text("全てのノードを自由に探索")
                                    .font(.caption)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                            Spacer()
                            if selectedPlan == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.jfRed)
                            }
                        }
                        .padding(14)
                        .glassCard()
                    }

                    ForEach(gamePlanRoutes) { plan in
                        Button {
                            selectedPlan = plan
                            currentNodeId = plan.nodeIds.first ?? "start"
                            breadcrumb = []
                            showPlanPicker = false
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(plan.color.opacity(0.12))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: plan.icon)
                                        .font(.title3)
                                        .foregroundStyle(plan.color)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.jfTextPrimary)
                                    Text(plan.description)
                                        .font(.caption)
                                        .foregroundStyle(Color.jfTextTertiary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text("\(plan.nodeIds.count)ステップ")
                                        .font(.caption2)
                                        .foregroundStyle(plan.color)
                                }
                                Spacer()
                                if selectedPlan?.id == plan.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(plan.color)
                                }
                            }
                            .padding(14)
                            .glassCard()
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("ゲームプラン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showPlanPicker = false }
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Navigation

    private func navigateTo(_ nodeId: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentNodeId = nodeId
        }
    }

    // MARK: - Video Matching

    /// Find a video by ID, URL, or title match
    private func findVideo(_ ref: String?, title: String?) -> Video? {
        if let ref = ref, !ref.isEmpty {
            if let v = api.videos.first(where: { $0.id == ref }) { return v }
            if let v = api.videos.first(where: { $0.video_url == ref }) { return v }
        }
        if let t = title, !t.isEmpty {
            if let v = api.videos.first(where: { $0.title == t }) { return v }
            if let v = api.videos.first(where: {
                ($0.title ?? "").localizedCaseInsensitiveContains(t) ||
                t.localizedCaseInsensitiveContains($0.title ?? "???")
            }) { return v }
        }
        return nil
    }

    private func matchingVideos(for node: FlowNode) -> [Video] {
        guard let label = node.label, !label.isEmpty else { return [] }
        return api.videos.filter { video in
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

    // MARK: - Helpers

    private func nodeColor(_ type: String?) -> Color {
        switch type {
        case "start": return .green; case "decision": return .yellow; case "action": return .blue
        case "position": return .purple; case "submission": return .red; case "result": return .cyan
        case "top": return .orange; default: return .gray
        }
    }

    private func nodeEmoji(_ type: String?) -> String {
        switch type {
        case "start": return "🏁"; case "decision": return "🤔"; case "action": return "⚡"
        case "position": return "🤼"; case "submission": return "🔒"; case "result": return "✅"
        case "top": return "👆"; default: return "●"
        }
    }

    private func nodeTypeLabel(_ type: String?) -> String {
        switch type {
        case "start": return "スタート"; case "decision": return "判断"; case "action": return "アクション"
        case "position": return "ポジション"; case "submission": return "極め"; case "result": return "結果"
        case "top": return "トップ"; default: return type ?? ""
        }
    }

    private func edgeLabelColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green; case "no": return .orange; case "counter": return .yellow
        case "transition": return .blue; case "td": return .cyan; default: return Color.jfTextSecondary
        }
    }
}
