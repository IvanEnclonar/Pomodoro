# 🍅 Pomodoro

A minimal, native macOS Pomodoro Timer that lives in your menu bar. Built with SwiftUI — no Xcode required.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **⏱ Pomodoro Timer** — Focus / Short Break / Long Break cycle with 4-session rounds
- **📊 Dashboard** — Today's focus time, session count, streak tracker, weekly bar chart, and 30-day heatmap
- **🔥 Streak Tracking** — Configurable daily minimum (default: 25 min) to count toward your streak
- **🔔 Completion Sound** — Choose from 14 macOS system sounds (Ping, Glass, Hero, etc.)
- **⚙️ Customizable** — Adjustable focus/break durations, auto-start breaks toggle
- **🖥 Menu Bar App** — Lives in the menu bar with live countdown, no Dock icon
- **💾 Persistent Stats** — 365 days of focus history saved via UserDefaults
- **✨ Smooth Transitions** — Animated session changes with color-coded states

## Build & Run

No Xcode project needed — just a shell script:

```bash
git clone https://github.com/ivanenclonar/Pomodoro.git
cd Pomodoro
bash build.sh
open Pomodoro.app
```

### Requirements

- macOS 13 (Ventura) or later
- Apple Silicon (arm64) — the build script targets `arm64-apple-macosx13.0`
- Xcode Command Line Tools (`xcode-select --install`)

## Usage

1. **Start/Pause** — Click play/pause in the window or use the menu bar dropdown
2. **Show Window** — Click the menu bar icon → "Show Window" (⌘O)
3. **Dashboard** — Click the chart icon to see your stats, streak, and heatmap
4. **Settings** — ⌘, to configure durations, sounds, and streak minimum
5. **Quit** — Menu bar → "Quit Pomodoro" (⌘Q)

## Project Structure

```
Sources/Pomodoro/
├── PomodoroApp.swift      # App entry, WindowGroup, MenuBarExtra
├── TimerManager.swift     # Timer logic, persistence, streak calculation
├── ContentView.swift      # Main timer UI with session indicators
├── StatsView.swift        # Dashboard: stats, weekly chart, heatmap
└── SettingsView.swift     # Preferences: durations, sound, streak min
```

## License

MIT
