import SwiftUI

struct SjjjfMemberCardView: View {
    @EnvironmentObject var apiService: APIService
    @State private var member: SjjjfMember?
    @State private var isLoading = true
    @State private var showRegister = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let member = member {
                memberCard(member)
            } else {
                registerPrompt
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("Competition Profile")
        .task { await loadMember() }
        .sheet(isPresented: $showRegister) {
            SjjjfRegisterView { newMember in
                self.member = newMember
                showRegister = false
            }
            .environmentObject(apiService)
        }
    }

    func memberCard(_ m: SjjjfMember) -> some View {
        VStack(spacing: 0) {
            // Card
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SJJJF/ASJJF")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                        Text("SPORT JIU-JITSU JAPAN FEDERATION")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)
                    }
                    Spacer()
                }

                // Member Number
                Text(m.member_number)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.jfRed)
                    .tracking(3)

                // QR placeholder
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)

                // Info fields
                VStack(spacing: 12) {
                    infoRow("Name", apiService.currentUser?.display_name ?? "-")
                    infoRow("Belt", m.belt.uppercased())
                    infoRow("Weight", m.weight_class ?? "-")
                    infoRow("Dojo", m.dojo_name ?? "-")
                    infoRow("Points", "\(m.points) pts")
                }

                if let valid = m.valid_until {
                    Text("Valid until: \(valid)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding(28)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.18),
                             Color(red: 0.06, green: 0.13, blue: 0.24)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            .padding(20)

            // Entries section
            NavigationLink(destination: MyEntriesView().environmentObject(apiService)) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.jfRed)
                    Text("My Tournament Entries")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.jfCardBg)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    var registerPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.jfRed)
            Text("Competition Profile")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text("Set up your competition profile to enter SJJJF/ASJJF tournaments, earn ranking points, and get your digital ID card.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Set Up Profile") { showRegister = true }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.jfRed)
                .cornerRadius(12)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
            Spacer()
        }
    }

    func loadMember() async {
        isLoading = true
        member = try? await apiService.getSjjjfMember()
        isLoading = false
    }
}
