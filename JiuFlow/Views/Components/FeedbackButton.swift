import SwiftUI

/// Compact toolbar entry point for the feedback sheet. Lives in the navigation bar so it never
/// covers content (the old floating bubble hid card chevrons at the bottom-right of every tab).
struct FeedbackButton: View {
    let page: String

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "bubble.left.and.text.bubble")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.jfTextSecondary)
        }
        .accessibilityLabel(tr("フィードバックを送る"))
        .accessibilityIdentifier("feedbackButton")
        .sheet(isPresented: $showSheet) {
            FeedbackSheet(page: page)
        }
    }
}

// MARK: - Feedback Sheet

private struct FeedbackSheet: View {
    let page: String
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 0
    @State private var message: String = ""
    @State private var isSending = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Page label
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(Color.jfTextTertiary)
                        Text(tr("ページ") + ": " + page)
                            .font(.subheadline)
                            .foregroundStyle(Color.jfTextSecondary)
                        Spacer()
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 12)

                    // Star rating
                    VStack(spacing: 10) {
                        Text(tr("評価"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        rating = star
                                    }
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(star <= rating ? .yellow : Color.jfTextTertiary)
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                }
                                .sensoryFeedback(.selection, trigger: rating)
                            }
                        }
                    }

                    // Free text
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tr("フィードバック"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.jfTextPrimary)

                        TextEditor(text: $message)
                            .frame(minHeight: 80)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.jfCardBg)
                            .foregroundStyle(Color.jfTextPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.jfBorder, lineWidth: 1)
                            )
                    }

                    // Send button
                    Button {
                        Task { await sendFeedback() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSending {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isSending ? tr("送信中...") : tr("送信"))
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            rating > 0 && !isSending
                                ? LinearGradient.jfRedGradient
                                : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(rating == 0 || isSending)

                    // Success animation
                    if showSuccess {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.green)
                            }
                            Text(tr("ありがとうございます!"))
                                .font(.headline)
                                .foregroundStyle(Color.jfTextPrimary)
                            Text(tr("フィードバックを受け付けました"))
                                .font(.caption)
                                .foregroundStyle(Color.jfTextTertiary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(20)
            }
            .background(Color.jfDarkBg)
            .navigationTitle(tr("フィードバック"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("閉じる")) { dismiss() }
                        .foregroundStyle(Color.jfTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sendFeedback() async {
        isSending = true
        defer { isSending = false }

        let deviceInfo = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion), \(UIDevice.current.model)"
        let body: [String: Any] = [
            "page": page,
            "rating": rating,
            "message": message,
            "device_info": deviceInfo
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/feedback") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                withAnimation(.spring(response: 0.4)) {
                    showSuccess = true
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        } catch {
            // Silently fail — feedback is non-critical
        }
    }
}
