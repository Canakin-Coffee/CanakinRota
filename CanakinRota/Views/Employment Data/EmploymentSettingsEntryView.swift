import SwiftUI
import SwiftData
import CanakinStaffShared

struct EmploymentSettingsEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store = EmploymentSettingsStore.shared
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case niRate, threshold, pensionRate, weeks, hours, holidayAllocation, holidayAccrualRate, averageBreakHours, minimumHourlyWage, startTime, endTime, holidayYearStart
    }

    @State private var isEditing = false

    @State private var tempNIRate: Double = 0
    @State private var tempNIThreshold: Double = 0
    @State private var tempPensionRate: Double = 0
    @State private var tempWeeks: Double = 0
    @State private var tempHours: Double = 0
    @State private var tempHolidayAllocation: Double = 0
    @State private var tempHolidayAccrualRate: Double = 0.1207
    @State private var tempAverageBreakHours: Double = 0.5
    @State private var tempMinimumHourlyWage: Double = 0.0
    @State private var tempMinimumWageEffectiveDate = Date()
    @State private var showSetRateSheet = false
    @State private var stagedMinimumWage: Double = 0.0
    @State private var stagedMinimumWageDate = Date()
    @State private var tempStartTime = Date()
    @State private var tempEndTime = Date()
    @State private var tempHolidayAnchor = Date()
    @State private var tempTimeOffCountsAllCalendarDays = true

    private var currentSettings: EmploymentSettings {
        if let settings = store.currentSettings {
            return settings
        } else {
            // Create default settings with a consistent ID
            let newSettings = EmploymentSettings.createDefault()
            newSettings.id = "default" // Use consistent ID
            modelContext.insert(newSettings)
            try? modelContext.save()
            store.currentSettings = newSettings
            return newSettings
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Staff Wages & Employer Costs") {
                    HStack {
                        Text("NI Rate")
                        Spacer()
                        TextField("NI Rate", value: $tempNIRate, format: .percent.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .niRate)
                            .onSubmit {
                                saveNIRate()
                            }
                    }
                    
                    HStack {
                        Text("NI Threshold")
                        Spacer()
                        TextField("NI Threshold", value: $tempNIThreshold, format: .currency(code: "GBP").precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .threshold)
                            .onSubmit {
                                saveNIThreshold()
                            }
                    }
                    
                    HStack {
                        Text("Pension Rate")
                        Spacer()
                        TextField("Pension Rate", value: $tempPensionRate, format: .percent.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .pensionRate)
                            .onSubmit {
                                savePensionRate()
                            }
                    }
                    
                    HStack {
                        Text("Weeks in a Year")
                        Spacer()
                        TextField("Weeks", value: $tempWeeks, format: .number.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .weeks)
                            .onSubmit {
                                saveWeeks()
                            }
                    }
                    
                    HStack {
                        Text("Hours in a Week")
                        Spacer()
                        TextField("Hours", value: $tempHours, format: .number.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .hours)
                            .onSubmit {
                                saveHours()
                            }
                    }
                    
                    HStack {
                        Text("Annual Holiday Allocation")
                        Spacer()
                        TextField("Days", value: $tempHolidayAllocation, format: .number.precision(.fractionLength(1)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .holidayAllocation)
                            .onSubmit {
                                saveHolidayAllocation()
                            }
                    }
                    
                    HStack {
                        Text("Holiday Accrual Rate")
                        Spacer()
                        TextField("Rate", value: $tempHolidayAccrualRate, format: .percent.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .holidayAccrualRate)
                            .onSubmit {
                                saveHolidayAccrualRate()
                            }
                        Text("(P&L / wages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Average Break Hours")
                        Spacer()
                        TextField("Hours", value: $tempAverageBreakHours, format: .number.precision(.fractionLength(2)))
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .averageBreakHours)
                            .onSubmit {
                                saveAverageBreakHours()
                            }
                        Text("(for hourly P&L calculations)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Minimum Hourly Wage")
                        Spacer()
                        TextField("Wage", value: $tempMinimumHourlyWage, format: .currency(code: "GBP").precision(.fractionLength(2)))
                            .frame(width: 110)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .minimumHourlyWage)
                            .onSubmit {
                                saveMinimumHourlyWage()
                            }
                    }
                    
                    HStack {
                        Text("Wage Effective From")
                        Spacer()
                        DatePicker("", selection: $tempMinimumWageEffectiveDate, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    
                    Button {
                        stagedMinimumWage = tempMinimumHourlyWage
                        stagedMinimumWageDate = tempMinimumWageEffectiveDate
                        showSetRateSheet = true
                    } label: {
                        Label("Set New Rate", systemImage: "plus.circle")
                    }
                    
                    if !currentSettings.minimumHourlyWageHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wage History")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(currentSettings.minimumHourlyWageHistory.reversed(), id: \.self) { entry in
                                HStack {
                                    Text(entry.effectiveFrom, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(Formatters.currency(Decimal(entry.rate)))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                Section("Default Shift Times") {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        DatePicker("", selection: $tempStartTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: tempStartTime) { _, newTime in
                                Task { @MainActor in
                                    saveStartTime(newTime)
                                }
                            }
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        DatePicker("", selection: $tempEndTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: tempEndTime) { _, newTime in
                                Task { @MainActor in
                                    saveEndTime(newTime)
                                }
                            }
                    }
                }
                
                Section("Settings Information") {
                    Toggle(isOn: Binding(
                        get: { tempTimeOffCountsAllCalendarDays },
                        set: { newValue in
                            tempTimeOffCountsAllCalendarDays = newValue
                            saveTimeOffCalendarDayMode(newValue)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Holiday counts all calendar days")
                            Text("Off = only days the employee normally works (Mon–Fri by default, or their weekly availability). On = every calendar day (7-day operations).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Holiday Year Start")
                        Spacer()
                        DatePicker("", selection: $tempHolidayAnchor, displayedComponents: [.date])
                            .labelsHidden()
                            .onChange(of: tempHolidayAnchor) { _, newDate in
                                Task { @MainActor in
                                    saveHolidayAnchor(newDate)
                                }
                            }
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(currentSettings.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(currentSettings.updatedAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                store.setModelContext(modelContext)
                loadTemps()
            }
            .navigationTitle("Employment Settings")
            .toolbar { keyboardToolbar() }
            .onChange(of: focusedField) { oldField, newField in
                // DecimalPad fields may not trigger onSubmit (no return key on iOS),
                // so persist minimum wage when focus leaves that field.
                if oldField == .minimumHourlyWage && newField != .minimumHourlyWage {
                    saveMinimumHourlyWage()
                }
                store.isEditing = (newField != nil)
            }
            .onChange(of: tempMinimumWageEffectiveDate) { _, newDate in
                tempMinimumHourlyWage = currentSettings.minimumHourlyWage(on: newDate)
            }
            .sheet(isPresented: $showSetRateSheet) {
                NavigationStack {
                    Form {
                        Section("New Minimum Hourly Wage") {
                            TextField("Wage", value: $stagedMinimumWage, format: .currency(code: "GBP").precision(.fractionLength(2)))
                                .multilineTextAlignment(.trailing)
                            DatePicker("Effective From", selection: $stagedMinimumWageDate, displayedComponents: [.date])
                        }
                        Section {
                            Text("This will create a dated wage history entry. Historical wage calculations before this date will keep using earlier rates.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .navigationTitle("Set New Rate")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showSetRateSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                applyStagedMinimumWageRate()
                                showSetRateSheet = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func keyboardToolbar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { focusedField = nil }
        }
    }

    private func loadTemps() {
        let settings = currentSettings
        tempNIRate = settings.employerNIRate
        tempNIThreshold = settings.niThresholdPerYear
        tempPensionRate = settings.pensionRate
        tempWeeks = settings.weeksPerYear
        tempHours = settings.standardWeeklyHours
        tempHolidayAllocation = settings.annualHolidayAllocation
        tempHolidayAccrualRate = settings.holidayAccrualRate
        tempAverageBreakHours = settings.averageBreakHours
        settings.ensureMinimumWageHistoryInitialized()
        tempMinimumWageEffectiveDate = Date()
        tempMinimumHourlyWage = settings.minimumHourlyWage(on: tempMinimumWageEffectiveDate)
        
        // Initialize time pickers with current settings
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.hour = settings.defaultShiftStartHour
        startComponents.minute = settings.defaultShiftStartMinute
        tempStartTime = calendar.date(from: startComponents) ?? Date()
        
        var endComponents = DateComponents()
        endComponents.hour = settings.defaultShiftEndHour
        endComponents.minute = settings.defaultShiftEndMinute
        tempEndTime = calendar.date(from: endComponents) ?? Date()
        // Build an anchor date for this year using month/day
        var anchorComponents = calendar.dateComponents([.year], from: Date())
        anchorComponents.month = settings.holidayYearStartMonth
        anchorComponents.day = settings.holidayYearStartDay
        tempHolidayAnchor = calendar.date(from: anchorComponents) ?? Date()
        tempTimeOffCountsAllCalendarDays = settings.timeOffCountsAllCalendarDays
    }

    // MARK: - Save Methods
    
    private func saveNIRate() {
        let settings = currentSettings
        // Normalize percent input: allow entering 15 for 15% or 0.15
        var normalized = tempNIRate
        if normalized > 1 { normalized = normalized / 100 }
        normalized = max(0, min(normalized, 1))
        settings.employerNIRate = normalized
        tempNIRate = normalized
        store.saveSettings(settings)
    }
    
    private func saveNIThreshold() {
        let settings = currentSettings
        settings.niThresholdPerYear = tempNIThreshold
        store.saveSettings(settings)
    }
    
    private func savePensionRate() {
        let settings = currentSettings
        // Normalize percent input: allow entering 3 for 3% or 0.03
        var normalized = tempPensionRate
        if normalized > 1 { normalized = normalized / 100 }
        normalized = max(0, min(normalized, 1))
        settings.pensionRate = normalized
        tempPensionRate = normalized
        store.saveSettings(settings)
    }
    
    private func saveWeeks() {
        let settings = currentSettings
        settings.weeksPerYear = tempWeeks
        store.saveSettings(settings)
    }
    
    private func saveHours() {
        let settings = currentSettings
        settings.standardWeeklyHours = tempHours
        store.saveSettings(settings)
    }
    
    private func saveHolidayAllocation() {
        let settings = currentSettings
        settings.annualHolidayAllocation = tempHolidayAllocation
        store.saveSettings(settings)
    }

    private func saveHolidayAccrualRate() {
        let settings = currentSettings
        var normalized = tempHolidayAccrualRate
        if normalized > 1 { normalized = normalized / 100 }
        normalized = max(0, min(normalized, 1))
        settings.holidayAccrualRate = normalized
        tempHolidayAccrualRate = normalized
        store.saveSettings(settings)
    }
    
    private func saveAverageBreakHours() {
        let settings = currentSettings
        settings.averageBreakHours = max(0.0, tempAverageBreakHours) // Ensure non-negative
        tempAverageBreakHours = settings.averageBreakHours
        store.saveSettings(settings)
    }

    private func saveMinimumHourlyWage() {
        let settings = currentSettings
        settings.setMinimumHourlyWage(max(0.0, tempMinimumHourlyWage), effectiveFrom: tempMinimumWageEffectiveDate)
        tempMinimumHourlyWage = settings.minimumHourlyWage(on: tempMinimumWageEffectiveDate)
        store.saveSettings(settings)
    }
    
    private func applyStagedMinimumWageRate() {
        let settings = currentSettings
        settings.setMinimumHourlyWage(max(0.0, stagedMinimumWage), effectiveFrom: stagedMinimumWageDate)
        tempMinimumWageEffectiveDate = stagedMinimumWageDate
        tempMinimumHourlyWage = settings.minimumHourlyWage(on: stagedMinimumWageDate)
        store.saveSettings(settings)
    }
    
    private func saveHolidayAnchor(_ newDate: Date) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: newDate)
        let day = calendar.component(.day, from: newDate)
        let settings = currentSettings
        settings.holidayYearStartMonth = month
        settings.holidayYearStartDay = day
        store.saveSettings(settings)
    }

    private func saveTimeOffCalendarDayMode(_ countsAllDays: Bool) {
        let settings = currentSettings
        settings.timeOffCountsAllCalendarDays = countsAllDays
        store.saveSettings(settings)
    }
    
    private func saveStartTime(_ newTime: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: newTime)
        let minute = calendar.component(.minute, from: newTime)
        
        let settings = currentSettings
        settings.defaultShiftStartHour = hour
        settings.defaultShiftStartMinute = minute
        store.saveSettings(settings)
    }
    
    private func saveEndTime(_ newTime: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: newTime)
        let minute = calendar.component(.minute, from: newTime)
        
        let settings = currentSettings
        settings.defaultShiftEndHour = hour
        settings.defaultShiftEndMinute = minute
        store.saveSettings(settings)
    }
}
