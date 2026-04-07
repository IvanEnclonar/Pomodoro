## 2026-04-07 - Validate AppStorage Inputs for Framework APIs
**Vulnerability:** Unvalidated AppStorage inputs passed directly to framework APIs like NSSound.
**Learning:** Values managed by @AppStorage must not be implicitly trusted and can be tampered with via UserDefaults.
**Prevention:** Always validate external configuration inputs against a known whitelist before using them in initializers.
