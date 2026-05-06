## 2025-02-14 - Unsanitized AppStorage Input Causing Integer Overflow DoS
**Vulnerability:** Values retrieved from `@AppStorage` (UserDefaults) were used directly in multiplication without bounds checking, which can cause a runtime crash (trap) in Swift due to integer overflow if the input is maliciously manipulated or corrupted.
**Learning:** `UserDefaults` should be treated as external, untrusted input. In Swift, integer overflow is not a silent wraparound by default; it causes a crash (trap).
**Prevention:** Always clamp or validate `@AppStorage` numerical inputs to safe boundaries (e.g., `max(1, min(val, 1440))`) before using them in calculations.
