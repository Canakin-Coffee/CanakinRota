import Foundation
import SwiftData
import CanakinStaffShared

/// Dirty-set sync helper for rota entities (roles only in this app).
@MainActor
final class SyncManager {
    static let shared = SyncManager()

    private var dirtyRoleIds = Set<UUID>()

    private init() {}

    func markDirty(role: Role) {
        dirtyRoleIds.insert(role.id)
    }

    func flushNow(context: ModelContext) async {
        guard !dirtyRoleIds.isEmpty else { return }
        let ids = dirtyRoleIds
        dirtyRoleIds.removeAll()

        let descriptor = FetchDescriptor<Role>()
        let roles = (try? context.fetch(descriptor)) ?? []
        for role in roles where ids.contains(role.id) {
            try? await FirestoreManager.shared.saveRoleToFirestore(role)
        }
    }
}
