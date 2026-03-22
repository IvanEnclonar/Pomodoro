## 2024-03-22 - Missing App Sandbox and Hardened Runtime in Build Script
**Vulnerability:** The standalone build script (`build.sh`) does not code sign the application bundle with the macOS App Sandbox or Hardened Runtime enabled, leaving the application without fundamental macOS security boundaries.
**Learning:** When building macOS applications outside of Xcode using ad-hoc shell scripts, security features like the App Sandbox and Hardened Runtime are not applied automatically and must be explicitly enforced via `codesign` and an entitlements file.
**Prevention:** Always include a `codesign` step with `--options runtime` and an entitlements file specifying `<key>com.apple.security.app-sandbox</key><true/>` in custom macOS build scripts.
