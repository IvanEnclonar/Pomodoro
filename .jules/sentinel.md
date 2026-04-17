## 2024-04-17 - [Unvalidated AppStorage Input Vulnerability]
**Vulnerability:** The application used unvalidated values from `@AppStorage` (UserDefaults) directly in sensitive operations like `NSSound` initialization and duration calculations. This could lead to runtime crashes or arbitrary resource loading if the UserDefaults were modified externally.
**Learning:** Values managed by `@AppStorage` should not be treated as implicitly trusted internal state. They are a form of external input that can be modified independently of the application's UI, and must be validated against a known whitelist or safe boundaries before usage.
**Prevention:** Always validate and clamp `@AppStorage` values using safe computed properties before using them in calculations or framework calls.
