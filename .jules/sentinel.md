## 2024-05-23 - Trusting Local Storage Input
**Vulnerability:** The application trusted values from `UserDefaults` (via `@AppStorage`) directly in critical logic and arithmetic without validation.
**Learning:** `UserDefaults` files are stored as plain XML/Binary plists on disk and can be easily modified by users or malware running with user privileges. Treating them as trusted input can lead to logic errors, crashes (division by zero), or unexpected behavior (negative durations).
**Prevention:** Always treat `@AppStorage` and `UserDefaults` values as untrusted external input. Validate and clamp them to safe ranges before use.
