## 2026-01-14 - UserDefaults as Untrusted Input
**Vulnerability:** The application used values from `UserDefaults` (via `@AppStorage`) directly in critical logic (timer duration, streak calculation, sound loading) without validation.
**Learning:** `UserDefaults` can be modified externally or corrupted, leading to invalid states (negative duration) or potential resource misuse (loading arbitrary sounds). Even in a local-only app, treating configuration as untrusted input is vital for robustness and integrity.
**Prevention:** Always validate and clamp configuration values read from storage before using them in logic or calculations. Use strict allowlists for resource loading (e.g., sound names).
