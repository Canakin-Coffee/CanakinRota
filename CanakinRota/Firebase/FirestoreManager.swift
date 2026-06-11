import Foundation
import os
import Combine
import FirebaseFirestore
import SwiftData
import FirebaseAuth
import CanakinStaffShared

/// Rota-only Firestore coordinator (shared Firebase project with CanakinCafe).
class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Published var isLoading = false
    @Published var errorMessage: String?

    let userManager = StaffFirestoreService.shared.userManager
    let settingsManager = RotaFirestoreSettingsManager()
    let roleManager = StaffFirestoreService.shared.roleManager
    let shiftManager = StaffFirestoreService.shared.shiftManager
    private let authorityPermissionManager = StaffFirestoreService.shared.authorityPermissionManager

    private init() {}

    var currentUser: FirebaseAuth.User? { auth.currentUser }
    var isAuthenticated: Bool { auth.currentUser != nil }

    func setupRealTimeListeners(modelContext: ModelContext) {
        userManager.setupRealTimeListeners(modelContext: modelContext)
        settingsManager.setupRealTimeListeners(modelContext: modelContext)
        roleManager.setupRealTimeListeners(modelContext: modelContext)
        shiftManager.setupRealTimeListeners(modelContext: modelContext)
        authorityPermissionManager.setupRealTimeListeners(modelContext: modelContext)
    }

    func stopAllListeners() {
        userManager.stopListeners()
        settingsManager.stopListeners()
        roleManager.stopListeners()
        shiftManager.stopListeners()
        authorityPermissionManager.stopListeners()
    }

    func loadAllDataForCompany(modelContext: ModelContext, skipCompanies: Bool = false, skipUsers: Bool = false) async {
        AppLog.sync.info("SYNC: Starting loadAllDataForCompany (rota)...")

        if !skipCompanies {
            await syncCompanies(modelContext: modelContext)
        }
        if !skipUsers {
            await syncUsers(modelContext: modelContext)
        }

        await loadRotaEssentialsForCompany(modelContext: modelContext)
        await syncShifts(modelContext: modelContext)

        AppLog.sync.info("SYNC: loadAllDataForCompany complete")
    }

    /// Fast path for sign-in: roles, settings, and schedule only (shifts load separately).
    func loadRotaEssentialsForCompany(modelContext: ModelContext) async {
        AppLog.sync.info("SYNC: Starting loadRotaEssentialsForCompany...")
        await syncAuthorityLevelPermissions(modelContext: modelContext)
        await syncSettings(modelContext: modelContext)
        await syncRoles(modelContext: modelContext)
        await syncWeeklySchedule(modelContext: modelContext)
        AppLog.sync.info("SYNC: loadRotaEssentialsForCompany complete")
    }

    func syncAuthorityLevelPermissions(modelContext: ModelContext) async {
        await authorityPermissionManager.syncDataFromFirestore(modelContext: modelContext)
    }

    func saveAuthorityLevelPermissionToFirestore(_ record: AuthorityLevelPermission) async throws {
        try await authorityPermissionManager.saveAuthorityLevelPermissionToFirestore(record)
    }

    func syncShifts(modelContext: ModelContext) async {
        await shiftManager.syncDataFromFirestore(modelContext: modelContext)
    }

    func syncUsers(modelContext: ModelContext) async {
        await userManager.syncDataFromFirestore(modelContext: modelContext)
    }

    private func syncSettings(modelContext: ModelContext) async {
        await settingsManager.syncDataFromFirestore(modelContext: modelContext)
    }

    private func syncRoles(modelContext: ModelContext) async {
        await roleManager.syncDataFromFirestore(modelContext: modelContext)
    }

    
    @MainActor
    func syncCompanies(modelContext: ModelContext) async {
        do {
            print("🔥 Loading companies from Firebase...")
            let companies = try await loadCompaniesFromFirestore()
            
            // Use FetchDescriptor to get existing companies
            let descriptor = FetchDescriptor<Company>()
            let existingCompanies = (try? modelContext.fetch(descriptor)) ?? []
            let existingCompaniesById = Dictionary(uniqueKeysWithValues: existingCompanies.map { ($0.id, $0) })
            
            var hasChanges = false
            var updatedCount = 0
            var insertedCount = 0
            
            for company in companies {
                if let existingCompany = existingCompaniesById[company.id] {
                    // Update existing company only if fields have changed
                    var companyChanged = false
                    if existingCompany.name != company.name { existingCompany.name = company.name; companyChanged = true }
                    if existingCompany.symbol != company.symbol { existingCompany.symbol = company.symbol; companyChanged = true }
                    if existingCompany.phoneNumber != company.phoneNumber { existingCompany.phoneNumber = company.phoneNumber; companyChanged = true }
                    if existingCompany.address != company.address { existingCompany.address = company.address; companyChanged = true }
                    if existingCompany.regNumber != company.regNumber { existingCompany.regNumber = company.regNumber; companyChanged = true }
                    if existingCompany.vatNumber != company.vatNumber { existingCompany.vatNumber = company.vatNumber; companyChanged = true }
                    if existingCompany.dateCreated != company.dateCreated { existingCompany.dateCreated = company.dateCreated; companyChanged = true }
                    if existingCompany.dateUpdated != company.dateUpdated { existingCompany.dateUpdated = company.dateUpdated; companyChanged = true }
                    
                    if companyChanged {
                        hasChanges = true
                        updatedCount += 1
                    }
                } else {
                    // Insert new company
                    modelContext.insert(company)
                    hasChanges = true
                    insertedCount += 1
                }
            }
            
            if hasChanges {
                do {
                    try modelContext.save()
                    print("✅ Companies synchronized: \(insertedCount) inserted, \(updatedCount) updated")
                } catch {
                    print("❌ Failed to save companies: \(error.localizedDescription)")
                }
            } else {
                print("✅ Companies synchronized: No changes (\(companies.count) companies already up to date)")
            }
        } catch {
            print("❌ Failed to load companies from Firebase: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func syncWeeklySchedule(modelContext: ModelContext) async {
        do {
            async let dayRoleSchedulesTask = fetchAllDayRoleSchedulesFromFirestore()
            async let shiftSlotsTask = fetchAllIndividualShiftSlotsFromFirestore()
            let (dayRoleSchedules, shiftSlots) = try await (dayRoleSchedulesTask, shiftSlotsTask)

            guard let companyId = CompanyContext.shared.currentCompany?.id else {
                AppLog.sync.warning("No company ID available, skipping weekly schedule sync")
                return
            }

            let allSchedules = (try? modelContext.fetch(FetchDescriptor<DayRoleSchedule>())) ?? []
            for schedule in allSchedules where schedule.companyId != companyId {
                modelContext.delete(schedule)
            }

            let scheduleDescriptor = FetchDescriptor<DayRoleSchedule>(
                predicate: #Predicate<DayRoleSchedule> { $0.companyId == companyId }
            )
            let existingSchedules = (try? modelContext.fetch(scheduleDescriptor)) ?? []
            let existingSchedulesById = Dictionary(uniqueKeysWithValues: existingSchedules.map { ($0.id, $0) })
            let firebaseScheduleIds = Set(dayRoleSchedules.map(\.id))
            var hasChanges = !allSchedules.filter { $0.companyId != companyId }.isEmpty

            for firebaseSchedule in dayRoleSchedules {
                if let existingSchedule = existingSchedulesById[firebaseSchedule.id] {
                    if existingSchedule.dayOfWeek != firebaseSchedule.dayOfWeek { existingSchedule.dayOfWeek = firebaseSchedule.dayOfWeek; hasChanges = true }
                    if existingSchedule.roleId != firebaseSchedule.roleId { existingSchedule.roleId = firebaseSchedule.roleId; hasChanges = true }
                    if existingSchedule.totalStaffRequired != firebaseSchedule.totalStaffRequired { existingSchedule.totalStaffRequired = firebaseSchedule.totalStaffRequired; hasChanges = true }
                    if existingSchedule.shiftSlotIdsData != firebaseSchedule.shiftSlotIdsData { existingSchedule.shiftSlotIdsData = firebaseSchedule.shiftSlotIdsData; hasChanges = true }
                    if existingSchedule.companyId != firebaseSchedule.companyId { existingSchedule.companyId = firebaseSchedule.companyId; hasChanges = true }
                } else {
                    modelContext.insert(firebaseSchedule)
                    hasChanges = true
                }
            }

            for scheduleToDelete in existingSchedules where !firebaseScheduleIds.contains(scheduleToDelete.id) {
                modelContext.delete(scheduleToDelete)
                hasChanges = true
            }

            let allSlots = (try? modelContext.fetch(FetchDescriptor<IndividualShiftSlot>())) ?? []
            for slot in allSlots where slot.companyId != companyId {
                modelContext.delete(slot)
            }

            let slotDescriptor = FetchDescriptor<IndividualShiftSlot>(
                predicate: #Predicate<IndividualShiftSlot> { $0.companyId == companyId }
            )
            let existingSlots = (try? modelContext.fetch(slotDescriptor)) ?? []
            let existingSlotsById = Dictionary(uniqueKeysWithValues: existingSlots.map { ($0.id, $0) })
            let firebaseSlotIds = Set(shiftSlots.map(\.id))

            for firebaseSlot in shiftSlots {
                if let existingSlot = existingSlotsById[firebaseSlot.id] {
                    if existingSlot.dayRoleScheduleId != firebaseSlot.dayRoleScheduleId { existingSlot.dayRoleScheduleId = firebaseSlot.dayRoleScheduleId; hasChanges = true }
                    if existingSlot.slotNumber != firebaseSlot.slotNumber { existingSlot.slotNumber = firebaseSlot.slotNumber; hasChanges = true }
                    if existingSlot.startHour != firebaseSlot.startHour { existingSlot.startHour = firebaseSlot.startHour; hasChanges = true }
                    if existingSlot.startMinute != firebaseSlot.startMinute { existingSlot.startMinute = firebaseSlot.startMinute; hasChanges = true }
                    if existingSlot.endHour != firebaseSlot.endHour { existingSlot.endHour = firebaseSlot.endHour; hasChanges = true }
                    if existingSlot.endMinute != firebaseSlot.endMinute { existingSlot.endMinute = firebaseSlot.endMinute; hasChanges = true }
                    if existingSlot.isActive != firebaseSlot.isActive { existingSlot.isActive = firebaseSlot.isActive; hasChanges = true }
                    if existingSlot.notes != firebaseSlot.notes { existingSlot.notes = firebaseSlot.notes; hasChanges = true }
                    if existingSlot.companyId != firebaseSlot.companyId { existingSlot.companyId = firebaseSlot.companyId; hasChanges = true }
                } else {
                    modelContext.insert(firebaseSlot)
                    hasChanges = true
                }
            }

            for slotToDelete in existingSlots where !firebaseSlotIds.contains(slotToDelete.id) {
                modelContext.delete(slotToDelete)
                hasChanges = true
            }

            if hasChanges {
                try? modelContext.save()
            }
        } catch {
            AppLog.sync.error("Failed to sync weekly schedule", error: error)
        }
    }

    private func fetchAllDayRoleSchedulesFromFirestore() async throws -> [DayRoleSchedule] {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        guard let companyId = CompanyContext.shared.currentCompany?.id else { return [] }

        let snapshot = try await db.collection("dayRoleSchedules")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { return nil }
            let schedule = DayRoleSchedule(
                dayOfWeek: data["dayOfWeek"] as? Int ?? 1,
                roleId: data["roleId"] as? String ?? "",
                totalStaffRequired: data["totalStaffRequired"] as? Int ?? 0,
                companyId: data["companyId"] as? String
            )
            schedule.id = id
            schedule.shiftSlotIdsData = data["shiftSlotIdsData"] as? String ?? "[]"
            return schedule
        }
    }

    private func fetchAllIndividualShiftSlotsFromFirestore() async throws -> [IndividualShiftSlot] {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        guard let companyId = CompanyContext.shared.currentCompany?.id else { return [] }

        let snapshot = try await db.collection("individualShiftSlots")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let idString = data["id"] as? String, let id = UUID(uuidString: idString) else { return nil }
            let slot = IndividualShiftSlot(
                dayRoleScheduleId: data["dayRoleScheduleId"] as? String ?? "",
                slotNumber: data["slotNumber"] as? Int ?? 1,
                startHour: data["startHour"] as? Int ?? 9,
                startMinute: data["startMinute"] as? Int ?? 0,
                endHour: data["endHour"] as? Int ?? 17,
                endMinute: data["endMinute"] as? Int ?? 0,
                isActive: data["isActive"] as? Bool ?? true,
                notes: data["notes"] as? String ?? "",
                companyId: data["companyId"] as? String
            )
            slot.id = id
            return slot
        }
    }

    func getFirestoreDB() -> Firestore { db }
    func getAuth() -> Auth { auth }

    enum FirestoreError: Error, LocalizedError {
        case notAuthenticated
        case invalidData(String)
        case networkError(String)
        case unknownError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "User not authenticated"
            case .invalidData(let message): return "Invalid data: \(message)"
            case .networkError(let message): return "Network error: \(message)"
            case .unknownError(let message): return "Unknown error: \(message)"
            }
        }
    }
}

