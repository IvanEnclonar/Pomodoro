## 2025-04-22 - Unvalidated @AppStorage Input
**Vulnerability:** Values from `@AppStorage` (UserDefaults) were used directly in calculations and framework calls (`NSSound` initialization) without validation. This can lead to integer overflow crashes or unvalidated input vulnerabilities, as `UserDefaults` can be modified externally by malicious actors or corrupted.
**Learning:** `@AppStorage` is an external input source, not implicitly trusted internal state.
**Prevention:** Always validate and clamp `@AppStorage` inputs using safe computed properties (e.g., clamping durations to 1...1440 minutes, whitelisting strings) before using them in the application logic.
