## 2024-05-01 - Untrusted @AppStorage Input Causes Local DoS
**Vulnerability:** The application uses `@AppStorage` (UserDefaults) values directly in mathematical calculations. Since UserDefaults can be modified externally, arbitrarily large integers cause Swift to trap on integer overflow, leading to a local DoS.
**Learning:** Values managed by `@AppStorage` are external inputs and should not be treated as implicitly trusted internal state. They bypass UI bounds and must be validated.
**Prevention:** Always validate and clamp `@AppStorage` inputs against safe boundaries (e.g., 1...1440 minutes) using private computed properties before utilizing them.
