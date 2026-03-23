import SwiftUI

struct MyEntriesView: View {
    @EnvironmentObject var apiService: APIService
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
                    Text("No tournament entries yet")
                        .foregroundColor(.gray)
                    Text("Enter a tournament from the Tournaments page")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.entry_number)
                                .font(.caption.bold().monospaced())
                                .foregroundColor(.jfRed)
                            Spacer()
                            Text(entry.status.uppercased())
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(entry.status == "registered" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(entry.status == "registered" ? .green : .orange)
                                .cornerRadius(4)
                        }
                        Text("\(entry.belt.capitalized) / \(entry.weight_class) / \(entry.gi_nogi.uppercased())")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("\u{00a5}\(entry.amount_jpy)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if let place = entry.place {
                            HStack {
                                Image(systemName: "medal.fill")
                                    .foregroundColor(place == 1 ? .yellow : place == 2 ? .gray : .orange)
                                Text("Place: \(place)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.jfCardBg)
                }
                .listStyle(.plain)
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("出場履歴")
        .task {
            entries = (try? await apiService.getMyEntries()) ?? []
            isLoading = false
        }
    }
}
