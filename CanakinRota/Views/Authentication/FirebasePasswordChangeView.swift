import SwiftUI
import CanakinStaffShared
import FirebaseAuth

struct FirebasePasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Password") {
                    SecureField("Enter current password", text: $currentPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("New Password") {
                    SecureField("Enter new password", text: $newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: changePassword) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Changing Password...")
                            }
                        } else {
                            Text("Change Password")
                        }
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func changePassword() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "No user is currently signed in."
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match."
            showAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "New password must be at least 6 characters long."
            showAlert = true
            return
        }
        
        isLoading = true
        
        // First, re-authenticate the user with their current password
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    alertMessage = "Current password is incorrect: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            
            // Now change the password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        alertMessage = "Failed to change password: \(error.localizedDescription)"
                        isSuccess = false
                    } else {
                        alertMessage = "Password changed successfully!"
                        isSuccess = true
                    }
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    FirebasePasswordChangeView()
} 