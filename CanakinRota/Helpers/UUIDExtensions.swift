import Foundation
import SwiftData
import CanakinStaffShared

// MARK: - UUID Extensions for SwiftData Compatibility
extension UUID {
    /// Returns the UUID as a string for use in SwiftData predicates and queries
    var stringValue: String {
        return self.uuidString
    }
}

// MARK: - User Extensions for UUID Handling
extension User {
    /// Returns the user's ID as a string for use in SwiftData predicates
    var idString: String {
        return self.id.uuidString
    }
}



// MARK: - Model Extensions for UUID Display
// Note: These methods were removed due to SwiftData schema issues with FetchDescriptor
// Use direct queries in views instead

// MARK: - Display Helpers
struct DisplayHelpers {
    /// Formats a UUID for display by showing the first 8 characters
    /// - Parameter uuid: The UUID to format
    /// - Returns: A shortened string representation
    static func shortUUID(_ uuid: UUID) -> String {
        let uuidString = uuid.uuidString
        return String(uuidString.prefix(8))
    }
    
    /// Formats a UUID string for display by showing the first 8 characters
    /// - Parameter uuidString: The UUID string to format
    /// - Returns: A shortened string representation
    static func shortUUIDString(_ uuidString: String) -> String {
        return String(uuidString.prefix(8))
    }
} 