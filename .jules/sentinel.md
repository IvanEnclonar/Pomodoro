## 2024-05-24 - UserDefaults Validation and Whitelisting

**Vulnerability:** The application used `@AppStorage` values directly in framework initializers (`NSSound(named:)`) and calculations without validation. This allowed potential tampering of the raw `UserDefaults` plist file on disk to inject invalid strings or negative duration integers.

**Learning:** `@AppStorage` should be treated as external untrusted input, not as implicitly trusted internal state. Users or processes can modify `UserDefaults` independently of the application's UI constraints. Using unvalidated strings in framework constructors or negative values in time duration logic can lead to unpredictable behavior, UI crashes, or resource issues.

**Prevention:** Always validate values read from `@AppStorage`. Enforce a strict whitelist against known safe values (e.g., `availableSounds.contains()`) before passing strings to APIs. Enforce sane boundaries (e.g., `max(0, value)`) on integers used for durations or indexes.
