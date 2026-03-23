import SwiftUI

struct LiveClassesView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var premium: PremiumManager
    @State private var classes: [LiveClass] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if classes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "video")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No classes scheduled")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(classes) { cls in
                            classCard(cls)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("Live Classes")
        .task {
            classes = (try? await api.getLiveClasses()) ?? []
            isLoading = false
        }
    }

    func classCard(_ c: LiveClass) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if c.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("LIVE").font(.caption2.bold()).foregroundColor(.red)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.red.opacity(0.15)).cornerRadius(6)
                } else {
                    Text(c.status.uppercased())
                        .font(.caption2.bold()).foregroundColor(.gray)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15)).cornerRadius(6)
                }
                if c.isProOnly {
                    ProBadge(size: .tiny)
                }
                Spacer()
                if let count = c.attendee_count {
                    Label("\(count)", systemImage: "person.2").font(.caption2).foregroundColor(.gray)
                }
            }

            Text(c.title).font(.headline.bold()).foregroundColor(.white)

            HStack(spacing: 12) {
                Label(c.instructor_name, systemImage: "person.fill").font(.caption).foregroundColor(.gray)
                Label("\(c.duration_minutes)min", systemImage: "clock").font(.caption).foregroundColor(.gray)
            }

            Text(c.scheduled_at.prefix(16)).font(.caption2).foregroundColor(.gray)
        }
        .padding()
        .background(Color.jfCardBg)
        .cornerRadius(16)
    }
}
