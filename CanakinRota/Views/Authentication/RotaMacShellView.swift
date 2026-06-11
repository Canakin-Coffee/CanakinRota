import SwiftUI
import SwiftData
import FirebaseAuth
import CanakinStaffShared

struct RotaMacShellView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authorityManager: AuthorityManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @Query(sort: [SortDescriptor(\CanakinStaffShared.User.name)]) private var users: [CanakinStaffShared.User]

    var body: some View {
        NavigationStack {
            Group {
                if authorityManager.isAuthenticated, let user = authorityManager.currentUser {
                    RotaMenuView()
                        .id(user.id)
                } else {
                    SignInView()
                        .navigationBarHidden(true)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await endPersistedSessionOnLaunch()
        }
        .onChange(of: authorityManager.currentUser) { _, newValue in
            print("🖥️ [Mac] Current user changed to: \(newValue?.name ?? "nil")")
        }
        .onChange(of: authorityManager.isAuthenticated) { _, newValue in
            print("🖥️ [Mac] Authentication state changed: \(newValue)")
        }
    }

    /// Firebase persists auth in the keychain across debug rebuilds — always require sign-in on launch.
    private func endPersistedSessionOnLaunch() async {
        let hasFirebaseSession = Auth.auth().currentUser != nil
        let hasLocalSession = authorityManager.isAuthenticated || authorityManager.currentUser != nil

        guard hasFirebaseSession || hasLocalSession else {
            print("🖥️ [Mac] Cold launch — no persisted session")
            return
        }

        print("🖥️ [Mac] Cold launch — ending persisted session (Firebase: \(hasFirebaseSession))")
        await MainActor.run {
            authorityManager.endSessionOnRelaunch()
            firebaseManager.setAuthenticated(false)
        }
    }
}
