## 2024-05-24 - Unvalidated AppStorage Input to NSSound

**Vulnerability:** The application was directly using the `completionSound` string stored in `@AppStorage` (UserDefaults) to initialize `NSSound(named:)`.
**Learning:** Values managed by `@AppStorage` should not be treated as implicitly trusted internal state. They are a form of external input that can be modified independently of the application's UI (e.g., via the `defaults` command line tool or property list manipulation). Passing unvalidated input to external frameworks or APIs can lead to unexpected behavior or potential vulnerabilities.
**Prevention:** Always validate values read from `@AppStorage` against a known whitelist or safe boundaries before using them in sensitive APIs, framework calls, or business logic.
