## 2024-05-24 - Integer Overflow leading to Local Denial of Service
**Vulnerability:** `@AppStorage` values were used directly in integer multiplication (`streakMinMinutes * 60`), which can cause an integer overflow trap and crash the app if a malicious or corrupted large value is present in `UserDefaults`.
**Learning:** `@AppStorage` (UserDefaults) should be treated as untrusted external input and validated/clamped before use, as integer overflows trap by default in Swift.
**Prevention:** Always clamp `@AppStorage` numerical inputs to safe boundaries (e.g., `1...1440` minutes) using private computed properties before using them in calculations.
