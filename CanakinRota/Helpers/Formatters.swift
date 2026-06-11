// File: Helpers/Formatters.swift

// File: Helpers/Formatters.swift

import Foundation
import CanakinStaffShared
import SwiftUI

enum Formatters {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    //  ISO 8601 Date-Time
    static let isoDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static func isoDateTime(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoDateTimeFormatter.string(from: date)
    }
    
    static let isoDateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "y-MM-dd"
        f.timeZone = .current
        return f
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter
    }()
    
    static func currency(_ value: Decimal?, code: String = "GBP") -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "—"
    }
    
    static func date(_ value: Date?, long: Bool = false) -> String {
        guard let value else { return "—" }
        let formatter = long ? longDateFormatter : shortDateFormatter
        return formatter.string(from: value)
    }
    
    static func dateTime(_ value: Date?) -> String {
        guard let value else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }
    
    static func decimal(_ value: Decimal?, scale: Int = 2) -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = scale
        formatter.maximumFractionDigits = scale
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "—"
    }
    
    static let removeDecimals: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Format time duration in HH:MM format (e.g., "3h 30m" for 3.5 hours)
    static func duration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else if m > 0 {
            return "\(m)m"
        } else {
            return "0m"
        }
    }
    
    /// Format time duration from TimeInterval in HH:MM format
    static func durationFromInterval(_ timeInterval: TimeInterval) -> String {
        let hours = timeInterval / 3600.0
        return duration(hours)
    }
    
    static func percent(_ value: Decimal?, scale: Int = 1) -> String {
        guard let value else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = scale
        formatter.maximumFractionDigits = scale
        let percentValue = NSDecimalNumber(decimal: value)
        return formatter.string(from: percentValue) ?? "—"
    }
    
    static func temperature(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f°C", value)
    }
    
    static func removeDecimals(_ value: Decimal?) -> String {
        guard let value else { return "—" }
        return removeDecimals.string(from: NSDecimalNumber(decimal: value)) ?? "—"
    }
    
    // MARK: - Legacy Timesheet Formatting (deprecated - use duration() instead)
    
    /// Format hours with 2 decimal places (deprecated - use duration() instead)
    static func hours(_ value: Double) -> String {
        return duration(value)
    }
    
    /// Format hours as decimal only (deprecated - use duration() instead)
    static func hoursDecimal(_ value: Double) -> String {
        return duration(value)
    }
    
    /// Format break time from hours to minutes (deprecated - use duration() instead)
    static func breakTimeFromHours(_ hours: Double) -> String {
        return duration(hours)
    }
}

// MARK: - DateFormatter Extension for yyyyMMdd format
extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

extension Formatters {
    enum ValueFormat {
        case currency, decimal, percent

        var formatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            formatter.roundingMode = .halfUp
            switch self {
            case .currency:
                formatter.numberStyle = .currency
                formatter.currencyCode = "GBP"
                formatter.currencySymbol = "£"
            case .decimal:
                formatter.numberStyle = .decimal
            case .percent:
                formatter.numberStyle = .decimal
                formatter.positiveSuffix = "%"
                formatter.negativeSuffix = "%"
                formatter.currencySymbol = ""
            }
            return formatter
        }
    }
}

extension Decimal {
    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
    
    var doubleValue: Double {
        (self as NSDecimalNumber).doubleValue
    }
    
    static func fromDouble(_ value: Double) -> Decimal {
        Decimal(string: String(value)) ?? 0
    }
}

struct InputFormatter: View {
    @Binding var value: Decimal
    @State private var valueString: String = ""

    var label: String
    var format: Formatters.ValueFormat

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.00", text: $valueString, onEditingChanged: { editing in
                if !editing {
                    commitValueString()
                }
            })
            .keyboardType(.decimalPad)
            .frame(width: 100)
            .multilineTextAlignment(.trailing)
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(value > 0 ? Color.primary : Color.red)
            .onChange(of: valueString) {
                syncValueString()
            }
        }
        .onAppear {
            valueString = format.formatter.string(from: NSDecimalNumber(decimal: value)) ?? ""
        }
        .padding(.vertical, 5)
    }

    private func syncValueString() {
        if let number = format.formatter.number(from: valueString) {
            value = number.decimalValue
        } else {
            // fallback to manual filtering
            let sanitized = valueString.filter { "0123456789.".contains($0) }
            if let decimal = Decimal(string: sanitized) {
                value = decimal
            }
        }
    }

    private func commitValueString() {
        valueString = format.formatter.string(from: NSDecimalNumber(decimal: value)) ?? ""
    }
}
