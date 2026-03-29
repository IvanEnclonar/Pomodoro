## 2024-05-22 - Untrusted UserDefaults via @AppStorage
**Vulnerability:** Values from `UserDefaults` (via `@AppStorage`) were used directly in timer duration calculations without validation.
**Learning:** `@AppStorage` provides convenient UI binding but does not validate input. `UserDefaults` can be modified externally or corrupted, leading to logic errors (negative time) or potential overflows in critical logic.
**Prevention:** Always clamp or validate `@AppStorage` values before using them in critical logic, or use a computed property wrapper that enforces validity.
