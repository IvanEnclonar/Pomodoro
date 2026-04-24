## 2024-04-24 - Validate AppStorage/UserDefaults as Untrusted Input
**Vulnerability:** Core logic trusted `AppStorage` integer values without clamping and sound strings without whitelisting, which could lead to integer overflows or unexpected state if `UserDefaults` is modified externally or maliciously.
**Learning:** Values from `@AppStorage` or `UserDefaults` should be treated as untrusted external input, not safe internal state, because they can be altered outside the app's UI constraints.
**Prevention:** Always validate, clamp, or whitelist `AppStorage` inputs via safe computed properties before using them in business logic or framework APIs (like `NSSound`).
