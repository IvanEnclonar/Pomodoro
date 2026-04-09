## 2024-04-09 - Fix unvalidated UserDefaults input in AppStorage

**Vulnerability:** `completionSound` and duration minutes retrieved from `@AppStorage` (which wraps `UserDefaults`) were used directly without validation. This allowed arbitrary string injection into `NSSound(named:)` and potential negative duration logic bugs if the underlying `UserDefaults` plist was tampered with externally.

**Learning:** `@AppStorage` values are external inputs and should never be implicitly trusted. They can be modified by users outside of the app's UI, leading to unexpected behavior or potential security issues when interacting with system frameworks like AppKit.

**Prevention:** Always validate `@AppStorage` variables against a known safe whitelist or bounds (e.g., using `max(0, ...)` for numeric values or checking against an array of allowed strings) before using them in application logic or framework calls.