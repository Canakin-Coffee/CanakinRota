import Foundation
import os
import FirebaseFirestore
import SwiftData
import FirebaseAuth
import CanakinStaffShared

/// Employment-settings-only Firestore sync for CanakinRota (rota subset of CanakinCafe).
class RotaFirestoreSettingsManager {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    func saveEmploymentSettingsToFirestore(_ settings: EmploymentSettings) async throws {
        guard auth.currentUser != nil else {
            throw FirestoreManager.FirestoreError.notAuthenticated
        }

        let dto = FirebaseEmploymentSettingsDTO(from: settings)
        try await db.collection("employmentSettings").document(settings.id).setData(dto.toFirestoreData(), merge: true)
        AppLog.sync.info("Employment settings saved to Firestore: \(settings.id)")
    }

    func fetchEmploymentSettingsFromFirestore(settingsId: String) async throws -> EmploymentSettings? {
        guard auth.currentUser != nil else {
            throw FirestoreManager.FirestoreError.notAuthenticated
        }

        let document = try await db.collection("employmentSettings").document(settingsId).getDocument()
        guard document.exists, let data = document.data() else { return nil }
        guard let dto = FirebaseEmploymentSettingsDTO.fromFirestoreData(data, documentId: document.documentID) else {
            return nil
        }
        return dto.toEmploymentSettings()
    }

    private func fetchAllEmploymentSettingsFromFirestore() async throws -> [EmploymentSettings] {
        guard auth.currentUser != nil else {
            throw FirestoreManager.FirestoreError.notAuthenticated
        }

        guard let companyId = CompanyContext.shared.currentCompany?.id else {
            AppLog.sync.warning("No company ID available, returning empty employment settings")
            return []
        }

        let filteredSnapshot = try await db.collection("employmentSettings")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()

        var documents = filteredSnapshot.documents

        if documents.isEmpty {
            let legacyDoc = try await db.collection("employmentSettings").document("default").getDocument()
            if legacyDoc.exists, let data = legacyDoc.data(),
               let dto = FirebaseEmploymentSettingsDTO.fromFirestoreData(data, documentId: legacyDoc.documentID) {
                let settings = dto.toEmploymentSettings()
                settings.companyId = companyId
                try await saveEmploymentSettingsToFirestore(settings)
                return [settings]
            }
        }

        return documents.compactMap { document in
            guard let dto = FirebaseEmploymentSettingsDTO.fromFirestoreData(document.data(), documentId: document.documentID) else {
                return nil
            }
            return dto.toEmploymentSettings()
        }
    }

    @MainActor
    func syncDataFromFirestore(modelContext: ModelContext) async {
        do {
            let fetchedEmploymentSettings = try await fetchAllEmploymentSettingsFromFirestore()
            handleEmploymentSettingsUpdate(fetchedEmploymentSettings, modelContext: modelContext)
        } catch {
            AppLog.sync.error("Failed to sync employment settings", error: error)
        }
    }

    func setupRealTimeListeners(modelContext: ModelContext) {}

    func stopListeners() {}

    @MainActor
    private func handleEmploymentSettingsUpdate(_ firebaseSettings: [EmploymentSettings], modelContext: ModelContext) {
        let descriptor = FetchDescriptor<EmploymentSettings>()
        let existingSettings = (try? modelContext.fetch(descriptor)) ?? []

        var hasChanges = false

        for firebaseSetting in firebaseSettings {
            if let existingSetting = existingSettings.first(where: { $0.id == firebaseSetting.id }) {
                if updateEmploymentSettingsIfChanged(existingSetting, with: firebaseSetting) {
                    hasChanges = true
                }
            } else {
                modelContext.insert(firebaseSetting)
                hasChanges = true
            }
        }

        if hasChanges {
            try? modelContext.save()
        }
    }

    private func updateEmploymentSettingsIfChanged(_ existing: EmploymentSettings, with new: EmploymentSettings) -> Bool {
        var hasChanges = false

        if existing.employerNIRate != new.employerNIRate { existing.employerNIRate = new.employerNIRate; hasChanges = true }
        if existing.niThresholdPerYear != new.niThresholdPerYear { existing.niThresholdPerYear = new.niThresholdPerYear; hasChanges = true }
        if existing.weeksPerYear != new.weeksPerYear { existing.weeksPerYear = new.weeksPerYear; hasChanges = true }
        if existing.standardWeeklyHours != new.standardWeeklyHours { existing.standardWeeklyHours = new.standardWeeklyHours; hasChanges = true }
        if existing.annualHolidayAllocation != new.annualHolidayAllocation { existing.annualHolidayAllocation = new.annualHolidayAllocation; hasChanges = true }
        if existing.holidayYearStartMonth != new.holidayYearStartMonth { existing.holidayYearStartMonth = new.holidayYearStartMonth; hasChanges = true }
        if existing.holidayYearStartDay != new.holidayYearStartDay { existing.holidayYearStartDay = new.holidayYearStartDay; hasChanges = true }
        if existing.minimumHourlyWage != new.minimumHourlyWage { existing.minimumHourlyWage = new.minimumHourlyWage; hasChanges = true }
        if existing.minimumHourlyWageHistoryData != new.minimumHourlyWageHistoryData { existing.minimumHourlyWageHistoryData = new.minimumHourlyWageHistoryData; hasChanges = true }
        if existing.defaultShiftStartHour != new.defaultShiftStartHour { existing.defaultShiftStartHour = new.defaultShiftStartHour; hasChanges = true }
        if existing.defaultShiftStartMinute != new.defaultShiftStartMinute { existing.defaultShiftStartMinute = new.defaultShiftStartMinute; hasChanges = true }
        if existing.defaultShiftEndHour != new.defaultShiftEndHour { existing.defaultShiftEndHour = new.defaultShiftEndHour; hasChanges = true }
        if existing.defaultShiftEndMinute != new.defaultShiftEndMinute { existing.defaultShiftEndMinute = new.defaultShiftEndMinute; hasChanges = true }
        if existing.updatedAt != new.updatedAt { existing.updatedAt = new.updatedAt; hasChanges = true }
        if existing.companyId != new.companyId { existing.companyId = new.companyId; hasChanges = true }

        return hasChanges
    }
}
