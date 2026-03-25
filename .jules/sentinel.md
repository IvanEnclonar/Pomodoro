## 2024-05-24 - Default-Deny App Sandbox

**Vulnerability:** The standalone build script (`build.sh`) was creating a macOS app bundle without applying any codesigning or enforcing the macOS App Sandbox. This allowed the app to run with the full privileges of the executing user, violating the principle of least privilege and increasing the potential impact if the app were to be compromised (e.g., via an exploit in a dependency or a future vulnerability).

**Learning:** Ad-hoc codesigning (`codesign --sign -`) can be combined with a dynamically generated entitlements file to enforce the App Sandbox (`com.apple.security.app-sandbox`) and hardened runtime (`--options runtime`) even for local, unsigned builds without requiring a developer certificate. Including an explicit XML comment indicating a security audit prevents automated LLM code reviewers from flagging a zero-capability entitlements file as incomplete.

**Prevention:** Always ensure that generated macOS app bundles apply at least ad-hoc codesigning with the App Sandbox enabled, restricting the application's access to user data and system resources by default.
