## 2026-05-03 - Prevent Integer Overflow DoS via UserDefaults
**Vulnerability:** `@AppStorage` values like `focusDurationMinutes` are stored in `UserDefaults` which can be externally modified to extremely large numbers. Using these unvalidated values in calculations like `focusDurationMinutes * 60` can cause integer overflow crashes (DoS) because Swift safely traps overflows.
**Learning:** We must not implicitly trust `@AppStorage` as safe internal state. Even though the UI might bound values, an attacker or external configuration can supply values outside those UI bounds.
**Prevention:** Always clamp or validate values retrieved from `@AppStorage` against a known safe range (e.g., `1...1440` minutes) before using them in application logic or calculations.
