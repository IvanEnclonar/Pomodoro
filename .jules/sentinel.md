## 2024-05-15 - [CRITICAL] Prevent UserDefaults Unvalidated Input
**Vulnerability:** `@AppStorage` values like durations and completion sound were directly utilized in critical pathways such as `NSSound` instantiation without validation, making it susceptible to a local Denial-of-Service or logic disruption if manipulated.
**Learning:** External inputs like `UserDefaults` via `@AppStorage` should not be trusted intrinsically and must be validated/clamped before logic utilization.
**Prevention:** Use privately computed properties to clamp/validate raw `@AppStorage` strings/integers against allowed bounds or explicit whitelists.
