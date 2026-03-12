## 2024-05-18 - Untrusted User Defaults Input DoS

**Vulnerability:** `@AppStorage` automatically maps untrusted system values directly to local properties. Unchecked integers could exceed bounds and crash via integer overflow when calculating time variables. Unvalidated strings passed to `NSSound` could load arbitrary system resources or cause crashes.
**Learning:** External or persistent state cannot be implicitly trusted even in simple apps. Swift's crash-on-overflow can turn simple logic errors into local Denial of Service via parameter tampering.
**Prevention:** Clamp untrusted `@AppStorage` integer inputs before mathematical operations using `max()` and `min()`. Validate untrusted strings against explicitly defined allowlists before resource loading.
