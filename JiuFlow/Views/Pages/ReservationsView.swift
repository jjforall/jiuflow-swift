import SwiftUI

struct ReservationsView: View {
    @EnvironmentObject var api: APIService

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("クラス予約")
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        Text("道場のクラスを予約して\n練習を計画しましょう")
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)

                    // Dojos with booking
                    if !api.dojos.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "予約可能な道場", icon: "building.2.fill")
                                .padding(.horizontal, 16)

                            LazyVStack(spacing: 10) {
                                ForEach(api.dojos.prefix(10)) { dojo in
                                    ReservationDojoRow(dojo: dojo)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Web link
                    Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/dojos")!) {
                        Label("すべての道場を見る", systemImage: "safari")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
            .background(Color.jfDarkBg)
            .navigationTitle("予約")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if api.dojos.isEmpty {
                    await api.loadDojos()
                }
            }
        }
    }
}

struct ReservationDojoRow: View {
    let dojo: Dojo

    var body: some View {
        Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/dojo/\(dojo.id)/book")!) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.martial.arts")
                        .font(.body)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(dojo.displayName)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)
                            .lineLimit(1)

                        if dojo.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }

                    if !dojo.displayLocation.isEmpty {
                        Text(dojo.displayLocation)
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text("予約")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(12)
            .glassCard(cornerRadius: 14)
        }
    }
}
