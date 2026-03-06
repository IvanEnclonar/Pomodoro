## 2026-03-06 - Unvalidated @AppStorage Integer Overflow Risk
**Vulnerability:** Untrusted integers from UserDefaults (via @AppStorage) are directly multiplied by 60 without bounds checking. Because Swift integer overflows trap by default, an external actor (or malformed plist) injecting excessively large values causes the app to crash (Local Denial of Service).
**Learning:** @AppStorage properties read directly from UserDefaults, which is outside the app's immediate memory space and can be altered externally via `defaults write` or editing the property list file. They must be treated as untrusted input.
**Prevention:** Always clamp @AppStorage numeric inputs to safe, expected ranges before using them in arithmetic operations or critical logic.
