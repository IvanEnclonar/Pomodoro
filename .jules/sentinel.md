## 2026-02-28 - [UserDefaults Injection]
**Vulnerability:** Untrusted input from `@AppStorage` (UserDefaults) was directly used for duration calculations and resource loading (`NSSound`).
**Learning:** macOS preferences can be manipulated externally via terminal `defaults write` or directly editing plist files.
**Prevention:** Treat all `@AppStorage` values as untrusted input. Validate strings against allowlists and clamp numeric inputs before use.
