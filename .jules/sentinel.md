## 2024-04-18 - Unvalidated AppStorage Inputs

**Vulnerability:** The application was directly instantiating `NSSound` using a string loaded from `@AppStorage("completionSound")` in `TimerManager.swift` and `SettingsView.swift` without validating it against a whitelist.
**Learning:** Values managed by `@AppStorage` (UserDefaults) should not be treated as implicitly trusted internal state. It is a form of external input that can be modified independently of the application's UI, and must be validated against a known whitelist or safe boundaries before usage in sensitive APIs or framework calls.
**Prevention:** Always validate external configuration and persistent state data (like UserDefaults) against expected bounds or whitelists (e.g., using a safe computed property) before passing it to system frameworks or instantiating objects dynamically.
