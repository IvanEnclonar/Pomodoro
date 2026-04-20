## 2024-04-20 - Unvalidated @AppStorage Input Leading to Runtime Crashes/Vulnerabilities
**Vulnerability:** Values from `@AppStorage` (UserDefaults) were used directly in calculations and native API calls (like `NSSound`) without validation, allowing potential DoS (via integer overflow trapping) or unexpected behavior if UserDefaults were externally modified.
**Learning:** `@AppStorage` variables are external inputs and must be treated as untrusted. Swift's default overflow trapping combined with unvalidated integers from UserDefaults creates an easy local DoS vector.
**Prevention:** Always implement private computed properties that clamp numerical limits and validate strings against whitelists before passing `@AppStorage` values into application logic or system APIs.
