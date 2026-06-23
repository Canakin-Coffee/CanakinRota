//
//  FirebaseEmploymentSettingsDTO.swift
//  CanakinRota
//

import Foundation
import os
import FirebaseFirestore
import CanakinStaffShared

struct FirebaseEmploymentSettingsDTO: Codable {
    struct MinimumWageRateEntryDTO: Codable {
        let effectiveFrom: Date
        let rate: Double
    }

    struct MinimumWageBandRateEntryDTO: Codable {
        let band: String
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
    let payrollRunDay: Int
    let timeOffCountsAllCalendarDays: Bool
    let clockInGeofenceEnabled: Bool
    let clockInGeofenceLatitude: Double
    let clockInGeofenceLongitude: Double
    let clockInGeofenceRadiusMetres: Double
    let minimumHourlyWage: Double
    let minimumHourlyWageHistory: [MinimumWageRateEntryDTO]
    let minimumWageBandHistory: [MinimumWageBandRateEntryDTO]
    let recipeLabourPlanningBand: String
    let createdAt: Date
    let updatedAt: Date
    let manuallyAdded: Bool
    
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
        payrollRunDay: Int = 31,
        timeOffCountsAllCalendarDays: Bool = false,
        clockInGeofenceEnabled: Bool = false,
        clockInGeofenceLatitude: Double = 0,
        clockInGeofenceLongitude: Double = 0,
        clockInGeofenceRadiusMetres: Double = 50,
        minimumHourlyWage: Double = 0.0,
        minimumHourlyWageHistory: [MinimumWageRateEntryDTO] = [],
        minimumWageBandHistory: [MinimumWageBandRateEntryDTO] = [],
        recipeLabourPlanningBand: String = MinimumWageAgeBand.age21AndOver.rawValue,
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
        self.payrollRunDay = payrollRunDay
        self.timeOffCountsAllCalendarDays = timeOffCountsAllCalendarDays
        self.clockInGeofenceEnabled = clockInGeofenceEnabled
        self.clockInGeofenceLatitude = clockInGeofenceLatitude
        self.clockInGeofenceLongitude = clockInGeofenceLongitude
        self.clockInGeofenceRadiusMetres = clockInGeofenceRadiusMetres
        self.minimumHourlyWage = minimumHourlyWage
        self.minimumHourlyWageHistory = minimumHourlyWageHistory
        self.minimumWageBandHistory = minimumWageBandHistory
        self.recipeLabourPlanningBand = recipeLabourPlanningBand
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
        self.payrollRunDay = employmentSettings.payrollRunDay
        self.timeOffCountsAllCalendarDays = employmentSettings.timeOffCountsAllCalendarDays
        self.clockInGeofenceEnabled = employmentSettings.clockInGeofenceEnabled
        self.clockInGeofenceLatitude = employmentSettings.clockInGeofenceLatitude
        self.clockInGeofenceLongitude = employmentSettings.clockInGeofenceLongitude
        self.clockInGeofenceRadiusMetres = employmentSettings.clockInGeofenceRadiusMetres
        self.minimumHourlyWage = employmentSettings.minimumHourlyWage(on: Date())
        self.minimumHourlyWageHistory = employmentSettings.minimumHourlyWageHistory.map {
            MinimumWageRateEntryDTO(effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        self.minimumWageBandHistory = employmentSettings.minimumWageBandHistory.map {
            MinimumWageBandRateEntryDTO(band: $0.bandRaw, effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        self.recipeLabourPlanningBand = employmentSettings.recipeLabourPlanningBandRaw
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
            minimumHourlyWage: minimumHourlyWage,
            manuallyAdded: manuallyAdded,
            companyId: companyId
        )
        settings.createdAt = createdAt
        settings.updatedAt = updatedAt
        settings.payrollRunDay = payrollRunDay
        settings.clockInGeofenceEnabled = clockInGeofenceEnabled
        settings.clockInGeofenceLatitude = clockInGeofenceLatitude
        settings.clockInGeofenceLongitude = clockInGeofenceLongitude
        settings.clockInGeofenceRadiusMetres = clockInGeofenceRadiusMetres
        settings.minimumHourlyWageHistory = minimumHourlyWageHistory.map {
            EmploymentSettings.MinimumWageRateEntry(effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        settings.minimumWageBandHistory = minimumWageBandHistory.map {
            MinimumWageBandRateEntry(band: MinimumWageAgeBand(rawValue: $0.band) ?? .age21AndOver, effectiveFrom: $0.effectiveFrom, rate: $0.rate)
        }
        settings.recipeLabourPlanningBandRaw = recipeLabourPlanningBand
        if settings.minimumHourlyWageHistory.isEmpty {
            settings.minimumHourlyWage = minimumHourlyWage
        } else {
            settings.minimumHourlyWage = settings.minimumHourlyWage(on: Date())
        }
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
            "payrollRunDay": payrollRunDay,
            "timeOffCountsAllCalendarDays": timeOffCountsAllCalendarDays,
            "clockInGeofenceEnabled": clockInGeofenceEnabled,
            "clockInGeofenceLatitude": clockInGeofenceLatitude,
            "clockInGeofenceLongitude": clockInGeofenceLongitude,
            "clockInGeofenceRadiusMetres": clockInGeofenceRadiusMetres,
            "minimumHourlyWage": minimumHourlyWage,
            "minimumHourlyWageHistory": minimumHourlyWageHistory.map { [
                "effectiveFrom": Timestamp(date: $0.effectiveFrom),
                "rate": $0.rate
            ] },
            "minimumWageBandHistory": minimumWageBandHistory.map { [
                "band": $0.band,
                "effectiveFrom": Timestamp(date: $0.effectiveFrom),
                "rate": $0.rate
            ] },
            "recipeLabourPlanningBand": recipeLabourPlanningBand,
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
        
        func extractDouble(_ key: String) -> Double? {
            if let doubleValue = data[key] as? Double {
                return doubleValue
            } else if let intValue = data[key] as? Int {
                return Double(intValue)
            }
            AppLog.sync.error("Employment Settings: Missing or invalid '\(key)' field (got: \(String(describing: data[key])))")
            return nil
        }
        
        func extractInt(_ key: String) -> Int? {
            if let intValue = data[key] as? Int {
                return intValue
            } else if let doubleValue = data[key] as? Double {
                return Int(doubleValue)
            }
            AppLog.sync.error("Employment Settings: Missing or invalid '\(key)' field (got: \(String(describing: data[key])))")
            return nil
        }
        
        let holidayAccrualRate = extractDouble("holidayAccrualRate") ?? 0.1207
        let timeOffCountsAllCalendarDays = data["timeOffCountsAllCalendarDays"] as? Bool ?? false
        let payrollRunDay: Int = {
            if let intValue = data["payrollRunDay"] as? Int { return intValue }
            if let doubleValue = data["payrollRunDay"] as? Double { return Int(doubleValue) }
            return 31
        }()
        let clockInGeofenceEnabled = data["clockInGeofenceEnabled"] as? Bool ?? false
        let clockInGeofenceLatitude: Double = {
            if let value = data["clockInGeofenceLatitude"] as? Double { return value }
            if let value = data["clockInGeofenceLatitude"] as? Int { return Double(value) }
            return 0
        }()
        let clockInGeofenceLongitude: Double = {
            if let value = data["clockInGeofenceLongitude"] as? Double { return value }
            if let value = data["clockInGeofenceLongitude"] as? Int { return Double(value) }
            return 0
        }()
        let clockInGeofenceRadiusMetres: Double = {
            if let value = data["clockInGeofenceRadiusMetres"] as? Double { return value }
            if let value = data["clockInGeofenceRadiusMetres"] as? Int { return Double(value) }
            return 50
        }()

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

        let minimumWageBandHistory: [MinimumWageBandRateEntryDTO] = (data["minimumWageBandHistory"] as? [[String: Any]] ?? []).compactMap { item in
            guard let band = item["band"] as? String else { return nil }
            let date = (item["effectiveFrom"] as? Timestamp)?.dateValue() ?? Date.distantPast
            let rate: Double
            if let value = item["rate"] as? Double {
                rate = value
            } else if let value = item["rate"] as? Int {
                rate = Double(value)
            } else {
                return nil
            }
            return MinimumWageBandRateEntryDTO(band: band, effectiveFrom: date, rate: rate)
        }

        let recipeLabourPlanningBand = data["recipeLabourPlanningBand"] as? String ?? MinimumWageAgeBand.age21AndOver.rawValue

        guard let employerNIRate = extractDouble("employerNIRate"),
              let niThresholdPerYear = extractDouble("niThresholdPerYear"),
              let weeksPerYear = extractDouble("weeksPerYear"),
              let pensionRate = extractDouble("pensionRate"),
              let standardWeeklyHours = extractDouble("standardWeeklyHours"),
              let annualHolidayAllocation = extractDouble("annualHolidayAllocation"),
              let holidayYearStartMonth = extractInt("holidayYearStartMonth"),
              let holidayYearStartDay = extractInt("holidayYearStartDay"),
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
            payrollRunDay: payrollRunDay,
            timeOffCountsAllCalendarDays: timeOffCountsAllCalendarDays,
            clockInGeofenceEnabled: clockInGeofenceEnabled,
            clockInGeofenceLatitude: clockInGeofenceLatitude,
            clockInGeofenceLongitude: clockInGeofenceLongitude,
            clockInGeofenceRadiusMetres: clockInGeofenceRadiusMetres,
            minimumHourlyWage: minimumHourlyWage,
            minimumHourlyWageHistory: minimumHourlyWageHistory,
            minimumWageBandHistory: minimumWageBandHistory,
            recipeLabourPlanningBand: recipeLabourPlanningBand,
            createdAt: createdAt,
            updatedAt: updatedAt,
            manuallyAdded: manuallyAdded
        )
    }
}
