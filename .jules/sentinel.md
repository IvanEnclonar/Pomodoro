## 2024-04-05 - Unvalidated AppStorage as Input

**Vulnerability:** The application was directly instantiating an `NSSound` object using an unvalidated `String` retrieved from `@AppStorage` (`UserDefaults`).
**Learning:** `UserDefaults` state managed by `@AppStorage` should not be treated as implicitly trusted internal state. It is a form of external input that can be modified independently of the application's UI, potentially leading to the use of unexpected or unsafe values (e.g., loading an unexpected file or missing an asset).
**Prevention:** Always validate values read from `UserDefaults` / `@AppStorage` against a known whitelist or safe boundaries before using them in sensitive APIs or external framework calls.
