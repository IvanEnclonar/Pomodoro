## 2024-05-08 - UserDefaults Integer Overflow Crash (Local DoS)
**Vulnerability:** Retrieving unbounded integer values from `@AppStorage` (UserDefaults) and using them in mathematical operations (like multiplying by 60) can cause Swift to trap (crash) due to integer overflow, leading to a local denial-of-service.
**Learning:** Values from `@AppStorage` represent untrusted external input that can be modified outside the application's UI. They must not be treated as implicitly trusted internal state.
**Prevention:** Always validate and clamp integer inputs from UserDefaults to a safe boundary (e.g., 1...1440) before performing arithmetic or using them in logic.
