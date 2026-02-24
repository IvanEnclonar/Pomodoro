## 2025-05-15 - Input Validation for User Defaults
**Vulnerability:** Application state (timers, streaks) depended directly on unvalidated `UserDefaults` values via `@AppStorage`. A malicious actor or corrupted plist could inject negative or extremely large values, causing logic errors or Denial of Service (infinite loops, crashes).
**Learning:** Even local storage like `UserDefaults` should be treated as untrusted input, especially when it drives critical application logic like timer durations.
**Prevention:** Always validate and clamp values read from persistence layers before using them in calculations or state transitions. Use computed properties or accessors to enforce safe boundaries.
