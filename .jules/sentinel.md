## 2026-04-03 - [MEDIUM] AppStorage Unvalidated Input Pattern

**Vulnerability:** The application used `@AppStorage("completionSound")` directly to instantiate an `NSSound` object (`NSSound(named: NSSound.Name(completionSound))?.play()`). Because `@AppStorage` reads directly from macOS `UserDefaults` (which is stored as plaintext and can be tampered with externally), this constitutes an unvalidated input vulnerability where external processes could inject arbitrary string values.

**Learning:** The `@AppStorage` properties in SwiftUI are convenient but represent an unvalidated boundary with the underlying OS configuration. They should not be used directly in security-sensitive or unstable operations without proper validation, as local DoS or unintended behavior can occur if the local defaults file is tampered with.

**Prevention:** Ensure that values read from `@AppStorage` (or `UserDefaults`) that expect a restricted set of known inputs are validated against a whitelist (e.g., `availableSounds.contains(value) ? value : default`) before being processed by application logic.
