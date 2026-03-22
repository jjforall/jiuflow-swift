import SwiftUI

struct DojosTab: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""
    @State private var showMapView = false

    private var filteredDojos: [Dojo] {
        if searchText.isEmpty { return api.dojos }
        return api.dojos.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.displayLocation.localizedCaseInsensitiveContains(searchText) ||
            ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var verifiedDojos: [Dojo] {
        api.dojos.filter { $0.is_verified == true }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.isLoading && api.dojos.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCard(height: 90)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else if filteredDojos.isEmpty {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "道場が見つかりません",
                        message: searchText.isEmpty ? "引っ張って再読み込みしてください" : "検索条件を変更してください"
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Stats header
                            HStack(spacing: 16) {
                                DojoStatCard(
                                    icon: "building.2.fill",
                                    value: "\(api.dojos.count)",
                                    label: "道場"
                                )
                                DojoStatCard(
                                    icon: "checkmark.seal.fill",
                                    value: "\(verifiedDojos.count)",
                                    label: "認証済み"
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Dojo list
                            LazyVStack(spacing: 10) {
                                ForEach(filteredDojos) { dojo in
                                    NavigationLink {
                                        DojoDetailView(dojo: dojo)
                                    } label: {
                                        DojoCard(dojo: dojo)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("道場")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "道場名・地域で検索")
            .background(Color.jfDarkBg)
            .scrollContentBackground(.hidden)
            .task {
                if api.dojos.isEmpty {
                    await api.loadDojos()
                }
            }
            .refreshable {
                await api.loadDojos()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FeedbackButton(page: "道場")
        }
    }
}

// MARK: - Dojo Stat Card

struct DojoStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(Color.jfTextPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard()
    }
}

// MARK: - Dojo Card

struct DojoCard: View {
    let dojo: Dojo

    var body: some View {
        HStack(spacing: 14) {
            // Logo / icon
            ZStack {
                if let logoUrl = dojo.logo_url, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        dojoPlaceholder
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    dojoPlaceholder
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(dojo.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                        .lineLimit(1)

                    if dojo.is_verified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                if !dojo.displayLocation.isEmpty {
                    Label(dojo.displayLocation, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }

                if !dojo.displayDescription.isEmpty {
                    Text(dojo.displayDescription)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    private var dojoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.1))
            Image(systemName: "figure.martial.arts")
                .font(.title3)
                .foregroundStyle(.green.opacity(0.6))
        }
        .frame(width: 56, height: 56)
    }
}

// MARK: - Dojo Detail View

struct DojoDetailView: View {
    let dojo: Dojo

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.green.opacity(0.2), Color.green.opacity(0.05)],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 50
                                )
                            )
                        Image(systemName: "figure.martial.arts")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                    }
                    .frame(width: 100, height: 100)

                    HStack(spacing: 8) {
                        Text(dojo.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        if dojo.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                        }
                    }

                    if let name = dojo.name, dojo.name_ja != nil {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                // Location
                if !dojo.displayLocation.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("所在地", systemImage: "mappin.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)

                        Text(dojo.displayLocation)
                            .font(.body)
                            .foregroundStyle(Color.jfTextSecondary)

                        Button {
                            openInMaps(address: dojo.displayLocation)
                        } label: {
                            Label("マップで開く", systemImage: "map.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: false)
                    }
                    .padding(16)
                    .glassCard()
                }

                // Description
                if !dojo.displayDescription.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("概要", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Color.jfTextPrimary)

                        Text(dojo.displayDescription)
                            .font(.body)
                            .foregroundStyle(Color.jfTextSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                }

                // Review
                ReviewView(targetType: "dojo", targetId: dojo.id)

                // Book a class (only for verified booking dojos)
                if isBookableDojo(dojo.id) {
                    NavigationLink {
                        DojoBookingView(dojo: dojo)
                    } label: {
                        Label("クラスを予約する", systemImage: "calendar.badge.plus")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Only these 3 dojos have booking enabled
    private func isBookableDojo(_ id: String) -> Bool {
        ["dojo-yawara-harajuku", "dojo-overlimit-sapporo", "dojo-sweep-kitasando"].contains(id)
    }

    private func openInMaps(address: String) {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}
