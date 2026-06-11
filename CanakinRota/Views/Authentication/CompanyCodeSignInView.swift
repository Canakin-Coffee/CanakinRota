import SwiftUI
import CanakinStaffShared
import FirebaseAuth

struct CompanyCodeSignInView: View {
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
                TextField("Company Code (e.g., ACME-2024)", text: $companyCode)
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
            
            Text("Ask your administrator for the company code")
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
                // Look up Firebase config for this company code
                let config = try await CompanyConfigManager.shared.getConfig(for: companyCode)
                
                // Configure Firebase with the company's project
                try await CompanyConfigManager.shared.configureFirebase(config)
                
                // Sign in to the company's Firebase project
                let _ = try await Auth.auth().signIn(withEmail: email, password: password)
                
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

struct CompanyConfig {
    let companyCode: String
    let projectId: String
    let apiKey: String
    let appId: String
}

class CompanyConfigManager {
    static let shared = CompanyConfigManager()
    private init() {}
    
    func getConfig(for companyCode: String) async throws -> CompanyConfig {
        // In a real implementation, this would query a central database
        // For now, we'll check if it's the same as the saved config
        let savedCode = UserDefaults.standard.string(forKey: "company_code")
        
        guard savedCode == companyCode else {
            throw NSError(domain: "CompanyConfigError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company code not found"])
        }
        
        guard let projectId = UserDefaults.standard.string(forKey: "firebase_project_id"),
              let apiKey = UserDefaults.standard.string(forKey: "firebase_api_key"),
              let appId = UserDefaults.standard.string(forKey: "firebase_app_id") else {
            throw NSError(domain: "CompanyConfigError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Company configuration not found"])
        }
        
        return CompanyConfig(
            companyCode: companyCode,
            projectId: projectId,
            apiKey: apiKey,
            appId: appId
        )
    }
    
    func configureFirebase(_ config: CompanyConfig) async throws {
        // Configure Firebase with the company's project
        print("Configuring Firebase for company: \(config.companyCode)")
        print("Project ID: \(config.projectId)")
    }
}
