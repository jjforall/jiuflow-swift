import SwiftUI

struct TechniqueTab: View {
    @EnvironmentObject var api: APIService
    @State private var expandedCategories: Set<String> = []
    @State private var selectedSegment = 0  // 0=map, 1=flow

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment picker
                Picker("表示モード", selection: $selectedSegment) {
                    Text("マップ").tag(0)
                    Text("フロー").tag(1)
                    Text("グラフ").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Content
                Group {
                    if selectedSegment == 0 {
                        techniqueMapView
                    } else if selectedSegment == 1 {
                        TechniqueFlowView()
                            .environmentObject(api)
                    } else {
                        TechniqueGraphView()
                            .environmentObject(api)
                    }
                }
            }
            .background(Color.jfDarkBg)
            .scrollContentBackground(.hidden)
            .navigationTitle("テクニック")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if api.techniqueRoot == nil {
                    await api.loadTechniques()
                }
            }
        }
    }

    // MARK: - Map View (existing tree)

    @ViewBuilder
    private var techniqueMapView: some View {
        if api.isLoading && api.techniqueRoot == nil {
            VStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonCard(height: 80)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if let root = api.techniqueRoot {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Root info header
                    VStack(spacing: 10) {
                        Text(root.emoji ?? "")
                            .font(.system(size: 56))

                        Text(root.label ?? "テクニックマップ")
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        if let desc = root.desc {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(Color.jfTextTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Stats bar
                        if let children = root.children {
                            HStack(spacing: 20) {
                                TechniqueStatPill(
                                    icon: "folder.fill",
                                    value: "\(children.count)",
                                    label: "カテゴリ"
                                )
                                TechniqueStatPill(
                                    icon: "list.bullet",
                                    value: "\(root.childCount)",
                                    label: "テクニック"
                                )
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)

                    // Categories
                    if let categories = root.children {
                        ForEach(categories) { category in
                            TechniqueCategoryCard(
                                category: category,
                                isExpanded: expandedCategories.contains(category.id),
                                videos: api.videos
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    if expandedCategories.contains(category.id) {
                                        expandedCategories.remove(category.id)
                                    } else {
                                        expandedCategories.insert(category.id)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
            .refreshable {
                await api.loadTechniques()
            }
        } else {
            EmptyStateView(
                icon: "figure.martial.arts",
                title: "テクニックがありません",
                message: "引っ張って再読み込みしてください",
                actionTitle: "再読み込み"
            ) {
                Task { await api.loadTechniques() }
            }
        }
    }
}

// MARK: - Interactive Flow View ("Choose Your Own Adventure")

struct TechniqueFlowView: View {
    @EnvironmentObject var api: APIService
    @State private var currentNodeId: String = "start"
    @State private var breadcrumb: [String] = []  // node IDs visited
    @State private var selectedNodeDetail: FlowNode?

    private var currentNode: FlowNode? {
        api.flowNodes.first { $0.id == currentNodeId }
    }

    private var outgoingEdges: [FlowEdge] {
        api.flowEdges.filter { $0.source_id == currentNodeId }
    }

    /// Find matching videos for a node label
    private func matchingVideos(for node: FlowNode) -> [Video] {
        guard let label = node.label, !label.isEmpty else { return [] }
        return api.videos.filter { video in
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

    var body: some View {
        Group {
            if api.isLoading && api.flowNodes.isEmpty {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonCard(height: 100)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else if api.flowNodes.isEmpty {
                EmptyStateView(
                    icon: "arrow.triangle.branch",
                    title: "フローが読み込めません",
                    message: "ネットワーク接続を確認してください",
                    actionTitle: "再読み込み"
                ) {
                    Task { await api.loadTechniqueFlow() }
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Breadcrumb trail
                        if !breadcrumb.isEmpty {
                            breadcrumbView
                        }

                        // Current node card
                        if let node = currentNode {
                            currentNodeCard(node)
                        }

                        // Matching videos
                        if let node = currentNode {
                            let videos = matchingVideos(for: node)
                            if !videos.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: "関連動画", icon: "play.rectangle.fill")
                                    ForEach(videos) { video in
                                        flowVideoRow(video)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // Outgoing edges as option buttons
                        if !outgoingEdges.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("次のアクション")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .padding(.leading, 4)

                                ForEach(outgoingEdges) { edge in
                                    flowOptionButton(edge)
                                }
                            }
                        } else if currentNode != nil {
                            // Dead end
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(Color.green)
                                Text("ここが終点です")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.jfTextSecondary)
                            }
                            .padding(.top, 20)
                        }

                        // Reset button
                        if currentNodeId != "start" {
                            Button {
                                withAnimation(.spring(response: 0.35)) {
                                    currentNodeId = "start"
                                    breadcrumb = []
                                }
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
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await api.loadTechniqueFlow()
                    if api.videos.isEmpty {
                        await api.loadVideos()
                    }
                }
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

    // MARK: - Breadcrumb

    private var breadcrumbView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(breadcrumb.enumerated()), id: \.offset) { index, nodeId in
                    if let node = api.flowNodes.first(where: { $0.id == nodeId }) {
                        Button {
                            // Go back to this node
                            withAnimation(.spring(response: 0.35)) {
                                currentNodeId = nodeId
                                breadcrumb = Array(breadcrumb.prefix(index))
                            }
                        } label: {
                            Text(node.label ?? node.id)
                                .font(.caption2)
                                .foregroundStyle(Color.jfTextTertiary)
                                .lineLimit(1)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.jfTextTertiary.opacity(0.5))
                    }
                }

                // Current
                if let node = currentNode {
                    Text(node.label ?? node.id)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.jfRed)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Current Node Card

    private func currentNodeCard(_ node: FlowNode) -> some View {
        VStack(spacing: 14) {
            // Node type icon
            nodeTypeIcon(node.node_type)

            Text(node.label ?? "不明")
                .font(.title3.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .multilineTextAlignment(.center)

            // Node type badge
            if let nodeType = node.node_type {
                Text(nodeTypeLabel(nodeType))
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(nodeTypeColor(nodeType).opacity(0.2))
                    .foregroundStyle(nodeTypeColor(nodeType))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(nodeTypeBgColor(node.node_type).opacity(0.08))
        )
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Flow Option Button

    private func flowOptionButton(_ edge: FlowEdge) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                breadcrumb.append(currentNodeId)
                if let targetId = edge.target_id {
                    currentNodeId = targetId
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Edge category icon
                edgeCategoryIcon(edge.category)

                VStack(alignment: .leading, spacing: 2) {
                    // Edge label or target node label
                    if let edgeLabel = edge.label, !edgeLabel.isEmpty {
                        Text(edgeLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.jfTextPrimary)
                    }

                    // Show target node name
                    if let targetId = edge.target_id,
                       let targetNode = api.flowNodes.first(where: { $0.id == targetId }) {
                        Text(targetNode.label ?? targetId)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(14)
            .glassCard(cornerRadius: 14)
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: currentNodeId)
    }

    // MARK: - Video Row in Flow

    private func flowVideoRow(_ video: Video) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                AsyncImage(url: video.fullThumbnailURL(baseURL: api.baseURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ShimmerView()
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        )
                }
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Image(systemName: "play.circle.fill")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(video.displayTitle)
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)

                if let type = video.video_type {
                    CategoryBadge(text: type, color: videoTypeColor(type))
                }
            }

            Spacer()

            if let urlStr = video.video_url, let url = URL(string: urlStr) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.body)
                        .foregroundStyle(Color.jfRed)
                }
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 12)
    }

    // MARK: - Helpers

    private func nodeTypeIcon(_ type: String?) -> some View {
        let (icon, color, size): (String, Color, CGFloat) = {
            switch type {
            case "start": return ("flag.fill", .green, 36)
            case "decision": return ("questionmark.diamond.fill", .yellow, 40)
            case "action": return ("bolt.fill", .blue, 36)
            case "position": return ("person.fill", .purple, 36)
            case "submission": return ("hand.raised.fill", .red, 36)
            default: return ("circle.fill", .gray, 32)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: size))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.4), radius: 8)
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

    private func nodeTypeBgColor(_ type: String?) -> Color {
        guard let type else { return .gray }
        return nodeTypeColor(type)
    }

    private func nodeTypeLabel(_ type: String) -> String {
        switch type {
        case "start": return "スタート"
        case "decision": return "判断ポイント"
        case "action": return "テクニック"
        case "position": return "ポジション"
        case "submission": return "サブミッション"
        default: return type
        }
    }

    private func edgeCategoryIcon(_ category: String?) -> some View {
        let (icon, color): (String, Color) = {
            switch category {
            case "yes": return ("checkmark.circle.fill", .green)
            case "no": return ("xmark.circle.fill", .orange)
            case "counter": return ("arrow.uturn.backward.circle.fill", .yellow)
            case "transition": return ("arrow.right.circle.fill", .blue)
            default: return ("arrow.right.circle.fill", .jfTextTertiary)
            }
        }()

        return Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(color)
    }
}

// MARK: - Stat Pill

struct TechniqueStatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.jfRed)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.jfTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 20)
    }
}

// MARK: - Category Card

struct TechniqueCategoryCard: View {
    let category: TechniqueNode
    let isExpanded: Bool
    var videos: [Video] = []
    let onTap: () -> Void

    private var childCount: Int {
        category.children?.count ?? 0
    }

    private var progressValue: Double {
        guard let prob = category.prob else { return 0 }
        return Double(prob) / 100.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Emoji with progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.jfBorder, lineWidth: 3)
                            .frame(width: 48, height: 48)

                        if category.prob != nil {
                            Circle()
                                .trim(from: 0, to: progressValue)
                                .stroke(
                                    LinearGradient.jfRedGradient,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                )
                                .frame(width: 48, height: 48)
                                .rotationEffect(.degrees(-90))
                        }

                        Text(category.emoji ?? "")
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.label ?? "")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)

                        HStack(spacing: 8) {
                            if let desc = category.desc {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(Color.jfTextTertiary)
                                    .lineLimit(1)
                            }
                            if childCount > 0 {
                                Text("\(childCount)項目")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }

                    Spacer()

                    if let prob = category.prob {
                        Text("\(prob)%")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(Color.jfRed)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isExpanded)

            // Children (techniques)
            if isExpanded, let children = category.children {
                Divider()
                    .background(Color.jfBorder)
                    .padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(children) { tech in
                        TechniqueRow(technique: tech, videos: videos)
                        if tech.id != children.last?.id {
                            Divider()
                                .background(Color.jfBorder)
                                .padding(.leading, 56)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard()
    }
}

// MARK: - Technique Row

struct TechniqueRow: View {
    let technique: TechniqueNode
    var videos: [Video] = []
    @State private var showChildren = false

    /// Videos that match this technique name
    private var matchingVideos: [Video] {
        guard let label = technique.label, !label.isEmpty else { return [] }
        return videos.filter { video in
            guard let title = video.title else { return false }
            return title.localizedCaseInsensitiveContains(label) ||
                   label.localizedCaseInsensitiveContains(title)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(technique.emoji ?? "")
                    .font(.body)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(technique.label ?? "")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.jfTextPrimary)

                        if technique.recommended == true {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                        if technique.warning == true {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }

                        // Video indicator
                        if !matchingVideos.isEmpty {
                            Image(systemName: "play.rectangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.jfRed)
                        }
                    }

                    if let desc = technique.desc {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                            .lineLimit(2)
                    }

                    // Video links
                    if !matchingVideos.isEmpty {
                        ForEach(matchingVideos) { video in
                            if let urlStr = video.video_url, let url = URL(string: urlStr) {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 8))
                                        Text(video.displayTitle)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(Color.jfRed)
                                }
                            }
                        }
                    }
                }

                Spacer()

                if let prob = technique.prob {
                    Text("\(prob)%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextTertiary)
                }

                if technique.children != nil && !(technique.children?.isEmpty ?? true) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showChildren.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                            .rotationEffect(.degrees(showChildren ? 90 : 0))
                    }
                }
            }

            // Nested children
            if showChildren, let subChildren = technique.children, !subChildren.isEmpty {
                VStack(spacing: 4) {
                    ForEach(subChildren) { sub in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.jfBorder)
                                .frame(width: 1, height: 16)
                                .padding(.leading, 20)

                            Text(sub.emoji ?? "")
                                .font(.caption)
                            Text(sub.label ?? "")
                                .font(.caption)
                                .foregroundStyle(Color.jfTextSecondary)
                            Spacer()
                            if let prob = sub.prob {
                                Text("\(prob)%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
