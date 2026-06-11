import SwiftUI
import SwiftData
import CanakinStaffShared

/// Rota-focused settings (account, sign out, employment settings link).
struct SettingsTabView: View {
    @EnvironmentObject private var authorityManager: AuthorityManager
    @EnvironmentObject private var companyContext: CompanyContext
    @Environment(\.modelContext) private var modelContext

    let onSignOut: () -> Void

    @State private var showingLogoutAlert = false
    @State private var showingPasswordChange = false

    var body: some View {
        List {
            if let currentUser = authorityManager.currentUser {
                Section("User Account") {
                    Text(currentUser.name)
                        .font(.headline)
                    Text(currentUser.email)
                        .foregroundStyle(.secondary)
                    Text(currentUser.effectiveAuthorityLevel.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let company = companyContext.currentCompany {
                Section("Company") {
                    Text(company.name)
                    if !company.symbol.isEmpty {
                        Text(company.symbol)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink("Employment Settings") {
                    EmploymentSettingsEntryView()
                }
                Button("Change Password") {
                    showingPasswordChange = true
                }
                Button("Sign Out", role: .destructive) {
                    showingLogoutAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Sign Out?", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authorityManager.signOut(modelContext: modelContext)
                onSignOut()
            }
        } message: {
            Text("You will need to sign in again to access the rota.")
        }
        .sheet(isPresented: $showingPasswordChange) {
            FirebasePasswordChangeView()
        }
    }
}
