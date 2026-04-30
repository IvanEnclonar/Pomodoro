1. **Clamp `@AppStorage` Values in `TimerManager.swift`**
   - Add private computed properties (`safeFocusDurationMinutes`, `safeShortBreakDurationMinutes`, `safeLongBreakDurationMinutes`, `safeStreakMinMinutes`) to clamp user-controlled duration values between 1 and 1440 minutes.
   - Update `totalDuration(for:)` to use these safe properties to prevent integer overflow crashes.
   - Update `currentStreak` to use `safeStreakMinMinutes` to prevent integer overflow crashes.
2. **Verify changes**
   - Use `read_file` on `Sources/Pomodoro/TimerManager.swift` to verify the changes.
3. **Run all relevant tests**
   - Run all relevant tests (acknowledge that no test targets are available in the repository).
4. **Update Sentinel Journal**
   - Create `.jules/sentinel.md` and add an entry detailing the integer overflow crash vulnerability from unvalidated UserDefaults.
   - Verify the journal entry using `read_file` on `.jules/sentinel.md`.
5. **Pre-commit Steps**
   - Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
6. **Submit PR**
   - Submit the PR with the title '🛡️ Sentinel: [HIGH] Fix integer overflow crash from unvalidated UserDefaults'.
