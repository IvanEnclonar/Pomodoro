## 2024-10-24 - [Input Validation for AppStorage]
**Vulnerability:** Unchecked usage of `UserDefaults` values in arithmetic operations led to potential integer overflows and logic errors.
**Learning:** Even internal storage like `UserDefaults` should be treated as untrusted input, especially when used in critical logic or arithmetic. Users can modify these values externally.
**Prevention:** Always clamp or validate values from `@AppStorage` or `UserDefaults` before using them in calculations, especially multiplication.
