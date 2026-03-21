import SwiftUI

/// Visual flowchart showing the full graph structure
/// Users can zoom/pan to explore, tap nodes to see details
struct TechniqueVisualGraphView: View {
    @EnvironmentObject var api: APIService
    @State private var scale: CGFloat = 0.12
    @State private var lastScale: CGFloat = 0.12
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    @State private var selectedNode: FlowNode?
    @State private var highlightPath: Set<String> = [] // node IDs to highlight

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
            if api.flowNodes.isEmpty { await api.loadTechniqueFlow() }
        }
    }

    // MARK: - Canvas

    private var graphCanvas: some View {
        GeometryReader { geo in
            ZStack {
                Color.jfDarkBg

                Canvas { context, size in
                    let tx = transform(viewSize: size)
                    drawEdges(in: &context, tx: tx, viewSize: size)
                    drawNodes(in: &context, tx: tx, viewSize: size)
                }
                .gesture(
                    SimultaneousGesture(
                        MagnifyGesture()
                            .onChanged { v in scale = clamp(lastScale * v.magnification, 0.04, 0.8) }
                            .onEnded { _ in lastScale = scale },
                        DragGesture()
                            .onChanged { v in
                                panOffset = CGSize(
                                    width: lastPanOffset.width + v.translation.width,
                                    height: lastPanOffset.height + v.translation.height
                                )
                            }
                            .onEnded { _ in lastPanOffset = panOffset }
                    )
                )
                .onTapGesture { loc in
                    handleTap(at: loc, viewSize: geo.size)
                }

                // Overlays
                VStack {
                    legendOverlay
                    Spacer()
                    if let node = selectedNode {
                        selectedNodeCard(node)
                    }
                    controlsOverlay
                }
                .padding(10)
            }
        }
    }

    // MARK: - Transform

    private struct TX {
        let s: CGFloat, ox: CGFloat, oy: CGFloat
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: x * s + ox, y: y * s + oy)
        }
    }

    private func transform(viewSize: CGSize) -> TX {
        TX(s: scale, ox: panOffset.width + viewSize.width * 0.3, oy: panOffset.height + 30)
    }

    // MARK: - Draw

    private func drawEdges(in ctx: inout GraphicsContext, tx: TX, viewSize: CGSize) {
        for edge in api.flowEdges {
            guard let f = api.flowNodes.first(where: { $0.id == edge.source_id }),
                  let t = api.flowNodes.first(where: { $0.id == edge.target_id }),
                  let fx = f.x, let fy = f.y, let tx2 = t.x, let ty = t.y else { continue }

            let from = tx.pt(fx, fy)
            let to = tx.pt(tx2, ty)

            let isHighlighted = highlightPath.contains(f.id) && highlightPath.contains(t.id)

            var path = Path()
            path.move(to: from)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
            path.addQuadCurve(to: to, control: CGPoint(x: mid.x, y: mid.y))

            let color = isHighlighted ? Color.jfRed : edgeColor(edge.category)
            ctx.stroke(path, with: .color(color.opacity(isHighlighted ? 0.8 : 0.25)),
                       lineWidth: isHighlighted ? max(1, scale * 12) : max(0.3, scale * 4))
        }
    }

    private func drawNodes(in ctx: inout GraphicsContext, tx: TX, viewSize: CGSize) {
        let r = max(6, 20 * scale)
        let margin: CGFloat = r + 20

        for node in api.flowNodes {
            guard let x = node.x, let y = node.y else { continue }
            let center = tx.pt(x, y)

            // Cull
            guard center.x > -margin, center.x < viewSize.width + margin,
                  center.y > -margin, center.y < viewSize.height + margin else { continue }

            let isSelected = selectedNode?.id == node.id
            let isOnPath = highlightPath.contains(node.id)
            let color = nodeColor(node.node_type)

            // Circle
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(isSelected ? 0.6 : isOnPath ? 0.4 : 0.15)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(color.opacity(isSelected ? 1 : isOnPath ? 0.8 : 0.5)),
                       lineWidth: isSelected ? 2.5 : isOnPath ? 2 : 1)

            // Label (when zoomed in enough)
            if scale > 0.06 {
                let fontSize = max(6, min(11, 11 * scale * 5))
                let text = Text(node.label ?? "")
                    .font(.system(size: fontSize, weight: isSelected || isOnPath ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.jfTextPrimary.opacity(0.8))
                ctx.draw(ctx.resolve(text),
                         at: CGPoint(x: center.x, y: center.y + r + fontSize / 2 + 2),
                         anchor: .center)
            }

            // Emoji icon (when zoomed in)
            if scale > 0.1 {
                let emoji = Text(nodeEmoji(node.node_type)).font(.system(size: max(8, r * 0.8)))
                ctx.draw(ctx.resolve(emoji), at: center, anchor: .center)
            }
        }
    }

    // MARK: - Tap

    private func handleTap(at loc: CGPoint, viewSize: CGSize) {
        let tx = transform(viewSize: viewSize)
        let hitR = max(12, 24 * scale)
        var closest: FlowNode?
        var closestDist: CGFloat = .greatestFiniteMagnitude

        for node in api.flowNodes {
            guard let x = node.x, let y = node.y else { continue }
            let p = tx.pt(x, y)
            let d = hypot(p.x - loc.x, p.y - loc.y)
            if d < hitR + 10, d < closestDist {
                closest = node
                closestDist = d
            }
        }

        withAnimation(.spring(response: 0.3)) {
            if closest?.id == selectedNode?.id {
                selectedNode = nil
                highlightPath = []
            } else {
                selectedNode = closest
                // Build highlight path from start to this node (BFS)
                if let node = closest {
                    highlightPath = buildPathToNode(node.id)
                }
            }
        }
    }

    /// BFS backward from target to "start"
    private func buildPathToNode(_ targetId: String) -> Set<String> {
        var visited = Set<String>()
        var queue = [targetId]
        visited.insert(targetId)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == "start" { break }
            for edge in api.flowEdges where edge.target_id == current {
                if let src = edge.source_id, !visited.contains(src) {
                    visited.insert(src)
                    queue.append(src)
                }
            }
        }
        return visited.contains("start") ? visited : [targetId]
    }

    // MARK: - Selected Node Card

    private func selectedNodeCard(_ node: FlowNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nodeEmoji(node.node_type))
                Text(node.label ?? node.id)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Spacer()
                Button { withAnimation { selectedNode = nil; highlightPath = [] } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }

            CategoryBadge(text: nodeTypeLabel(node.node_type), color: nodeColor(node.node_type))

            // Show connections
            let outs = api.flowEdges.filter { $0.source_id == node.id }
            if !outs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(outs) { e in
                            if let tid = e.target_id,
                               let t = api.flowNodes.first(where: { $0.id == tid }) {
                                Button {
                                    withAnimation {
                                        selectedNode = t
                                        highlightPath = buildPathToNode(t.id)
                                    }
                                } label: {
                                    Text(e.label?.isEmpty == false ? e.label! : t.label ?? tid)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(edgeColor(e.category).opacity(0.15))
                                        .foregroundStyle(edgeColor(e.category))
                                        .clipShape(Capsule())
                                }
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

    // MARK: - Legend

    private var legendOverlay: some View {
        HStack(spacing: 8) {
            ForEach([("🏁","開始"),("🤔","判断"),("⚡","技"),("🤼","位置"),("✅","結果")], id: \.0) { e, l in
                HStack(spacing: 2) {
                    Text(e).font(.caption2)
                    Text(l).font(.system(size: 9)).foregroundStyle(Color.jfTextSecondary)
                }
            }
            Spacer()
            Text("\(api.flowNodes.count)")
                .font(.caption2.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Controls

    private var controlsOverlay: some View {
        HStack(spacing: 8) {
            Button { withAnimation { scale = clamp(scale * 0.6, 0.04, 0.8); lastScale = scale } } label: {
                Image(systemName: "minus.magnifyingglass").font(.body).foregroundStyle(Color.jfTextPrimary).frame(width: 36, height: 36)
            }
            Button { withAnimation { scale = clamp(scale * 1.6, 0.04, 0.8); lastScale = scale } } label: {
                Image(systemName: "plus.magnifyingglass").font(.body).foregroundStyle(Color.jfTextPrimary).frame(width: 36, height: 36)
            }
            Button { withAnimation { scale = 0.12; lastScale = 0.12; panOffset = .zero; lastPanOffset = .zero; highlightPath = [] } } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right").font(.body).foregroundStyle(Color.jfTextPrimary).frame(width: 36, height: 36)
            }
            Spacer()
            Text("\(Int(scale * 100))%").font(.caption2.bold().monospacedDigit()).foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(max(v, lo), hi) }

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
        case "start": return "開始"; case "decision": return "判断"; case "action": return "アクション"
        case "position": return "ポジション"; case "submission": return "極め"; case "result": return "結果"
        case "top": return "トップ"; default: return type ?? ""
        }
    }

    private func edgeColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green; case "no": return .orange; case "counter": return .yellow
        case "transition": return .blue; case "td": return .cyan; default: return .gray
        }
    }
}
