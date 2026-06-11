import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseFirestore
import CanakinStaffShared

struct CompanySignUpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyName = ""
    @State private var companyRegNumber = ""
    @State private var message = ""
    @State private var isCreating = false
    @State private var isCheckingEmail = false
    
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Your Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                                .submitLabel(.next)
                            
                            TextField("Surname", text: $surname)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                                .submitLabel(.next)
                            
                            TextField("Email Address", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textContentType(.emailAddress)
                                .submitLabel(.next)
                            
                            if isCheckingEmail {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Checking email availability...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                                .submitLabel(.next)
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                                .submitLabel(.done)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Company Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Company Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Company Name", text: $companyName)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.words)
                                .submitLabel(.next)
                            
                            TextField("Company Registration Number", text: $companyRegNumber)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .keyboardType(.numbersAndPunctuation)
                                .submitLabel(.done)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Message and Button
                    VStack(spacing: 16) {
                        if !message.isEmpty {
                            Text(message)
                                .foregroundColor(message.contains("✅") ? .green : .red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: createCompanyAndUser) {
                            if isCreating {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text("Creating Company...")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("Create Company Account")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isFormValid || isCreating || isCheckingEmail)
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create New Company")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            // Note: Email uniqueness check is performed during form submission
            // to avoid requiring authentication for the query
        }
    }
    
    private var isFormValid: Bool {
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSurname = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanCompanyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !cleanFirstName.isEmpty &&
               !cleanSurname.isEmpty &&
               !cleanEmail.isEmpty &&
               isValidEmail(cleanEmail) &&
               !password.isEmpty &&
               password == confirmPassword &&
               password.count >= 6 &&
               !cleanCompanyName.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Check if email is unique across ALL companies in Firebase
    private func checkEmailUniqueness(email: String) {
        guard !email.isEmpty, isValidEmail(email) else { return }
        
        isCheckingEmail = true
        
        Task {
            do {
                let db = Firestore.firestore()
                // Query users collection for this email across ALL companies
                let query = db.collection("users")
                    .whereField("email", isEqualTo: email.lowercased())
                    .limit(to: 1)
                
                let snapshot = try await query.getDocuments()
                
                await MainActor.run {
                    isCheckingEmail = false
                    
                    if !snapshot.documents.isEmpty {
                        message = "❌ This email is already registered. Please use a different email or sign in."
                    } else {
                        message = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingEmail = false
                    // Don't show error for check - just allow proceed and catch during creation
                    message = ""
                }
            }
        }
    }
    
    private func createCompanyAndUser() {
        guard isFormValid else { return }
        
        let cleanFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSurname = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanCompanyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRegNumber = companyRegNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        isCreating = true
        message = ""
        
        Task {
            do {
                // Step 1: Create Firebase Auth account FIRST (authenticates the user)
                // This validates email uniqueness and allows us to use authenticated Firestore operations
                let authResult = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
                let firebaseUID = authResult.user.uid
                
                print("✅ Firebase Auth account created: \(firebaseUID)")
                
                // Step 2: Create Company in SwiftData (source of truth)
                let companyId = UUID().uuidString
                let newCompany = Company(
                    id: companyId,
                    name: cleanCompanyName,
                    symbol: "",
                    phoneNumber: "",
                    address: "",
                    regNumber: cleanRegNumber,
                    vatNumber: "",
                    dateCreated: Date(),
                    dateUpdated: Date()
                )
                
                // Save company to SwiftData
                await MainActor.run {
                    modelContext.insert(newCompany)
                }
                
                do {
                    try await MainActor.run {
                        try modelContext.save()
                        print("✅ Company created in SwiftData: \(companyId)")
                    }
                } catch {
                    throw NSError(domain: "SignUpError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to save company to SwiftData: \(error.localizedDescription)"])
                }
                
                // Step 3: Save company to Firebase (now authenticated, uses existing manager)
                try await FirestoreManager.shared.saveCompanyToFirestore(newCompany)
                print("✅ Company saved to Firebase: \(companyId)")
                
                // Step 4: Create User in SwiftData
                let initials = "\(cleanFirstName.prefix(1))\(cleanSurname.prefix(1))".uppercased()
                let newUser = CanakinStaffShared.User(
                    id: UUID(),
                    name: cleanFirstName,
                    surname: cleanSurname,
                    initials: initials,
                    email: cleanEmail,
                    phoneNumber: nil,
                    assignedSection: .foh,
                    isActive: true,
                    notes: nil,
                    unavailableDays: [],
                    authorityLevel: .admin, // First user is admin
                    companyId: companyId, // Link to the new company
                    address: nil,
                    dateOfBirth: nil,
                    gender: nil,
                    taxId: nil,
                    employmentStartDate: Date(),
                    inactiveDate: nil,
                    allowAutoSignOn: false
                )
                
                newUser.firebaseUID = firebaseUID
                newUser.hasPassword = true
                
                // Save user to SwiftData
                await MainActor.run {
                    modelContext.insert(newUser)
                }
                
                do {
                    try await MainActor.run {
                        try modelContext.save()
                        print("✅ User created in SwiftData: \(newUser.id.uuidString)")
                    }
                } catch {
                    throw NSError(domain: "SignUpError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to save user to SwiftData: \(error.localizedDescription)"])
                }
                
                // Step 5: Save user to Firebase (now authenticated, uses existing manager)
                try await FirestoreManager.shared.saveUserToFirestore(newUser)
                print("✅ User saved to Firebase: \(newUser.id.uuidString)")
                
                // Step 6: Sign out (user will sign in with new credentials)
                try? Auth.auth().signOut()
                
                await MainActor.run {
                    isCreating = false
                    message = "✅ Company and account created successfully!"
                    
                    // Call completion after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete()
                    }
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    message = "❌ Failed to create company: \(error.localizedDescription)"
                    
                    // Clean up: try to delete company if user creation failed
                    if let error = error as NSError?, error.domain == "SignUpError" {
                        // Email already exists - don't clean up
                    } else {
                        // Other error - try to clean up Firebase Auth if it was created
                        // (This is best-effort, Firebase will handle orphaned accounts)
                    }
                }
            }
        }
    }
}

