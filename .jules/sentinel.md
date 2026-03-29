## 2024-05-24 - Missing App Sandbox and Hardened Runtime in Standalone Build
**Vulnerability:** The application was built via a custom shell script (`build.sh`) without enabling macOS App Sandbox or Hardened Runtime, violating defense-in-depth principles and leaving the application with unnecessary privileges.
**Learning:** Standalone `swiftc` builds do not automatically apply the standard Xcode security protections. An entitlements file must be explicitly generated and passed to the `codesign` tool.
**Prevention:** Always verify that custom build scripts manually invoke `codesign` with an `entitlements.plist` file containing `<key>com.apple.security.app-sandbox</key><true/>` and pass the `--options runtime` flag.
