## 2024-04-02 - Missing App Sandbox and Hardened Runtime in Build Script
**Vulnerability:** The build script created the application bundle without codesigning it with Hardened Runtime or the macOS App Sandbox enabled. This allowed the app to run with the full permissions of the user.
**Learning:** Even simple SwiftUI apps built outside of Xcode require explicit ad-hoc codesigning with an entitlements file to enforce sandboxing and hardened runtime. A zero-capability sandbox is a good default.
**Prevention:** Always include a `codesign` step with `--options runtime` and an explicit `entitlements.plist` enabling `com.apple.security.app-sandbox` when building macOS app bundles via shell scripts.
