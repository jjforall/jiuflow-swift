import SwiftUI

// MARK: - Smooth zoom animator (CADisplayLink driven, 60/120fps)

@Observable
private final class ZoomAnimator {
    var scale: CGFloat = 0.18
    var panOffset: CGSize = .zero
    // Last committed values (gesture baseline)
    var lastScale: CGFloat = 0.18
    var lastPanOffset: CGSize = .zero

    private var displayLink: CADisplayLink?
    private var startScale: CGFloat = 0
    private var startOffset: CGSize = .zero
    private var targetScale: CGFloat = 0
    private var targetOffset: CGSize = .zero
    private var startTime: CFTimeInterval = 0
    private let duration: CFTimeInterval = 0.48

    /// Animate smoothly to the target scale/offset (ease-in-out cubic)
    func animateTo(scale: CGFloat, offset: CGSize) {
        displayLink?.invalidate()
        startScale  = self.scale
        startOffset = self.panOffset
        targetScale  = scale
        targetOffset = offset
        startTime = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        let t = min((link.timestamp - startTime) / duration, 1.0)
        let e = easeInOutCubic(CGFloat(t))
        scale     = startScale  + (targetScale  - startScale)  * e
        panOffset = CGSize(
            width:  startOffset.width  + (targetOffset.width  - startOffset.width)  * e,
            height: startOffset.height + (targetOffset.height - startOffset.height) * e
        )
        if t >= 1.0 {
            link.invalidate()
            displayLink  = nil
            lastScale     = targetScale
            lastPanOffset = targetOffset
        }
    }

    private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4*t*t*t : 1 - pow(-2*t+2, 3)/2
    }
}

/// Visual flowchart showing the full graph structure
/// Users can zoom/pan to explore, tap nodes to see details
struct TechniqueVisualGraphView: View {
    /// Pass the selected plan from the parent (FlowTab) — no duplicate selector needed
    var activePlan: GamePlanRoute? = nil

    @EnvironmentObject var api: APIService
    @State private var zoom = ZoomAnimator()
    @State private var selectedNode: FlowNode?
    @State private var highlightPath: Set<String> = []

    // Double-tap-drag zoom state
    @State private var lastTapTime: Date = .distantPast
    @State private var lastTapLoc: CGPoint = .zero
    @State private var dtdActive = false
    @State private var dtdBaseScale: CGFloat = 0.18
    @State private var dtdBaseOffset: CGSize = .zero
    @State private var dtdAnchor: CGPoint = .zero
    @State private var dtdGestureID: CGPoint = CGPoint(x: -99999, y: -99999)

    // Convenience shorthands
    private var scale: CGFloat { zoom.scale }
    private var panOffset: CGSize { zoom.panOffset }

    private var planNodeSet: Set<String> {
        Set(activePlan?.nodeIds ?? [])
    }

