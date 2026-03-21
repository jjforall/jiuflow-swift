import SwiftUI

/// Returns the appropriate position icon for a flow node based on its ID and type
struct PositionIcon: View {
    let nodeId: String
    let nodeType: String?
    var size: CGFloat = 44

    var body: some View {
        let icon = iconForNode(nodeId: nodeId, nodeType: nodeType)
        icon
            .frame(width: size, height: size)
    }

    @ViewBuilder
    private func iconForNode(nodeId: String, nodeType: String?) -> some View {
        let s = size
        Canvas { ctx, canvasSize in
            let scale = canvasSize.width / 100.0
            drawIcon(nodeId: nodeId, nodeType: nodeType, in: &ctx, scale: scale)
        }
    }

    private func drawIcon(nodeId: String, nodeType: String?, in ctx: inout GraphicsContext, scale: CGFloat) {
        let blue = Color(red: 0.23, green: 0.51, blue: 0.96)
        let red = Color(red: 0.94, green: 0.27, blue: 0.27)
        let yellow = Color(red: 0.92, green: 0.70, blue: 0.05)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scale, y: y * scale)
        }
        func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color, _ w: CGFloat = 2.5) {
            var p = Path()
            p.move(to: pt(x1, y1))
            p.addLine(to: pt(x2, y2))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * scale / 100 * 3, lineCap: .round))
        }
        func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
            let rect = CGRect(x: (cx - r) * scale, y: (cy - r) * scale, width: r * 2 * scale, height: r * 2 * scale)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }
        func curve(_ x1: CGFloat, _ y1: CGFloat, _ cx: CGFloat, _ cy: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color) {
            var p = Path()
            p.move(to: pt(x1, y1))
            p.addQuadCurve(to: pt(x2, y2), control: pt(cx, cy))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 2.5 * scale / 100 * 3, lineCap: .round))
        }

        // Match node ID to specific position icons
        if nodeId.hasPrefix("p_closed") || nodeId.contains("closed") {
            // Closed Guard
            circle(35, 72, 7, blue); line(35, 79, 35, 58, blue); line(35, 62, 22, 55, blue); line(35, 62, 48, 55, blue)
            curve(35, 58, 25, 45, 50, 40, blue); curve(35, 58, 45, 45, 55, 42, blue)
            circle(50, 32, 7, red); line(50, 39, 50, 55, red); line(50, 45, 38, 40, red); line(50, 45, 62, 40, red)
            line(50, 55, 42, 68, red); line(50, 55, 58, 68, red)
        } else if nodeId.hasPrefix("p_half") || nodeId.contains("half_recovery") {
            // Half Guard
            circle(35, 72, 7, blue); line(35, 79, 35, 58, blue); line(35, 62, 22, 55, blue); line(35, 62, 48, 55, blue)
            curve(35, 58, 30, 48, 45, 44, blue); line(35, 58, 25, 48, blue)
            circle(50, 30, 7, red); line(50, 37, 48, 52, red); line(50, 43, 38, 38, red); line(50, 43, 62, 38, red)
            line(48, 52, 40, 65, red); line(48, 52, 58, 62, red)
        } else if nodeId.hasPrefix("p_butterfly") {
            // Butterfly Guard
            circle(35, 55, 7, blue); line(35, 62, 35, 75, blue); line(35, 67, 22, 60, blue); line(35, 67, 48, 58, blue)
            curve(35, 75, 40, 78, 48, 70, blue); curve(35, 75, 30, 78, 25, 70, blue)
            circle(55, 38, 7, red); line(55, 45, 52, 60, red); line(55, 50, 43, 45, red); line(55, 50, 67, 45, red)
            line(52, 60, 45, 72, red); line(52, 60, 62, 72, red)
        } else if nodeId.hasPrefix("p_dlr") || nodeId.contains("dlr") && !nodeId.contains("rdlr") {
            // DLR
            circle(30, 68, 7, blue); line(30, 75, 30, 55, blue); line(30, 60, 18, 53, blue); line(30, 60, 50, 50, blue)
            curve(30, 55, 45, 40, 60, 45, blue); line(30, 55, 20, 42, blue)
            circle(58, 25, 7, red); line(58, 32, 58, 50, red); line(58, 40, 45, 35, red); line(58, 40, 70, 35, red)
            line(58, 50, 50, 65, red); line(58, 50, 66, 65, red)
        } else if nodeId.hasPrefix("p_rdlr") {
            // Reverse DLR (mirror)
            circle(70, 68, 7, blue); line(70, 75, 70, 55, blue); line(70, 60, 82, 53, blue); line(70, 60, 50, 50, blue)
            curve(70, 55, 55, 40, 40, 45, blue); line(70, 55, 80, 42, blue)
            circle(42, 25, 7, red); line(42, 32, 42, 50, red); line(42, 40, 55, 35, red); line(42, 40, 30, 35, red)
            line(42, 50, 50, 65, red); line(42, 50, 34, 65, red)
        } else if nodeId.hasPrefix("p_spider") {
            // Spider Guard
            circle(35, 70, 7, blue); line(35, 63, 35, 52, blue); line(35, 55, 20, 45, blue); line(35, 55, 55, 40, blue)
            curve(35, 52, 28, 38, 22, 32, blue); curve(35, 52, 45, 35, 55, 30, blue)
            circle(60, 20, 7, red); line(60, 27, 58, 45, red); line(60, 33, 48, 30, red); line(60, 33, 72, 30, red)
            line(58, 45, 52, 62, red); line(58, 45, 68, 62, red)
        } else if nodeId.hasPrefix("p_knee_shield") {
            // Knee Shield
            circle(35, 70, 7, blue); line(35, 63, 35, 52, blue); line(35, 56, 22, 50, blue); line(35, 56, 48, 50, blue)
            curve(35, 52, 42, 42, 52, 42, blue); line(35, 52, 28, 42, blue)
            circle(55, 30, 7, red); line(55, 37, 53, 52, red); line(55, 42, 42, 38, red); line(55, 42, 67, 38, red)
            line(53, 52, 45, 65, red); line(53, 52, 63, 65, red)
        } else if nodeId.hasPrefix("p_turtle") {
            // Turtle
            circle(50, 45, 7, blue); line(50, 52, 50, 62, blue)
            line(50, 55, 35, 68, blue); line(50, 55, 65, 68, blue)
            line(50, 62, 38, 72, blue); line(50, 62, 62, 72, blue)
        } else if nodeId.hasPrefix("p_saddle") || nodeId.hasPrefix("p_5050") {
            // Saddle / 50-50 (legs entangled)
            circle(35, 30, 7, blue); line(35, 37, 35, 52, blue); line(35, 43, 22, 38, blue); line(35, 43, 48, 38, blue)
            circle(65, 30, 7, red); line(65, 37, 65, 52, red); line(65, 43, 52, 38, red); line(65, 43, 78, 38, red)
            // Entangled legs
            curve(35, 52, 45, 65, 55, 60, blue); curve(65, 52, 55, 65, 45, 60, red)
            curve(35, 52, 40, 70, 50, 72, blue); curve(65, 52, 60, 70, 50, 72, red)
        } else if nodeId.hasPrefix("p_x") || nodeId.hasPrefix("p_slx") {
            // X Guard / SLX
            circle(40, 65, 7, blue); line(40, 58, 40, 48, blue); line(40, 52, 28, 45, blue); line(40, 52, 52, 45, blue)
            // X legs under opponent
            line(40, 48, 55, 35, blue); line(40, 48, 50, 30, blue)
            circle(55, 22, 7, red); line(55, 29, 55, 45, red); line(55, 35, 42, 30, red); line(55, 35, 68, 30, red)
            line(55, 45, 48, 60, red); line(55, 45, 62, 60, red)
        } else if nodeId.hasPrefix("p_fhl") {
            // Front Headlock
            circle(45, 55, 7, blue); line(45, 48, 45, 38, blue); line(45, 42, 32, 48, blue); line(45, 42, 58, 48, blue)
            circle(50, 30, 7, red); line(50, 37, 48, 48, red)
            // Arm around head
            curve(50, 37, 42, 35, 40, 42, red); curve(50, 37, 55, 40, 52, 48, red)
            line(48, 48, 38, 60, red); line(48, 48, 58, 60, red)
        } else if nodeId.hasPrefix("p_lasso") || nodeId.hasPrefix("p_worm") {
            // Lasso/Worm Guard (foot wrapped around arm)
            circle(35, 70, 7, blue); line(35, 63, 35, 52, blue); line(35, 56, 22, 50, blue); line(35, 56, 48, 50, blue)
            // Lasso wrap
            curve(35, 52, 30, 35, 50, 30, blue); curve(50, 30, 60, 28, 58, 38, blue)
            line(35, 52, 25, 42, blue)
            circle(58, 22, 7, red); line(58, 29, 58, 48, red); line(58, 36, 45, 32, red); line(58, 36, 70, 32, red)
            line(58, 48, 50, 62, red); line(58, 48, 66, 62, red)
        } else if nodeId.hasPrefix("p_collar") || nodeId.hasPrefix("p_deep") || nodeId.hasPrefix("p_rubber") {
            // Generic guard (collar sleeve, deep half, rubber guard)
            circle(35, 68, 7, blue); line(35, 61, 35, 50, blue); line(35, 55, 22, 48, blue); line(35, 55, 50, 45, blue)
            curve(35, 50, 38, 38, 50, 35, blue); line(35, 50, 25, 40, blue)
            circle(55, 28, 7, red); line(55, 35, 53, 50, red); line(55, 40, 42, 36, red); line(55, 40, 68, 36, red)
            line(53, 50, 45, 62, red); line(53, 50, 63, 62, red)
        } else if nodeId == "start" {
            // Stand
            circle(35, 20, 7, blue); line(35, 27, 35, 55, blue); line(35, 35, 22, 42, blue); line(35, 35, 48, 42, blue)
            line(35, 55, 28, 78, blue); line(35, 55, 42, 78, blue)
            circle(65, 20, 7, red); line(65, 27, 65, 55, red); line(65, 35, 52, 42, red); line(65, 35, 78, 42, red)
            line(65, 55, 58, 78, red); line(65, 55, 72, 78, red)
        } else if nodeId.hasPrefix("p_guard") {
            // Guard Recovery
            circle(40, 70, 7, blue); line(40, 63, 40, 52, blue); line(40, 56, 28, 50, blue); line(40, 56, 52, 50, blue)
            curve(40, 52, 45, 42, 55, 40, blue); line(40, 52, 30, 42, blue)
            circle(55, 30, 7, red); line(55, 37, 53, 50, red); line(55, 42, 42, 38, red); line(55, 42, 68, 38, red)
            line(53, 50, 45, 62, red); line(53, 50, 63, 62, red)
        } else if nodeType == "decision" {
            // Decision node (person with question mark paths)
            circle(50, 30, 7, yellow); line(50, 37, 50, 55, yellow); line(50, 45, 35, 38, yellow); line(50, 45, 65, 38, yellow)
            // Branching paths
            var p1 = Path(); p1.move(to: pt(35, 60)); p1.addLine(to: pt(25, 72))
            ctx.stroke(p1, with: .color(yellow.opacity(0.5)), style: StrokeStyle(lineWidth: 2 * scale / 100 * 3, lineCap: .round, dash: [3 * scale / 30, 3 * scale / 30]))
            var p2 = Path(); p2.move(to: pt(50, 60)); p2.addLine(to: pt(50, 72))
            ctx.stroke(p2, with: .color(yellow.opacity(0.5)), style: StrokeStyle(lineWidth: 2 * scale / 100 * 3, lineCap: .round, dash: [3 * scale / 30, 3 * scale / 30]))
            var p3 = Path(); p3.move(to: pt(65, 60)); p3.addLine(to: pt(75, 72))
            ctx.stroke(p3, with: .color(yellow.opacity(0.5)), style: StrokeStyle(lineWidth: 2 * scale / 100 * 3, lineCap: .round, dash: [3 * scale / 30, 3 * scale / 30]))
            let q = Text("?").font(.system(size: 14 * scale / 100 * 3, weight: .bold)).foregroundStyle(yellow)
            ctx.draw(ctx.resolve(q), at: pt(50, 82), anchor: .center)
        } else if nodeType == "action" || nodeId.hasPrefix("a_") {
            // Action (person in motion)
            circle(45, 25, 7, blue); line(45, 32, 45, 50, blue); line(45, 38, 30, 32, blue); line(45, 38, 60, 30, blue)
            line(45, 50, 32, 70, blue); line(45, 50, 55, 65, blue)
            // Motion lines
            var m1 = Path(); m1.move(to: pt(65, 35)); m1.addLine(to: pt(75, 35))
            ctx.stroke(m1, with: .color(blue.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5 * scale / 100 * 3, lineCap: .round))
            var m2 = Path(); m2.move(to: pt(65, 42)); m2.addLine(to: pt(78, 42))
            ctx.stroke(m2, with: .color(blue.opacity(0.3)), style: StrokeStyle(lineWidth: 1.5 * scale / 100 * 3, lineCap: .round))
            var m3 = Path(); m3.move(to: pt(62, 49)); m3.addLine(to: pt(72, 49))
            ctx.stroke(m3, with: .color(blue.opacity(0.2)), style: StrokeStyle(lineWidth: 1.5 * scale / 100 * 3, lineCap: .round))
        } else if nodeType == "result" || nodeType == "top" {
            // Result / Top position
            circle(50, 28, 7, red); line(50, 35, 50, 48, red); line(50, 40, 37, 35, red); line(50, 40, 63, 35, red)
            curve(50, 48, 38, 55, 33, 62, red); curve(50, 48, 62, 55, 67, 62, red)
            circle(50, 75, 7, blue); line(50, 68, 50, 55, blue); line(50, 60, 35, 53, blue); line(50, 60, 65, 53, blue)
        } else {
            // Default: generic two-person icon
            circle(40, 35, 7, blue); line(40, 42, 40, 58, blue); line(40, 48, 28, 42, blue); line(40, 48, 52, 42, blue)
            line(40, 58, 32, 72, blue); line(40, 58, 48, 72, blue)
            circle(60, 35, 7, red); line(60, 42, 60, 58, red); line(60, 48, 48, 42, red); line(60, 48, 72, 42, red)
            line(60, 58, 52, 72, red); line(60, 58, 68, 72, red)
        }
    }
}
