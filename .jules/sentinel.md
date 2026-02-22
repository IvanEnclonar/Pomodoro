## 2024-05-22 - Unvalidated Configuration Persistence
**Vulnerability:** `TimerManager` directly trusted values loaded from `UserDefaults` via `@AppStorage` property wrappers. This allowed for potentially invalid states (negative durations, excessive values) if the underlying plist was tampered with.
**Learning:** Convenience wrappers like `@AppStorage` prioritize ease of use over security and do not offer built-in validation hooks. Trusting external storage implicitly is a risk even for local data.
**Prevention:** Always implement a validation step (e.g., `validateSettings()`) in the initialization phase of classes that load external configuration to enforce safe bounds and sane defaults.
