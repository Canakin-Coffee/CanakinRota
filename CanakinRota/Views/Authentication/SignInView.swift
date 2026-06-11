import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import CanakinStaffShared

struct SignInView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authorityManager: AuthorityManager
    @EnvironmentObject private var companyContext: CompanyContext
    @EnvironmentObject private var roleStore: RoleStore
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showingPasswordReset = false
    @State private var showingSignUp = false
    @State private var downloadProgress = ""
    
    private let firebaseManager = FirebaseManager.shared
    private let firestoreManager = FirestoreManager.shared
    private let keychainManager = KeychainPasswordManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)
                        .frame(width: 120, height: 120)

                    Text("Canakin Rota")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Staff scheduling & shifts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sign In Form
                VStack(spacing: 20) {
                    Text("Sign In")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 16) {
                        TextField("Email Address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .disabled(isLoading)
                        
                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Password", text: $password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .disabled(isLoading)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    }
                    
                    if !downloadProgress.isEmpty {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text(downloadProgress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: signIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            
                            Text(isLoading ? "Signing In..." : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    // Forgot Password Button
                    Button(action: { showingPasswordReset = true }) {
                        Text("Forgot Password?")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                    
                    // Sign Up / Create Company Option
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: { showingSignUp = true }) {
                        Text("Don't have an account? Create a new company")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Sign In Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
            }
            .sheet(isPresented: $showingSignUp) {
                CompanySignUpView(onComplete: {
                    showingSignUp = false
                    alertMessage = "Company created successfully! Please sign in with your email and password."
                    showingAlert = true
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var isFormValid: Bool {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanEmail.isEmpty && !cleanPassword.isEmpty
    }
    
    /// Simplified sign-in function
    private func signIn() {
        guard isFormValid else { return }
        
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await performLogin(email: cleanEmail, password: cleanPassword)
        }
    }
    
    /// Unified login function - simplified and streamlined
    private func performLogin(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            downloadProgress = "Authenticating..."
        }
        
        do {
            // Step 1: Authenticate with Firebase
            try await firebaseManager.signIn(email: email, password: password)
            
            guard let firebaseUser = firebaseManager.currentUser else {
                throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Firebase user after sign-in"])
            }
            
            // Step 2: Fetch user from Firestore to get companyId
            await MainActor.run {
                downloadProgress = "Finding user account..."
            }
            
            print("🔍 Searching for user in Firestore with firebaseUID: \(firebaseUser.uid)")
            var userDoc = try await Firestore.firestore()
                .collection("users")
                .whereField("firebaseUID", isEqualTo: firebaseUser.uid)
                .limit(to: 1)
                .getDocuments()
            
            print("📄 Firestore query returned \(userDoc.documents.count) document(s)")
            
            // If not found by firebaseUID, try searching by email as fallback
            if userDoc.documents.isEmpty {
                print("⚠️ User not found by firebaseUID, trying email search...")
                let emailQuery = try await Firestore.firestore()
                    .collection("users")
                    .whereField("email", isEqualTo: email.lowercased())
                    .limit(to: 1)
                    .getDocuments()
                
                print("📄 Email query returned \(emailQuery.documents.count) document(s)")
                
                if !emailQuery.documents.isEmpty {
                    let userData = emailQuery.documents.first!.data()
                    print("📋 Found user by email. User data: \(userData)")
                    print("📋 firebaseUID in document: \(userData["firebaseUID"] as? String ?? "nil")")
                    print("📋 isActive: \(userData["isActive"] as? Bool ?? true)")
                    
                    // Update the firebaseUID in Firestore to match current Firebase Auth user
                    let docRef = emailQuery.documents.first!.reference
                    try await docRef.updateData(["firebaseUID": firebaseUser.uid])
                    print("✅ Updated firebaseUID in Firestore to match current Firebase Auth user")
                    
                    // Use the emailQuery result as our userDoc
                    userDoc = emailQuery
                } else {
                    try? Auth.auth().signOut()
                    throw NSError(domain: "SignInError", code: 2, userInfo: [NSLocalizedDescriptionKey: "User account not found in system. Your Firebase account exists, but no user record was found in Firestore. Please contact your administrator."])
                }
            }
            
            guard !userDoc.documents.isEmpty,
                  let userData = userDoc.documents.first?.data(),
                  let userEmail = userData["email"] as? String,
                  let userCompanyId = userData["companyId"] as? String else {
                try? Auth.auth().signOut()
                throw NSError(domain: "SignInError", code: 2, userInfo: [NSLocalizedDescriptionKey: "User account is missing required information (email or companyId). Please contact your administrator."])
            }
            
            // Check if user is active
            let isActive = userData["isActive"] as? Bool ?? true
            if !isActive {
                try? Auth.auth().signOut()
                throw NSError(domain: "SignInError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Your account has been deactivated. Please contact your administrator."])
            }
            
            print("✅ User found in Firestore: \(userEmail), Company: \(userCompanyId), Active: \(isActive)")
            
            // Step 3: Prepare company context (critical - must be done before syncing other data)
            await MainActor.run {
                downloadProgress = "Loading company data..."
                companyContext.prepareCurrentCompany(withId: userCompanyId, context: modelContext)
            }
            await firestoreManager.syncCompanies(modelContext: modelContext)
            
            // Step 4: Set company context
            await MainActor.run {
                downloadProgress = "Setting up company context..."
                let companyDescriptor = FetchDescriptor<Company>()
                if let companies = try? modelContext.fetch(companyDescriptor),
                   let userCompany = companies.first(where: { $0.id == userCompanyId }) {
                    companyContext.setCurrentCompany(userCompany)
                }
            }
            
            // Step 5: Sync users
            await MainActor.run {
                downloadProgress = "Loading user data..."
            }
            await firestoreManager.syncUsers(modelContext: modelContext)
            
            // Step 6: Find current user in SwiftData
            await MainActor.run {
                downloadProgress = "Validating user..."
            }
            
            let descriptor = FetchDescriptor<CanakinStaffShared.User>()
            let allUsers = try modelContext.fetch(descriptor)
            
            guard let currentUser = allUsers.first(where: { 
                $0.firebaseUID == firebaseUser.uid || 
                $0.email.lowercased() == userEmail.lowercased() 
            }) else {
                try? Auth.auth().signOut()
                throw NSError(domain: "SignInError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No account found for this email. Please create a new company account."])
            }
            
            // Ensure Firebase UID is set
            if currentUser.firebaseUID != firebaseUser.uid {
                currentUser.firebaseUID = firebaseUser.uid
                try? modelContext.save()
            }
            
            // Step 7: Set up Firebase/model context (defer isAuthenticated until essentials sync completes)
            await MainActor.run {
                downloadProgress = "Setting up..."
                authorityManager.currentUser = currentUser
                authorityManager.saveCurrentUser()
                firebaseManager.setAuthenticated(true)
                firebaseManager.setModelContext(modelContext)
                roleStore.setModelContext(modelContext)
                roleStore.setCompanyContext(companyContext)
            }
            
            // Step 8: Load essentials only — shifts continue in background after sign-in
            await MainActor.run {
                downloadProgress = "Downloading rota data..."
            }
            await firestoreManager.loadRotaEssentialsForCompany(modelContext: modelContext)
            
            // Step 9: Start real-time sync
            await MainActor.run {
                downloadProgress = "Setting up real-time sync..."
            }
            firebaseManager.startRealTimeSync()
            
            // Step 10: Enter main app once essentials are ready
            await MainActor.run {
                authorityManager.applyPermissionsFromCache(modelContext: modelContext)
                authorityManager.isAuthenticated = true
            }
            
            // Step 11: Download shifts in background (can take a while for large rotas)
            Task { @MainActor in
                print("SYNC: Background shift download started")
                await firestoreManager.syncShifts(modelContext: modelContext)
                print("SYNC: Background shift download complete")
            }
            
            // Step 12: Save credentials for auto-sign-on if enabled
            if currentUser.allowAutoSignOn {
                UserDefaults.standard.set(email, forKey: "lastSignedInEmail")
                _ = keychainManager.savePassword(password, for: email)
            }
            
            // Complete
            await MainActor.run {
                isLoading = false
                downloadProgress = ""
            }
            
        } catch {
            // Log the full error for debugging
            print("❌ Login error: \(error)")
            print("❌ Error domain: \((error as NSError).domain)")
            print("❌ Error code: \((error as NSError).code)")
            print("❌ Error userInfo: \((error as NSError).userInfo)")
            
            await MainActor.run {
                isLoading = false
                downloadProgress = ""
                
                // Provide more user-friendly error messages
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("wrong password") || 
                   errorDescription.contains("invalid password") ||
                   errorDescription.contains("password is invalid") {
                    alertMessage = "Incorrect password. Please check your password and try again, or use 'Forgot Password' to reset it."
                } else if errorDescription.contains("user not found") || 
                          errorDescription.contains("there is no user record") {
                    alertMessage = "No account found with this email address. Please check your email or create a new account."
                } else if errorDescription.contains("network") || 
                          errorDescription.contains("connection") {
                    alertMessage = "Network error. Please check your internet connection and try again."
                } else if errorDescription.contains("too many requests") {
                    alertMessage = "Too many login attempts. Please wait a few minutes and try again."
                } else {
                    alertMessage = "Sign in failed: \(error.localizedDescription)"
                }
                
                showingAlert = true
            }
        }
    }
}
