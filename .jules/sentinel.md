## 2025-02-18 - Prevent DoS via UserDefaults Integer Overflow
**Vulnerability:** The application reads `@AppStorage` values directly into Swift's `Int` type and uses them in calculations without bounds checking. A malicious actor with access to the user's defaults could set these values to an extreme number causing integer overflow crashes (local DoS) due to Swift's default overflow trapping.
**Learning:** `@AppStorage` (UserDefaults) should be treated as untrusted external input and must be validated and clamped to safe boundaries before use.
**Prevention:** Always introduce `safe` wrapper properties that clamp untrusted values to a sane range (e.g., `1...1440` minutes) before they are used in any sensitive operations.
