## 2024-03-09 - Integer Overflow DoS via Unvalidated @AppStorage

**Vulnerability:** The application's core timer calculation used unvalidated values directly from `@AppStorage` (`focusDurationMinutes`, `shortBreakDurationMinutes`, `longBreakDurationMinutes`, `streakMinMinutes`). When maliciously altered via `UserDefaults`, extreme values multiplied by 60 caused integer overflows, leading to a local Denial of Service (DoS) by consistently crashing the application.

**Learning:** Due to Swift's default behavior of trapping on integer overflow, reading numbers from unvalidated storage (`UserDefaults`/`@AppStorage`) represents untrusted user input and can lead to immediate crashes when used in arithmetic or loops. The App Sandbox is designed to protect system resources, but untrusted local preferences represent an application-level threat vector that can compromise the application's availability.

**Prevention:** Always treat `@AppStorage` values as untrusted input. Before using these inputs in arithmetic operations, array accesses, or loops, safely sanitize them by clamping the values within reasonable bounds (e.g., `max(1, min(value, 1440))`).
