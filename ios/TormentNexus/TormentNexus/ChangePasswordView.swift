import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var email: String {
        UserDefaults.standard.string(forKey: "user_email") ?? ""
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    SecureField("Current Password", text: $currentPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("New Password", text: $newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if showSuccess {
                    Text("Password changed successfully! ✅")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }

                Button(action: changePassword) {
                    Text(isSaving ? "Saving..." : "Change Password")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.black : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isValid || isSaving)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }

    var isValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 6 && newPassword == confirmPassword
    }

    private func changePassword() {
        errorMessage = ""
        isSaving = true
        NetworkManager.shared.changePassword(
            email: email,
            currentPassword: currentPassword,
            newPassword: newPassword
        ) { result in
            isSaving = false
            switch result {
            case .success:
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
