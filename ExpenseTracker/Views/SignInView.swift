import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

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
                    GoogleSignInButton {
                        signInWithGoogle()
                    }
                }

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

    private func signInWithGoogle() {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController
        else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error {
                errorMessage = error.localizedDescription
                return
            }
            guard let idToken = result?.user.idToken?.tokenString,
                  let accessToken = result?.user.accessToken.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { _, error in
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    onSignedIn()
                }
            }
        }
    }
}
