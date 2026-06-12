import SwiftUI

struct MyEntriesView: View {
    @EnvironmentObject var api: APIService
    @State private var entries: [TournamentEntry] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("出場履歴なし")
                        .foregroundColor(.gray)
                    Text("大会ページからエントリーできます")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.entry_number)
                                .font(.caption.bold().monospaced())
                                .foregroundColor(.jfRed)
                            Spacer()
                            statusBadge(entry.status)
                        }
                        Text("\(beltJa(entry.belt)) / \(weightClassJa(entry.weight_class)) / \(entry.gi_nogi.uppercased())")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        // Status description
                        if !statusDesc(entry.status).isEmpty {
                            Text(statusDesc(entry.status))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        HStack(spacing: 12) {
                            Text("¥\(entry.amount_jpy)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if let place = entry.place {
                                HStack(spacing: 4) {
                                    Image(systemName: "medal.fill")
                                        .foregroundColor(place == 1 ? .yellow : place == 2 ? Color(white: 0.7) : .orange)
                                    Text(placeLabel(place))
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.jfCardBg)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("出場履歴")
        .task {
            entries = (try? await api.getMyEntries()) ?? []
            isLoading = false
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        let (label, fg, bg): (String, Color, Color) = {
            switch status {
            case "registered": return ("確定", .green, Color.green.opacity(0.15))
            case "waitlisted": return ("補欠", .orange, Color.orange.opacity(0.15))
            case "cancelled": return ("キャンセル", Color(white: 0.5), Color(white: 0.5).opacity(0.15))
            default: return ("審査中", Color(red: 0.83, green: 0.66, blue: 0.33), Color(red: 0.83, green: 0.66, blue: 0.33).opacity(0.15))
            }
        }()
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(4)
    }

    private func statusDesc(_ status: String) -> String {
        switch status {
        case "pending": return "審査中 — 主催者確認後に確定します"
        case "registered": return "出場確定 — エントリーが承認されました"
        case "waitlisted": return "補欠 — 定員が空き次第繰り上がります"
        case "cancelled": return "キャンセル済み"
        default: return ""
        }
    }

    private func placeLabel(_ place: Int) -> String {
        switch place {
        case 1: return "優勝"
        case 2: return "準優勝"
        case 3: return "3位"
        case 4: return "4位"
        default: return "\(place)位"
        }
    }

    private func beltJa(_ belt: String) -> String {
        switch belt.lowercased() {
        case "white": return "白帯"
        case "blue": return "青帯"
        case "purple": return "紫帯"
        case "brown": return "茶帯"
        case "black": return "黒帯"
        default: return belt.capitalized
        }
    }

    private func weightClassJa(_ wc: String) -> String {
        switch wc.lowercased() {
        case "rooster": return "ルースター"
        case "light-feather": return "ライトフェザー"
        case "feather": return "フェザー"
        case "light": return "ライト"
        case "middle": return "ミドル"
        case "medium-heavy": return "ミディアムヘビー"
        case "heavy": return "ヘビー"
        case "super-heavy": return "スーパーヘビー"
        case "ultra-heavy": return "ウルトラヘビー"
        default: return wc
        }
    }
}
