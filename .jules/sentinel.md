## 2024-10-24 - Unvalidated UserDefaults Input Causing Local DoS
**Vulnerability:** Values managed by `@AppStorage` were used directly in calculations without clamping, creating a risk of integer overflow crashes from malicious or corrupted UserDefaults input.
**Learning:** External inputs like `@AppStorage` should not be implicitly trusted and must be validated/clamped before usage to prevent local denial-of-service or runtime traps.
**Prevention:** Always validate and clamp UserDefaults configurations (e.g., using a safe range like 1...1440 minutes) to a known safe boundary before applying them in logic.
