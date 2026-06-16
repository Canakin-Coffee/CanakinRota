import SwiftData
import CanakinStaffShared

enum RotaSchema {
    static let models: [any PersistentModel.Type] = [
        User.self,
        Role.self,
        Shift.self,
        ShiftBreak.self,
        TimeOffRequest.self,
        StaffDayAvailability.self,
        UserRolePriority.self,
        AuthorityLevelPermission.self,
        DayRoleSchedule.self,
        IndividualShiftSlot.self,
        ShiftSelectionConfig.self,
        BusinessRule.self,
        StaffPreference.self,
        Company.self,
        EmploymentSettings.self
    ]
}
