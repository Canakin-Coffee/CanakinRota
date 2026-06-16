import SwiftUI
import CanakinStaffShared

/// iOS staff shell: sign in, then rota and shift tools.
struct StaffHomeView: View {
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

                    TimeTrackerView(user: user)
                        .tabItem {
                            Label("Clock", systemImage: "clock.fill")
                        }

                    NavigationStack {
                        PersonalTimeOffRequestView(user: user)
                    }
                        .tabItem {
                            Label("Time Off", systemImage: "beach.umbrella")
                        }

                    NavigationStack {
                        MyWorkAvailabilityView(user: user)
                    }
                    .tabItem {
                        Label("Availability", systemImage: "calendar.badge.checkmark")
                    }
                }
            } else {
                SignInView()
            }
        }
    }
}
