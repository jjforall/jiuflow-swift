import SwiftUI

struct SjjjfRegisterView: View {
    @EnvironmentObject var apiService: APIService
    @Environment(\.dismiss) var dismiss
    var onComplete: (SjjjfMember) -> Void

    @State private var belt = "white"
    @State private var weightClass = ""
    @State private var dojoName = ""
    @State private var isSubmitting = false
    @State private var error: String?

    let belts = ["white", "blue", "purple", "brown", "black"]
    let weightClasses = [
        "rooster": "Rooster (-57.5kg)",
        "light-feather": "Light Feather (-64kg)",
        "feather": "Feather (-70kg)",
        "light": "Light (-76kg)",
        "middle": "Middle (-82.3kg)",
        "medium-heavy": "Medium Heavy (-88.3kg)",
        "heavy": "Heavy (-94.3kg)",
        "super-heavy": "Super Heavy (-100.5kg)",
        "ultra-heavy": "Ultra Heavy (+100.5kg)",
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Belt / 帯") {
                    Picker("Belt", selection: $belt) {
                        ForEach(belts, id: \.self) { b in
                            Text(b.capitalized).tag(b)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Weight Class / 階級") {
                    Picker("Weight", selection: $weightClass) {
                        Text("Select...").tag("")
                        ForEach(Array(weightClasses.keys.sorted()), id: \.self) { key in
                            Text(weightClasses[key]!).tag(key)
                        }
                    }
                }

                Section("Dojo / 所属道場") {
                    TextField("Dojo name", text: $dojoName)
                }

                if let error = error {
                    Section {
                        Text(error).foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: register) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Register / 登録")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(isSubmitting || weightClass.isEmpty)
                }

                Section {
                    Text("Set up your profile to enter tournaments, earn ranking points, and get your digital competition ID card.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Competition Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func register() {
        isSubmitting = true
        error = nil
        Task {
            do {
                let member = try await apiService.registerSjjjfMember(
                    belt: belt,
                    weightClass: weightClass.isEmpty ? nil : weightClass,
                    dojoName: dojoName.isEmpty ? nil : dojoName
                )
                if let member = member {
                    await MainActor.run { onComplete(member) }
                } else {
                    await MainActor.run { error = "Registration failed" }
                }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
            await MainActor.run { isSubmitting = false }
        }
    }
}
