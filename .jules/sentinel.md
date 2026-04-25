## 2026-04-25 - Unvalidated AppStorage Input Vulnerability
**Vulnerability:** @AppStorage properties (UserDefaults) were used directly without validation, potentially leading to local DoS (integer overflows) or unvalidated input passed to APIs like NSSound.
**Learning:** UserDefaults cannot be trusted as internal state since it can be manipulated externally. Swift's default behavior of trapping on integer overflow turns corrupted UserDefaults integer values into a local DoS vector.
**Prevention:** Always use safe computed properties to clamp integers and validate strings against known whitelists before using @AppStorage values.
