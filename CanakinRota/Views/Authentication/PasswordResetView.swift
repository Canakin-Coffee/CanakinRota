import SwiftUI
import CanakinStaffShared
import FirebaseAuth

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Form Content
                VStack(spacing: 20) {
                    TextField("Email Address", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(isLoading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action Button
                Button(action: sendPasswordReset) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isLoading ? "Sending..." : "Send Reset Email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Password Reset", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("sent") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func sendPasswordReset() {
        guard isFormValid else { return }
        
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: cleanEmail)
                await MainActor.run {
                    alertMessage = "A password reset email has been sent to \(cleanEmail). Please check your email and follow the link to reset your password."
                    showingAlert = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorDescription = error.localizedDescription.lowercased()
                    if errorDescription.contains("user not found") || 
                       errorDescription.contains("there is no user record") ||
                       errorDescription.contains("invalid email") {
                        alertMessage = "No user found with this email address. Please check the email and try again."
                    } else {
                        alertMessage = "Failed to send password reset email: \(error.localizedDescription)"
                    }
                    showingAlert = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    PasswordResetView()
}
