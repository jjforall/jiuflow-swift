import SwiftUI

struct AIAnalysisView: View {
    @EnvironmentObject var api: APIService
    @EnvironmentObject var premium: PremiumManager
    @State private var analysis: AIAnalysis?
    @State private var isAnalyzing = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let analysis = analysis {
                    resultView(analysis)
                } else {
                    promptView
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationTitle("AI Roll Analysis")
    }

    var promptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.purple)

            Text("AI Roll Analysis")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Upload or record your sparring, and AI will analyze your positions, transitions, and suggest improvements.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            if let error = error {
                Text(error).font(.caption).foregroundColor(.jfRed)
            }

            Button(action: analyze) {
                HStack {
                    if isAnalyzing {
                        ProgressView().tint(.white)
                        Text("Analyzing...")
                    } else {
                        Image(systemName: "wand.and.stars")
                        Text("Analyze My Roll")
                    }
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: [.purple, .jfRed], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
            }
            .disabled(isAnalyzing)

            if !premium.isPremium {
                Text("Free: 1 analysis/month | PRO: Unlimited")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 40)
    }

    func resultView(_ a: AIAnalysis) -> some View {
        VStack(spacing: 16) {
            // Score
            VStack(spacing: 4) {
                Text("\(a.score)")
                    .font(.system(size: 56, weight: .black))
                    .foregroundColor(a.score >= 80 ? .jfGold : a.score >= 60 ? .white : .jfRed)
                Text("/ 100")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.jfCardBg)
            .cornerRadius(16)

            // Positions
            if let positions = a.positions {
                VStack(alignment: .leading, spacing: 8) {
                    Text("POSITIONS").font(.caption.bold()).foregroundColor(.gray).tracking(1)
                    ForEach(positions, id: \.name) { pos in
                        HStack {
                            Text(pos.name).font(.caption).foregroundColor(.white)
                            Spacer()
                            Text("\(pos.time_pct)%").font(.caption.bold()).foregroundColor(.jfRed)
                        }
                        ProgressView(value: Double(pos.time_pct), total: 100)
                            .tint(.jfRed)
                    }
                }
                .padding()
                .background(Color.jfCardBg)
                .cornerRadius(12)
            }

            // Strengths & Weaknesses
            HStack(spacing: 12) {
                if let strengths = a.strengths {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STRENGTHS").font(.system(size: 9, weight: .bold)).foregroundColor(.green).tracking(1)
                        ForEach(strengths, id: \.self) { s in
                            Label(s, systemImage: "checkmark.circle.fill").font(.caption).foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.jfCardBg)
                    .cornerRadius(12)
                }
                if let weaknesses = a.weaknesses {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("IMPROVE").font(.system(size: 9, weight: .bold)).foregroundColor(.jfRed).tracking(1)
                        ForEach(weaknesses, id: \.self) { w in
                            Label(w, systemImage: "exclamationmark.circle.fill").font(.caption).foregroundColor(.white)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.jfCardBg)
                    .cornerRadius(12)
                }
            }

            // Recommendations
            if let recs = a.recommendations {
                VStack(alignment: .leading, spacing: 8) {
                    Text("おすすめテクニック").font(.caption.bold()).foregroundColor(.jfGold).tracking(1)
                    ForEach(recs) { rec in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rec.name).font(.subheadline.bold()).foregroundColor(.white)
                            Text(rec.reason).font(.caption).foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.jfCardBg.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
            }

            Button("Analyze Again") { analysis = nil }
                .font(.caption.bold())
                .foregroundColor(.jfRed)
        }
    }

    func analyze() {
        isAnalyzing = true
        error = nil
        Task {
            do {
                analysis = try await api.requestAIAnalysis(videoUrl: nil)
            } catch {
                self.error = "Analysis failed. Try again."
            }
            isAnalyzing = false
        }
    }
}
