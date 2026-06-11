import Foundation
import SwiftData
import SwiftUI
import CanakinStaffShared

enum CanakinStaffSharedBridge {
    @MainActor
    static func configure() {
        CanakinStaffSharedConfig.authService = RotaStaffAuthService.shared
        CanakinStaffSharedConfig.employmentSettingsFirestore = FirestoreManager.shared
        CanakinStaffSharedConfig.stopAdditionalFirebaseListeners = {
            FirestoreManager.shared.stopAllListeners()
            StaffFirestoreService.shared.stopListeners()
        }
        CanakinStaffSharedConfig.clearAdditionalSwiftDataOnLogout = { context in
            try? context.save()
        }
        CanakinStaffSharedConfig.reseedDefaultRoles = { context, _ in
            try await StaffRoleReseeder.reseedRolesPreservingUUIDs(modelContext: context)
        }
        CanakinStaffSharedConfig.userShiftManagementView = { user in
            AnyView(UserShiftManagementView(user: user))
        }
        CanakinStaffSharedConfig.timeTrackerView = { user in
            AnyView(TimeTrackerView(user: user))
        }
        CanakinStaffSharedConfig.timesheetView = { user in
            AnyView(TimesheetView(user: user))
        }
    }
}

@MainActor
extension FirestoreManager: CanakinStaffSharedConfig.EmploymentSettingsFirestoreSyncing {}

@MainActor
final class RotaStaffAuthService: CanakinStaffSharedConfig.StaffAuthService {
    static let shared = RotaStaffAuthService()

    func signOut() throws {
        try FirebaseManager.shared.signOut()
    }

    func resetPassword(email: String) async throws {
        try await FirebaseManager.shared.resetPassword(email: email)
    }

    func createAuthAccountForImportedUser(email: String, name: String) async throws -> String {
        try await FirebaseManager.shared.createAuthAccountForImportedUser(email: email, name: name)
    }
}
