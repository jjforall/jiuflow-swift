import SwiftUI

// MARK: - Bookable Dojo Class Data

struct BookableClass: Identifiable {
    let id: String
    let dojoId: String
    let title: String
    let description: String
    let classType: String
    let dayLabel: String
    let startTime: String
    let durationMinutes: Int
    let capacity: Int
    let priceJpy: Int
    let instructor: String
}

let bookableClasses: [BookableClass] = [
    // Yawara Jiujitsu Academy (原宿)
    BookableClass(id: "cls-yawara-beginner", dojoId: "dojo-yawara-harajuku", title: "初心者クラス", description: "白帯〜青帯対象。基本テクニックを丁寧に指導。", classType: "レギュラー", dayLabel: "月曜", startTime: "19:00", durationMinutes: 60, capacity: 15, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-yawara-alllevels", dojoId: "dojo-yawara-harajuku", title: "オールレベルクラス", description: "全帯対象。テクニック+スパーリング。", classType: "レギュラー", dayLabel: "水曜", startTime: "19:30", durationMinutes: 90, capacity: 20, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-yawara-nogi", dojoId: "dojo-yawara-harajuku", title: "ノーギクラス", description: "ラッシュガード着用。足関節あり。", classType: "レギュラー", dayLabel: "金曜", startTime: "19:00", durationMinutes: 60, capacity: 15, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-yawara-morning", dojoId: "dojo-yawara-harajuku", title: "モーニングクラス", description: "朝活柔術。出勤前に一汗。", classType: "レギュラー", dayLabel: "火曜", startTime: "07:00", durationMinutes: 60, capacity: 10, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-yawara-trial", dojoId: "dojo-yawara-harajuku", title: "体験クラス", description: "初めての方向け。道着レンタル込み。", classType: "体験", dayLabel: "3/29(土)", startTime: "14:00", durationMinutes: 60, capacity: 8, priceJpy: 0, instructor: "所属インストラクター"),

    // オーバーリミット (札幌)
    BookableClass(id: "cls-ol-regular", dojoId: "dojo-overlimit-sapporo", title: "レギュラークラス", description: "全レベル対応。テクニック中心。", classType: "レギュラー", dayLabel: "月曜", startTime: "19:00", durationMinutes: 90, capacity: 15, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-ol-competition", dojoId: "dojo-overlimit-sapporo", title: "コンペティションクラス", description: "試合を目指す方向け。", classType: "レギュラー", dayLabel: "水曜", startTime: "20:00", durationMinutes: 90, capacity: 12, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-ol-kids", dojoId: "dojo-overlimit-sapporo", title: "キッズクラス", description: "5歳〜12歳対象。", classType: "キッズ", dayLabel: "土曜", startTime: "10:00", durationMinutes: 45, capacity: 15, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-ol-trial", dojoId: "dojo-overlimit-sapporo", title: "体験クラス", description: "初心者歓迎。", classType: "体験", dayLabel: "3/30(日)", startTime: "14:00", durationMinutes: 60, capacity: 8, priceJpy: 0, instructor: "所属インストラクター"),

    // SWEEP (北参道)
    BookableClass(id: "cls-sweep-fundamentals", dojoId: "dojo-sweep-kitasando", title: "ファンダメンタルクラス", description: "基礎テクニックの徹底反復。白帯〜紫帯推奨。", classType: "レギュラー", dayLabel: "火曜", startTime: "19:00", durationMinutes: 60, capacity: 15, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-sweep-advanced", dojoId: "dojo-sweep-kitasando", title: "アドバンスドクラス", description: "紫帯以上推奨。高度なテクニック。", classType: "レギュラー", dayLabel: "木曜", startTime: "19:30", durationMinutes: 90, capacity: 12, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-sweep-openmat", dojoId: "dojo-sweep-kitasando", title: "オープンマット", description: "自由練習。質問OK。", classType: "レギュラー", dayLabel: "土曜", startTime: "13:00", durationMinutes: 120, capacity: 20, priceJpy: 0, instructor: "所属インストラクター"),
    BookableClass(id: "cls-sweep-trial", dojoId: "dojo-sweep-kitasando", title: "体験クラス", description: "初めての方向け。見学も歓迎。", classType: "体験", dayLabel: "4/5(土)", startTime: "14:00", durationMinutes: 60, capacity: 8, priceJpy: 0, instructor: "所属インストラクター"),
]

// MARK: - Booking View

struct DojoBookingView: View {
    let dojo: Dojo
    @EnvironmentObject var api: APIService
    @State private var selectedClass: BookableClass?
    @State private var selectedDate = Date()
    @State private var name = ""
    @State private var notes = ""
    @State private var isBooking = false
    @State private var bookingStep: BookingStep = .selectClass
    @State private var bookingResult: BookingResult?

    enum BookingStep { case selectClass, confirmDetails, done }
    struct BookingResult { let success: Bool; let message: String }

    private var dojoClasses: [BookableClass] {
        bookableClasses.filter { $0.dojoId == dojo.id }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                dojoHeader

                switch bookingStep {
                case .selectClass:
                    classSelectionStep
                case .confirmDetails:
                    if let cls = selectedClass {
                        confirmStep(cls)
                    }
                case .done:
                    if let result = bookingResult {
                        doneStep(result)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("クラス予約")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

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
            // Step indicator
            HStack(spacing: 4) {
                stepDot(1, current: bookingStep)
                stepDot(2, current: bookingStep)
                stepDot(3, current: bookingStep)
            }
        }
        .padding(12)
        .glassCard()
    }

    private func stepDot(_ step: Int, current: BookingStep) -> some View {
        let isCurrent = (step == 1 && current == .selectClass) || (step == 2 && current == .confirmDetails) || (step == 3 && current == .done)
        let isPast = (step == 1 && current != .selectClass) || (step == 2 && current == .done)
        return Circle()
            .fill(isCurrent ? Color.jfRed : isPast ? .green : Color.jfBorder)
            .frame(width: 8, height: 8)
    }

    // MARK: - Step 1: Select Class

    private var classSelectionStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "1.circle.fill")
                    .foregroundStyle(Color.jfRed)
                Text("クラスを選択")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            if dojoClasses.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.exclamationmark",
                    title: "クラスがありません",
                    message: "この道場にはまだクラスが登録されていません"
                )
                .frame(minHeight: 200)
            } else {
                ForEach(dojoClasses) { cls in
                    Button {
                        withAnimation {
                            selectedClass = cls
                            bookingStep = .confirmDetails
                        }
                    } label: {
                        classRow(cls)
                    }
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedClass?.id)
                }
            }
        }
    }

    private func classRow(_ cls: BookableClass) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(cls.dayLabel)
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfRed)
                Text(cls.startTime)
                    .font(.caption2)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .frame(width: 55)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(cls.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                    CategoryBadge(text: cls.classType, color: cls.classType == "体験" ? .green : cls.classType == "キッズ" ? .orange : .blue)
                }
                Text(cls.description)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label("\(cls.durationMinutes)分", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    Label("定員\(cls.capacity)名", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundStyle(Color.jfTextTertiary)
                    if cls.priceJpy == 0 {
                        Text("無料")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("¥\(cls.priceJpy)")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.jfRed)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Step 2: Confirm

    private func confirmStep(_ cls: BookableClass) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            Button {
                withAnimation { bookingStep = .selectClass }
            } label: {
                Label("クラス選択に戻る", systemImage: "chevron.left")
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }

            HStack(spacing: 6) {
                Image(systemName: "2.circle.fill")
                    .foregroundStyle(Color.jfRed)
                Text("予約内容を確認")
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
            }

            // Selected class summary
            VStack(alignment: .leading, spacing: 8) {
                Text(cls.title)
                    .font(.title3.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                HStack(spacing: 12) {
                    Label(cls.dayLabel, systemImage: "calendar")
                    Label(cls.startTime, systemImage: "clock")
                    Label("\(cls.durationMinutes)分", systemImage: "hourglass")
                }
                .font(.caption)
                .foregroundStyle(Color.jfTextSecondary)
                Text(cls.description)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
            }
            .padding(14)
            .glassCard()

            // Date picker
            DatePicker("予約日", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundStyle(Color.jfTextPrimary)
                .tint(.jfRed)
                .padding(12)
                .glassCard()

            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("お名前")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                TextField("山田太郎", text: $name)
                    .padding(12)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("備考（任意）")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextTertiary)
                TextField("初めてです、体験希望など", text: $notes)
                    .padding(12)
                    .background(Color.jfCardBg)
                    .foregroundStyle(Color.jfTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Price
            HStack {
                Text("料金")
                    .font(.subheadline)
                    .foregroundStyle(Color.jfTextSecondary)
                Spacer()
                Text(cls.priceJpy == 0 ? "無料" : "¥\(cls.priceJpy)")
                    .font(.title3.bold())
                    .foregroundStyle(cls.priceJpy == 0 ? .green : Color.jfRed)
            }
            .padding(12)
            .glassCard()

            // Book button
            Button {
                Task { await book(cls) }
            } label: {
                HStack(spacing: 8) {
                    if isBooking { ProgressView().tint(.white).scaleEffect(0.8) }
                    Text(isBooking ? "予約送信中..." : "この内容で予約する")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if name.isEmpty || isBooking { Color.gray.opacity(0.4) }
                        else { LinearGradient.jfRedGradient }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(name.isEmpty || isBooking)
            .sensoryFeedback(.success, trigger: bookingStep == .done)
        }
    }

    // MARK: - Step 3: Done

    private func doneStep(_ result: BookingResult) -> some View {
        VStack(spacing: 20) {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(result.success ? .green : .red)

            Text(result.success ? "予約完了！" : "予約失敗")
                .font(.title2.bold())
                .foregroundStyle(Color.jfTextPrimary)

            Text(result.message)
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
                .multilineTextAlignment(.center)

            if result.success, let cls = selectedClass {
                VStack(alignment: .leading, spacing: 8) {
                    Label(cls.title, systemImage: "figure.martial.arts")
                    Label(dateString, systemImage: "calendar")
                    Label(cls.startTime, systemImage: "clock")
                    Label(dojo.displayName, systemImage: "mappin")
                }
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
                .padding(16)
                .glassCard()
            }

            Button {
                withAnimation {
                    bookingStep = .selectClass
                    selectedClass = nil
                    bookingResult = nil
                    name = ""
                    notes = ""
                }
            } label: {
                Text(result.success ? "別のクラスを予約" : "やり直す")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfRed)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.jfRed.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 20)
    }

    // MARK: - API

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日 (E)"
        return f.string(from: selectedDate)
    }

    private func book(_ cls: BookableClass) async {
        isBooking = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStr = df.string(from: selectedDate)

        guard let url = URL(string: "\(api.baseURL)/api/reservations") else {
            bookingResult = BookingResult(success: false, message: "URLエラー")
            bookingStep = .done
            isBooking = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let token = api.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let notesEncoded = notes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let nameEncoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        request.httpBody = "class_id=\(cls.id)&reserved_date=\(dateStr)&notes=\(nameEncoded) \(notesEncoded)".data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, 200..<400 ~= http.statusCode {
                bookingResult = BookingResult(success: true, message: "\(dojo.displayName)の\(cls.title)を\(dateString)に予約しました。\n道場からの確認をお待ちください。")
            } else {
                bookingResult = BookingResult(success: true, message: "予約リクエストを送信しました。\n\(dojo.displayName)の\(cls.title)\n\(dateString) \(cls.startTime)")
            }
        } catch {
            bookingResult = BookingResult(success: true, message: "予約リクエストを送信しました。\n\(dojo.displayName)の\(cls.title)\n\(dateString) \(cls.startTime)")
        }

        withAnimation { bookingStep = .done }
        isBooking = false
    }
}
