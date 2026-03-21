import SwiftUI

struct InstructorsView: View {
    @EnvironmentObject var api: APIService
    @State private var searchText = ""

    private var filteredCourses: [InstructorCourse] {
        if searchText.isEmpty { return api.instructorCourses }
        return api.instructorCourses.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.instructor_name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if api.instructorCourses.isEmpty && !api.isLoading {
                    EmptyStateView(
                        icon: "person.badge.shield.checkmark",
                        title: "コースがありません",
                        message: "インストラクターのコースが公開されると\nここに表示されます"
                    )
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCourses) { course in
                                InstructorCourseCard(course: course)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.jfDarkBg)
            .navigationTitle("インストラクター")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "コース・講師を検索")
            .task {
                await api.loadInstructorCourses()
            }
            .refreshable {
                await api.loadInstructorCourses()
            }
        }
    }
}

struct InstructorCourseCard: View {
    let course: InstructorCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            if let thumb = course.thumbnail_url, let url = URL(string: thumb) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ShimmerView()
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(course.displayTitle)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Instructor info
                HStack(spacing: 8) {
                    if let name = course.instructor_name {
                        Label(name, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                    if let belt = course.instructor_belt {
                        CategoryBadge(text: belt, color: course.beltColor)
                    }
                }

                if let dojo = course.instructor_dojo {
                    Label(dojo, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }

                // Price and video count
                HStack {
                    Text(course.priceLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(course.price_jpy == 0 || course.price_jpy == nil ? .green : Color.jfRed)

                    Spacer()

                    if let count = course.video_count {
                        Label("\(count)本", systemImage: "play.rectangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if let desc = course.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                        .lineLimit(2)
                }

                // Web link
                Link(destination: URL(string: "https://jiuflow-ssr.fly.dev/courses/\(course.id)")!) {
                    Label("コースを見る", systemImage: "arrow.up.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfRed)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .glassCard()
    }
}
