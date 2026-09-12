import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSigningUp = false

    let onSignedIn: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(isSigningUp ? "Create Account" : "Sign In") {
                        Task { await submit() }
                    }
                }

                Section {
                    Button(isSigningUp ? "Already have an account? Sign In" : "New here? Create Account") {
                        isSigningUp.toggle()
                        errorMessage = nil
                    }
                }
            }
            .navigationTitle("Sign In")
        }
    }

    private func submit() async {
        do {
            if isSigningUp {
                try await Auth.auth().createUser(withEmail: email, password: password)
            } else {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
            onSignedIn()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
