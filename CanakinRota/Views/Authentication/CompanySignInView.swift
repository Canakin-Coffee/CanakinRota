import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CanakinStaffShared

struct CompanySignInView: View {
    @State private var companyCode = ""
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isSigningIn = false
    
    let onSuccess: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Sign In to Your Company")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter your company code and credentials")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                TextField("Company Registration Number (e.g., 12345678)", text: $companyCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(message.contains("✅") ? .green : .red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: signIn) {
                if isSigningIn {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Signing In...")
                    }
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(companyCode.isEmpty || email.isEmpty || password.isEmpty || isSigningIn)
            
            Text("Ask your administrator for the company registration number")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func signIn() {
        isSigningIn = true
        message = ""
        
        Task {
            do {
                // First, verify the company registration number exists
                let companySnapshot = try await Firestore.firestore()
                    .collection("companies")
                    .whereField("regNumber", isEqualTo: companyCode)
                    .limit(to: 1)
                    .getDocuments()
                
                guard !companySnapshot.documents.isEmpty,
                      let companyData = companySnapshot.documents.first?.data(),
                      let companyId = companyData["id"] as? String else {
                    throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company registration number not found"])
                }
                
                // Sign in to Firebase Auth
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                
                // Verify user belongs to this company
                let userDoc = try await Firestore.firestore()
                    .collection("users")
                    .document(result.user.uid)
                    .getDocument()
                
                guard let userData = userDoc.data(),
                      let userCompanyId = userData["companyId"] as? String,
                      userCompanyId == companyId else {
                    try Auth.auth().signOut()
                    throw NSError(domain: "AuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "User does not belong to this company"])
                }
                
                // Save company info for the session
                UserDefaults.standard.set(companyCode, forKey: "current_company_code")
                UserDefaults.standard.set(companyId, forKey: "current_company_id")
                
                await MainActor.run {
                    isSigningIn = false
                    message = "✅ Successfully signed in!"
                    onSuccess?()
                }
                
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    message = "❌ Sign in failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
