import SwiftUI

// MARK: - BracketView

struct BracketView: View {
    let tournamentId: String
    let tournamentName: String

    @EnvironmentObject var api: APIService
    @EnvironmentObject var lang: LanguageManager

    @State private var v2Response: BracketV2Response?
    @State private var fallbackGroups: [BracketGroup] = []
    @State private var isLoading = true
    @State private var errorMsg: String?
    @State private var lastUpdated: Date = .distantPast
    @State private var selectedDojo: String? = nil
    @State private var selectedMat: Int? = nil
    @State private var selectedDivision: String? = nil

    private var myName: String? { api.currentUser?.display_name }

    // All divisions from entries (sorted: adult first, then m30, m36…)
    private var allDivisions: [String] {
        var seen = Set<String>()
        let divs: [String]
        if let resp = v2Response {
            divs = resp.entries.compactMap { $0.division }
        } else {
            divs = fallbackGroups.compactMap { extractDivisionFromKey($0.id) }
        }
        let ordered = divs.filter { seen.insert($0).inserted }
        return ordered.sorted { a, _ in a == "adult" || a == "Adult" }
    }

    private func extractDivisionFromKey(_ key: String) -> String? {
        if key.hasPrefix("Adult") { return "adult" }
        if key.hasPrefix("Master 30") { return "m30" }
        if key.hasPrefix("Master 36") { return "m36" }
        if key.hasPrefix("Master 41") { return "m41" }
        if key.hasPrefix("Master 46") { return "m46" }
        if key.hasPrefix("Master 51") { return "m51" }
        return nil
    }

    private func divisionDisplayName(_ div: String) -> String {
        switch div {
        case "adult": return "Adult"
        case "m30":   return "M30"
        case "m36":   return "M36"
        case "m41":   return "M41"
        case "m46":   return "M46"
        case "m51":   return "M51"
        default:      return div.uppercased()
        }
    }

    // Unique dojos across all entries
    private var allDojos: [String] {
        var seen = Set<String>()
        let names: [String]
        if let resp = v2Response {
            names = resp.entries.compactMap { $0.dojo_name }.filter { !$0.isEmpty }
        } else {
            names = fallbackGroups.flatMap { $0.entries.map { $0.dojo } }.filter { !$0.isEmpty && $0 != "-" }
        }
        return names.filter { seen.insert($0).inserted }.sorted()
    }

    // Unique mat numbers
    private var allMats: [Int] {
        var seen = Set<Int>()
        if let resp = v2Response {
            let fromMatches = resp.matches.compactMap { $0.mat_number }
            let fromEntries = resp.entries.compactMap { $0.mat_number }
            return (fromMatches + fromEntries).filter { seen.insert($0).inserted }.sorted()
        }
        return fallbackGroups.compactMap { $0.matNumber }.filter { seen.insert($0).inserted }.sorted()
    }

    // True when V2 matches are available
    private var hasMatches: Bool { (v2Response?.matches ?? []).isEmpty == false }