// MARK: - Rota API

extension FirestoreManager {
    func saveUserToFirestore(_ user: CanakinStaffShared.User) async throws {
        try await userManager.saveUserToFirestore(user)
    }

    func loadUsersFromFirestore() async throws -> [CanakinStaffShared.User] {
        try await userManager.fetchAllUsersFromFirestore()
    }

    func deleteUserFromFirestore(userId: String) async throws {
        try await userManager.deleteUserFromFirestore(userId: userId)
    }

    func fetchUserFromFirestore(userId: String) async throws -> CanakinStaffShared.User? {
        try await userManager.fetchUserFromFirestore(userId: userId)
    }

    func saveUserRolePriorityToFirestore(_ userRolePriority: UserRolePriority) async throws {
        try await userManager.saveUserRolePriorityToFirestore(userRolePriority)
    }

    func deleteUserRolePriorityFromFirestore(userRolePriorityId: String) async throws {
        try await userManager.deleteUserRolePriorityFromFirestore(userRolePriorityId: userRolePriorityId)
    }

    func saveTimeOffRequestToFirestore(_ timeOffRequest: TimeOffRequest) async throws {
        try await userManager.saveTimeOffRequestToFirestore(timeOffRequest)
    }

    func deleteTimeOffRequestFromFirestore(timeOffRequestId: String) async throws {
        try await userManager.deleteTimeOffRequestFromFirestore(timeOffRequestId: timeOffRequestId)
    }

