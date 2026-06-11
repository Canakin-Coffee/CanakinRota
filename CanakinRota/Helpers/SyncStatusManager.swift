import Foundation
import Combine
import SwiftUI

@MainActor
final class SyncStatusManager: ObservableObject {
    static let shared = SyncStatusManager()

    enum Domain: CaseIterable, Hashable {
        case employmentSettings
        case roles
        case dayRoleSchedules
        case shiftSlots
        case shifts
    }

    @Published private(set) var loadedDomains: Set<Domain> = []
    @Published private(set) var startedAt: Date = Date()
    @Published private(set) var lastActivityAt: Date?
    @Published private(set) var pendingOperations: Int = 0

    var totalDomains: Int { Domain.allCases.count }
    var loadedCount: Int { loadedDomains.count }
    var progress: Double {
        let base = totalDomains == 0 ? 1.0 : Double(loadedCount) / Double(totalDomains)
        if isRotaReady {
            return isBusy ? min(0.95, max(base, 0.9)) : 1.0
        }
        return base
    }

    var isRotaReady: Bool {
        loadedDomains.contains(.employmentSettings) &&
        loadedDomains.contains(.roles) &&
        loadedDomains.contains(.dayRoleSchedules) &&
        loadedDomains.contains(.shifts)
    }

    // Banner visibility logic: show until core ready, then keep a small background period
    var shouldShowBanner: Bool {
        if !isRotaReady { return true }
        // After core ready, keep banner while background activity continues briefly
        let now = Date()
        let recentActivity = (lastActivityAt != nil) ? now.timeIntervalSince(lastActivityAt!) < 8.0 : true
        let withinMaxWindow = now.timeIntervalSince(startedAt) < 25.0
        return (isBusy || recentActivity) && withinMaxWindow
    }

    var isBusy: Bool { pendingOperations > 0 }

    func markLoaded(_ domain: Domain) {
        // Mark as loaded on the main thread to ensure UI updates
        if !loadedDomains.contains(domain) {
            loadedDomains.insert(domain)
        }
    }

    func reset() {
        loadedDomains.removeAll()
        startedAt = Date()
        lastActivityAt = nil
    }

    func noteActivity() {
        lastActivityAt = Date()
    }

    func beginOperation() {
        pendingOperations += 1
        noteActivity()
    }

    func endOperation() {
        pendingOperations = max(0, pendingOperations - 1)
        noteActivity()
    }
}