    var body: some View {
        ZStack {
            Color(white: 0.04).ignoresSafeArea()

            if isLoading && v2Response == nil && fallbackGroups.isEmpty {
                loadingView
                    .transition(.opacity)
            } else if let err = errorMsg, v2Response == nil && fallbackGroups.isEmpty {
                errorView(err)
                    .transition(.opacity)
            } else if !hasMatches && fallbackGroups.isEmpty {
                emptyView
                    .transition(.opacity)
            } else {
                contentScrollView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: fallbackGroups.isEmpty)
        .navigationTitle(lang.t("ブラケット", en: "Bracket"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await loadBracket() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.jfRed)
                }
                .disabled(isLoading)
            }
        }
        .task(id: tournamentId) {
            await loadBracket()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if !Task.isCancelled { await loadBracket() }
            }
        }
    }

    // MARK: - Sub-views

    private var loadingView: some View {
        VStack(spacing: 14) {
            ForEach(0..<4, id: \.self) { _ in SkeletonCard(height: 80) }
        }
        .padding(.horizontal)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.jfTextTertiary)
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(Color.jfTextTertiary)
            Text(lang.t("エントリーがまだありません", en: "No entries yet"))
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
            Text(lang.t("エントリー受付後にブラケットが表示されます", en: "Bracket will appear after entries open"))
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // Division tabs (Adult / M30 / M36 …)
    private var divisionTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(["all"] + allDivisions, id: \.self) { div in
                    let isAll = div == "all"
                    let active = isAll ? selectedDivision == nil : selectedDivision == div
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDivision = isAll ? nil : div
                            selectedDojo = nil
                            selectedMat = nil
                        }
                    } label: {
                        Text(isAll ? lang.t("すべて", en: "All") : divisionDisplayName(div))
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(active ? Color.jfRed : Color(white: 0.09))
                            .foregroundStyle(active ? .white : Color.jfTextSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(active ? Color.jfRed : Color(white: 0.16), lineWidth: 1.5))
                    }
                    .animation(.easeInOut(duration: 0.15), value: active)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !allMats.isEmpty {
                    ForEach(allMats, id: \.self) { mat in
                        let active = selectedMat == mat
                        Button {
                            selectedMat = active ? nil : mat
                            if !active { selectedDojo = nil }
                        } label: {
                            Label(lang.t("マット\(mat)", en: "Mat \(mat)"),
                                  systemImage: "rectangle.split.3x1")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(active ? Color.jfRed : Color.jfCardBg)
                                .foregroundStyle(active ? .white : Color.jfTextSecondary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(active ? Color.jfRed : Color.jfBorder, lineWidth: 1))
                        }
                    }
                    if !allDojos.isEmpty {
                        Divider().frame(height: 20)
                    }
                }
                ForEach(allDojos, id: \.self) { dojo in
                    let active = selectedDojo == dojo
                    Button {
                        selectedDojo = active ? nil : dojo
                        if !active { selectedMat = nil }
                    } label: {
                        Text(dojo)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(active ? Color.jfRed : Color.jfCardBg)
                            .foregroundStyle(active ? .white : Color.jfTextSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(active ? Color.jfRed : Color.jfBorder, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // Filtered groups for V1 fallback
    private var filteredFallbackGroups: [BracketGroup] {
        fallbackGroups.compactMap { group in
            // Division filter first
            if let div = selectedDivision {
                let gDiv = extractDivisionFromKey(group.id) ?? "adult"
                guard gDiv == div else { return nil }
            }
            if let mat = selectedMat {
                guard group.matNumber == mat else { return nil }
                return group
            }
            if let dojo = selectedDojo {
                let filtered = group.entries.filter { $0.dojo == dojo || $0.dojo.contains(dojo) }
                guard !filtered.isEmpty else { return nil }
                return BracketGroup(id: group.id, label: group.label, entries: filtered, matNumber: group.matNumber)
            }
            return group
        }
    }

    // Filtered V2 response
    private var filteredV2Response: BracketV2Response? {
        guard let resp = v2Response else { return nil }
        // Apply division filter to entries
        let divEntries: [TournamentEntry]
        if let div = selectedDivision {
            divEntries = resp.entries.filter { ($0.division ?? "adult") == div }
        } else {
            divEntries = resp.entries
        }
        let divEntryIds = Set(divEntries.map { $0.id })

        if selectedMat == nil && selectedDojo == nil && selectedDivision == nil { return resp }

        let filteredMatches: [TournamentMatch]
        if let mat = selectedMat {
            filteredMatches = resp.matches.filter {
                $0.mat_number == mat &&
                (($0.entry1_id.map { divEntryIds.contains($0) } ?? true) ||
                 ($0.entry2_id.map { divEntryIds.contains($0) } ?? true))
            }
        } else if let dojo = selectedDojo {
            let dojoEntryIds = Set(divEntries.filter { ($0.dojo_name ?? "").contains(dojo) }.map { $0.id })
            filteredMatches = resp.matches.filter {
                ($0.entry1_id.map { dojoEntryIds.contains($0) } ?? false) ||
                ($0.entry2_id.map { dojoEntryIds.contains($0) } ?? false)
            }
        } else {
            filteredMatches = resp.matches.filter {
                ($0.entry1_id.map { divEntryIds.contains($0) } ?? true) ||
                ($0.entry2_id.map { divEntryIds.contains($0) } ?? true)
            }
        }
        return BracketV2Response(tournament_id: resp.tournament_id, entries: divEntries, matches: filteredMatches)
    }

    private var contentScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Division tabs (sticky at top)
                if allDivisions.count > 1 {
                    divisionTabs
                        .padding(.horizontal, -16)
                }
                if !allMats.isEmpty || !allDojos.isEmpty {
                    filterChips
                        .padding(.horizontal, -16)
                }
                if hasMatches, let resp = filteredV2Response {
                    BracketV2Section(
                        response: resp,
                        lang: lang,
                        myName: myName
                    )
                } else {
                    // V1 fallback: seeded display
                    ForEach(filteredFallbackGroups) { group in
                        BracketGroupCard(group: group, lang: lang, myName: myName)
                    }
                }

                // Footer
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    if lastUpdated != .distantPast {
                        Text(lang.t(
                            "更新: \(lastUpdated.formatted(date: .omitted, time: .shortened))",
                            en: "Updated: \(lastUpdated.formatted(date: .omitted, time: .shortened))"
                        ))
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Load

    private func loadBracket() async {
        isLoading = true
        errorMsg = nil
        do {
            let resp = try await api.fetchBracketV2(tournamentId: tournamentId)
            v2Response = resp
            if resp.matches.isEmpty {
                // Build V1-style groups from TournamentEntry
                fallbackGroups = buildFallbackGroups(from: resp.entries)
            } else {
                fallbackGroups = []
            }
            lastUpdated = .now
        } catch {
            // Try V1 fallback on V2 failure
            do {
                let v1 = try await api.fetchBracket(tournamentId: tournamentId)
                fallbackGroups = buildGroupsFromV1(from: v1.entries)
                v2Response = nil
                lastUpdated = .now
            } catch {
                errorMsg = lang.t("データを取得できませんでした", en: "Could not load bracket data")
            }
        }
        isLoading = false
    }

    // Build BracketGroup list from TournamentEntry (V2 response, no matches)
    private func buildFallbackGroups(from entries: [TournamentEntry]) -> [BracketGroup] {
        var dict: [String: [BracketEntry]] = [:]
        var matByKey: [String: Int] = [:]
        for e in entries {
            let key = groupKey(belt: e.belt, weightClass: e.weight_class, giNogi: e.gi_nogi, division: e.division)
            let be = BracketEntry(
                id: e.id,
                name: e.display_name,
                belt: e.belt,
                weight_class: e.weight_class,
                gi_nogi: e.gi_nogi,
                dojo: e.dojo_name ?? "",
                points: e.points_earned ?? 0
            )
            dict[key, default: []].append(be)
            if let mat = e.mat_number, matByKey[key] == nil { matByKey[key] = mat }
        }
        return dict
            .sorted { $0.key < $1.key }
            .map { BracketGroup(id: $0.key, label: $0.key, entries: $0.value.sorted { $0.points > $1.points }, matNumber: matByKey[$0.key]) }
    }

    // Build BracketGroup list from V1 BracketEntry
    private func buildGroupsFromV1(from entries: [BracketEntry]) -> [BracketGroup] {
        var dict: [String: [BracketEntry]] = [:]
        for e in entries {
            let key = groupKey(belt: e.belt, weightClass: e.weight_class, giNogi: e.gi_nogi, division: nil)
            dict[key, default: []].append(e)
        }
        return dict
            .sorted { $0.key < $1.key }
            .map { BracketGroup(id: $0.key, label: $0.key, entries: $0.value.sorted { $0.points > $1.points }) }
    }

    private func divisionLabel(_ div: String?) -> String {
        switch div {
        case "m30": return "Master 30"
        case "m36": return "Master 36"
        case "m41": return "Master 41"
        case "m46": return "Master 46"
        case "m51": return "Master 51"
        default: return "Adult"
        }
    }

    private func groupKey(belt: String, weightClass: String, giNogi: String, division: String?) -> String {
        let dl = divisionLabel(division)
        let b = belt.uppercased()
        let wc = weightClassJa(weightClass)
        let gi = giNogi.uppercased()
        return "\(dl) \(b) \(wc) (\(gi))"
    }

    // MARK: - Helpers

    private func weightClassJa(_ wc: String) -> String {
        switch wc.lowercased() {
        case "rooster":       return "ルースター (-57.5kg)"
        case "light-feather": return "ライトフェザー (-64kg)"
        case "feather":       return "フェザー (-70kg)"
        case "light":         return "ライト (-76kg)"
        case "middle":        return "ミドル (-82.3kg)"
        case "medium-heavy":  return "ミディアムヘビー (-88.3kg)"
        case "heavy":         return "ヘビー (-94.3kg)"
        case "super-heavy":   return "スーパーヘビー (-100.5kg)"
        case "ultra-heavy":   return "ウルトラヘビー (+100.5kg)"
        default:              return wc
        }
    }
}

// MARK: - BracketV2Section  (matches あり → ラウンドツリー)

private struct BracketV2Section: View {
    let response: BracketV2Response
    let lang: LanguageManager
    let myName: String?

    // Entries keyed by id for O(1) lookup
    private var entryMap: [String: TournamentEntry] {
        Dictionary(uniqueKeysWithValues: response.entries.map { ($0.id, $0) })
    }

    // group_key → [TournamentMatch] sorted by round then match_number
    private var matchesByGroup: [(key: String, matches: [TournamentMatch])] {
        var dict: [String: [TournamentMatch]] = [:]
        for m in response.matches {
            dict[m.group_key, default: []].append(m)
        }
        return dict
            .map { (key: $0.key, matches: $0.value.sorted { $0.round == $1.round ? $0.match_number < $1.match_number : $0.round < $1.round }) }
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        let em = entryMap
        ForEach(matchesByGroup, id: \.key) { group in
            BracketGroupTreeCard(
                groupKey: group.key,
                matches: group.matches,
                entryMap: em,
                lang: lang,
                myName: myName
            )
        }
    }
}

// MARK: - BracketGroupTreeCard  (1グループ = 1カード with 横スクロールツリー)

private struct BracketGroupTreeCard: View {
    let groupKey: String
    let matches: [TournamentMatch]
    let entryMap: [String: TournamentEntry]
    let lang: LanguageManager
    let myName: String?

    private var maxRound: Int { matches.map(\.round).max() ?? 1 }

    // Belt color derived from group_key (e.g. "blue_middle_gi")
    private var beltColor: Color {
        let k = groupKey.lowercased()
        if k.contains("white")  { return Color(white: 0.85) }
        if k.contains("blue")   { return Color(red: 0.15, green: 0.39, blue: 0.92) }
        if k.contains("purple") { return Color(red: 0.49, green: 0.23, blue: 0.93) }
        if k.contains("brown")  { return Color(red: 0.57, green: 0.25, blue: 0.05) }
        if k.contains("black")  { return Color(white: 0.3) }
        return Color.jfRed
    }

    private var headerLabel: String {
        // group_key is typically "blue_middle_gi" → "Blue ミドル (-82.3kg) (GI)"
        let parts = groupKey.split(separator: "_").map(String.init)
        let belt  = (parts.first ?? groupKey).capitalized
        let giNogi = (parts.last ?? "").uppercased()
        let wc = parts.dropFirst().dropLast().joined(separator: "-")
        return "\(belt) \(weightClassJa(wc)) (\(giNogi))"
    }

    private var roundLabels: [Int: String] {
        let total = maxRound
        var labels: [Int: String] = [:]
        for r in 1...total {
            let fromEnd = total - r  // 0 = final, 1 = semi, 2 = QF…
            switch fromEnd {
            case 0: labels[r] = lang.t("決勝", en: "Final")
            case 1: labels[r] = lang.t("準決勝", en: "Semi")
            case 2: labels[r] = lang.t("準々決勝", en: "QF")
            default: labels[r] = lang.t("\(r)回戦", en: "Round \(r)")
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            HStack(spacing: 0) {
                Rectangle()
                    .fill(beltColor)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(lang.t("\(matches.count)試合", en: "\(matches.count) matches"))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(14)
                Spacer()
            }
            .background(Color.jfCardBg)

            Divider().background(Color.jfBorder)

            // ── Round Tree (horizontal scroll) ──
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(1...maxRound, id: \.self) { round in
                        let roundMatches = matches.filter { $0.round == round }
                        let label = roundLabels[round] ?? lang.t("\(round)回戦", en: "Round \(round)")

                        RoundColumn(
                            label: label,
                            matches: roundMatches,
                            entryMap: entryMap,
                            lang: lang,
                            myName: myName,
                            isLastRound: round == maxRound
                        )

                        // Connector line between columns (except after last)
                        if round < maxRound {
                            Rectangle()
                                .fill(Color.jfBorder)
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 40)
                        }
                    }
                }
                .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.jfBorder, lineWidth: 1))
    }

    private func weightClassJa(_ wc: String) -> String {
        switch wc.lowercased() {
        case "rooster":       return "ルースター (-57.5kg)"
        case "light-feather": return "ライトフェザー (-64kg)"
        case "feather":       return "フェザー (-70kg)"
        case "light":         return "ライト (-76kg)"
        case "middle":        return "ミドル (-82.3kg)"
        case "medium-heavy":  return "ミディアムヘビー (-88.3kg)"
        case "heavy":         return "ヘビー (-94.3kg)"
        case "super-heavy":   return "スーパーヘビー (-100.5kg)"
        case "ultra-heavy":   return "ウルトラヘビー (+100.5kg)"
        default:              return wc.isEmpty ? "" : wc
        }
    }
}

// MARK: - RoundColumn

private struct RoundColumn: View {
    let label: String
    let matches: [TournamentMatch]
    let entryMap: [String: TournamentEntry]
    let lang: LanguageManager
    let myName: String?
    let isLastRound: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Round label header
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

            ForEach(matches) { match in
                MatchCard(
                    match: match,
                    entryMap: entryMap,
                    myName: myName,
                    isLastRound: isLastRound
                )
            }
        }
        .frame(width: 180)
        .padding(.horizontal, 8)
    }
}