    func saveRoleToFirestore(_ role: Role) async throws {
        try await roleManager.saveRoleToFirestore(role)
    }

    func deleteRoleFromFirestore(roleId: String) async throws {
        try await roleManager.deleteRoleFromFirestore(roleId: roleId)
    }

    func listenToRoles(completion: @escaping ([Role]) -> Void) -> ListenerRegistration {
        roleManager.listenToRoles(completion: completion)
    }

    func saveShiftToFirestore(_ shift: Shift) async throws {
        try await shiftManager.saveShiftToFirestore(shift)
    }

    func saveShiftsBatchToFirestore(_ shifts: [Shift]) async throws {
        try await shiftManager.saveShiftsBatchToFirestore(shifts)
    }

    func publishShiftsBatch(_ shifts: [Shift]) async throws {
        try await shiftManager.saveShiftsBatchToFirestore(shifts)
    }

    func deleteShiftFromFirestore(shiftId: String) async throws {
        try await shiftManager.deleteShiftFromFirestore(shiftId: shiftId)
    }

    func saveShiftBreakToFirestore(_ shiftBreak: ShiftBreak) async throws {
        try await shiftManager.saveShiftBreakToFirestore(shiftBreak)
    }

    func deleteShiftBreakFromFirestore(shiftBreakId: String) async throws {
        try await shiftManager.deleteShiftBreakFromFirestore(shiftBreakId: shiftBreakId)
    }

