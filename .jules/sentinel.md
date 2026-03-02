## 2026-03-02 - [CRITICAL] Sanitize UserDefaults Data Before Use
**Vulnerability:** Core logic and native resource calls implicitly trusted user-modifiable values directly from `UserDefaults` (via `@AppStorage`).
**Learning:** `UserDefaults` data can be altered directly via the `defaults` command-line utility or by editing plist files. Untrusted injection of resource strings into `NSSound` initialization and unconstrained numbers into mathematical date calculations created risks of denial-of-service, crashes, and integer overflows.
**Prevention:** Always treat `@AppStorage` and `UserDefaults` values as potentially malicious input. Explicitly validate strings against a known allowlist and enforce min/max bounds (clamping) on integer inputs before involving them in critical operations.
