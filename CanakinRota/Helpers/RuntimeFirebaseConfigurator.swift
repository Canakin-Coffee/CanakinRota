import Foundation
import FirebaseCore

enum RuntimeFirebaseConfigError: Error {
    case invalidFile
    case copyFailed
}

struct RuntimeFirebaseConfigurator {
    static let shared = RuntimeFirebaseConfigurator()
    private let persistedPlistFilename = "GoogleService-Info.plist"
    private let subdirectory = "Firebase"

    private var persistedPlistURL: URL? {
        do {
            let appSupport = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dir = appSupport.appendingPathComponent(subdirectory, isDirectory: true)
            if !FileManager.default.fileExists(atPath: dir.path) {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            return dir.appendingPathComponent(persistedPlistFilename)
        } catch {
            return nil
        }
    }

    func loadPersistedOptions() -> FirebaseOptions? {
        guard let url = persistedPlistURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        return FirebaseOptions(contentsOfFile: url.path)
    }

    func configureFromPersistedIfAvailable() {
        guard FirebaseApp.app() == nil, let url = persistedPlistURL, FileManager.default.fileExists(atPath: url.path) else { return }
        if let options = FirebaseOptions(contentsOfFile: url.path) {
            FirebaseApp.configure(options: options)
        }
    }

    func persistPlistAndConfigure(from url: URL) throws {
        guard let options = FirebaseOptions(contentsOfFile: url.path) else {
            throw RuntimeFirebaseConfigError.invalidFile
        }
        guard let dest = persistedPlistURL else { throw RuntimeFirebaseConfigError.copyFailed }
        _ = try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: url, to: dest)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
    }
}
