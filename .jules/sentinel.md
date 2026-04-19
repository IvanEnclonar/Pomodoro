## 2024-04-19 - [Fix Unvalidated UserDefaults Input]
**Vulnerability:** `@AppStorage` (UserDefaults) values such as `completionSound` and timer durations were used directly in `NSSound` initialization and calculations without bounds checking or validation.
**Learning:** `UserDefaults` should not be treated as implicitly trusted internal state; it can be modified independently of the application's UI, leading to potential unvalidated input vulnerabilities (e.g. crashes from integer overflows).
**Prevention:** Always validate and clamp values from `@AppStorage` against a known whitelist or safe boundaries (e.g. 1...1440 minutes) before using them in sensitive APIs or framework calls.
