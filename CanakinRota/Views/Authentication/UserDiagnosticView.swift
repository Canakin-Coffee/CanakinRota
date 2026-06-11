import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CanakinStaffShared

struct UserDiagnosticView: View {
    @State private var diagnosticResults: [String] = []
    @State private var isRunning = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("User Diagnostic Tool")
                    .font(.title)
                    .padding()
                
                Button("Run User Diagnostic") {
                    Task {
                        await runDiagnostic()
                    }
                }
                .disabled(isRunning)
                .padding()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(diagnosticResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(result.contains("❌") ? .red : 
                                               result.contains("✅") ? .green : 
                                               result.contains("⚠️") ? .orange : .primary)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func runDiagnostic() async {
        isRunning = true
        diagnosticResults.removeAll()
        
        addResult("🔍 Starting User Diagnostic...")
        
        // Check Firebase Auth
        await checkFirebaseAuth()
        
        // Check User Document in Firestore
        await checkUserDocument()
        
        // Check Company Document
        await checkCompanyDocument()
        
        // Test Collection Access
        await testCollectionAccess()
        
        // Test Specific Permissions
        await testSpecificPermissions()
        
        addResult("✅ Diagnostic Complete!")
        isRunning = false
    }
    
    private func checkFirebaseAuth() async {
        addResult("🔐 Checking Firebase Authentication...")
        
        let auth = Auth.auth()
        if let user = auth.currentUser {
            addResult("   ✅ User authenticated: \(user.uid)")
            addResult("   📧 Email: \(user.email ?? "nil")")
            addResult("   ✅ Email verified: \(user.isEmailVerified)")
        } else {
            addResult("   ❌ No authenticated user")
        }
    }
    
    private func checkUserDocument() async {
        addResult("👤 Checking User Document in Firestore...")
        
        guard let currentUser = Auth.auth().currentUser else {
            addResult("   ❌ No authenticated user")
            return
        }
        
        addResult("   🔑 Current Firebase UID: \(currentUser.uid)")
        addResult("   📧 Current Email: \(currentUser.email ?? "nil")")
        
        do {
            let db = Firestore.firestore()
            
            // Search for user document by email (since documents use SwiftData UUID as ID)
            let query = db.collection("users").whereField("email", isEqualTo: currentUser.email ?? "")
            let querySnapshot = try await query.getDocuments()
            
            if !querySnapshot.documents.isEmpty {
                let userDoc = querySnapshot.documents.first!
                let data = userDoc.data()
                addResult("   ✅ User document found by email search")
                addResult("   📋 Document ID: \(userDoc.documentID)")
                addResult("   📋 Name: \(data["name"] as? String ?? "nil")")
                addResult("   📧 Email: \(data["email"] as? String ?? "nil")")
                addResult("   🏢 Company ID: \(data["companyId"] as? String ?? "nil")")
                addResult("   🔐 Authority: \(data["authorityLevel"] as? String ?? "nil")")
                addResult("   ✅ Active: \(data["isActive"] as? Bool ?? false)")
                addResult("   🔑 Firebase UID in doc: \(data["firebaseUID"] as? String ?? "nil")")
                
                // Check if companyId is set
                if let companyId = data["companyId"] as? String, !companyId.isEmpty {
                    addResult("   ✅ Company ID is properly set")
                } else {
                    addResult("   ❌ Company ID is missing or empty!")
                }
            } else {
                addResult("   ❌ User document not found by email search!")
            }
        } catch {
            addResult("   ❌ Error reading user document: \(error.localizedDescription)")
        }
    }
    
    private func checkCompanyDocument() async {
        addResult("🏢 Checking Company Document...")
        
        guard let currentUser = Auth.auth().currentUser else {
            addResult("   ❌ No authenticated user")
            return
        }
        
        do {
            let db = Firestore.firestore()
            
            // Find user document by email first
            let userQuery = db.collection("users").whereField("email", isEqualTo: currentUser.email ?? "")
            let userQuerySnapshot = try await userQuery.getDocuments()
            
            if !userQuerySnapshot.documents.isEmpty {
                let userDoc = userQuerySnapshot.documents.first!
                let data = userDoc.data()
                
                if let companyId = data["companyId"] as? String,
                   !companyId.isEmpty {
                    addResult("   ✅ Company ID found: \(companyId)")
                    
                    let companyDoc = try await db.collection("companies").document(companyId).getDocument()
                    
                    if companyDoc.exists {
                        let companyData = companyDoc.data() ?? [:]
                        addResult("   ✅ Company document exists")
                        addResult("   📋 Company Name: \(companyData["name"] as? String ?? "nil")")
                        addResult("   📧 Company Email: \(companyData["email"] as? String ?? "nil")")
                        addResult("   📍 Company Address: \(companyData["address"] as? String ?? "nil")")
                    } else {
                        addResult("   ❌ Company document does not exist for ID: \(companyId)")
                    }
                } else {
                    addResult("   ❌ No company ID found in user document")
                }
            } else {
                addResult("   ❌ User document not found, cannot check company")
            }
        } catch {
            addResult("   ❌ Error reading company document: \(error.localizedDescription)")
        }
    }
    
    private func testCollectionAccess() async {
        addResult("🔍 Testing Collection Access...")
        
        let collections = ["ingredients", "suppliers", "categories", "stocks", "appliances", "temperatureRecords"]
        
        for collection in collections {
            do {
                let db = Firestore.firestore()
                let snapshot = try await db.collection(collection).limit(to: 1).getDocuments()
                addResult("   ✅ \(collection): Accessible (\(snapshot.documents.count) docs)")
            } catch {
                addResult("   ❌ \(collection): \(error.localizedDescription)")
            }
        }
    }
    
    private func testSpecificPermissions() async {
        addResult("🔐 Testing Specific Permissions...")
        
        let authorityManager = AuthorityManager.shared
        
        addResult("   🏢 canViewFixedCosts: \(authorityManager.canViewFixedCosts())")
        addResult("   👥 canManageUsers: \(authorityManager.canManageUsers())")
        addResult("   📋 canManageRoles: \(authorityManager.canManageRoles())")
        addResult("   📊 canViewReports: \(authorityManager.canViewReports())")
        addResult("   📅 canViewRota: \(authorityManager.canViewRota())")
        addResult("   📝 canEditRota: \(authorityManager.canEditRota())")
        addResult("   🕒 canClockInOut: \(authorityManager.canClockInOut())")
        addResult("   📚 canManageRecipes: \(authorityManager.canManageRecipes())")
        addResult("   🏪 canManageSuppliers: \(authorityManager.canManageSuppliers())")
        addResult("   💰 canManageFinancials: \(authorityManager.canManageFinancials())")
        addResult("   ⚙️ canManageSettings: \(authorityManager.canManageSettings())")
        addResult("   📦 canManageInventory: \(authorityManager.canManageInventory())")
        addResult("   🏗️ canViewStockManagement: \(authorityManager.canViewStockManagement())")
        addResult("   🌡️ canManageTemperatures: \(authorityManager.canManageTemperatures())")
        addResult("   💼 canManageJobs: \(authorityManager.canManageJobs())")
        
        // Check current user details
        if let currentUser = authorityManager.currentUser {
            addResult("   👤 Current User Authority Level: \(currentUser.effectiveAuthorityLevel.rawValue)")
            addResult("   📧 Current User Email: \(currentUser.email)")
            addResult("   🏢 Current User Company ID: \(currentUser.companyId ?? "nil")")
        } else {
            addResult("   ❌ No current user in AuthorityManager")
        }
    }
    
    @MainActor
    private func addResult(_ result: String) {
        diagnosticResults.append(result)
    }
}

#Preview {
    UserDiagnosticView()
}
