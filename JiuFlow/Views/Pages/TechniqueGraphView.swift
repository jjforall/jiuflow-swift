import SwiftUI

struct TechniqueGraphView: View {
    @EnvironmentObject var api: APIService
    @State private var scale: CGFloat = 0.8
    @State private var offset: CGSize = .zero
    @State private var selectedNode: FlowNode?

    private let nodeSize: CGFloat = 70

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
                graphContent
            }
        }
        .task {
            if api.flowNodes.isEmpty {
                await api.loadTechniqueFlow()
            }
        }
    }

    // MARK: - Graph

    private var graphContent: some View {
        ZStack {
            // Pannable, zoomable canvas
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Edges
                    ForEach(api.flowEdges) { edge in
                        edgeLine(edge)
                    }

                    // Nodes
                    ForEach(api.flowNodes) { node in
                        nodeView(node)
                            .position(positionFor(node))
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(scale)
                .padding(40)
            }

            // Zoom controls
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Spacer()
                    zoomButton(icon: "minus.magnifyingglass") {
                        withAnimation(.spring(response: 0.3)) { scale = max(0.3, scale - 0.15) }
                    }
                    zoomButton(icon: "plus.magnifyingglass") {
                        withAnimation(.spring(response: 0.3)) { scale = min(2.0, scale + 0.15) }
                    }
                    zoomButton(icon: "arrow.counterclockwise") {
                        withAnimation(.spring(response: 0.3)) { scale = 0.8 }
                    }
                }
                .padding(16)
            }

            // Selected node detail overlay
            if let node = selectedNode {
                nodeDetailOverlay(node)
            }
        }
    }

    // MARK: - Canvas Size

    private var canvasSize: CGSize {
        let maxX = api.flowNodes.compactMap(\.x).max() ?? 500
        let maxY = api.flowNodes.compactMap(\.y).max() ?? 500
        return CGSize(width: max(maxX + 200, 600), height: max(maxY + 200, 600))
    }

    // MARK: - Node Position

    private func positionFor(_ node: FlowNode) -> CGPoint {
        // Use x, y from API if available, otherwise auto-layout
        if let x = node.x, let y = node.y {
            return CGPoint(x: x + 100, y: y + 100)
        }
        // Auto-layout fallback: grid
        guard let index = api.flowNodes.firstIndex(where: { $0.id == node.id }) else {
            return CGPoint(x: 300, y: 300)
        }
        let cols = 4
        let row = index / cols
        let col = index % cols
        return CGPoint(x: CGFloat(col) * 160 + 100, y: CGFloat(row) * 140 + 100)
    }

    // MARK: - Node View

    private func nodeView(_ node: FlowNode) -> some View {
        let isSelected = selectedNode?.id == node.id
        let color = nodeColor(node.node_type)

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedNode = selectedNode?.id == node.id ? nil : node
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: nodeSize, height: nodeSize)
                    Circle()
                        .stroke(color, lineWidth: isSelected ? 3 : 1.5)
                        .frame(width: nodeSize, height: nodeSize)
                    Image(systemName: nodeIcon(node.node_type))
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }
                .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)

                Text(node.label ?? node.id)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: nodeSize + 20)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSelected)
    }

    // MARK: - Edge Line

    private func edgeLine(_ edge: FlowEdge) -> some View {
        let from = api.flowNodes.first { $0.id == edge.source_id }
        let to = api.flowNodes.first { $0.id == edge.target_id }

        return Group {
            if let from = from, let to = to {
                let start = positionFor(from)
                let end = positionFor(to)
                let color = edgeColor(edge.category)

                Path { path in
                    path.move(to: start)
                    // Curved line
                    let midY = (start.y + end.y) / 2
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: start.x, y: midY),
                        control2: CGPoint(x: end.x, y: midY)
                    )
                }
                .stroke(color.opacity(0.5), lineWidth: 1.5)

                // Arrow at end
                let angle = atan2(end.y - start.y, end.x - start.x)
                arrowHead(at: end, angle: angle, color: color)

                // Edge label
                if let label = edge.label, !label.isEmpty {
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundStyle(Color.jfTextTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.jfDarkBg.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - 10)
                }
            }
        }
    }

    private func arrowHead(at point: CGPoint, angle: CGFloat, color: Color) -> some View {
        let arrowSize: CGFloat = 8
        let adjusted = CGPoint(
            x: point.x - cos(angle) * (nodeSize / 2 + 2),
            y: point.y - sin(angle) * (nodeSize / 2 + 2)
        )

        return Path { path in
            path.move(to: adjusted)
            path.addLine(to: CGPoint(
                x: adjusted.x - arrowSize * cos(angle - .pi / 6),
                y: adjusted.y - arrowSize * sin(angle - .pi / 6)
            ))
            path.move(to: adjusted)
            path.addLine(to: CGPoint(
                x: adjusted.x - arrowSize * cos(angle + .pi / 6),
                y: adjusted.y - arrowSize * sin(angle + .pi / 6)
            ))
        }
        .stroke(color.opacity(0.7), lineWidth: 2)
    }

    // MARK: - Node Detail Overlay

    private func nodeDetailOverlay(_ node: FlowNode) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: nodeIcon(node.node_type))
                        .font(.title3)
                        .foregroundStyle(nodeColor(node.node_type))
                    Text(node.label ?? node.id)
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Button {
                        withAnimation { selectedNode = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if let type = node.node_type {
                    HStack(spacing: 8) {
                        CategoryBadge(text: nodeTypeLabel(type), color: nodeColor(node.node_type))
                        Spacer()
                    }
                }

                // Connected edges
                let edges = api.flowEdges.filter { $0.source_id == node.id }
                if !edges.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("次のアクション:")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                        ForEach(edges) { edge in
                            if let targetId = edge.target_id,
                               let target = api.flowNodes.first(where: { $0.id == targetId }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(edgeColor(edge.category))
                                    Text(edge.label ?? target.label ?? targetId)
                                        .font(.caption)
                                        .foregroundStyle(Color.jfTextSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.jfBorder, lineWidth: 0.5)
            )
            .padding(16)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Zoom Button

    private func zoomButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.jfTextPrimary)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(Circle())
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
        default: return .gray
        }
    }

    private func nodeIcon(_ type: String?) -> String {
        switch type {
        case "start": return "flag.fill"
        case "decision": return "questionmark.diamond.fill"
        case "action": return "bolt.fill"
        case "position": return "person.fill"
        case "submission": return "hand.raised.fill"
        default: return "circle.fill"
        }
    }

    private func nodeTypeLabel(_ type: String) -> String {
        switch type {
        case "start": return "スタート"
        case "decision": return "判断"
        case "action": return "アクション"
        case "position": return "ポジション"
        case "submission": return "極め"
        default: return type
        }
    }

    private func edgeColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green
        case "no": return .orange
        case "counter": return .yellow
        case "transition": return .blue
        default: return .gray
        }
    }
}
