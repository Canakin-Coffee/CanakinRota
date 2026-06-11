//
import os
//  FirebaseEmploymentSettingsDTO.swift
//  CanakinCafe
//
//  Created by Lee Simmons on 04/04/2025.
//

import Foundation
import FirebaseFirestore
import CanakinStaffShared

struct FirebaseEmploymentSettingsDTO: Codable {
    struct MinimumWageRateEntryDTO: Codable {
        let effectiveFrom: Date
        let rate: Double
    }

    let id: String
    let companyId: String?
    let employerNIRate: Double
    let niThresholdPerYear: Double
    let pensionRate: Double
    let weeksPerYear: Double
    let standardWeeklyHours: Double
    let annualHolidayAllocation: Double
    let holidayAccrualRate: Double
    let holidayYearStartMonth: Int
    let holidayYearStartDay: Int
    let timeOffCountsAllCalendarDays: Bool
    let averageBreakHours: Double
    let minimumHourlyWage: Double
    let minimumHourlyWageHistory: [MinimumWageRateEntryDTO]
    let defaultShiftStartHour: Int
    let defaultShiftStartMinute: Int
    let defaultShiftEndHour: Int
    let defaultShiftEndMinute: Int
    let createdAt: Date
    let updatedAt: Date
    let manuallyAdded: Bool
    
    // Custom initializer for creating from individual values
    init(
        id: String,
        companyId: String?,
        employerNIRate: Double,
        niThresholdPerYear: Double,
        pensionRate: Double = 0.0,
        weeksPerYear: Double,
        standardWeeklyHours: Double,
        annualHolidayAllocation: Double,
        holidayAccrualRate: Double = 0.1207,
        holidayYearStartMonth: Int,
        holidayYearStartDay: Int,
        timeOffCountsAllCalendarDays: Bool = true,
        averageBreakHours: Double = 0.5,
        minimumHourlyWage: Double = 0.0,
        minimumHourlyWageHistory: [MinimumWageRateEntryDTO] = [],
        defaultShiftStartHour: Int,
        defaultShiftStartMinute: Int,
        defaultShiftEndHour: Int,
        defaultShiftEndMinute: Int,
        createdAt: Date,
        updatedAt: Date,
        manuallyAdded: Bool
    ) {
        self.id = id
        self.companyId = companyId
        self.employerNIRate = employerNIRate
        self.niThresholdPerYear = niThresholdPerYear
        self.pensionRate = pensionRate
        self.weeksPerYear = weeksPerYear
        self.standardWeeklyHours = standardWeeklyHours
        self.annualHolidayAllocation = annualHolidayAllocation
        self.holidayAccrualRate = holidayAccrualRate
        self.holidayYearStartMonth = holidayYearStartMonth
        self.holidayYearStartDay = holidayYearStartDay
        self.timeOffCountsAllCalendarDays = timeOffCountsAllCalendarDays
        self.averageBreakHours = averageBreakHours
        self.minimumHourlyWage = minimumHourlyWage
        self.minimumHourlyWageHistory = minimumHourlyWageHistory
        self.defaultShiftStartHour = defaultShiftStartHour
        self.defaultShiftStartMinute = defaultShiftStartMinute
        self.defaultShiftEndHour = defaultShiftEndHour
        self.defaultShiftEndMinute = defaultShiftEndMinute
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.manuallyAdded = manuallyAdded
    }
    
