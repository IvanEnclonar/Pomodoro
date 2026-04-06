## 2024-04-06 - Unvalidated UserDefaults Input Used in Framework Calls
**Vulnerability:** The application used values directly from `@AppStorage` (`UserDefaults`) to construct an `NSSound.Name` and play a sound without validation. UserDefaults can be modified externally and should not be treated as trusted internal state.
**Learning:** External input (even from UserDefaults) must be validated against a known whitelist or safe boundaries before usage in sensitive APIs or framework calls to prevent unexpected behavior.
**Prevention:** Always validate values read from `@AppStorage` against a whitelist (e.g., using a safe wrapper property) before passing them to internal frameworks.
