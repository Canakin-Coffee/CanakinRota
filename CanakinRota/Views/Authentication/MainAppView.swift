import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SwiftData
import CanakinStaffShared

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authorityManager: AuthorityManager
    @EnvironmentObject private var companyContext: CompanyContext
    @State private var isLoading = false  // Start as false so UI appears immediately
    @State private var companyExists = false
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    // Company creation states
    @State private var showCompanyForm = false
    @State private var companyName = ""
    @State private var isCreatingCompany = false
    @State private var companySetupStep = ""
    
    // User management states
    @State private var showUserForm = false
    @State private var userFirstName = ""
    @State private var userSurname = ""
    @State private var userEmail = ""
    @State private var isCreatingUser = false
    @State private var currentSetupStep = ""
    
    // Setup completion state
    @State private var setupComplete = false
    @State private var authenticationComplete = false
    @State private var hasCheckedUsers = false
    @State private var isCheckingUsers = false
    
    // Firebase manager
    private let firebaseManager = FirebaseManager.shared
    
    // Employment settings store
    @StateObject private var employmentStore = EmploymentSettingsStore.shared
    
    // Notification center for logout handling
    private let notificationCenter = NotificationCenter.default
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Checking Firebase for company data...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if companyExists && !authenticationComplete {
                // Company exists – either prompt for System Owner creation, or show Sign In if users exist
                if showUserForm {
                    userCreationForm
                } else if setupComplete {
                    // Users exist – proceed to Sign In screen
                    SignInView()
                        .onReceive(authorityManager.$isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                authenticationComplete = true
                            }
                        }
                        .task {
                            // Check if Firebase has an active session (user backgrounded the app)
                            // This preserves login when app is suspended, but doesn't auto-fill credentials on cold launch
                            // Use .task instead of .onAppear to ensure async execution doesn't block UI
                            // Small delay to allow UI to render first
                            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                            if Auth.auth().currentUser != nil && !authenticationComplete {
                                loadAuthenticatedUser()
                            }
                        }
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Company found. Checking for users...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .onAppear {
                        if !hasCheckedUsers && !isCheckingUsers {
                            hasCheckedUsers = true
                            checkForUsers()
                        }
                    }
                }
            } else if companyExists && authenticationComplete {
                // Setup complete and authenticated - show main app
                RotaMacShellView()
            } else if showError {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Error")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await checkCompanyFile()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if companyExists {
                if showUserForm {
                    // User creation form
                    userCreationForm
                } else {
                    // Company exists - automatically check for users
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Company found. Checking for users...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .onAppear {
                        // Guarded check to avoid loops/repeats
                        if !hasCheckedUsers && !isCheckingUsers {
                            hasCheckedUsers = true
                            checkForUsers()
                        }
                    }
                }
            } else if showCompanyForm {
                // Company creation form
                companyCreationForm
            } else {
                // No company found - automatically show creation form
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("No company found. Setting up first-time configuration...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    // Automatically show company form
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showCompanyForm = true
                    }
                }
            }
        }
        .task {
            // Use .task instead of .onAppear to ensure async execution doesn't block UI
            await checkCompanyFile()
        }
        .onReceive(notificationCenter.publisher(for: .didRequestLogout)) { _ in
            handleLogoutRequest()
        }
    }
    

    
    private var userCreationForm: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Create System Owner")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please enter the System Owner's details. A secure password will be generated and sent to their email.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                TextField("First Name", text: $userFirstName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Surname", text: $userSurname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                TextField("Email Address", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                Text("A secure password will be generated and sent to the email address above.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            
            if isCreatingUser {
                ProgressView(currentSetupStep.isEmpty ? "Creating System Owner..." : currentSetupStep)
                    .padding()
            } else {
                HStack(spacing: 15) {
                    Button("Cancel") {
                        showUserForm = false
                        resetUserForm()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Create System Owner") {
                        createUser()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             userSurname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
    }
    
    private var companyCreationForm: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Create Company")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please enter your company details:")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                TextField("Company Name", text: $companyName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Text("You can add additional company details later in the settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            
            if isCreatingCompany {
                ProgressView(companySetupStep.isEmpty ? "Creating company..." : companySetupStep)
                    .padding()
            } else {
                HStack(spacing: 15) {
                    Button("Cancel") {
                        showCompanyForm = false
                        resetForm()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Create Company") {
                        createCompany()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
    }
    
    private func loadAuthenticatedUser() {
        Task {
            guard let firebaseUser = Auth.auth().currentUser else {
                return
            }
            
            print("🔐 MAINAPP: Found existing Firebase session for: \(firebaseUser.email ?? "unknown")")
            
            do {
                // Find user document by email
                let db = Firestore.firestore()
                let userQuery = db.collection("users").whereField("email", isEqualTo: firebaseUser.email ?? "")
                let userQuerySnapshot = try await userQuery.getDocuments()
                
                if !userQuerySnapshot.documents.isEmpty {
                    let userDoc = userQuerySnapshot.documents.first!
                    let userData = userDoc.data()
                    
                    // Check if this user has auto-sign-on enabled (for testing/development)
                    let allowAutoSignOn = userData["allowAutoSignOn"] as? Bool ?? false
                    
                    if !allowAutoSignOn {
                        // User does not have auto-sign-on enabled - sign them out and show login screen
                        // Do this asynchronously to avoid blocking launch
                        print("🔒 MAINAPP: User does not have allowAutoSignOn - signing out (requires manual login)")
                        Task { @MainActor in
                            // Small delay to allow UI to render first
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            try? Auth.auth().signOut()
                        }
                        return
                    }
                    
                    print("✅ MAINAPP: User has allowAutoSignOn enabled - proceeding with auto-login")
                    
                    // User has allowAutoSignOn enabled - proceed with auto-login
                    
                    // Create User object from Firebase data
                    let user = CanakinStaffShared.User(
                        name: userData["name"] as? String ?? "",
                        surname: userData["surname"] as? String ?? "",
                        initials: userData["initials"] as? String ?? "",
                        email: userData["email"] as? String ?? "",
                        phoneNumber: userData["phoneNumber"] as? String,
                        assignedSection: UserSection(rawValue: userData["assignedSection"] as? String ?? "foh") ?? .foh,
                        isActive: userData["isActive"] as? Bool ?? true,
                        notes: userData["notes"] as? String,
                        unavailableDays: [],
                        userColor: userData["userColor"] as? String,
                        authorityLevel: UserAuthorityLevel(rawValue: userData["authorityLevel"] as? String ?? "staff") ?? .staff,
                        companyId: userData["companyId"] as? String,
                        address: userData["address"] as? String,
                        dateOfBirth: (userData["dateOfBirth"] as? Timestamp)?.dateValue(),
                        gender: userData["gender"] as? String,
                        taxId: userData["taxId"] as? String,
                        employmentStartDate: (userData["employmentStartDate"] as? Timestamp)?.dateValue(),
                        inactiveDate: (userData["inactiveDate"] as? Timestamp)?.dateValue(),
                        allowAutoSignOn: userData["allowAutoSignOn"] as? Bool ?? false
                    )
                    
                    // Set the Swift UUID from Firebase data
                    if let swiftIdString = userData["id"] as? String, let swiftId = UUID(uuidString: swiftIdString) {
                        user.id = swiftId
                    }
                    
                    // Set additional properties
                    user.hasPassword = userData["hasPassword"] as? Bool ?? true
                    user.firebaseUID = firebaseUser.uid
                    user.customPermissionsData = userData["customPermissionsData"] as? String
                    user.annualHolidayAllocation = userData["annualHolidayAllocation"] as? Int ?? 28
                    user.holidayDaysTaken = userData["holidayDaysTaken"] as? Int ?? 0
                    
                    if let holidayYearStartDate = userData["holidayYearStartDate"] as? Timestamp {
                        user.holidayYearStartDate = holidayYearStartDate.dateValue()
                    }
                    
                    // CRITICAL: Must set up Firebase sync for already-authenticated users
                    print("🔧 MAINAPP: Setting up Firebase sync for authenticated user: \(user.name)")
                    firebaseManager.setAuthenticated(true)
                    firebaseManager.setModelContext(modelContext)
                    
                    // Sign in user immediately to show UI
                    await MainActor.run {
                        authorityManager.signIn(user: user, modelContext: modelContext)
                        authenticationComplete = true
                    }
                    
                    print("✅ MAINAPP: User authenticated, showing UI immediately")
                    
                    // CRITICAL: Load companies and users FIRST, then set company context BEFORE loading other data
                    print("📥 MAINAPP: Loading companies and users first...")
                    await FirestoreManager.shared.syncCompanies(modelContext: modelContext)
                    await FirestoreManager.shared.syncUsers(modelContext: modelContext)
                    
                    // Set company context from user's companyId (CRITICAL for multi-tenant filtering)
                    await MainActor.run {
                        let descriptor = FetchDescriptor<Company>()
                        if let companies = try? modelContext.fetch(descriptor), !companies.isEmpty {
                            if let userCompanyId = user.companyId,
                               let userCompany = companies.first(where: { $0.id == userCompanyId }) {
                                companyContext.setCurrentCompany(userCompany)
                                print("🏢 MAINAPP: Set company context to user's company: \(userCompany.name) (ID: \(userCompanyId))")
                            } else {
                                companyContext.loadCurrentCompanyFromContext(companies)
                                print("⚠️ MAINAPP: User has no companyId, using first company")
                            }
                        }
                    }
                    
                    // Check if database was reset and needs a full sync
                    let databaseWasReset = UserDefaults.standard.bool(forKey: "databaseWasReset")
                    if databaseWasReset {
                        print("⚠️ MAINAPP: Database was reset - performing full data sync from Firebase")
                    }
                    
                    // Perform initial data sync (now that company context is set)
                    // This allows the app to render immediately while data loads progressively
                    Task {
                        print("📥 MAINAPP: Starting initial data sync from Firebase (company context set)...")
                        // Skip companies and users since we already loaded them
                        await FirestoreManager.shared.loadAllDataForCompany(modelContext: modelContext, skipCompanies: true, skipUsers: true)
                        print("✅ MAINAPP: Initial data sync complete")
                        
                        // Clear the database reset flag after successful sync
                        if databaseWasReset {
                            UserDefaults.standard.set(false, forKey: "databaseWasReset")
                            UserDefaults.standard.synchronize()
                            print("✅ MAINAPP: Database reset flag cleared after successful sync")
                        }
                        
                        // NOW start real-time listeners AFTER initial sync completes
                        // Add a small delay to let initial sync settle and prevent duplicate processing
                        print("🔥 MAINAPP: Waiting 2 seconds before starting real-time listeners...")
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        
                        print("🔥 MAINAPP: Starting real-time listeners after initial sync...")
                        await MainActor.run {
                            firebaseManager.startRealTimeSync()
                        }
                        print("✅ MAINAPP: Real-time listeners started")
                    }
                }
            } catch {
                print("❌ MAINAPP: Error loading authenticated user: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkForUsers() {
        Task {
            await MainActor.run { isCheckingUsers = true }
            do {
                let usersSnapshot = try await Firestore.firestore()
                    .collection("users")
                    .limit(to: 1)
                    .getDocuments()
                let usersExist = !usersSnapshot.documents.isEmpty
                
                if !usersExist {
                    await MainActor.run {
                        showUserForm = true
                        setupComplete = false
                    }
                } else {
                    await MainActor.run {
                        setupComplete = true
                        showUserForm = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Error checking for users: \(error.localizedDescription)"
                    showError = true
                }
            }
            await MainActor.run { isCheckingUsers = false }
        }
    }
    
    private func checkCompanyFile() async {
        // Don't set isLoading or block UI - check Firebase status immediately
        
        // Check if Firebase is configured
        guard Auth.auth().app != nil else {
            await MainActor.run {
                errorMessage = "Firebase is not properly configured."
                showError = true
                isLoading = false
            }
            return
        }
        
        // If no current user, show SignInView immediately (no loading, no delay)
        if Auth.auth().currentUser == nil {
            await MainActor.run {
                isLoading = false
                companyExists = true
                setupComplete = true  // Show SignInView immediately
            }
            return
        }
        
        // User is authenticated - briefly show loading while we check setup state
        await MainActor.run {
            isLoading = true
        }
        
        // Small delay to allow UI to update, then check setup
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // User is authenticated - check if they need to complete setup
        await MainActor.run {
            isLoading = false
            companyExists = true
            // Don't set setupComplete here - let checkForUsers() handle it
        }
    }
    

    
    private func createUser() {
        let cleanFirstName = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSurname = userSurname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Set initial progress message
        currentSetupStep = "Creating System Owner..."
        
        guard !cleanFirstName.isEmpty && !cleanSurname.isEmpty && !cleanEmail.isEmpty else {
            return
        }
        
        Task {
            await MainActor.run {
                isCreatingUser = true
            }
            
            do {
                await MainActor.run {
                    currentSetupStep = "Setting up local System Owner profile..."
                }
                
                // STEP 1: Get the company from Firebase to set the companyId
                let companiesSnapshot = try await Firestore.firestore().collection("companies").getDocuments()
                guard let companyDoc = companiesSnapshot.documents.first else {
                    throw NSError(domain: "UserCreationError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No company found in Firebase"])
                }
                
                let companyId = companyDoc.documentID
                
                // Ensure employment settings are loaded before creating user
                await employmentStore.loadFromFirebase()
                
                // STEP 2: Create SwiftData User object FIRST (this is the source of truth)
                let user = CanakinStaffShared.User(
                    name: cleanFirstName,
                    surname: cleanSurname,
                    initials: "\(cleanFirstName.prefix(1))\(cleanSurname.prefix(1))".uppercased(),
                    email: cleanEmail,
                    isActive: true,
                    userColor: UserColorGenerator.generateUniqueColor(),
                    authorityLevel: .admin, // This user gets ADMIN
                    companyId: companyId, // Set the company ID to link to the company
                    employmentStartDate: Date() // Set employment start to now
                )
                
                // Set password-related properties after creation
                user.hasPassword = true
                
                // Update holiday allocation from employment settings if available
                user.updateHolidayAllocationFromEmploymentSettings()
                
                // STEP 3: Add to SwiftData first (this is the source of truth)
                await MainActor.run {
                    modelContext.insert(user)
                    do {
                        try modelContext.save()
                        currentSetupStep = "Local System Owner profile created..."
                    } catch {
                        // Error will be handled below
                    }
                }
                
                // Check if we need to throw an error
                do {
                    try modelContext.save() // Ensure save succeeded
                } catch {
                    throw error
                }
                
                await MainActor.run {
                    currentSetupStep = "Creating Firebase authentication..."
                }
                
                // STEP 4: Try to create Firebase Auth account, handle existing users gracefully
                let firebaseUID: String
                do {
                    firebaseUID = try await FirebaseManager.shared.createAuthAccountForImportedUser(
                        email: cleanEmail,
                        name: "\(cleanFirstName) \(cleanSurname)"
                    )
                    
                    await MainActor.run {
                        currentSetupStep = "Firebase Auth account created!"
                    }
                    
                } catch {
                    let errorDescription = error.localizedDescription.lowercased()
                    if errorDescription.contains("email") && (errorDescription.contains("already") || errorDescription.contains("in use")) {
                        await MainActor.run {
                            currentSetupStep = "User exists - sending password reset..."
                        }
                        
                        do {
                            try await FirebaseManager.shared.resetPassword(email: cleanEmail)
                        } catch {
                            // Continue setup even if password reset fails
                        }
                        
                        firebaseUID = "existing_user_\(UUID().uuidString)"
                        
                        await MainActor.run {
                            currentSetupStep = "Setup continuing with existing account..."
                        }
                        
                    } else {
                        throw error
                    }
                }
                
                // STEP 5: Update the SwiftData user with Firebase UID
                await MainActor.run {
                    user.firebaseUID = firebaseUID
                    do {
                        try modelContext.save()
                    } catch {
                        // Handle error silently
                    }
                }
                
                await MainActor.run {
                    currentSetupStep = "Syncing to Firebase..."
                }
                
                // STEP 6: Sync the SwiftData user to Firebase (SwiftData is source of truth)
                var userData: [String: Any] = [
                    "id": user.id.uuidString,
                    "name": user.name,
                    "surname": user.surname,
                    "email": user.email,
                    "isActive": user.isActive,
                    "hasPassword": user.hasPassword,
                    "authorityLevel": user.authorityLevel?.rawValue ?? "admin",
                    "employmentStartDate": user.employmentStartDate as Any,
                    "userColor": user.userColor ?? "",
                    "annualHolidayAllocation": user.annualHolidayAllocation,
                    "holidayDaysTaken": user.holidayDaysTaken,
                    "holidayYearStartDate": user.holidayYearStartDate,
                    "firebaseUID": firebaseUID,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                // Add non-optional fields
                if !user.initials.isEmpty {
                    userData["initials"] = user.initials
                }
                
                // Add optional fields if they have values
                if let phoneNumber = user.phoneNumber, !phoneNumber.isEmpty {
                    userData["phoneNumber"] = phoneNumber
                }
                if let notes = user.notes, !notes.isEmpty {
                    userData["notes"] = notes
                }
                if let address = user.address, !address.isEmpty {
                    userData["address"] = address
                }
                if let dateOfBirth = user.dateOfBirth {
                    userData["dateOfBirth"] = dateOfBirth as Any
                }
                if let gender = user.gender, !gender.isEmpty {
                    userData["gender"] = gender
                }
                if let taxId = user.taxId, !taxId.isEmpty {
                    userData["taxId"] = taxId
                }
                if let inactiveDate = user.inactiveDate {
                    userData["inactiveDate"] = inactiveDate as Any
                }
                if let customPermissionsData = user.customPermissionsData, !customPermissionsData.isEmpty {
                    userData["customPermissionsData"] = customPermissionsData
                }
                if let companyId = user.companyId, !companyId.isEmpty {
                    userData["companyId"] = companyId
                }
                if let firebaseUID = user.firebaseUID, !firebaseUID.isEmpty {
                    userData["firebaseUID"] = firebaseUID
                }
                if let assignedSection = user.assignedSection?.rawValue {
                    userData["assignedSection"] = assignedSection
                }

                userData["unavailableDaysData"] = user.unavailableDaysData
                
                let userDocRef = Firestore.firestore().collection("users").document(user.id.uuidString)
                try await userDocRef.setData(userData, merge: true)
                
                await addCompanyToSwiftData(companyDoc: companyDoc)

                await MainActor.run {
                    currentSetupStep = "Seeding default reference data..."
                }
                
                // Rota app: no cafe reference-data seeding required

                await MainActor.run {
                    isCreatingUser = false
                    currentSetupStep = "System Owner setup complete!"
                    resetUserForm()
                    showUserForm = false
                    setupComplete = true
                }
                
            } catch {
                await MainActor.run {
                    isCreatingUser = false
                    currentSetupStep = ""
                    
                    // Provide specific guidance based on error type
                    if error.localizedDescription.contains("UserAlreadyExists") {
                        errorMessage = """
                        👤 User Account Already Exists
                        
                        An account with this email already exists in Firebase.
                        A password reset email has been sent to \(cleanEmail).
                        
                        Please:
                        1. Check your email for the password reset link
                        2. Set your password using the link
                        3. Use the 'Sign In' button below to complete setup
                        
                        The app setup is complete - you can now sign in.
                        """
                        // Mark setup as complete since the user can now sign in
                        setupComplete = true
                    } else {
                        errorMessage = "Error creating System Owner: \(error.localizedDescription)"
                    }
                    
                    showError = true
                }
            }
        }
    }
    
    private func createCompany() {
        let cleanName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            return
        }

        Task {
            await MainActor.run {
                isCreatingCompany = true
            }

            do {
                // STEP 1: Create Company in SwiftData first (source of truth)
                let newCompany = Company(
                    id: UUID().uuidString,
                    name: cleanName,
                    symbol: "",
                    phoneNumber: "",
                    address: "",
                    regNumber: "",
                    vatNumber: "",
                    dateCreated: Date(),
                    dateUpdated: Date()
                )

                await MainActor.run {
                    modelContext.insert(newCompany)
                    do { try modelContext.save() } catch { /* handled below */ }
                }

                // STEP 2: Sync to Firestore using the same UUID as document ID
                let companyData: [String: Any] = [
                    "id": newCompany.id,
                    "name": newCompany.name,
                    "symbol": newCompany.symbol,
                    "phoneNumber": newCompany.phoneNumber,
                    "address": newCompany.address,
                    "regNumber": newCompany.regNumber,
                    "vatNumber": newCompany.vatNumber,
                    // Use keys aligned with loader expectations
                    "dateCreated": Timestamp(date: newCompany.dateCreated),
                    "dateUpdated": Timestamp(date: newCompany.dateUpdated)
                ]

                try await Firestore.firestore()
                    .collection("companies")
                    .document(newCompany.id)
                    .setData(companyData, merge: true)

                // Do not seed here. Seeding happens after System Owner creation.

                await MainActor.run {
                    isCreatingCompany = false
                    resetForm()
                    showCompanyForm = false
                    companyExists = true
                }

            } catch {
                await MainActor.run {
                    isCreatingCompany = false
                    errorMessage = "Failed to create company: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func resetForm() {
        companyName = ""
        companySetupStep = ""
    }
    

    
    private func resetUserForm() {
        userFirstName = ""
        userSurname = ""
        userEmail = ""
    }
    
    private func handleSignOut() {
        // Reset all setup states
        isLoading = true
        companyExists = false
        errorMessage = ""
        showError = false
        showCompanyForm = false
        showUserForm = false
        setupComplete = false
        authenticationComplete = false
        hasCheckedUsers = false
        isCheckingUsers = false
        resetForm()
        resetUserForm()
        
        // Restart the setup process
        Task {
            await checkCompanyFile()
        }
    }
    

    
    private func addUserToSwiftData(userData: [String: Any]) async {
        await MainActor.run {
            do {
                // Check if user already exists in SwiftData (by email or Firebase UID)
                let userEmail = userData["email"] as? String ?? ""
                let firebaseUID = userData["firebaseUID"] as? String ?? ""
                
                let descriptor = FetchDescriptor<CanakinStaffShared.User>()
                let allUsers = try modelContext.fetch(descriptor)
                
                let existingUser = allUsers.first { user in
                    user.email.lowercased() == userEmail.lowercased() ||
                    (user.firebaseUID != nil && user.firebaseUID == firebaseUID)
                }
                
                if existingUser != nil {
                    return
                }
                
                // Create new User object from Firebase data
                let user = CanakinStaffShared.User(
                    name: userData["name"] as? String ?? "",
                    surname: userData["surname"] as? String ?? "",
                    initials: userData["initials"] as? String ?? "",
                    email: userData["email"] as? String ?? "",
                    phoneNumber: userData["phoneNumber"] as? String,
                    assignedSection: UserSection(rawValue: userData["assignedSection"] as? String ?? "foh") ?? .foh,
                    isActive: userData["isActive"] as? Bool ?? true,
                    notes: userData["notes"] as? String,
                    unavailableDays: [],
                    userColor: userData["userColor"] as? String,
                    authorityLevel: UserAuthorityLevel(rawValue: userData["authorityLevel"] as? String ?? "staff") ?? .staff,
                    companyId: userData["companyId"] as? String,
                    address: userData["address"] as? String,
                    dateOfBirth: (userData["dateOfBirth"] as? Timestamp)?.dateValue(),
                    gender: userData["gender"] as? String,
                    taxId: userData["taxId"] as? String,
                    employmentStartDate: (userData["employmentStartDate"] as? Timestamp)?.dateValue(),
                    inactiveDate: (userData["inactiveDate"] as? Timestamp)?.dateValue()
                )
                
                // Set the Swift UUID from Firebase data to prevent duplicates
                if let swiftIdString = userData["id"] as? String, let swiftId = UUID(uuidString: swiftIdString) {
                    user.id = swiftId
                }
                
                // Set additional properties that aren't in the initializer
                user.hasPassword = userData["hasPassword"] as? Bool ?? true
                user.annualHolidayAllocation = userData["annualHolidayAllocation"] as? Int ?? 28
                user.holidayDaysTaken = userData["holidayDaysTaken"] as? Int ?? 0
                
                if let holidayYearStartDate = userData["holidayYearStartDate"] as? Timestamp {
                    user.holidayYearStartDate = holidayYearStartDate.dateValue()
                }
                
                // Set Firebase UID if available
                if let firebaseUID = userData["firebaseUID"] as? String {
                    user.firebaseUID = firebaseUID
                }
                
                // Add to model context
                modelContext.insert(user)
                
                // Save to SwiftData
                try modelContext.save()
                
            } catch {
                // Handle error silently in production
            }
        }
    }
    
    private func addCompanyToSwiftData(companyDoc: QueryDocumentSnapshot) async {
        await MainActor.run {
            do {
                let data = companyDoc.data()
                let companyId = companyDoc.documentID
                
                // Check if company already exists in SwiftData
                let descriptor = FetchDescriptor<Company>(
                    predicate: #Predicate<Company> { company in
                        company.id == companyId
                    }
                )
                
                let existingCompanies = try modelContext.fetch(descriptor)
                
                if !existingCompanies.isEmpty {
                    return
                }
                
                // Create new Company object from Firebase data
                let company = Company(
                    id: companyId,
                    name: data["name"] as? String ?? "",
                    symbol: data["symbol"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    regNumber: data["regNumber"] as? String ?? "",
                    vatNumber: data["vatNumber"] as? String ?? "",
                    dateCreated: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    dateUpdated: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                )
                
                // Add to model context
                modelContext.insert(company)
                
                // Save to SwiftData
                try modelContext.save()
                
            } catch {
                // Handle error silently in production
            }
        }
    }
    
    private func handleLogoutRequest() {
        // Reset all setup states to force return to authentication flow
        isLoading = true
        companyExists = false
        errorMessage = ""
        showError = false
        showCompanyForm = false
        showUserForm = false
        setupComplete = false
        authenticationComplete = false
        currentSetupStep = ""
        hasCheckedUsers = false
        isCheckingUsers = false
        resetForm()
        resetUserForm()
        
        // Restart the setup process to force user back to sign-in
        Task {
            await checkCompanyFile()
        }
    }
}

