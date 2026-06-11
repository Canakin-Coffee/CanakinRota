//
import Combine
//  AlertManager.swift
//  CanakinCafe
//
//  Created by Lee Simmons on 02/01/2025.
//

import Foundation
import SwiftUI

final class AlertManager: ObservableObject {
    var showAlert = false
    var alertMessage = ""
    
    init(showAlert: Bool = false, alertMessage: String = "") {
        self.showAlert = showAlert
        self.alertMessage = alertMessage
    }
    
    func showMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

func friendlyErrorMessage(for error: Error) -> String {
    if let nsError = error as NSError? {
        switch nsError.domain {
        case NSCocoaErrorDomain:
            return "Database error: \(nsError.localizedDescription)"
        case NSURLErrorDomain:
            return "Network error: \(nsError.localizedDescription)"
        default:
            return "System error: \(nsError.localizedDescription)"
        }
    }
    
    return error.localizedDescription
}

struct AlertBuilder {
    
    /// Create a duplicate alert for any entity type
    /// - Parameter entityName: The name of the entity type (e.g., "Category", "Supplier")
    /// - Returns: An alert for duplicate entities
    static func duplicateAlert(entityName: String) -> Alert {
        Alert(
            title: Text("Duplicate \(entityName)"),
            message: Text("A \(entityName.lowercased()) with this name already exists."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Create an empty name alert for any entity type
    /// - Parameter entityName: The name of the entity type (e.g., "Category", "Supplier")
    /// - Returns: An alert for empty entity names
    static func emptyNameAlert(entityName: String) -> Alert {
        Alert(
            title: Text("Empty \(entityName) Name"),
            message: Text("Please enter a \(entityName.lowercased()) name before leaving this screen."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Create a cannot delete alert for any entity type
    /// - Parameter entityName: The name of the entity type (e.g., "Category", "Supplier")
    /// - Returns: An alert for entities that cannot be deleted
    static func cannotDeleteAlert(entityName: String) -> Alert {
        Alert(
            title: Text("Cannot Delete \(entityName)"),
            message: Text("This \(entityName.lowercased()) cannot be deleted because it is associated with one or more items."),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Create a validation error alert
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    /// - Returns: An alert for validation errors
    static func validationAlert(title: String, message: String) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Create a confirmation alert
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    ///   - confirmAction: Action to perform on confirmation
    ///   - cancelAction: Action to perform on cancellation
    /// - Returns: An alert with confirmation and cancel buttons
    static func confirmationAlert(
        title: String,
        message: String,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void = {}
    ) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .destructive(Text("Confirm"), action: confirmAction),
            secondaryButton: .cancel(Text("Cancel"), action: cancelAction)
        )
    }
    
    /// Create a success alert
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    /// - Returns: A success alert
    static func successAlert(title: String, message: String) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
    }
    
    /// Create an error alert
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    /// - Returns: An error alert
    static func errorAlert(title: String, message: String) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
    }
}
