## 2026-03-15 - Missing macOS App Sandbox and Hardened Runtime
**Vulnerability:** The standalone app built via `build.sh` was not enforcing the macOS App Sandbox (`com.apple.security.app-sandbox`) or Hardened Runtime (`--options runtime`), leaving the application without critical defense-in-depth isolation against local exploitation.
**Learning:** Shell-based build scripts for macOS apps often omit proper entitlements and ad-hoc codesigning by default, meaning the resulting `.app` bundle has full user privileges and bypasses standard macOS security restrictions.
**Prevention:** Always generate an `entitlements.plist` file with App Sandbox enabled and pass it to the `codesign` tool along with the `--options runtime` flag during the bundle creation process in standalone build scripts.
