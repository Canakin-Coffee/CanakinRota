import SwiftUI
import SwiftData
import CanakinStaffShared

/// iOS staff shell: sign in, then rota and shift tools.
struct StaffHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authorityManager: AuthorityManager

    var body: some View {
        Group {
            if authorityManager.isAuthenticated, let user = authorityManager.currentUser {
                TabView {
                    UserShiftManagementView(user: user)
                        .tabItem {
                            Label("My Shifts", systemImage: "calendar")
                        }

                    NavigationStack {
                        EnhancedMobileRotaView()
                    }
                    .tabItem {
                        Label("Rota", systemImage: "calendar.badge.clock")
                    }

                    NavigationStack {
                        MyWorkAvailabilityView(user: user)
                    }
                    .tabItem {
                        Label("Availability", systemImage: "calendar.badge.checkmark")
                    }

                    NavigationStack {
                        SettingsTabView(onSignOut: {
                            authorityManager.signOut(modelContext: modelContext)
                        })
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            } else {
                SignInView()
            }
        }
    }
}
