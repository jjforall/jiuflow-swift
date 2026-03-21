import SwiftUI

// MARK: - Dojo Class Model

struct DojoClass: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let class_type_label: String?
    let day_label: String?
    let start_time: String?
    let duration_minutes: Int?
    let capacity: Int?
    let booked_count: Int?
    let available: Int?
    let price_jpy: Int?
    let is_free: Bool?
    let dojo_id: String?
    let dojo_name: String?
}

// MARK: - Booking View

struct DojoBookingView: View {
    let dojo: Dojo
    @EnvironmentObject var api: APIService
    @State private var classes: [DojoClass] = []
    @State private var isLoading = true
    @State private var selectedClass: DojoClass?
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var isBooking = false
    @State private var bookingResult: (success: Bool, message: String)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Dojo header
                dojoHeader

                if isLoading {
                    VStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { _ in SkeletonCard(height: 100) }
                    }
                } else if classes.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "クラスがありません",
                        message: "この道場にはまだクラスが登録されていません"
                    )
                    .frame(minHeight: 200)
                } else {
                    // Class list
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "クラス一覧", icon: "calendar")
                            .padding(.horizontal, 4)

                        ForEach(classes) { cls in
                            classCard(cls)
                        }
                    }
                }

                // Booking form (when class selected)
                if let cls = selectedClass {
                    bookingForm(cls)
                }

                // Result
                if let result = bookingResult {
                    resultBanner(result)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("クラス予約")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadClasses() }
    }

    // MARK: - Dojo Header

    private var dojoHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "figure.martial.arts")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(dojo.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                if !dojo.displayLocation.isEmpty {
                    Label(dojo.displayLocation, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }
            Spacer()
        }
        .padding(12)
        .glassCard()
    }

    // MARK: - Class Card

    private func classCard(_ cls: DojoClass) -> some View {
        Button {
            withAnimation { selectedClass = cls }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(cls.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    if cls.is_free == true {
                        CategoryBadge(text: "無料", color: .green)
                    } else if let price = cls.price_jpy, price > 0 {
                        Text("¥\(price)")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfRed)
                    }
                }

                HStack(spacing: 12) {
                    if let day = cls.day_label {
                        Label(day, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    if let time = cls.start_time {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                    if let dur = cls.duration_minutes {
                        Text("\(dur)分")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }

                if let avail = cls.available, let cap = cls.capacity {
                    HStack(spacing: 6) {
                        Text("空き \(avail)/\(cap)")
                            .font(.caption.bold())
                            .foregroundStyle(avail > 0 ? .green : .red)
                        if avail == 0 {
                            Text("満員")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }

                if let type = cls.class_type_label {
                    CategoryBadge(text: type, color: .blue)
                }
            }
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedClass?.id == cls.id ? Color.jfRed : Color.clear, lineWidth: 2)
            )
            .glassCard(cornerRadius: 14)
        }
    }

    // MARK: - Booking Form

    private func bookingForm(_ cls: DojoClass) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "予約フォーム", icon: "pencil.and.list.clipboard")

            Text(cls.title)
                .font(.headline)
                .foregroundStyle(Color.jfTextPrimary)

            DatePicker("予約日", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundStyle(Color.jfTextPrimary)
                .tint(.jfRed)

            VStack(alignment: .leading, spacing: 6) {
                Text("備考（任意）")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                TextField("初めてです、体験希望など", text: $notes)
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                Task { await book(cls) }
            } label: {
                HStack {
                    if isBooking { ProgressView().tint(.white) }
                    Text(isBooking ? "予約中..." : "予約する")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isBooking ? Color.gray : Color.jfRed)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isBooking)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Result

    private func resultBanner(_ result: (success: Bool, message: String)) -> some View {
        HStack(spacing: 10) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(result.success ? .green : .red)
            Text(result.message)
                .font(.subheadline)
                .foregroundStyle(result.success ? .green : .red)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((result.success ? Color.green : Color.red).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - API

    private func loadClasses() async {
        isLoading = true
        guard let url = URL(string: "\(api.baseURL)/dojo/\(dojo.id)/book") else {
            isLoading = false
            return
        }
        // Try to fetch class data from API
        // The web returns HTML, so we parse from dojo detail or use a workaround
        // For now, show the dojo info and let user book
        isLoading = false
    }

    private func book(_ cls: DojoClass) async {
        isBooking = true
        let dateStr = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: selectedDate)
        }()

        guard let url = URL(string: "\(api.baseURL)/api/reservations") else {
            bookingResult = (false, "URLエラー")
            isBooking = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = "class_id=\(cls.id)&reserved_date=\(dateStr)&notes=\(notes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                bookingResult = (true, "予約が完了しました！")
                selectedClass = nil
            } else {
                bookingResult = (false, "予約に失敗しました。ログインが必要かもしれません。")
            }
        } catch {
            bookingResult = (false, "通信エラー: \(error.localizedDescription)")
        }
        isBooking = false
    }
}
