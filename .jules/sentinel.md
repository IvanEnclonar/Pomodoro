## 2024-05-18 - Missing macOS App Sandbox
**Vulnerability:** The standalone Pomodoro application bundle was built without codesigning, hardened runtime, or the App Sandbox.
**Learning:** Shell-script-built Swift macOS applications lack Xcode's automatic entitlements management, leading to unrestricted execution privileges by default if not explicitly sandboxed.
**Prevention:** Always apply an explicit default-deny App Sandbox (`com.apple.security.app-sandbox`) and hardened runtime via ad-hoc codesigning when generating macOS application bundles manually.