    init(from employmentSettings: EmploymentSettings) {
        self.id = employmentSettings.id
        self.companyId = employmentSettings.companyId
        self.employerNIRate = employmentSettings.employerNIRate
        self.niThresholdPerYear = employmentSettings.niThresholdPerYear
        self.pensionRate = employmentSettings.pensionRate
        self.weeksPerYear = employmentSettings.weeksPerYear
        self.standardWeeklyHours = employmentSettings.standardWeeklyHours
        self.annualHolidayAllocation = employmentSettings.annualHolidayAllocation
        self.holidayAccrualRate = employmentSettings.holidayAccrualRate
        self.holidayYearStartMonth = employmentSettings.holidayYearStartMonth
        self.holidayYearStartDay = employmentSettings.holidayYearStartDay
        self.timeOffCountsAllCalendarDays = employmentSettings.timeOffCountsAllCalendarDays
        self.averageBreakHours = employmentSettings.averageBreakHours
        self.minimumHourlyWage = employmentSettings.minimumHourlyWage
        self.minimumHourlyWageHistory = employmentSettings.minimumHourlyWageHistory.map {
            MinimumWageRateEntryDTO(effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        self.defaultShiftStartHour = employmentSettings.defaultShiftStartHour
        self.defaultShiftStartMinute = employmentSettings.defaultShiftStartMinute
        self.defaultShiftEndHour = employmentSettings.defaultShiftEndHour
        self.defaultShiftEndMinute = employmentSettings.defaultShiftEndMinute
        self.createdAt = employmentSettings.createdAt
        self.updatedAt = employmentSettings.updatedAt
        self.manuallyAdded = employmentSettings.manuallyAdded
    }
    
    func toEmploymentSettings() -> EmploymentSettings {
        let settings = EmploymentSettings(
            id: id,
            employerNIRate: employerNIRate,
            niThresholdPerYear: niThresholdPerYear,
            pensionRate: pensionRate,
            weeksPerYear: weeksPerYear,
            standardWeeklyHours: standardWeeklyHours,
            annualHolidayAllocation: annualHolidayAllocation,
            holidayAccrualRate: holidayAccrualRate,
            holidayYearStartMonth: holidayYearStartMonth,
            holidayYearStartDay: holidayYearStartDay,
            timeOffCountsAllCalendarDays: timeOffCountsAllCalendarDays,
            averageBreakHours: averageBreakHours,
            minimumHourlyWage: minimumHourlyWage,
            defaultShiftStartHour: defaultShiftStartHour,
            defaultShiftStartMinute: defaultShiftStartMinute,
            defaultShiftEndHour: defaultShiftEndHour,
            defaultShiftEndMinute: defaultShiftEndMinute,
            manuallyAdded: manuallyAdded,
            companyId: companyId
        )
        settings.createdAt = createdAt
        settings.updatedAt = updatedAt
        settings.minimumHourlyWageHistory = minimumHourlyWageHistory.map {
            EmploymentSettings.MinimumWageRateEntry(effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        settings.minimumHourlyWage = settings.minimumHourlyWage(on: Date())
        return settings
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "companyId": companyId ?? "",
            "employerNIRate": employerNIRate,
            "niThresholdPerYear": niThresholdPerYear,
            "pensionRate": pensionRate,
            "weeksPerYear": weeksPerYear,
            "standardWeeklyHours": standardWeeklyHours,
            "annualHolidayAllocation": annualHolidayAllocation,
            "holidayAccrualRate": holidayAccrualRate,
            "holidayYearStartMonth": holidayYearStartMonth,
            "holidayYearStartDay": holidayYearStartDay,
            "timeOffCountsAllCalendarDays": timeOffCountsAllCalendarDays,
            "averageBreakHours": averageBreakHours,
            "minimumHourlyWage": minimumHourlyWage,
            "minimumHourlyWageHistory": minimumHourlyWageHistory.map { [
                "effectiveFrom": Timestamp(date: $0.effectiveFrom),
                "rate": $0.rate
            ] },
            "defaultShiftStartHour": defaultShiftStartHour,
            "defaultShiftStartMinute": defaultShiftStartMinute,
            "defaultShiftEndHour": defaultShiftEndHour,
            "defaultShiftEndMinute": defaultShiftEndMinute,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "manuallyAdded": manuallyAdded
        ]
    }
    
    static func fromFirestoreData(_ data: [String: Any], documentId: String) -> FirebaseEmploymentSettingsDTO? {
        guard let id = data["id"] as? String else {
            AppLog.sync.error("Employment Settings: Missing 'id' field in document \(documentId)")
            return nil
        }
        
        // Helper to safely extract Double values (handles both Int and Double)
        func extractDouble(_ key: String) -> Double? {
            if let doubleValue = data[key] as? Double {
                return doubleValue
            } else if let intValue = data[key] as? Int {
                return Double(intValue)
            }
            AppLog.sync.error("Employment Settings: Missing or invalid '\(key)' field (got: \(String(describing: data[key])))")
            return nil
        }
        
        // Helper to safely extract Int values
        func extractInt(_ key: String) -> Int? {
            if let intValue = data[key] as? Int {
                return intValue
            } else if let doubleValue = data[key] as? Double {
                return Int(doubleValue)
            }
            AppLog.sync.error("Employment Settings: Missing or invalid '\(key)' field (got: \(String(describing: data[key])))")
            return nil
        }
        
        let holidayAccrualRate = extractDouble("holidayAccrualRate") ?? 0.1207 // backward compatibility
        let timeOffCountsAllCalendarDays = data["timeOffCountsAllCalendarDays"] as? Bool ?? true

        let minimumHourlyWage = extractDouble("minimumHourlyWage") ?? 0.0
        let minimumHourlyWageHistory: [MinimumWageRateEntryDTO] = (data["minimumHourlyWageHistory"] as? [[String: Any]] ?? []).compactMap { item in
            let date = (item["effectiveFrom"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let rate: Double
            if let value = item["rate"] as? Double {
                rate = value
            } else if let value = item["rate"] as? Int {
                rate = Double(value)
            } else {
                return nil
            }
            return MinimumWageRateEntryDTO(effectiveFrom: date, rate: rate)
        }

        guard let employerNIRate = extractDouble("employerNIRate"),
              let niThresholdPerYear = extractDouble("niThresholdPerYear"),
              let weeksPerYear = extractDouble("weeksPerYear"),
              let pensionRate = extractDouble("pensionRate"),
              let standardWeeklyHours = extractDouble("standardWeeklyHours"),
              let annualHolidayAllocation = extractDouble("annualHolidayAllocation"),
              let holidayYearStartMonth = extractInt("holidayYearStartMonth"),
              let holidayYearStartDay = extractInt("holidayYearStartDay"),
              let averageBreakHours = extractDouble("averageBreakHours"), // Default to 0.5 if missing (backward compatibility)
              let defaultShiftStartHour = extractInt("defaultShiftStartHour"),
              let defaultShiftStartMinute = extractInt("defaultShiftStartMinute"),
              let defaultShiftEndHour = extractInt("defaultShiftEndHour"),
              let defaultShiftEndMinute = extractInt("defaultShiftEndMinute"),
              let manuallyAdded = data["manuallyAdded"] as? Bool else {
            AppLog.sync.error("Employment Settings: Failed to parse document \(documentId) - one or more required fields missing")
            return nil
        }
        
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let companyId = data["companyId"] as? String
        
        AppLog.sync.info("Employment Settings parsed successfully: employerNIRate=\(employerNIRate), niThreshold=\(niThresholdPerYear)")
        
        return FirebaseEmploymentSettingsDTO(
            id: id,
            companyId: companyId,
            employerNIRate: employerNIRate,
            niThresholdPerYear: niThresholdPerYear,
            pensionRate: pensionRate,
            weeksPerYear: weeksPerYear,
            standardWeeklyHours: standardWeeklyHours,
            annualHolidayAllocation: annualHolidayAllocation,
            holidayAccrualRate: holidayAccrualRate,
            holidayYearStartMonth: holidayYearStartMonth,
            holidayYearStartDay: holidayYearStartDay,
            timeOffCountsAllCalendarDays: timeOffCountsAllCalendarDays,
            averageBreakHours: averageBreakHours,
            minimumHourlyWage: minimumHourlyWage,
            minimumHourlyWageHistory: minimumHourlyWageHistory,
            defaultShiftStartHour: defaultShiftStartHour,
            defaultShiftStartMinute: defaultShiftStartMinute,
            defaultShiftEndHour: defaultShiftEndHour,
            defaultShiftEndMinute: defaultShiftEndMinute,
            createdAt: createdAt,
            updatedAt: updatedAt,
            manuallyAdded: manuallyAdded
        )
    }
} 
