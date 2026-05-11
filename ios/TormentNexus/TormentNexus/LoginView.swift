
import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var onLoginSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Image(systemName: "hanger")
                    .font(.system(size: 60))
                    .foregroundColor(.black)
                Text("FitCheck")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Your digital wardrobe")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if isRegistering {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleSubmit) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    } else {
                        Text(isRegistering ? "Create Account" : "Login")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                
                Button(action: { isRegistering.toggle(); errorMessage = "" }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Sign up")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func handleSubmit() {
        errorMessage = ""
        isLoading = true
        
        if isRegistering {
            guard !displayName.isEmpty else {
                errorMessage = "Please enter a display name"
                isLoading = false
                return
            }
            NetworkManager.shared.register(email: email, password: password, displayName: displayName) { result in
                isLoading = false
                switch result {
                case .success(let token):
                    NetworkManager.shared.token = token
                    onLoginSuccess()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            NetworkManager.shared.login(email: email, password: password) { result in
                isLoading = false
                switch result {
                case .success(let token):
                    NetworkManager.shared.token = token
                    onLoginSuccess()
                case .failure:
                    errorMessage = "Invalid email or password"
                }
            }
        }
    }
}
