import SwiftUI

struct WelcomeView: View {
    @ObservedObject var appState: AppState
    @State private var keyInput: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Cursed")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Enter your OpenAI API key to get started")
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SecureField("sk-...", text: $keyInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 350)
                    .onSubmit(submitKey)

                Button("Submit", action: submitKey)
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submitKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appState.apiKey = trimmed
    }
}
