import SwiftUI
import SwiftData
import CanakinStaffShared

struct PasswordSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authorityManager: AuthorityManager
    
    let user: User
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private var passwordStrength: PasswordStrength {
        KeychainPasswordManager.shared.validatePasswordStrength(password)
    }
    
    private var isFormValid: Bool {
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !cleanPassword.isEmpty && 
               cleanPassword == cleanConfirmPassword &&
               cleanPassword.count >= 8
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Set Up Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Welcome \(user.name)! Please create a secure password for your account.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Password Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                        
                        HStack {
                            if showPassword {
                                TextField("Enter password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                                    .disabled(isLoading)
                            } else {
                                SecureField("Enter password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                                    .disabled(isLoading)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .disabled(isLoading)
                        }
                        
                        // Password strength indicator
                        PasswordStrengthIndicator(strength: passwordStrength)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                                    .disabled(isLoading)
                            } else {
                                SecureField("Confirm password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .autocapitalization(.none)
                                    .disabled(isLoading)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .disabled(isLoading)
                        }
                        
                        // Password confirmation status
                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password == confirmPassword ? .green : .red)
                                Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(password == confirmPassword ? .green : .red)
                            }
                        }
                    }
                    
                    // Password requirements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password Requirements")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            RequirementRow(
                                text: "At least 8 characters",
                                isMet: password.count >= 8
                            )
                            RequirementRow(
                                text: "At least one lowercase letter",
                                isMet: password.range(of: "[a-z]", options: .regularExpression) != nil
                            )
                            RequirementRow(
                                text: "At least one uppercase letter",
                                isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil
                            )
                            RequirementRow(
                                text: "At least one number",
                                isMet: password.range(of: "[0-9]", options: .regularExpression) != nil
                            )
                            RequirementRow(
                                text: "At least one special character",
                                isMet: password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil
                            )
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: setPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            
                            Text(isLoading ? "Setting Password..." : "Set Password & Continue")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    Button(action: generateSecurePassword) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Generate Secure Password")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Password Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // If this is a first-time user, we should sign them out
                        // since they haven't completed the setup
                        authorityManager.signOut(modelContext: modelContext)
                        dismiss()
                    }
                }
            }
            .alert("Password Setup", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func setPassword() {
        guard isFormValid else {
            alertMessage = "Please ensure passwords match and meet requirements"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if user.setPassword(cleanPassword) {
            do {
                try modelContext.save()
                alertMessage = "Password set successfully! You can now access the app."
                showingAlert = true
            } catch {
                alertMessage = "Failed to save user: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            alertMessage = "Failed to set password. Please try again."
            showingAlert = true
        }
        
        isLoading = false
    }
    
    private func generateSecurePassword() {
        let generatedPassword = KeychainPasswordManager.shared.generateSecurePassword()
        password = generatedPassword
        confirmPassword = generatedPassword
    }
}

// MARK: - Requirement Row View
struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
        }
    }
}

// MARK: - Password Strength Indicator
struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Strength:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(strength.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strength.uiColor)
            }
            
            // Strength bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(strength.uiColor)
                        .frame(width: geometry.size.width * strength.progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Password Strength Extension
extension PasswordStrength {
    var progress: Double {
        switch self {
        case .weak: return 0.33
        case .medium: return 0.66
        case .strong: return 1.0
        }
    }
    
    var uiColor: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

#Preview {
    PasswordSetupView(user: User(name: "John", surname: "Doe", initials: "JD", email: "john@example.com"))
} 