import SwiftUI

/// Full in-app game plan detail view (no web links)
struct GamePlanInAppDetailView: View {
    let template: GPTemplate
    let planData: GamePlanData?
    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Hero
                heroSection

                // Principles
                if let principles = planData?.meta?.principles, !principles.isEmpty {
                    principlesSection(principles)
                }

                // Positions
                if let positions = planData?.positions, !positions.isEmpty {
                    positionsSection(positions)
                }

                // Submissions / Techniques
                if let subs = planData?.submissions, !subs.isEmpty {
                    submissionsSection(subs)
                }

                // Transitions
                if let transitions = planData?.transitions, !transitions.isEmpty {
                    transitionsSection(transitions)
                }

                // Defense Notes
                if let defense = planData?.defenseNotes, !defense.isEmpty {
                    defenseSection(defense)
                }

                // Not Used
                if let notUsed = planData?.notUsed, !notUsed.isEmpty {
                    notUsedSection(notUsed)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Text(template.icon)
                .font(.system(size: 56))

            Text(template.name)
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)

            CategoryBadge(text: template.tag, color: template.tagColor)

            Text(template.description)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)

            if let desc = planData?.meta?.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Principles

    private func principlesSection(_ principles: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(lang.t("原則", en: "Principles"), icon: "lightbulb.fill", color: .yellow)

            ForEach(Array(principles.enumerated()), id: \.offset) { i, p in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    Text(p)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                        .lineSpacing(3)
                }
            }
        }
        .padding(14)
        .background(Color.yellow.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Positions

    private func positionsSection(_ positions: [GPPosition]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(lang.t("ポジション", en: "Positions"), icon: "figure.martial.arts", color: .purple)

            ForEach(positions) { pos in
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(posTypeColor(pos._type).opacity(0.12))
                            .frame(width: 32, height: 32)
                        Text(pos._type == "*" ? "★" : pos._type == "!" ? "⚠" : "●")
                            .font(.caption)
                            .foregroundStyle(posTypeColor(pos._type))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(pos.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                        if !pos.description.isEmpty {
                            Text(pos.description)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                                .lineSpacing(2)
                        }
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Submissions

    private func submissionsSection(_ subs: [GPSubmission]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(lang.t("サブミッション・スイープ", en: "Submissions & Sweeps"), icon: "bolt.fill", color: .red)

            ForEach(subs) { sub in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(subPriorityColor(sub.priority))
                        .frame(width: 8, height: 8)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(sub.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.jfTextPrimary)
                            if !sub.from.isEmpty {
                                Text("← \(sub.from)")
                                    .font(.caption2)
                                    .foregroundStyle(Color.jfTextTertiary)
                            }
                        }
                        if !sub.notes.isEmpty {
                            Text(sub.notes)
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Transitions

    private func transitionsSection(_ transitions: [GPTransition]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(lang.t("トランジション", en: "Transitions"), icon: "arrow.triangle.branch", color: .blue)

            ForEach(transitions) { t in
                HStack(spacing: 8) {
                    Text(t.from)
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(t.to)
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    if !t.trigger.isEmpty {
                        Text("(\(t.trigger))")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Defense

    private func defenseSection(_ notes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(lang.t("防御の注意点", en: "Defense Notes"), icon: "shield.fill", color: .orange)

            ForEach(notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 2)
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Not Used

    private func notUsedSection(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(lang.t("使わないテクニック", en: "Unused Techniques"), icon: "xmark.circle.fill", color: .gray)

            ForEach(items, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "minus.circle")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    Text(item)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
        }
        .padding(14)
        .glassCard()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)
        }
    }

    private func posTypeColor(_ type: String) -> Color {
        switch type {
        case "*": return .yellow  // Main position
        case "!": return .orange  // Emergency
        default: return .purple
        }
    }

    private func subPriorityColor(_ priority: String) -> Color {
        switch priority {
        case "high": return .red
        case "medium": return .orange
        default: return .gray
        }
    }
}

// MARK: - Game Plan Data Models (matches SSR JSON)

struct GamePlanData: Codable {
    let meta: GPMeta?
    let positions: [GPPosition]?
    let submissions: [GPSubmission]?
    let transitions: [GPTransition]?
    let defenseNotes: [String]?
    let notUsed: [String]?
}

struct GPMeta: Codable {
    let name: String?
    let description: String?
    let principles: [String]?
}

struct GPPosition: Codable, Identifiable {
    var id: String { _id ?? name }
    let _id: String?
    let name: String
    let type: String?
    let _type: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case name, type, _type, description
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _id = try c.decodeIfPresent(String.self, forKey: ._id)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: .type)
        _type = (try? c.decode(String.self, forKey: ._type)) ?? ""
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
    }
}

struct GPSubmission: Codable, Identifiable {
    var id: String { name }
    let name: String
    let from: String
    let priority: String
    let notes: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? ""
        from = (try? c.decode(String.self, forKey: .from)) ?? ""
        priority = (try? c.decode(String.self, forKey: .priority)) ?? ""
        notes = (try? c.decode(String.self, forKey: .notes)) ?? ""
    }
}

struct GPTransition: Codable, Identifiable {
    var id: String { "\(from)-\(to)" }
    let from: String
    let to: String
    let trigger: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        from = (try? c.decode(String.self, forKey: .from)) ?? ""
        to = (try? c.decode(String.self, forKey: .to)) ?? ""
        trigger = (try? c.decode(String.self, forKey: .trigger)) ?? ""
    }
}
