## 2026-05-09 - Fix UserDefaults Local DoS
**Vulnerability:** Unvalidated `@AppStorage` (UserDefaults) values in Swift can trigger default integer overflow traps when used in mathematical operations, leading to an unhandled exception and application crash (local Denial of Service).
**Learning:** `UserDefaults` should be treated as untrusted external input because it can be modified independently of the application's UI. Reading unvalidated values and performing arithmetic without clamping exposes the application to DoS attacks.
**Prevention:** Always validate and clamp values retrieved from `@AppStorage` against a known safe boundary or whitelist before usage in calculations or framework calls.
