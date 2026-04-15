## 2024-04-15 - [Unvalidated UserDefaults Input Vulnerability]
**Vulnerability:** Unvalidated values retrieved from `@AppStorage` (UserDefaults) being used directly to initialize `NSSound` objects.
**Learning:** `UserDefaults` values (`@AppStorage`) should not be treated as implicitly trusted internal state. They are external inputs that can be modified independently of the application's UI, potentially causing crashes or unexpected behavior if invalid values are passed to system APIs.
**Prevention:** Always validate configuration values retrieved from `UserDefaults` against a whitelist of known safe boundaries or enums before passing them to sensitive APIs or framework functions.
