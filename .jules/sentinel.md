## 2025-02-14 - Ad-Hoc Codesigning and Sandbox Enablement
**Vulnerability:** The standalone app bundle lacked an App Sandbox and Hardened Runtime, violating defense-in-depth principles for a native macOS application.
**Learning:** For standalone swift scripts/bundles without an Xcode project, we can enforce strict capabilities directly via shell scripting using `mktemp` to generate an entitlements plist and applying it via `codesign`. Including an XML comment clarifies the zero-capability configuration for audits.
**Prevention:** Whenever generating standalone apps or bundles via scripts outside Xcode, ensure codesign is invoked with the `--options runtime` flag and a temporary default-deny entitlements file (com.apple.security.app-sandbox = true) to maintain a secure baseline.
