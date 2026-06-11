import SwiftUI
import CanakinStaffShared
import FirebaseCore

struct FirebaseProjectSetupView: View {
    let onCompleted: (() -> Void)?
    
    @State private var companyCode = ""
    @State private var projectId = ""
    @State private var apiKey = ""
    @State private var appId = ""
    @State private var message = ""
    @State private var isConfiguring = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Set Up Your Company")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Configure your company's Firebase project details")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                TextField("Company Code (e.g., ACME-2024)", text: $companyCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Project ID", text: $projectId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("App ID", text: $appId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            .padding(.horizontal)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(message.contains("✅") ? .green : .red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: configureFirebase) {
                if isConfiguring {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting...")
                    }
                } else {
                    Text("Connect to Firebase")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(companyCode.isEmpty || projectId.isEmpty || apiKey.isEmpty || appId.isEmpty || isConfiguring)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to get these details:")
                    .font(.headline)
                Text("1. Go to Firebase Console")
                Text("2. Select your project")
                Text("3. Go to Project Settings")
                Text("4. Scroll down to 'Your apps'")
                Text("5. Copy the values from your iOS app config")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func configureFirebase() {
        isConfiguring = true
        message = ""
        
        Task {
            do {
                // Create Firebase configuration
                let config = FirebaseConfig(
                    companyCode: companyCode,
                    projectId: projectId,
                    apiKey: apiKey,
                    appId: appId
                )
                
                // Save configuration
                try await FirebaseConfigManager.shared.saveConfig(config)
                
                // Configure Firebase
                try await FirebaseConfigManager.shared.configureFirebase()
                
                await MainActor.run {
                    isConfiguring = false
                    message = "✅ Successfully connected to Firebase!"
                    onCompleted?()
                }
            } catch {
                await MainActor.run {
                    isConfiguring = false
                    message = "❌ Failed to connect: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FirebaseConfig {
    let companyCode: String
    let projectId: String
    let apiKey: String
    let appId: String
}

class FirebaseConfigManager {
    static let shared = FirebaseConfigManager()
    private init() {}
    
    func saveConfig(_ config: FirebaseConfig) async throws {
        // Save to UserDefaults or Keychain
        UserDefaults.standard.set(config.companyCode, forKey: "company_code")
        UserDefaults.standard.set(config.projectId, forKey: "firebase_project_id")
        UserDefaults.standard.set(config.apiKey, forKey: "firebase_api_key")
        UserDefaults.standard.set(config.appId, forKey: "firebase_app_id")
    }
    
    func configureFirebase() async throws {
        // Configure Firebase with the saved config
        // This would need to be implemented based on your Firebase setup
        print("Configuring Firebase with project: \(UserDefaults.standard.string(forKey: "firebase_project_id") ?? "unknown")")
    }
}
