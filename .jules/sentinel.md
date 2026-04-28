## 2024-05-24 - Unsanitized UserDefaults Input Risk
**Vulnerability:** `@AppStorage` values were used directly in calculations without validation, creating a risk of integer overflow and application crashes if a malicious or corrupted value was set via UserDefaults.
**Learning:** In Swift, `@AppStorage` reads from external storage (UserDefaults). Values can be modified outside the application's UI, meaning they should be treated as untrusted input. Directly multiplying untrusted inputs by 60 can lead to integer overflow traps.
**Prevention:** Always validate and clamp `@AppStorage` values to safe, expected ranges before using them in internal logic or calculations.
