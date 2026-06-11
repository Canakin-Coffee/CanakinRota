import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import CanakinStaffShared

struct FirebaseConnectionTest: View {
    @State private var testResults: [String] = []
    @State private var isRunning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Firebase Connection Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults, id: \.self) { result in
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal)
                        }
                    }
                }
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: runTests) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isRunning ? "Running Tests..." : "Run Connection Tests")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isRunning)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Firebase Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func runTests() {
        isRunning = true
        testResults.removeAll()
        
        Task {
            await runAllTests()
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    private func runAllTests() async {
        addResult("🚀 Starting Firebase Connection Tests...")
        
        // Test 1: Firebase App Configuration
        await testFirebaseConfiguration()
        
        // Test 2: Network Connectivity
        await testNetworkConnectivity()
        
        // Test 3: Firestore Connection
        await testFirestoreConnection()
        
        // Test 4: Authentication State
        await testAuthenticationState()
        
        // Test 5: User Collection Access
        await testUserCollectionAccess()
        
        // Test 6: Company Collection Access
        await testCompanyCollectionAccess()
        
        addResult("✅ All tests completed!")
    }
    
    private func testFirebaseConfiguration() async {
        addResult("📱 Test 1: Firebase App Configuration")
        
        if let app = FirebaseApp.app() {
            let options = app.options
            addResult("   ✅ Firebase App initialized")
            if let projectID = options.projectID {
                addResult("   📋 Project ID: \(projectID)")
            } else {
                addResult("   📋 Project ID: nil")
            }
            if let apiKey = options.apiKey {
                addResult("   🔑 API Key: \(apiKey.prefix(10))...")
            } else {
                addResult("   🔑 API Key: nil")
            }
            addResult("   📱 App ID: \(options.googleAppID.prefix(10))...")
        } else {
            addResult("   ❌ Firebase App not configured")
        }
    }
    
    private func testNetworkConnectivity() async {
        addResult("🌐 Test 2: Network Connectivity")
        
        do {
            // Test basic internet connectivity
            let url = URL(string: "https://www.google.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("   ✅ Internet connection: \(httpResponse.statusCode)")
            } else {
                addResult("   ⚠️ Internet connection: Unknown response")
            }
        } catch {
            addResult("   ❌ Internet connection failed: \(error.localizedDescription)")
        }
        
        // Test Firebase connectivity
        do {
            let url = URL(string: "https://firestore.googleapis.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                addResult("   ✅ Firebase connectivity: \(httpResponse.statusCode)")
            } else {
                addResult("   ⚠️ Firebase connectivity: Unknown response")
            }
        } catch {
            addResult("   ❌ Firebase connectivity failed: \(error.localizedDescription)")
        }
    }
    
    private func testFirestoreConnection() async {
        addResult("🔥 Test 3: Firestore Connection")
        
        do {
            let db = Firestore.firestore()
            // Try to read from a test collection
            let _ = try await db.collection("test").limit(to: 1).getDocuments()
            addResult("   ✅ Firestore connection successful")
        } catch {
            addResult("   ❌ Firestore connection failed: \(error.localizedDescription)")
        }
    }
    
    private func testAuthenticationState() async {
        addResult("🔐 Test 4: Authentication State")
        
        let auth = Auth.auth()
        if let user = auth.currentUser {
            addResult("   ✅ User authenticated: \(user.uid)")
            addResult("   📧 Email: \(user.email ?? "nil")")
            addResult("   ✅ Email verified: \(user.isEmailVerified)")
        } else {
            addResult("   ⚠️ No authenticated user")
        }
    }
    
    private func testUserCollectionAccess() async {
        addResult("👤 Test 5: User Collection Access")
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users").limit(to: 5).getDocuments()
            
            addResult("   ✅ User collection accessible")
            addResult("   📊 Documents found: \(snapshot.documents.count)")
            
            for (index, doc) in snapshot.documents.enumerated() {
                let data = doc.data()
                let email = data["email"] as? String ?? "Unknown"
                let firebaseUID = data["firebaseUID"] as? String ?? "None"
                addResult("   📋 User \(index + 1): \(email) (UID: \(firebaseUID.prefix(8))...)")
            }
        } catch {
            addResult("   ❌ User collection access failed: \(error.localizedDescription)")
        }
    }
    
    private func testCompanyCollectionAccess() async {
        addResult("🏢 Test 6: Company Collection Access")
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("companies").limit(to: 5).getDocuments()
            
            addResult("   ✅ Company collection accessible")
            addResult("   📊 Documents found: \(snapshot.documents.count)")
            
            for (index, doc) in snapshot.documents.enumerated() {
                let data = doc.data()
                let name = data["name"] as? String ?? "Unknown"
                let code = data["code"] as? String ?? "None"
                addResult("   📋 Company \(index + 1): \(name) (Code: \(code))")
            }
        } catch {
            addResult("   ❌ Company collection access failed: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func addResult(_ result: String) {
        testResults.append(result)
    }
}

#Preview {
    FirebaseConnectionTest()
}
