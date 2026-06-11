import SwiftUI
import CanakinStaffShared
import FirebaseAuth
import FirebaseFirestore

struct CompanySetupView: View {
    @State private var companyName = ""
    @State private var companyCode = ""
    @State private var adminEmail = ""
    @State private var adminPassword = ""
    @State private var confirmPassword = ""
    @State private var message = ""
    @State private var isCreating = false
    
    let onCompleted: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Set Up Your Company")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Create your company account and get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                TextField("Company Name", text: $companyName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Company Registration Number (e.g., 12345678)", text: $companyCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                TextField("Admin Email", text: $adminEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $adminPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
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
            
            Button(action: createCompany) {
                if isCreating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating Company...")
                    }
                } else {
                    Text("Create Company")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(companyName.isEmpty || companyCode.isEmpty || adminEmail.isEmpty || adminPassword.isEmpty || confirmPassword.isEmpty || adminPassword != confirmPassword || isCreating)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Company Registration Number:")
                    .font(.headline)
                Text("• Enter your UK company registration number")
                Text("• Share this number with your team members")
                Text("• Example: 12345678, 87654321, etc.")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func createCompany() {
        isCreating = true
        message = ""
        
        Task {
            do {
                // Create company in Firestore
                let companyId = UUID().uuidString
                let companyData: [String: Any] = [
                    "id": companyId,
                    "name": companyName,
                    "symbol": "",  // Keep existing symbol field empty for now
                    "address": "",
                    "phoneNumber": "",
                    "regNumber": companyCode,  // Use regNumber as company code
                    "vatNumber": "",
                    "dateCreated": Date(),
                    "dateUpdated": Date()
                ]
                
                // Save to Firestore
                try await Firestore.firestore().collection("companies").document(companyId).setData(companyData)
                
                // Create admin user
                let userResult = try await Auth.auth().createUser(withEmail: adminEmail, password: adminPassword)
                
                let userData: [String: Any] = [
                    "id": userResult.user.uid,
                    "email": adminEmail,
                    "name": "Admin",
                    "role": "System Owner",
                    "companyId": companyId,
                    "companyCode": companyCode,  // Store company code for reference
                    "isActive": true,
                    "createdAt": Date()
                ]
                
                try await Firestore.firestore().collection("users").document(userResult.user.uid).setData(userData)
                
                // Save company code to UserDefaults for future reference
                UserDefaults.standard.set(companyCode, forKey: "current_company_code")
                UserDefaults.standard.set(companyId, forKey: "current_company_id")
                
                await MainActor.run {
                    isCreating = false
                    message = "✅ Company created successfully!"
                    onCompleted?()
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    message = "❌ Failed to create company: \(error.localizedDescription)"
                }
            }
        }
    }
}
