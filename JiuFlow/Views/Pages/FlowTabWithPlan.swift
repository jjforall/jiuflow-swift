import SwiftUI

/// FlowTab opened with a specific game plan pre-selected
struct FlowTabWithPlan: View {
    let plan: GamePlanRoute
    @EnvironmentObject var api: APIService
    @State private var currentNodeId: String = "start"
    @State private var breadcrumb: [String] = []

    private var currentNode: FlowNode? {
        api.flowNodes.first { $0.id == currentNodeId }
    }

    private var outEdges: [FlowEdge] {
        api.flowEdges.filter { $0.source_id == currentNodeId }
    }

    private var planNodeSet: Set<String> {
        Set(plan.nodeIds)
    }

    // Edges filtered to plan route
    private var planEdges: [FlowEdge] {
        outEdges.filter { edge in
            planNodeSet.contains(edge.target_id ?? "")
        }
    }

    // Other edges (not in plan)
    private var otherEdges: [FlowEdge] {
        outEdges.filter { edge in
            !planNodeSet.contains(edge.target_id ?? "")
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // Plan banner
                planBanner

                // Progress bar
                progressBar

                // Current node
                if let node = currentNode {
                    nodeCard(node)
                }

                // Plan route paths (highlighted)
                if !planEdges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(plan.color)
                            Text("ゲームプランのルート")
                                .font(.caption.bold())
                                .foregroundStyle(plan.color)
                        }
                        .padding(.horizontal, 16)

                        ForEach(planEdges, id: \.id) { edge in
                            edgeButton(edge, highlighted: true)
                        }
                    }
                }

                // Other paths (dimmed)
                if !otherEdges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(Color.jfTextTertiary)
                            Text("その他のルート")
                                .font(.caption.bold())
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        .padding(.horizontal, 16)

                        ForEach(otherEdges, id: \.id) { edge in
                            edgeButton(edge, highlighted: false)
                        }
                    }
                }

                // Dead end
                if outEdges.isEmpty && currentNode != nil {
                    VStack(spacing: 12) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 36))
                            .foregroundStyle(plan.color)
                        Text("ゴール！")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)
                        Text("このゲームプランの最終ポジションです")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                        Button {
                            withAnimation {
                                currentNodeId = plan.nodeIds.first ?? "start"
                                breadcrumb = []
                            }
                        } label: {
                            Text("最初から")
                                .font(.caption.bold())
                                .foregroundStyle(plan.color)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            currentNodeId = plan.nodeIds.first ?? "start"
        }
        .task {
            if api.flowNodes.isEmpty { await api.loadTechniqueFlow() }
        }
    }

    // MARK: - Plan Banner

    private var planBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: plan.icon)
                .font(.title3)
                .foregroundStyle(plan.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(plan.description)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(plan.color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(plan.color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    // MARK: - Progress

    private var progressBar: some View {
        let currentIdx = plan.nodeIds.firstIndex(of: currentNodeId) ?? 0
        let total = plan.nodeIds.count
        let pct = total > 0 ? Double(currentIdx) / Double(total - 1) : 0

        return VStack(spacing: 6) {
            // Node names as breadcrumb dots
            HStack(spacing: 4) {
                ForEach(Array(plan.nodeIds.enumerated()), id: \.offset) { i, nodeId in
                    let isVisited = i <= currentIdx
                    let isCurrent = nodeId == currentNodeId
                    Circle()
                        .fill(isCurrent ? plan.color : isVisited ? plan.color.opacity(0.5) : Color.jfBorder)
                        .frame(width: isCurrent ? 10 : 6, height: isCurrent ? 10 : 6)
                        .onTapGesture {
                            withAnimation { currentNodeId = nodeId }
                        }
                    if i < plan.nodeIds.count - 1 {
                        Rectangle()
                            .fill(isVisited ? plan.color.opacity(0.3) : Color.jfBorder)
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, 16)

            Text("ステップ \(currentIdx + 1) / \(total)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Node Card

    private func nodeCard(_ node: FlowNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                PositionIcon(nodeId: node.id, nodeType: node.node_type, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.label ?? node.id)
                        .font(.headline)
                        .foregroundStyle(Color.jfTextPrimary)
                    if let type = node.node_type {
                        CategoryBadge(text: type, color: plan.color)
                    }
                }
                Spacer()
            }

            if let desc = node.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .glassCard()
        .padding(.horizontal, 16)
    }

    // MARK: - Edge Button

    private func edgeButton(_ edge: FlowEdge, highlighted: Bool) -> some View {
        let targetNode = api.flowNodes.first { $0.id == (edge.target_id ?? "") }

        return Button {
            withAnimation(.spring(response: 0.35)) {
                breadcrumb.append(currentNodeId)
                currentNodeId = edge.target_id ?? currentNodeId
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: highlighted ? "arrow.right.circle.fill" : "arrow.right.circle")
                    .font(.body)
                    .foregroundStyle(highlighted ? plan.color : Color.jfTextTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(edge.label ?? targetNode?.label ?? edge.target_id ?? "")
                        .font(.subheadline.bold())
                        .foregroundStyle(highlighted ? Color.jfTextPrimary : Color.jfTextTertiary)
                    if let desc = targetNode?.description {
                        Text(desc)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if highlighted {
                    Text("推奨")
                        .font(.caption2.bold())
                        .foregroundStyle(plan.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(plan.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(highlighted ? plan.color.opacity(0.05) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(highlighted ? plan.color.opacity(0.2) : Color.jfBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
    }
}
