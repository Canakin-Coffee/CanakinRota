import SwiftUI
import CanakinStaffShared
import UniformTypeIdentifiers
import FirebaseCore

struct CompanyOnboardingView: View {
    @State private var showingPlistPicker = false
    @State private var message: String = ""
    @State private var didConfigure = false
    @State private var isBusy = false
    
    var onCompleted: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            Text("Set Up Your Company")
                .font(.largeTitle).fontWeight(.bold)
            Text("Import your Firebase iOS config (GoogleService-Info.plist) to connect this app to your company's Firebase project.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingPlistPicker = true }) {
                Label("Import GoogleService-Info.plist", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isBusy)

            if isBusy { ProgressView().padding(.top, 8) }
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(didConfigure ? .green : .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if didConfigure {
                Button("Continue") { onCompleted?() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .fileImporter(isPresented: $showingPlistPicker, allowedContentTypes: [UTType.propertyList, UTType.xml, UTType.data, UTType.plainText, UTType.item], allowsMultipleSelection: false) { result in
            switch result {
            case .failure(let error):
                message = "Import failed: \(error.localizedDescription)"
            case .success(let urls):
                guard let url = urls.first else { return }
                isBusy = true
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        // Start security-scoped resource access
                        guard url.startAccessingSecurityScopedResource() else {
                            throw RuntimeFirebaseConfigError.invalidFile
                        }
                        defer { url.stopAccessingSecurityScopedResource() }
                        
                        try RuntimeFirebaseConfigurator.shared.persistPlistAndConfigure(from: url)
                        DispatchQueue.main.async {
                            isBusy = false
                            didConfigure = true
                            message = "Firebase configured successfully."
                        }
                    } catch {
                        DispatchQueue.main.async {
                            isBusy = false
                            didConfigure = false
                            message = "Failed to configure: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .onAppear {
            // Try to configure if a config is already persisted
            RuntimeFirebaseConfigurator.shared.configureFromPersistedIfAvailable()
            didConfigure = (FirebaseApp.app() != nil)
            if didConfigure { message = "Firebase already configured." }
        }
    }
}


