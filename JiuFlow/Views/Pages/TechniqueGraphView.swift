import SwiftUI

struct TechniqueGraphView: View {
    @EnvironmentObject var api: APIService
    @State private var selectedNode: FlowNode?
    @State private var scale: CGFloat = 0.15
    @State private var lastScale: CGFloat = 0.15
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero

    private let nodeRadius: CGFloat = 30

    // Coordinate space: API gives x:0-3880, y:0-4380
    // We scale these down and allow pan/zoom

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
                graphCanvas
            }
        }
        .task {
            if api.flowNodes.isEmpty {
                await api.loadTechniqueFlow()
            }
        }
    }

    // MARK: - Canvas

    private var graphCanvas: some View {
        GeometryReader { geo in
            ZStack {
                Color.jfDarkBg

                // Graph layer
                Canvas { context, size in
                    let transform = currentTransform(viewSize: size)

                    // Draw edges
                    for edge in api.flowEdges {
                        drawEdge(edge, in: &context, transform: transform)
                    }

                    // Draw nodes
                    for node in api.flowNodes {
                        drawNode(node, in: &context, transform: transform, viewSize: size)
                    }
                }
                .gesture(
                    SimultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in
                                let newScale = lastScale * value.magnification
                                scale = min(max(newScale, 0.05), 1.5)
                            }
                            .onEnded { _ in
                                lastScale = scale
                            },
                        DragGesture()
                            .onChanged { value in
                                panOffset = CGSize(
                                    width: lastPanOffset.width + value.translation.width,
                                    height: lastPanOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastPanOffset = panOffset
                            }
                    )
                )
                .onTapGesture { location in
                    handleTap(at: location, viewSize: geo.size)
                }

                // UI Overlay
                VStack {
                    // Legend
                    legendBar
                    Spacer()

                    // Controls + selected node
                    VStack(spacing: 12) {
                        if let node = selectedNode {
                            nodeDetailCard(node)
                        }
                        controlsBar
                    }
                }
                .padding(12)
            }
        }
    }

    // MARK: - Transform

    private func currentTransform(viewSize: CGSize) -> GraphTransform {
        GraphTransform(
            scale: scale,
            offsetX: panOffset.width + viewSize.width / 2,
            offsetY: panOffset.height + 40
        )
    }

    private struct GraphTransform {
        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        func point(x: Double, y: Double) -> CGPoint {
            CGPoint(
                x: x * scale + offsetX,
                y: y * scale + offsetY
            )
        }
    }

    // MARK: - Draw Node

    private func drawNode(_ node: FlowNode, in context: inout GraphicsContext, transform: GraphTransform, viewSize: CGSize) {
        guard let x = node.x, let y = node.y else { return }
        let center = transform.point(x: x, y: y)

        // Cull off-screen nodes
        let margin: CGFloat = 60
        guard center.x > -margin && center.x < viewSize.width + margin &&
              center.y > -margin && center.y < viewSize.height + margin else { return }

        let r = nodeRadius * max(scale * 2, 0.5)
        let isSelected = selectedNode?.id == node.id
        let color = nodeSwiftUIColor(node.node_type)

        // Circle fill
        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        let fillPath = Path(ellipseIn: rect)
        context.fill(fillPath, with: .color(color.opacity(isSelected ? 0.5 : 0.2)))
        context.stroke(fillPath, with: .color(color.opacity(isSelected ? 1.0 : 0.6)), lineWidth: isSelected ? 2.5 : 1.5)

        // Label (only show when zoomed enough)
        if scale > 0.08 {
            let label = node.label ?? node.id
            let fontSize = max(8, min(12, 12 * scale * 3))
            let text = Text(label)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(Color.jfTextPrimary)
            context.draw(
                context.resolve(text),
                at: CGPoint(x: center.x, y: center.y + r + fontSize / 2 + 4),
                anchor: .center
            )
        }

        // Icon
        let iconSize = max(10, r * 0.7)
        let icon = nodeIconChar(node.node_type)
        let iconText = Text(icon).font(.system(size: iconSize))
        context.draw(context.resolve(iconText), at: center, anchor: .center)
    }

    // MARK: - Draw Edge

    private func drawEdge(_ edge: FlowEdge, in context: inout GraphicsContext, transform: GraphTransform) {
        guard let fromNode = api.flowNodes.first(where: { $0.id == edge.source_id }),
              let toNode = api.flowNodes.first(where: { $0.id == edge.target_id }),
              let fx = fromNode.x, let fy = fromNode.y,
              let tx = toNode.x, let ty = toNode.y else { return }

        let from = transform.point(x: fx, y: fy)
        let to = transform.point(x: tx, y: ty)
        let color = edgeSwiftUIColor(edge.category)

        var path = Path()
        path.move(to: from)

        // Slight curve
        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let dx = to.x - from.x
        let dy = to.y - from.y
        let controlOffset = min(abs(dx), abs(dy)) * 0.2
        path.addQuadCurve(
            to: to,
            control: CGPoint(x: midX - controlOffset * 0.3, y: midY)
        )

        context.stroke(path, with: .color(color.opacity(0.35)), lineWidth: max(0.5, scale * 5))
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint, viewSize: CGSize) {
        let transform = currentTransform(viewSize: viewSize)

        var closest: FlowNode?
        var closestDist: CGFloat = .greatestFiniteMagnitude

        for node in api.flowNodes {
            guard let x = node.x, let y = node.y else { continue }
            let p = transform.point(x: x, y: y)
            let dist = hypot(p.x - location.x, p.y - location.y)
            let hitRadius = nodeRadius * max(scale * 2, 0.5) + 10
            if dist < hitRadius && dist < closestDist {
                closest = node
                closestDist = dist
            }
        }

        withAnimation(.spring(response: 0.3)) {
            selectedNode = closest?.id == selectedNode?.id ? nil : closest
        }
    }

    // MARK: - Legend

    private var legendBar: some View {
        HStack(spacing: 10) {
            legendItem(color: .green, label: "開始")
            legendItem(color: .yellow, label: "判断")
            legendItem(color: .blue, label: "技")
            legendItem(color: .purple, label: "位置")
            legendItem(color: .red, label: "極め")
            Spacer()
            Text("\(api.flowNodes.count)ノード")
                .font(.caption2)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 9)).foregroundStyle(Color.jfTextSecondary)
        }
    }

    // MARK: - Controls

    private var controlsBar: some View {
        HStack(spacing: 10) {
            controlButton(icon: "minus.magnifyingglass") {
                withAnimation { scale = max(0.05, scale * 0.7); lastScale = scale }
            }
            controlButton(icon: "plus.magnifyingglass") {
                withAnimation { scale = min(1.5, scale * 1.4); lastScale = scale }
            }
            controlButton(icon: "arrow.up.left.and.arrow.down.right") {
                withAnimation { scale = 0.15; lastScale = 0.15; panOffset = .zero; lastPanOffset = .zero }
            }

            Spacer()

            Text("\(Int(scale * 100))%")
                .font(.caption2.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.jfTextPrimary)
                .frame(width: 36, height: 36)
        }
    }

    // MARK: - Node Detail Card

    private func nodeDetailCard(_ node: FlowNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nodeIconChar(node.node_type))
                    .font(.title3)
                Text(node.label ?? node.id)
                    .font(.subheadline.bold())
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
                CategoryBadge(text: nodeTypeLabel(type), color: nodeSwiftUIColor(node.node_type))
            }

            let outEdges = api.flowEdges.filter { $0.source_id == node.id }
            if !outEdges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(outEdges) { edge in
                            if let tid = edge.target_id,
                               let target = api.flowNodes.first(where: { $0.id == tid }) {
                                Text(edge.label?.isEmpty == false ? edge.label! : target.label ?? tid)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(edgeSwiftUIColor(edge.category).opacity(0.15))
                                    .foregroundStyle(edgeSwiftUIColor(edge.category))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Color/Icon Helpers

    private func nodeSwiftUIColor(_ type: String?) -> Color {
        switch type {
        case "start": return .green
        case "decision": return .yellow
        case "action": return .blue
        case "position": return .purple
        case "submission": return .red
        default: return .gray
        }
    }

    private func nodeIconChar(_ type: String?) -> String {
        switch type {
        case "start": return "🏁"
        case "decision": return "❓"
        case "action": return "⚡"
        case "position": return "🤼"
        case "submission": return "🔒"
        default: return "●"
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

    private func edgeSwiftUIColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green
        case "no": return .orange
        case "counter": return .yellow
        case "transition": return .blue
        case "td": return .cyan
        default: return .gray
        }
    }
}
