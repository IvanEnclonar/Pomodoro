## 2024-05-24 - UserDefaults Integer Overflow Prevention
**Vulnerability:** Untrusted external input from UserDefaults (@AppStorage) can cause integer overflow traps in Swift, leading to local denial of service crashes.
**Learning:** In Swift, integer overflows trap by default. Values retrieved from @AppStorage should not be implicitly trusted and must be validated/clamped to safe ranges.
**Prevention:** Always clamp integer inputs loaded from UserDefaults to known safe boundaries (e.g., 1...1440) before using them in calculations or timer limits.