// MARK: - MatchCard

private struct MatchCard: View {
    let match: TournamentMatch
    let entryMap: [String: TournamentEntry]
    let myName: String?
    let isLastRound: Bool

    private func name(for entryId: String?) -> String {
        guard let eid = entryId else { return "BYE" }
        return entryMap[eid]?.display_name ?? "TBD"
    }

    private func isBye(_ entryId: String?) -> Bool { entryId == nil }

    private func isWinner(_ entryId: String?) -> Bool {
        guard let eid = entryId, let wid = match.winner_id else { return false }
        return eid == wid
    }

    private func isMe(_ entryId: String?) -> Bool {
        guard let eid = entryId, let me = myName else { return false }
        return entryMap[eid]?.display_name == me
    }

    var body: some View {
        VStack(spacing: 0) {
            slotView(entryId: match.entry1_id)
            Divider().background(Color.jfBorder)
            slotView(entryId: match.entry2_id)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isLastRound ? Color.jfRed.opacity(0.5) : Color.jfBorder, lineWidth: isLastRound ? 1.5 : 1)
        )
    }

    @ViewBuilder
    private func slotView(entryId: String?) -> some View {
        let bye    = isBye(entryId)
        let winner = isWinner(entryId)
        let me     = isMe(entryId)
        let n      = name(for: entryId)
        let decided = match.winner_id != nil

        HStack(spacing: 6) {
            // Winner indicator bar
            Rectangle()
                .fill(winner ? Color.jfRed : (me ? Color.jfRed.opacity(0.5) : Color.clear))
                .frame(width: 3)

            if bye {
                Text("BYE")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary.opacity(0.4))
                    .italic()
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(n)
                            .font(.caption.weight(winner ? .bold : .regular))
                            .foregroundStyle(winner ? Color.jfRed : (decided && !winner ? Color.jfTextTertiary : .white))
                            .lineLimit(1)
                        if me {
                            Text("YOU")
                                .font(.system(size: 7, weight: .black))
                                .foregroundStyle(Color.jfRed)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.jfRed.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        if winner {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.33))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            winner ? Color.jfRed.opacity(0.08) :
            (me     ? Color.jfRed.opacity(0.04) :
            (bye    ? Color.black.opacity(0.2)  : Color.jfCardBg))
        )
    }
}

