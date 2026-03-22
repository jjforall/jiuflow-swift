import SwiftUI

struct LineageTreeView: View {
    @EnvironmentObject var api: APIService
    @State private var selectedAthlete: Athlete?
    @State private var expandedNodes: Set<String> = ["root"]

    // Build tree from athlete lineage data
    private var tree: LineageNode {
        buildTree()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if api.athletes.isEmpty {
                    LoadingWithTips()
                } else {
                    // Legend
                    HStack(spacing: 12) {
                        legendDot(color: .yellow, label: "起源")
                        legendDot(color: .purple, label: "グレイシー")
                        legendDot(color: .blue, label: "現役")
                        legendDot(color: .green, label: "日本")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Tree
                    treeNode(tree, depth: 0)
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("系統図")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if api.athletes.isEmpty { await api.loadAthletes() }
        }
        .sheet(item: $selectedAthlete) { athlete in
            NavigationStack {
                AthleteDetailView(athlete: athlete)
            }
        }
    }

    // MARK: - Tree Node View

    private func treeNode(_ node: LineageNode, depth: Int) -> some View {
        let isExpanded = expandedNodes.contains(node.id)
        let hasChildren = !node.children.isEmpty
        let indent = CGFloat(depth) * 20

        return VStack(alignment: .leading, spacing: 0) {
            // Node row
            HStack(spacing: 8) {
                // Connector line
                if depth > 0 {
                    HStack(spacing: 0) {
                        ForEach(0..<depth, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.jfBorder)
                                .frame(width: 1)
                                .padding(.horizontal, 9)
                        }
                    }
                    .frame(width: indent)
                }

                // Expand button or dot
                if hasChildren {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if isExpanded { expandedNodes.remove(node.id) }
                            else { expandedNodes.insert(node.id) }
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                            .font(.body)
                            .foregroundStyle(nodeColor(node))
                    }
                } else {
                    Circle()
                        .fill(nodeColor(node))
                        .frame(width: 10, height: 10)
                        .padding(.horizontal, 5)
                }

                // Avatar
                if let athlete = node.athlete {
                    Button {
                        selectedAthlete = athlete
                    } label: {
                        HStack(spacing: 10) {
                            AsyncImage(url: athleteAvatarURL(athlete.avatar_url)) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Circle().fill(nodeColor(node).opacity(0.2))
                                        .overlay(
                                            Text(String(node.name.prefix(1)))
                                                .font(.caption2.bold())
                                                .foregroundStyle(nodeColor(node))
                                        )
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 1) {
                                Text(node.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.jfTextPrimary)
                                if let style = athlete.style {
                                    Text(style)
                                        .font(.caption2)
                                        .foregroundStyle(Color.jfTextTertiary)
                                }
                            }

                            if hasChildren {
                                Text("\(node.children.count)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(nodeColor(node))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(nodeColor(node).opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } else {
                    // Name-only node (no athlete in DB)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(nodeColor(node).opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(node.name.prefix(1)))
                                    .font(.caption2.bold())
                                    .foregroundStyle(nodeColor(node))
                            )
                        Text(node.name)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)

            // Children
            if isExpanded {
                ForEach(node.children) { child in
                    treeNode(child, depth: depth + 1)
                }
            }
        }
    }

    // MARK: - Legend

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundStyle(Color.jfTextTertiary)
        }
    }

    // MARK: - Node Color

    private func nodeColor(_ node: LineageNode) -> Color {
        let name = node.name.lowercased()
        if name.contains("嘉納") || name.contains("前田") || name.contains("maeda") || name.contains("kano") { return .yellow }
        if name.contains("グレイシー") || name.contains("gracie") { return .purple }
        if name.contains("yaway") || name.contains("双子") || name.contains("村田") || name.contains("青木") || name.contains("中井") || name.contains("石井") || name.contains("井上") { return .green }
        return .blue
    }

    // MARK: - Build Tree

    private func buildTree() -> LineageNode {
        // Parse all lineages and build a tree
        var parentToChildren: [String: Set<String>] = [:]
        var nameToAthlete: [String: Athlete] = [:]

        for athlete in api.athletes {
            guard let lineageStr = athlete.lineage else { continue }
            let parts = lineageStr.components(separatedBy: " → ").map { $0.trimmingCharacters(in: .whitespaces) }

            // Map last name to athlete
            if let last = parts.last {
                nameToAthlete[last] = athlete
            }

            // Build parent→child relationships
            for i in 0..<parts.count - 1 {
                parentToChildren[parts[i], default: []].insert(parts[i + 1])
                // Also map intermediate names if we have athletes for them
                if let a = api.athletes.first(where: {
                    $0.displayName.contains(parts[i]) || (parts[i]).contains($0.displayName)
                }) {
                    nameToAthlete[parts[i]] = a
                }
            }
        }

        // Find root nodes (nodes that are never children)
        let allChildren = Set(parentToChildren.values.flatMap { $0 })
        let allParents = Set(parentToChildren.keys)
        let roots = allParents.subtracting(allChildren)

        func buildNode(_ name: String) -> LineageNode {
            let children = (parentToChildren[name] ?? []).sorted().map { buildNode($0) }
            return LineageNode(id: name, name: name, athlete: nameToAthlete[name], children: children)
        }

        // Create root with all top-level ancestors
        let rootChildren = roots.sorted().map { buildNode($0) }

        return LineageNode(id: "root", name: "柔術の系統", athlete: nil, children: rootChildren)
    }
}

// MARK: - Lineage Node Model

struct LineageNode: Identifiable {
    let id: String
    let name: String
    let athlete: Athlete?
    let children: [LineageNode]
}

// Make Athlete conform to Identifiable for sheet
extension Athlete: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: Athlete, rhs: Athlete) -> Bool { lhs.id == rhs.id }
}