    @MainActor
    func removeDuplicateShifts(modelContext: ModelContext) throws {
        try shiftManager.removeDuplicateShifts(modelContext: modelContext)
    }

    func saveEmploymentSettingsToFirestore(_ settings: EmploymentSettings) async throws {
        try await settingsManager.saveEmploymentSettingsToFirestore(settings)
    }

    func fetchEmploymentSettingsFromFirestore(settingsId: String) async throws -> EmploymentSettings? {
        try await settingsManager.fetchEmploymentSettingsFromFirestore(settingsId: settingsId)
    }

    func fetchEmploymentSettingsFromFirestore(companyId: String) async throws -> EmploymentSettings? {
        _ = companyId
        return try await settingsManager.fetchEmploymentSettingsFromFirestore(settingsId: "default")
    }

    func listenToEmploymentSettings(completion: @escaping ([EmploymentSettings]) -> Void) -> ListenerRegistration {
        db.collection("employmentSettings").addSnapshotListener { snapshot, _ in
            let settings = snapshot?.documents.compactMap { doc -> EmploymentSettings? in
                FirebaseEmploymentSettingsDTO.fromFirestoreData(doc.data(), documentId: doc.documentID)?.toEmploymentSettings()
            } ?? []
            completion(settings)
        }
    }

    func saveCompanyToFirestore(_ company: Company) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }

        let companyData: [String: Any] = [
            "id": company.id,
            "name": company.name,
            "symbol": company.symbol,
            "phoneNumber": company.phoneNumber,
            "address": company.address,
            "regNumber": company.regNumber,
            "vatNumber": company.vatNumber,
            "dateCreated": Timestamp(date: company.dateCreated),
            "dateUpdated": Timestamp(date: company.dateUpdated)
        ]

        try await db.collection("companies").document(company.id).setData(companyData, merge: true)
        AppLog.sync.info("Company saved to Firestore: \(company.name)")
    }

    func loadCompaniesFromFirestore() async throws -> [Company] {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        let snapshot = try await db.collection("companies").getDocuments()
        return snapshot.documents.compactMap { createCompanyFromFirestoreData($0.data()) }
    }

    private func createCompanyFromFirestoreData(_ data: [String: Any]) -> Company {
        Company(
            id: data["id"] as? String ?? UUID().uuidString,
            name: data["name"] as? String ?? "Unknown Company",
            symbol: data["symbol"] as? String ?? data["code"] as? String ?? "",
            phoneNumber: data["phoneNumber"] as? String ?? "",
            address: data["address"] as? String ?? "",
            regNumber: data["regNumber"] as? String ?? "",
            vatNumber: data["vatNumber"] as? String ?? "",
            dateCreated: (data["dateCreated"] as? Timestamp)?.dateValue() ?? (data["createdDate"] as? Timestamp)?.dateValue() ?? Date(),
            dateUpdated: (data["dateUpdated"] as? Timestamp)?.dateValue() ?? (data["updatedDate"] as? Timestamp)?.dateValue() ?? Date()
        )
    }

    func saveShiftSelectionConfigToFirestore(_ shiftSelectionConfig: ShiftSelectionConfig) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        guard let companyId = CompanyContext.shared.currentCompany?.id else {
            throw FirestoreError.invalidData("No company selected")
        }

        let data: [String: Any] = [
            "id": shiftSelectionConfig.id.uuidString,
            "companyId": companyId,
            "name": shiftSelectionConfig.name,
            "isActive": shiftSelectionConfig.isActive,
            "maxWeeklyHours": shiftSelectionConfig.maxWeeklyHours,
            "maxDailyHours": shiftSelectionConfig.maxDailyHours,
            "updatedAt": Timestamp(date: Date())
        ]
        try await db.collection("shiftSelectionConfigs").document(shiftSelectionConfig.id.uuidString).setData(data, merge: true)
    }

    func saveDayRoleScheduleToFirestore(_ dayRoleSchedule: DayRoleSchedule) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        let scheduleData: [String: Any] = [
            "id": dayRoleSchedule.id.uuidString,
            "dayOfWeek": dayRoleSchedule.dayOfWeek ?? 1,
            "roleId": dayRoleSchedule.roleId ?? "",
            "totalStaffRequired": dayRoleSchedule.totalStaffRequired ?? 0,
            "shiftSlotIdsData": dayRoleSchedule.shiftSlotIdsData,
            "companyId": dayRoleSchedule.companyId ?? ""
        ]
        try await getFirestoreDB().collection("dayRoleSchedules").document(dayRoleSchedule.id.uuidString).setData(scheduleData, merge: true)
    }

    func saveIndividualShiftSlotToFirestore(_ individualShiftSlot: IndividualShiftSlot) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        let slotData: [String: Any] = [
            "id": individualShiftSlot.id.uuidString,
            "dayRoleScheduleId": individualShiftSlot.dayRoleScheduleId,
            "slotNumber": individualShiftSlot.slotNumber,
            "startHour": individualShiftSlot.startHour,
            "startMinute": individualShiftSlot.startMinute,
            "endHour": individualShiftSlot.endHour,
            "endMinute": individualShiftSlot.endMinute,
            "isActive": individualShiftSlot.isActive,
            "notes": individualShiftSlot.notes,
            "companyId": individualShiftSlot.companyId ?? ""
        ]
        try await getFirestoreDB().collection("individualShiftSlots").document(individualShiftSlot.id.uuidString).setData(slotData, merge: true)
    }

    func deleteDayRoleScheduleFromFirestore(dayRoleScheduleId: String) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        try await getFirestoreDB().collection("dayRoleSchedules").document(dayRoleScheduleId).delete()
    }

    func deleteIndividualShiftSlotFromFirestore(shiftSlotId: String) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        try await getFirestoreDB().collection("individualShiftSlots").document(shiftSlotId).delete()
    }

    func claimShift(shiftId: String, claimerUserId: String) async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        try await db.collection("shifts").document(shiftId).setData([
            "userId": claimerUserId,
            "isOfferedForTrade": false,
            "offeredByUserId": FieldValue.delete(),
            "offeredAt": FieldValue.delete()
        ], merge: true)
    }

    func deleteUnpublishedShiftsBatch() async throws {
        guard auth.currentUser != nil else { throw FirestoreError.notAuthenticated }
        guard let companyId = CompanyContext.shared.currentCompany?.id else { return }

        let snapshot = try await db.collection("shifts")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isPublished", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        snapshot.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }
}
