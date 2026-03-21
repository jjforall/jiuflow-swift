import SwiftUI

/// Star rating + comment component for videos, dojos, athletes
struct ReviewView: View {
    let targetType: String // "video", "dojo", "athlete"
    let targetId: String
    @EnvironmentObject var api: APIService
    @State private var rating: Int = 0
    @State private var comment = ""
    @State private var isSending = false
    @State private var result: (success: Bool, message: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stars
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("評価する")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        rating = i
                    } label: {
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(i <= rating ? .yellow : Color.jfTextTertiary.opacity(0.3))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Comment
            TextField("コメント（任意）", text: $comment)
                .textInputAutocapitalization(.never)
                .padding(10)
                .background(Color.jfCardBg)
                .foregroundStyle(Color.jfTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Send
            Button {
                Task { await send() }
            } label: {
                HStack(spacing: 6) {
                    if isSending { ProgressView().tint(.white).scaleEffect(0.7) }
                    Text(isSending ? "送信中..." : "送信")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(rating == 0 ? Color.gray.opacity(0.4) : Color.jfRed)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(rating == 0 || isSending)

            if let r = result {
                HStack(spacing: 4) {
                    Image(systemName: r.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                    Text(r.message)
                        .font(.caption)
                }
                .foregroundStyle(r.success ? .green : .red)
            }
        }
        .padding(12)
        .glassCard()
    }

    private func send() async {
        isSending = true
        // Send review
        if rating > 0 {
            let reviewURL = URL(string: "\(api.baseURL)/api/reviews")!
            var req = URLRequest(url: reviewURL)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let t = api.authToken { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
            req.httpBody = "target_type=\(targetType)&target_id=\(targetId)&rating=\(rating)".data(using: .utf8)
            let _ = try? await URLSession.shared.data(for: req)
        }
        // Send comment
        if !comment.isEmpty {
            let commentURL = URL(string: "\(api.baseURL)/api/comments")!
            var req = URLRequest(url: commentURL)
            req.httpMethod = "POST"
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let t = api.authToken { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
            let encoded = comment.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            req.httpBody = "target_type=\(targetType)&target_id=\(targetId)&body=\(encoded)".data(using: .utf8)
            let _ = try? await URLSession.shared.data(for: req)
        }
        result = (true, "送信しました！")
        isSending = false
    }
}
