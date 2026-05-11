## 2024-05-11 - Unvalidated UserDefaults Input
**Vulnerability:** Values retrieved from `@AppStorage` (UserDefaults) are used directly without validation in calculations and sensitive APIs (e.g., `NSSound(named:)`).
**Learning:** It is crucial to treat UserDefaults as untrusted external input that can be modified independently of the application's UI. Using unvalidated string input in `NSSound(named:)` can lead to arbitrary sound injection or path traversal. Using unvalidated integer inputs can cause integer overflow and runtime crashes.
**Prevention:** Always clamp integer values from `@AppStorage` to safe boundaries (e.g., `1...1440` minutes) and whitelist string values against predefined allowed lists before utilizing them.
