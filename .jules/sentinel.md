## 2024-03-24 - Missing App Sandbox and Hardened Runtime in Custom Build Script
**Vulnerability:** The macOS application build script (`build.sh`) was missing code signing, App Sandbox, and Hardened Runtime, running without proper constraints.
**Learning:** Custom shell scripts for macOS builds often omit critical security configurations typically handled automatically by Xcode, creating an architectural security gap.
**Prevention:** Always include `codesign` with an explicit default-deny entitlements file (and Hardened Runtime) when using custom build pipelines.