// MARK: - BracketGroupCard (V1 fallback — seeded display)

private struct BracketGroupCard: View {
    let group: BracketGroup
    let lang: LanguageManager
    let myName: String?

    private var beltColor: Color {
        let belt = group.label.lowercased()
        if belt.contains("white")  { return Color(white: 0.85) }
        if belt.contains("blue")   { return Color(red: 0.15, green: 0.39, blue: 0.92) }
        if belt.contains("purple") { return Color(red: 0.49, green: 0.23, blue: 0.93) }
        if belt.contains("brown")  { return Color(red: 0.57, green: 0.25, blue: 0.05) }
        if belt.contains("black")  { return Color(white: 0.3) }
        return Color.jfRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Rectangle()
                    .fill(beltColor)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(lang.t("\(group.entries.count)選手", en: "\(group.entries.count) athletes"))
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
                .padding(14)
                Spacer()
            }
            .background(Color.jfCardBg)

            Divider().background(Color.jfBorder)

            let matchups = buildMatchups(group.entries)
            if matchups.isEmpty {
                Text(lang.t("選手なし", en: "No athletes"))
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .padding(14)
            } else {
                ForEach(Array(matchups.enumerated()), id: \.offset) { idx, pair in
                    MatchupRow(seed: idx + 1, p1: pair.0, p2: pair.1, lang: lang, myName: myName)
                    if idx < matchups.count - 1 {
                        Divider().background(Color.jfBorder).padding(.horizontal)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.jfBorder, lineWidth: 1))
    }

