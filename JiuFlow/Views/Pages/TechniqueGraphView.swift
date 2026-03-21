import SwiftUI

struct TechniqueGraphView: View {
    @EnvironmentObject var api: APIService
    @State private var currentNodeId: String = "start"
    @State private var breadcrumb: [String] = []
    @State private var selectedDetail: FlowNode?
    @State private var animateIn = false

    private var currentNode: FlowNode? {
        api.flowNodes.first { $0.id == currentNodeId }
    }

    /// Edges going out from current node
    private var outEdges: [FlowEdge] {
        api.flowEdges.filter { $0.source_id == currentNodeId }
    }

    /// Target nodes reachable from current
    private var childNodes: [FlowNode] {
        let targetIds = Set(outEdges.compactMap(\.target_id))
        return api.flowNodes.filter { targetIds.contains($0.id) }
    }

    /// Edges coming into current node
    private var inEdges: [FlowEdge] {
        api.flowEdges.filter { $0.target_id == currentNodeId }
    }

    var body: some View {
        Group {
            if api.isLoading && api.flowNodes.isEmpty {
                LoadingOverlay(message: "グラフを読み込み中...")
            } else if api.flowNodes.isEmpty {
                EmptyStateView(
                    icon: "circle.grid.cross",
                    title: "フローデータがありません",
                    actionTitle: "再読み込み"
                ) {
                    Task { await api.loadTechniqueFlow() }
                }
            } else {
                navigationGraphView
            }
        }
        .task {
            if api.flowNodes.isEmpty {
                await api.loadTechniqueFlow()
            }
            if api.videos.isEmpty {
                await api.loadVideos()
            }
        }
    }

    // MARK: - Main Navigation Graph

    private var navigationGraphView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Breadcrumb
                if !breadcrumb.isEmpty {
                    breadcrumbBar
                }

                // Current node (hero)
                if let node = currentNode {
                    currentNodeHero(node)
                }

                // Outgoing paths
                if !outEdges.isEmpty {
                    pathsSection
                }

                // Dead end
                if outEdges.isEmpty, currentNode != nil {
                    deadEndView
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentNodeId)
    }

    // MARK: - Breadcrumb

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Start button
                Button {
                    navigateTo("start")
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
        VStack(spacing: 16) {
            // Type icon
            ZStack {
                Circle()
                    .fill(nodeColor(node.node_type).opacity(0.15))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(nodeColor(node.node_type), lineWidth: 2.5)
                    .frame(width: 80, height: 80)
                Text(nodeEmoji(node.node_type))
                    .font(.system(size: 36))
            }
            .shadow(color: nodeColor(node.node_type).opacity(0.3), radius: 12)

            // Label
            Text(node.label ?? node.id)
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .multilineTextAlignment(.center)

            // Type badge
            if let type = Optional(node.node_type) {
                CategoryBadge(text: nodeTypeLabel(type), color: nodeColor(node.node_type))
            }

            // Description
            if let desc = node.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            // Tips from pros
            if let tips = node.tips, !tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("プロの考え方")
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

            // Video link
            if let url = node.video_url, let videoURL = URL(string: url) {
                Link(destination: videoURL) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.jfRed.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "play.fill")
                                .foregroundStyle(Color.jfRed)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.video_title ?? "関連動画を見る")
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                                .lineLimit(1)
                            Text("YouTube")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    .padding(10)
                    .glassCard(cornerRadius: 14)
                }
            }

            // Matching app videos
            let matched = matchingVideos(for: node)
            if !matched.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("関連動画")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                    ForEach(matched) { video in
                        if let urlStr = video.video_url, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundStyle(Color.jfRed)
                                    Text(video.displayTitle)
                                        .font(.caption)
                                        .foregroundStyle(Color.jfTextPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2)
                                        .foregroundStyle(Color.jfTextTertiary)
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .glassCard(cornerRadius: 12)
            }

            // Connection stats
            HStack(spacing: 16) {
                Label("\(inEdges.count) 入力", systemImage: "arrow.down.left")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                Label("\(outEdges.count) 出力", systemImage: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .padding(20)
        .glassCard()
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .id(node.id) // force re-render on navigation
    }

    // MARK: - Paths Section

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
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

            // Edge buttons
            ForEach(outEdges) { edge in
                if let targetId = edge.target_id,
                   let target = api.flowNodes.first(where: { $0.id == targetId }) {
                    pathButton(edge: edge, target: target)
                }
            }
        }
    }

    private func pathButton(edge: FlowEdge, target: FlowNode) -> some View {
        Button {
            breadcrumb.append(currentNodeId)
            navigateTo(target.id)
        } label: {
            HStack(spacing: 14) {
                // Node type icon
                ZStack {
                    Circle()
                        .fill(nodeColor(target.node_type).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(nodeEmoji(target.node_type))
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Edge label (the action/transition)
                    if let edgeLabel = edge.label, !edgeLabel.isEmpty {
                        Text(edgeLabel)
                            .font(.caption)
                            .foregroundStyle(edgeLabelColor(edge.category))
                    }

                    // Target node name
                    Text(target.label ?? target.id)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Type + connection count
                    HStack(spacing: 8) {
                        Text(nodeTypeLabel(target.node_type))
                            .font(.caption2)
                            .foregroundStyle(nodeColor(target.node_type))
                        let nextCount = api.flowEdges.filter { $0.source_id == target.id }.count
                        if nextCount > 0 {
                            Text("→ \(nextCount)展開")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        // Video indicator
                        if target.video_url != nil {
                            Image(systemName: "play.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.jfRed)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(12)
            .glassCard(cornerRadius: 14)
        }
        .padding(.horizontal, 16)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: currentNodeId)
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

            Text("ブレッドクラムから前のステップに戻れます")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)

            Button {
                navigateTo("start")
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

    // MARK: - Navigation

    private func navigateTo(_ nodeId: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentNodeId = nodeId
        }
    }

    // MARK: - Video Matching

    private func matchingVideos(for node: FlowNode) -> [Video] {
        guard let label = node.label, !label.isEmpty else { return [] }
        return api.videos.filter { video in
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

    // MARK: - Style Helpers

    private func nodeColor(_ type: String?) -> Color {
        switch type {
        case "start": return .green
        case "decision": return .yellow
        case "action": return .blue
        case "position": return .purple
        case "submission": return .red
        case "result": return .cyan
        case "top": return .orange
        default: return .gray
        }
    }

    private func nodeEmoji(_ type: String?) -> String {
        switch type {
        case "start": return "🏁"
        case "decision": return "🤔"
        case "action": return "⚡"
        case "position": return "🤼"
        case "submission": return "🔒"
        case "result": return "✅"
        case "top": return "👆"
        default: return "●"
        }
    }

    private func nodeTypeLabel(_ type: String?) -> String {
        switch type {
        case "start": return "スタート"
        case "decision": return "判断ポイント"
        case "action": return "アクション"
        case "position": return "ポジション"
        case "submission": return "極め技"
        case "result": return "結果"
        case "top": return "トップ"
        default: return type ?? ""
        }
    }

    private func edgeLabelColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green
        case "no": return .orange
        case "counter": return .yellow
        case "transition": return .blue
        case "td": return .cyan
        default: return Color.jfTextSecondary
        }
    }
}
