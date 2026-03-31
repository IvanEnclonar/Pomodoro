# Sentinel Journal

## 2024-05-24 - Unvalidated AppStorage Input Leading to Unintended System API Calls
**Vulnerability:** The application reads a `completionSound` string from `@AppStorage` without validation and passes it directly to `NSSound(named:)`.
**Learning:** Values originating from `@AppStorage` (UserDefaults) represent untrusted user input and can be externally modified to arbitrary strings. Passing these unvalidated values directly to system APIs creates an entry point for potential unexpected behavior or injection.
**Prevention:** Always validate values read from `@AppStorage` against a whitelist of expected, safe values before using them in sensitive operations or passing them to system APIs.
