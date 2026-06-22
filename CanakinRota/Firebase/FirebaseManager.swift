import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import FirebaseCore
import CanakinStaffShared

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let firestoreManager = FirestoreManager.shared
    
    // Real-time sync state
    @Published var isSyncing = false
    @Published var syncProgress = 0.0
    @Published var lastSyncDate: Date?
    
    // ModelContext for data operations
    private var modelContext: ModelContext?
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                
                if user == nil {
                    self?.stopRealTimeSync()
                }
            }
        }
    }
    
    // MARK: - Real-time Data Sync
    
    func startRealTimeSync() {
        print("🚀 START: startRealTimeSync() called")
        print("   isAuthenticated: \(isAuthenticated)")
        print("   modelContext exists: \(modelContext != nil)")
        
        guard isAuthenticated, let modelContext = getModelContext() else {
            print("❌ START: Cannot start sync - authentication or modelContext missing")
            return 
        }

        print("✅ START: Starting real-time sync with all listeners...")
        isSyncing = true
        syncProgress = 0.0
        
        firestoreManager.setupRealTimeListeners(modelContext: modelContext)
        
        lastSyncDate = Date()
        syncProgress = 1.0
        isSyncing = false
        
        print("✅ START: Real-time sync initialized successfully")
    }
    
    func stopRealTimeSync() {
        isSyncing = false
        syncProgress = 0.0
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func getModelContext() -> ModelContext? {
        return modelContext
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔐 Attempting to sign in with email: \(email)")
            let result = try await auth.signIn(withEmail: email, password: password)
            self.currentUser = result.user
            self.isLoading = false
            print("✅ Successfully signed in. Firebase UID: \(result.user.uid)")
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            print("❌ Firebase sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            self.currentUser = result.user
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            throw error
        }
    }
    
    func createAuthAccountForImportedUser(email: String, name: String) async throws -> String {
        let normalized = StaffFirebaseProvisioner.normalizedEmail(email)
        let defaultPassword = generateSecureDefaultPassword()
        let provisioningAuth = try StaffFirebaseProvisioner.provisioningAuth()

        do {
            let result = try await provisioningAuth.createUser(withEmail: normalized, password: defaultPassword)
            let firebaseUID = result.user.uid
            print("✅ Created Firebase Auth account \(firebaseUID) for \(normalized)")

            try provisioningAuth.signOut()
            try await resetPassword(email: normalized)
            print("📧 Password setup email requested for new account \(normalized)")

            return firebaseUID
        } catch {
            if StaffFirebaseProvisioner.isEmailAlreadyInUse(error) {
                print("ℹ️ Firebase Auth account already exists for \(normalized); sending password reset")
                try await resetPassword(email: normalized)
                throw StaffAuthEmailAlreadyInUseError(email: normalized)
            }
            print("❌ Failed to create Firebase Auth account for \(normalized): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Generates a secure default password for imported users
    private func generateSecureDefaultPassword() -> String {
        let length = 12
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        let password = String((0..<length).map { _ in characters.randomElement()! })
        return password
    }
    
    func signOut() throws {
        try auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        let normalized = StaffFirebaseProvisioner.normalizedEmail(email)
        print("📧 Requesting Firebase password reset for \(normalized)")
        try await StaffFirebaseProvisioner.sendPasswordReset(using: auth, email: normalized)
        print("✅ Firebase accepted password reset request for \(normalized)")
    }
    
    
    
    func createAuthAccountWithAdminNotification(email: String, name: String, adminEmail: String) async throws -> String {
        let defaultPassword = generateSecureDefaultPassword()
        
        do {
            let result = try await auth.createUser(withEmail: email, password: defaultPassword)
            let firebaseUID = result.user.uid
            
            return firebaseUID
            
        } catch {
            throw error
        }
    }
    
    func setAuthenticated(_ authenticated: Bool) {
        self.isAuthenticated = authenticated
    }
    
    func forceSignOut() {
        try? auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
} 
