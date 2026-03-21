import SwiftUI

struct InstructorSystemsView: View {
    private let systems = [
        InstructorSystem(
            id: "ryozo", name: "村田良蔵システム", nameEn: "Ryozo System",
            icon: "brain.head.profile", color: .purple,
            description: "40年以上の経験から生まれた独自の柔術理論体系",
            path: "/ryozo-system"
        ),
        InstructorSystem(
            id: "awata", name: "粟田システム", nameEn: "Awata System",
            icon: "figure.martial.arts", color: .blue,
            description: "効率的なポジショニングと流れを重視した指導法",
            path: "/awata-system"
        ),
        InstructorSystem(
            id: "hamada", name: "濱田システム", nameEn: "Hamada System",
            icon: "bolt.fill", color: .orange,
            description: "アグレッシブなガードゲームを軸にした体系",
            path: "/hamada-system"
        ),
        InstructorSystem(
            id: "hiroki", name: "ヒロキシステム", nameEn: "Hiroki System",
            icon: "arrow.triangle.branch", color: .green,
            description: "フローベースのトランジションを重視",
            path: "/hiroki-system"
        ),
        InstructorSystem(
            id: "noji", name: "野地システム", nameEn: "Noji System",
            icon: "shield.lefthalf.filled", color: .red,
            description: "ディフェンシブからカウンターへの展開",
            path: "/noji-system"
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.jfRed)

                        Text("指導者のシステムを学ぶ")
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    .padding(.vertical, 12)

                    ForEach(systems) { system in
                        InstructorSystemCard(system: system)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("指導者システム")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct InstructorSystem: Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let icon: String
    let color: Color
    let description: String
    let path: String
}

struct InstructorSystemCard: View {
    let system: InstructorSystem

    var body: some View {
        Link(destination: URL(string: "https://jiuflow-ssr.fly.dev\(system.path)")!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(system.color.opacity(0.12))
                        .frame(width: 56, height: 56)
                    Image(systemName: system.icon)
                        .font(.title2)
                        .foregroundStyle(system.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(system.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    Text(system.nameEn)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)

                    Text(system.description)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(14)
            .glassCard()
        }
    }
}
