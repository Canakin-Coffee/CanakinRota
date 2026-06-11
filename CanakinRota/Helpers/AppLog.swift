//
//  AppLog.swift
//  CanakinCafe
//
//  Unified logging facade. Replaces ad-hoc `print(...)` calls across the app
//  with categorised, level-based logging on top of Apple's unified logging
//  system (`os.Logger`).
//
//  ─────────────────────────────────────────────────────────────────────────────
//  WHY NOT `print`?
//  ─────────────────────────────────────────────────────────────────────────────
//  • `print` runs synchronously on the calling thread — when sync code fires
//    hundreds of prints per second it stalls the main thread.
//  • `print` always evaluates its arguments, even if nobody reads them.
//  • `print` can't be filtered by subsystem/category in Console.app, can't be
//    silenced in release builds without recompiling, and can't be exported as
//    a structured log.
//  • `os.Logger` gives us all of the above for free, and uses lazy
//    `OSLogStringInterpolation` so message formatting only happens if the
//    message is actually emitted.
//
//  ─────────────────────────────────────────────────────────────────────────────
//  USAGE
//  ─────────────────────────────────────────────────────────────────────────────
//      AppLog.sync.info("SupplierOrder saved id=\(order.id.uuidString)")
//      AppLog.sync.warning("No company ID, skipping shopping list sync")
//      AppLog.sync.error("Failed to sync orders", error: error)
//      AppLog.auth.notice("User signed in: \(user.email)")
//      AppLog.db.debug("Fetched \(items.count) items for order")
//
//  ─────────────────────────────────────────────────────────────────────────────
//  CATEGORIES (pick the closest one — keep this list short and stable)
//  ─────────────────────────────────────────────────────────────────────────────
//  • sync          Firestore reads/writes/listeners and SwiftData ↔ Firebase
//                  reconciliation.
//  • auth          Sign in/out, session, company context switching.
//  • db            Local SwiftData operations not tied to a sync round-trip
//                  (migrations, seeding, cascade deletes).
//  • ui            View-level events worth keeping (rare — most should be
//                  removed rather than logged).
//  • sales         Square sales ingestion, COGS, P&L calculations.
//  • integration   Third-party API traffic that isn't Firestore (Square API,
//                  Xero API, etc.).
//  • migration     One-shot data migrations and schema fix-ups.
//  • general       Catch-all when nothing fits — try to avoid.
//
//  ─────────────────────────────────────────────────────────────────────────────
//  LEVEL GUIDE (mapping from existing `print` patterns)
//  ─────────────────────────────────────────────────────────────────────────────
//  Existing print prefix              →   New call
//  ──────────────────────────────────     ──────────────────────────────────────
//  print("🔥 X saved to Firestore…")  →   AppLog.sync.info("X saved …")
//  print("✅ Synced N items")         →   AppLog.sync.info("Synced N items")
//  print("📦 SYNC: Loading X…")       →   AppLog.sync.notice("Loading X")
//  print("⚠️ Some warning")           →   AppLog.sync.warning("Some warning")
//  print("❌ Failed: \(error)")       →   AppLog.sync.error("Failed", error: error)
//  print("🔍 Debug detail …")         →   AppLog.db.debug("Debug detail …")
//
//  Drop the emoji from the message — `warning` / `error` already get one
//  prepended automatically. Drop "DEBUG" / "INFO" prefixes too — the level
//  conveys that.
//
//  ─────────────────────────────────────────────────────────────────────────────
//  RELEASE BEHAVIOUR
//  ─────────────────────────────────────────────────────────────────────────────
//  `os.Logger` automatically discards `.debug` messages in release and only
//  persists `.notice` and above to disk. No build flag needed. Argument
//  formatting is also lazy, so a `.debug` call site costs ~nothing in release.
//
//  ─────────────────────────────────────────────────────────────────────────────
//  GOTCHAS (encountered during the original print → AppLog sweep)
//  ─────────────────────────────────────────────────────────────────────────────
//  `os.Logger` accepts an `OSLogMessage` built via `OSLogStringInterpolation`
//  which is internally an `@autoclosure @escaping` argument. That has a few
//  subtle implications that `print` did not:
//
//  1. IMPLICIT SELF.
//     Inside a method, `print("x \(myProperty)")` works, but
//     `AppLog.sync.info("x \(myProperty)")` will fail with:
//        "reference to property 'myProperty' in closure requires explicit
//         use of 'self' to make capture semantics explicit"
//     Fix: write `\(self.myProperty)`.
//
//  2. INOUT PARAMETERS.
//     A function with `inout` parameters cannot interpolate them directly:
//        "escaping autoclosure captures 'inout' parameter 'totalGross'"
//     Fix: copy to a local before logging:
//        let g = totalGross
//        AppLog.ui.info("Gross: \(g)")
//
//  3. NON-CONFORMING TYPES.
//     `os.Logger` interpolation requires types to conform to
//     `CustomStringConvertible` (or one of the specific OSLog overloads).
//     Things like `PersistentIdentifier`, `Unit.UnitType`, `CodingKey`,
//     `Any?` from a `[String: Any]` dictionary won't compile directly.
//     Fix: wrap in `String(describing:)` or cast first:
//        AppLog.sync.warning("Duplicate id: \(String(describing: stock.id))")
//        let name = (data["supplierName"] as? String) ?? "Unknown"
//        AppLog.sync.info("Saved \(name)")
//
//  4. NO LITERAL FORMAT STRINGS.
//     `AppLog.sales.info(String(format: "%@", x))` compiles but reduces the
//     readability advantage. Prefer building the formatted string into a
//     local first:
//        let row = String(format: "TOTAL %.2f", x)
//        AppLog.sales.debug("\(row)")
//
//  ─────────────────────────────────────────────────────────────────────────────
//  AUTOMATED MIGRATION
//  ─────────────────────────────────────────────────────────────────────────────
//  If new `print(...)` calls creep back in (e.g. via copy-paste from Stack
//  Overflow), sweep them with the helper script:
//      python3 Scripts/migrate_prints.py CanakinCafe
//  It safely transforms single-line prints whose only argument is a string
//  literal, picks the level from the leading emoji, and routes to the right
//  category based on file path. Multi-line prints, ternaries, and prints whose
//  argument is a function call (`print(String(format: …))`, etc.) are left
//  alone and reported so they can be migrated by hand.
//

import Foundation
import os
import CanakinStaffShared

/// Application-wide structured logger. Always go through `AppLog.<category>`.
enum AppLog {
    /// Subsystem string used by all categories. Picked up by Console.app's
    /// "Subsystem" filter so you can isolate this app's traffic.
    private static let subsystem: String = Bundle.main.bundleIdentifier ?? "com.canakin.CanakinCafe"

    static let sync        = Logger(subsystem: subsystem, category: "sync")
    static let auth        = Logger(subsystem: subsystem, category: "auth")
    static let db          = Logger(subsystem: subsystem, category: "db")
    static let ui          = Logger(subsystem: subsystem, category: "ui")
    static let sales       = Logger(subsystem: subsystem, category: "sales")
    static let integration = Logger(subsystem: subsystem, category: "integration")
    static let migration   = Logger(subsystem: subsystem, category: "migration")
    static let general     = Logger(subsystem: subsystem, category: "general")
}

// MARK: - Convenience extensions

extension Logger {
    /// Convenience for the very common `print("❌ X: \(error.localizedDescription)")`
    /// pattern. Emits at `.error` level with the localised description appended.
    func error(_ message: String, error: Error) {
        self.error("\(message, privacy: .public) | \(error.localizedDescription, privacy: .public)")
    }
}
