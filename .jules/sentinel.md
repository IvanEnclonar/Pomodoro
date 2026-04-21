## 2026-04-21 - Unvalidated @AppStorage Input Vulnerability
**Vulnerability:** Values managed by `@AppStorage` (UserDefaults) were used directly in calculations and external APIs (`NSSound`) without validation, risking integer overflow traps and unvalidated input vulnerabilities.
**Learning:** `@AppStorage` acts as external input that can be modified outside the app's UI. It cannot be inherently trusted.
**Prevention:** Always validate and clamp `@AppStorage` values via safe computed properties before use in application logic or framework calls.
