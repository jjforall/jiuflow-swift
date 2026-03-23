import SwiftUI

struct DailyDrillView: View {
    @EnvironmentObject var api: APIService
    @State private var drill: DailyDrill?
    @State private var streak: UserStreak?
    @State private var isLoading = true
    @State private var isCompleting = false
    @State private var showComplete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Streak card
                if let streak = streak {
                    streakCard(streak)
                }

                // Today's drill
                if isLoading {
                    ProgressView().frame(height: 200)
                } else if let drill = drill {
                    drillCard(drill)
                } else {
                    Text("No drill available").foregroundColor(.gray)
                }
            }
            .padding()
        }
        .background(Color.jfDarkBg)
        .navigationTitle("Daily Drill")
        .task {
            drill = try? await api.getDailyDrill()
            streak = try? await api.getStreak()
            isLoading = false
        }
        .alert("Drill Complete!", isPresented: $showComplete) {
            Button("OK") {}
        } message: {
            if let s = streak {
                Text("Streak: \(s.current_streak) days! Total: \(s.total_completed) drills completed.")
            }
        }
    }

    func streakCard(_ s: UserStreak) -> some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(s.current_streak)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.orange)
                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Divider().frame(height: 40)
            VStack(spacing: 4) {
                Text("\(s.longest_streak)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("best")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            VStack(spacing: 4) {
                Text("\(s.total_completed)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("total")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.jfCardBg)
        .cornerRadius(16)
    }

    func drillCard(_ d: DailyDrill) -> some View {
        VStack(spacing: 16) {
            Text("TODAY'S TECHNIQUE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .foregroundColor(.jfGold)

            Text(d.displayName)
                .font(.title2.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            if let cat = d.category {
                Text(cat.uppercased())
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundColor(.gray)
            }

            if d.video_url != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.jfRed)
            }

            Button(action: completeDrill) {
                HStack {
                    if isCompleting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Complete")
                    }
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.jfRed)
                .cornerRadius(12)
            }
            .disabled(isCompleting)
        }
        .padding(24)
        .background(Color.jfCardBg)
        .cornerRadius(20)
    }

    func completeDrill() {
        guard let d = drill else { return }
        isCompleting = true
        Task {
            streak = try? await api.completeDrill(drillId: d.id)
            isCompleting = false
            showComplete = true
        }
    }
}