    var body: some View {
        Group {
            if api.isLoading && api.flowNodes.isEmpty {
                LoadingOverlay(message: tr("グラフを読み込み中..."))
            } else if api.flowNodes.isEmpty {
                EmptyStateView(
                    icon: "circle.grid.cross",
                    title: tr("フローデータがありません"),
                    actionTitle: tr("再読み込み")
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
        .onChange(of: activePlan?.id) { _, _ in
            // Sync highlight path when parent changes the selected plan
            if let plan = activePlan {
                highlightPath = Set(plan.nodeIds)
            } else {
                highlightPath = []
            }
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
                    MagnifyGesture()
                        .onChanged { v in
                            let newScale = clamp(zoom.lastScale * v.magnification, 0.04, 0.8)
                            // Zoom toward the pinch midpoint (not screen center)
                            let ratio = newScale / zoom.lastScale
                            let anchorX = v.startLocation.x
                            let anchorY = v.startLocation.y
                            let baseOX = zoom.lastPanOffset.width + geo.size.width * 0.3
                            let baseOY = zoom.lastPanOffset.height + 30
                            zoom.panOffset = CGSize(
                                width: anchorX - (anchorX - baseOX) * ratio - geo.size.width * 0.3,
                                height: anchorY - (anchorY - baseOY) * ratio - 30
                            )
                            zoom.scale = newScale
                        }
                        .onEnded { _ in zoom.lastScale = zoom.scale; zoom.lastPanOffset = zoom.panOffset }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { v in
                            // Detect start of a new drag gesture by startLocation identity
                            let isNewGesture = v.startLocation != dtdGestureID
                            if isNewGesture {
                                dtdGestureID = v.startLocation
                                let elapsed = Date().timeIntervalSince(lastTapTime)
                                let dist = hypot(v.startLocation.x - lastTapLoc.x,
                                                 v.startLocation.y - lastTapLoc.y)
                                // Within 1.2s and 100pt of previous tap → double-tap-drag
                                if elapsed < 1.2 && dist < 100 {
                                    dtdActive = true
                                    dtdAnchor = v.startLocation
                                    dtdBaseScale = zoom.scale
                                    dtdBaseOffset = zoom.panOffset
                                } else {
                                    dtdActive = false
                                }
                            }

                            if dtdActive {
                                // Drag up = zoom in, drag down = zoom out
                                let dy = v.translation.height
                                let newScale = clamp(dtdBaseScale * pow(2.0, -dy / 150.0), 0.04, 0.8)
                                let ratio = newScale / dtdBaseScale
                                let fullOX = dtdBaseOffset.width + geo.size.width * 0.3
                                let fullOY = dtdBaseOffset.height + 30
                                zoom.scale = newScale
                                zoom.panOffset = CGSize(
                                    width: dtdAnchor.x - (dtdAnchor.x - fullOX) * ratio - geo.size.width * 0.3,
                                    height: dtdAnchor.y - (dtdAnchor.y - fullOY) * ratio - 30
                                )
                            } else {
                                zoom.panOffset = CGSize(
                                    width: zoom.lastPanOffset.width + v.translation.width,
                                    height: zoom.lastPanOffset.height + v.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            if dtdActive {
                                zoom.lastScale = zoom.scale
                                zoom.lastPanOffset = zoom.panOffset
                                dtdActive = false
                            } else {
                                zoom.lastPanOffset = zoom.panOffset
                            }
                        }
                )
                // Double tap: zoom 2.5x centered on tap point
                .onTapGesture(count: 2) { loc in
                    handleDoubleTap(at: loc, viewSize: geo.size)
                }
                // Single tap: select node + record for double-tap-drag detection
                .onTapGesture { loc in
                    lastTapTime = Date()
                    lastTapLoc = loc
                    handleTap(at: loc, viewSize: geo.size)
                }

                // Overlays
                VStack(spacing: 0) {
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
            let bothOnPlan = planNodeSet.contains(f.id) && planNodeSet.contains(t.id)
            let hasPlan = activePlan != nil
            let isDimmed = hasPlan && !bothOnPlan && !isHighlighted

            var path = Path()
            path.move(to: from)
            let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
            path.addQuadCurve(to: to, control: CGPoint(x: mid.x, y: mid.y))

            let color = bothOnPlan ? (activePlan?.color ?? Color.jfRed) : (isHighlighted ? Color.jfRed : edgeColor(edge.category))
            let opacity: Double = isDimmed ? 0.03 : (bothOnPlan ? 0.6 : (isHighlighted ? 0.7 : 0.1))
            let lw: CGFloat = bothOnPlan ? max(1.2, scale * 8) : (isHighlighted ? max(0.8, scale * 6) : max(0.3, min(1.5, scale * 3)))
            ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lw)
        }
    }

    private func drawNodes(in ctx: inout GraphicsContext, tx: TX, viewSize: CGSize) {
        let r = max(8, 24 * scale)
        let margin: CGFloat = r + 20

        for node in api.flowNodes {
            guard let x = node.x, let y = node.y else { continue }
            let center = tx.pt(x, y)

            // Cull
            guard center.x > -margin, center.x < viewSize.width + margin,
                  center.y > -margin, center.y < viewSize.height + margin else { continue }

            let isSelected = selectedNode?.id == node.id
            let isOnPath = highlightPath.contains(node.id)
            let isOnPlan = planNodeSet.contains(node.id)
            let hasPlan = activePlan != nil
            let isDimmed = hasPlan && !isOnPlan && !isSelected
            let color = isOnPlan ? (activePlan?.color ?? nodeColor(node.node_type)) : nodeColor(node.node_type)

            // Circle — brighter fill for visibility
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            let fillOpacity: Double = isDimmed ? 0.03 : (isSelected ? 0.7 : isOnPath ? 0.5 : isOnPlan ? 0.5 : 0.2)
            let strokeOpacity: Double = isDimmed ? 0.1 : (isSelected ? 1 : isOnPath ? 0.9 : isOnPlan ? 0.9 : 0.6)
            let lineW: CGFloat = isSelected ? 3 : (isOnPlan ? 3 : isOnPath ? 2.5 : 1.5)
            ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(fillOpacity)))
            ctx.stroke(Path(ellipseIn: rect), with: .color(color.opacity(strokeOpacity)), lineWidth: lineW)

            // Plan badge (plan icon character)
            if isOnPlan, let plan = activePlan, scale > 0.08 {
                let badge = plan.icon.isEmpty ? "●" : String(plan.id.prefix(2))
                let badgeText = Text(badge).font(.system(size: max(5, r * 0.5), weight: .black)).foregroundStyle(plan.color)
                ctx.draw(ctx.resolve(badgeText),
                         at: CGPoint(x: center.x + r * 0.7, y: center.y - r * 0.7),
                         anchor: .center)
            }

            // Label (when zoomed in enough) with dark background for readability
            if scale > 0.10 {
                let fontSize = max(8, min(13, 13 * scale * 5))
                let rawLabel = node.label ?? ""
                // Cap length to prevent overlap; CJK chars are ~1em wide
                let labelText = rawLabel.count > 9 ? String(rawLabel.prefix(8)) + "…" : rawLabel
                if !labelText.isEmpty {
                    let labelPt = CGPoint(x: center.x, y: center.y + r + fontSize * 0.6 + 4)
                    // Background pill — CJK characters are ~0.9em, ASCII ~0.55em
                    // Use 0.75 as conservative mixed estimate, plus generous padding
                    let bgW = CGFloat(labelText.count) * fontSize * 0.78 + 14
                    let bgH = fontSize + 6
                    let bgRect = CGRect(x: labelPt.x - bgW / 2, y: labelPt.y - bgH / 2, width: bgW, height: bgH)
                    ctx.fill(Path(roundedRect: bgRect, cornerRadius: 4),
                             with: .color(Color.black.opacity(isDimmed ? 0 : 0.72)))

                    let text = Text(labelText)
                        .font(.system(size: fontSize, weight: isSelected || isOnPath ? .bold : .medium))
                        .foregroundStyle(isDimmed ? Color.jfTextTertiary.opacity(0.2) : (isSelected ? Color.white : color))
                    ctx.draw(ctx.resolve(text), at: labelPt, anchor: .center)
                }
            }

            // Video indicator (show 🎬 if node has a linked video)
            if scale > 0.08, findVideo(node.video_url, title: node.video_title) != nil {
                let vidIcon = Text("🎬").font(.system(size: max(5, r * 0.5)))
                ctx.draw(ctx.resolve(vidIcon),
                         at: CGPoint(x: center.x - r * 0.7, y: center.y - r * 0.7),
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

    /// Double tap: zoom in 2.5x (centered on tap point), or zoom back out if already zoomed in
    private func handleDoubleTap(at loc: CGPoint, viewSize: CGSize) {
        let defaultScale: CGFloat = 0.18
        if zoom.scale > defaultScale * 1.5 {
            // Already zoomed — snap back to default
            zoom.animateTo(scale: defaultScale, offset: .zero)
        } else {
            // Zoom in 2.5x centered on the tapped point
            let newScale = clamp(zoom.scale * 2.5, 0.04, 0.8)
            let ratio = newScale / zoom.scale
            let fullOX = zoom.panOffset.width + viewSize.width * 0.3
            let fullOY = zoom.panOffset.height + 30
            let newOX = loc.x - (loc.x - fullOX) * ratio - viewSize.width * 0.3
            let newOY = loc.y - (loc.y - fullOY) * ratio - 30
            zoom.animateTo(scale: newScale, offset: CGSize(width: newOX, height: newOY))
        }
    }

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

            // Video link — prominent
            if let video = findVideo(node.video_url, title: node.video_title) {
                NavigationLink {
                    VideoDetailView(video: video, baseURL: api.baseURL)
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.jfRed.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundStyle(Color.jfRed)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tr("教則動画"))
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                            Text(video.displayTitle)
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.jfRed)
                    }
                    .padding(8)
                    .background(Color.jfRed.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Also show keyword-matched videos
            let titleMatched = matchingVideosByLabel(for: node)
            if !titleMatched.isEmpty {
                ForEach(titleMatched.prefix(3)) { video in
                    NavigationLink {
                        VideoDetailView(video: video, baseURL: api.baseURL)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle")
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                            Text(video.displayTitle)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

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
            ForEach([("🏁",tr("開始")),("🤔",tr("判断")),("⚡",tr("技")),("🤼",tr("位置")),("✅",tr("結果"))], id: \.0) { e, l in
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
            Button { zoom.animateTo(scale: clamp(zoom.scale * 0.6, 0.04, 0.8), offset: zoom.panOffset) } label: {
                Image(systemName: "minus.magnifyingglass").font(.body).foregroundStyle(Color.jfTextPrimary).frame(width: 36, height: 36)
            }
            Button { zoom.animateTo(scale: clamp(zoom.scale * 1.6, 0.04, 0.8), offset: zoom.panOffset) } label: {
                Image(systemName: "plus.magnifyingglass").font(.body).foregroundStyle(Color.jfTextPrimary).frame(width: 36, height: 36)
            }
            Button { zoom.animateTo(scale: 0.18, offset: .zero); highlightPath = [] } label: {
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

    // MARK: - Video Matching

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

    /// Find videos whose title contains the node label (keyword match)
    private func matchingVideosByLabel(for node: FlowNode) -> [Video] {
        guard let label = node.label, label.count >= 3 else { return [] }
        let linked = findVideo(node.video_url, title: node.video_title)
        return api.videos.filter { video in
            guard video.id != linked?.id else { return false }
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

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
        case "start": return tr("開始"); case "decision": return tr("判断"); case "action": return tr("アクション")
        case "position": return tr("ポジション"); case "submission": return tr("極め"); case "result": return tr("結果")
        case "top": return tr("トップ"); default: return type ?? ""
        }
    }

    private func edgeColor(_ category: String?) -> Color {
        switch category {
        case "yes": return .green; case "no": return .orange; case "counter": return .yellow
        case "transition": return .blue; case "td": return .cyan; default: return .gray
        }
    }
}