    private func buildMatchups(_ entries: [BracketEntry]) -> [(BracketEntry?, BracketEntry?)] {
        guard !entries.isEmpty else { return [] }
        if entries.count == 1 { return [(entries[0], nil)] }
        var pairs: [(BracketEntry?, BracketEntry?)] = []
        let n = entries.count
        let slots = Int(pow(2.0, ceil(log2(Double(n)))))
        var seeded: [BracketEntry?] = Array(repeating: nil, count: slots)
        for (i, e) in entries.enumerated() { seeded[i] = e }
        for i in stride(from: 0, to: slots / 2, by: 1) {
            pairs.append((seeded[i], seeded[slots - 1 - i]))
        }
        return pairs
    }
}

// MARK: - MatchupRow (V1 fallback)

private struct MatchupRow: View {
    let seed: Int
    let p1: BracketEntry?
    let p2: BracketEntry?
    let lang: LanguageManager
    let myName: String?

    var body: some View {
        VStack(spacing: 0) {
            participantRow(entry: p1, seedNum: seed * 2 - 1)
            HStack {
                Text("vs")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.jfTextTertiary)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 18)
            .background(Color.black.opacity(0.3))
            participantRow(entry: p2, seedNum: seed * 2)
        }
        .background(Color.jfCardBg)
    }

    private func participantRow(entry: BracketEntry?, seedNum: Int) -> some View {
        let isMe = entry != nil && entry?.name == myName
        return HStack(spacing: 10) {
            Rectangle()
                .fill(isMe ? Color.jfRed : Color.clear)
                .frame(width: 3)
            Text("\(seedNum)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(Color.jfTextTertiary)
                .frame(width: 22)
            if let e = entry {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(e.name)
                            .font(.subheadline.weight(isMe ? .bold : .semibold))
                            .foregroundStyle(isMe ? Color.jfRed : .white)
                            .lineLimit(1)
                        if isMe {
                            Text("YOU")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.jfRed)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.jfRed.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    if !e.dojo.isEmpty && e.dojo != "-" {
                        Text(e.dojo)
                            .font(.caption2)
                            .foregroundStyle(Color.jfTextTertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if e.points > 0 {
                    Text("\(e.points)pts")
                        .font(.caption2.bold())
                        .foregroundStyle(Color(red: 0.83, green: 0.66, blue: 0.33))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.83, green: 0.66, blue: 0.33).opacity(0.15))
                        .clipShape(Capsule())
                }
            } else {
                Text("BYE")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextTertiary.opacity(0.4))
                    .italic()
                Spacer()
            }
        }
        .padding(.trailing, 14)
        .padding(.vertical, 10)
        .background(isMe ? Color.jfRed.opacity(0.06) : (entry == nil ? Color.black.opacity(0.15) : Color.clear))
    }
}
