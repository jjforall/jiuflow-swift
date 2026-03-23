import SwiftUI

struct FeedView: View {
    @EnvironmentObject var api: APIService
    @State private var events: [FeedEvent] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No activity yet")
                        .foregroundColor(.gray)
                    Text("Complete drills and log training to see the feed")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(events) { event in
                            eventCard(event)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("Community Feed")
        .task {
            events = (try? await api.getFeed()) ?? []
            isLoading = false
        }
        .refreshable {
            events = (try? await api.getFeed()) ?? []
        }
    }

    func eventCard(_ e: FeedEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: e.eventIcon)
                    .font(.caption)
                    .foregroundColor(e.eventColor)
                    .frame(width: 28, height: 28)
                    .background(e.eventColor.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(e.display_name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(e.created_at.prefix(10))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
            }

            Text(e.title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))

            if let detail = e.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Kudos button
            HStack {
                Button(action: { kudos(e) }) {
                    HStack(spacing: 4) {
                        Image(systemName: e.has_kudoed ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                        Text("\(e.kudos_count)")
                            .font(.caption.bold())
                    }
                    .foregroundColor(e.has_kudoed ? .jfRed : .gray)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.jfCardBg)
        .cornerRadius(12)
    }

    func kudos(_ event: FeedEvent) {
        Task {
            let _ = try? await api.toggleKudos(eventId: event.id)
            events = (try? await api.getFeed()) ?? events
        }
    }
}
