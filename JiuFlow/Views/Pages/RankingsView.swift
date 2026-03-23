import SwiftUI

struct RankingsView: View {
    @EnvironmentObject var apiService: APIService
    @State private var rankings: [Ranking] = []
    @State private var isLoading = true
    @State private var selectedBelt = "all"
    @State private var selectedWeight = "all"

    let belts = ["all", "white", "blue", "purple", "brown", "black"]

    var body: some View {
        VStack(spacing: 0) {
            // Belt filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(belts, id: \.self) { belt in
                        Button(belt == "all" ? "All" : belt.capitalized) {
                            selectedBelt = belt
                            Task { await loadRankings() }
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedBelt == belt ? Color.jfRed : Color.jfCardBg)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if rankings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No rankings yet")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                List(Array(rankings.enumerated()), id: \.element.id) { index, ranking in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(index == 0 ? .jfGold : index == 1 ? .gray : index == 2 ? .orange : .gray)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ranking.display_name)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            HStack(spacing: 6) {
                                Text(ranking.belt.uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ranking.beltColor)
                                    .foregroundColor(ranking.belt == "white" ? .black : .white)
                                    .cornerRadius(4)
                                Text(ranking.weight_class)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                if let dojo = ranking.dojo_name {
                                    Text(dojo)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(ranking.points)")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.jfRed)
                            HStack(spacing: 4) {
                                if ranking.gold > 0 { Label("\(ranking.gold)", systemImage: "medal.fill").font(.caption2).foregroundColor(.yellow) }
                                if ranking.silver > 0 { Label("\(ranking.silver)", systemImage: "medal.fill").font(.caption2).foregroundColor(.gray) }
                                if ranking.bronze > 0 { Label("\(ranking.bronze)", systemImage: "medal.fill").font(.caption2).foregroundColor(.orange) }
                            }
                        }
                    }
                    .listRowBackground(Color.jfCardBg)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("SJJJF Rankings")
        .task { await loadRankings() }
    }

    func loadRankings() async {
        isLoading = true
        rankings = (try? await apiService.getRankings(belt: selectedBelt, weight: selectedWeight)) ?? []
        isLoading = false
    }
}
