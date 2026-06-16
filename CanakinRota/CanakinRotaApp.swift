import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CanakinStaffShared
#if os(macOS)
import AppKit
#endif

@main
struct CanakinRotaApp: App {
    let container: ModelContainer

    @StateObject private var alertManager: AlertManager
    @StateObject private var authorityManager: AuthorityManager
    @StateObject private var companyContext: CompanyContext
    @StateObject private var firebaseManager: FirebaseManager
    @StateObject private var roleStore: RoleStore
    @StateObject private var employmentStore: EmploymentSettingsStore

    init() {
        // Must run before any singleton touches Firestore (e.g. FirebaseManager / FirestoreManager).
        Self.configureFirebaseIfNeeded()

        CanakinStaffSharedBridge.configure()

        _alertManager = StateObject(wrappedValue: AlertManager())
        _authorityManager = StateObject(wrappedValue: AuthorityManager.shared)
        _companyContext = StateObject(wrappedValue: CompanyContext.shared)
        _firebaseManager = StateObject(wrappedValue: FirebaseManager.shared)
        _roleStore = StateObject(wrappedValue: RoleStore.shared)
        _employmentStore = StateObject(wrappedValue: EmploymentSettingsStore.shared)

        container = Self.makeModelContainer()
    }

    /// Configures Firebase before Firestore singletons are created.
    private static func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else { return }

        if let options = bundledFirebaseOptions() {
            FirebaseApp.configure(options: options)
        } else if let options = RuntimeFirebaseConfigurator.shared.loadPersistedOptions(),
                  Self.validFirebaseOptions(options) {
            FirebaseApp.configure(options: options)
        } else {
            print("❌ FIREBASE: No valid GoogleService-Info.plist found (missing or empty API_KEY)")
            FirebaseApp.configure()
        }

        #if os(macOS)
        let firestore = Firestore.firestore()
        var firestoreSettings = firestore.settings
        firestoreSettings.isPersistenceEnabled = false
        firestore.settings = firestoreSettings
        #endif
    }

    private static func bundledFirebaseOptions() -> FirebaseOptions? {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            return nil
        }
        return validFirebaseOptions(options) ? options : nil
    }

    private static func validFirebaseOptions(_ options: FirebaseOptions) -> Bool {
        guard let apiKey = options.apiKey, !apiKey.isEmpty else { return false }
        guard let projectID = options.projectID, !projectID.isEmpty else { return false }
        return true
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema(RotaSchema.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            print("DATABASE ERROR: \(error)")

            let errorString = error.localizedDescription.lowercased()
            let isSchemaError = errorString.contains("no such table")
                || errorString.contains("schema")
                || errorString.contains("migration")
                || errorString.contains("couldn't be opened")

            guard isSchemaError else {
                fatalError("Could not create ModelContainer: \(error)")
            }

            print("DATABASE: Schema mismatch detected. Resetting local store...")
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            let relatedURLs = [
                storeURL,
                URL.applicationSupportDirectory.appending(path: "default.store-shm"),
                URL.applicationSupportDirectory.appending(path: "default.store-wal")
            ]
            for url in relatedURLs {
                try? FileManager.default.removeItem(at: url)
            }

            do {
                let container = try ModelContainer(for: schema, configurations: [configuration])
                UserDefaults.standard.set(true, forKey: "databaseWasReset")
                print("DATABASE: Successfully recreated database after reset")
                return container
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootRotaView()
                .environment(\.modelContext, container.mainContext)
                .environmentObject(alertManager)
                .environmentObject(authorityManager)
                .environmentObject(companyContext)
                .environmentObject(firebaseManager)
                .environmentObject(roleStore)
                .environmentObject(employmentStore)
                .onAppear {
                    firebaseManager.setModelContext(container.mainContext)
                    roleStore.setModelContext(container.mainContext)
                    roleStore.setCompanyContext(CompanyContext.shared)
                    #if os(macOS)
                    // End any Firebase keychain session before the shell can auto-restore it.
                    if Auth.auth().currentUser != nil {
                        try? Auth.auth().signOut()
                        authorityManager.endSessionOnRelaunch()
                        firebaseManager.setAuthenticated(false)
                    }
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    #endif
                }
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

struct RootRotaView: View {
    var body: some View {
        #if os(macOS)
        RotaMacShellView()
        #else
        StaffHomeView()
        #endif
    }
}
