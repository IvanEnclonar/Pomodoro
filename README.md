# 🍅 Pomodoro

A minimal, native macOS Pomodoro Timer that lives in your menu bar. Built with SwiftUI — no Xcode required.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **⏱ Pomodoro Timer** — Focus / Short Break / Long Break cycle with 4-session rounds
- **📊 Dashboard** — Today's focus time, session count, streak tracker, weekly bar chart, and 30-day heatmap
- **🔥 Streak Tracking** — Configurable daily minimum (default: 25 min) to count toward your streak
- **🔔 Completion Sound** — Choose from 14 macOS system sounds (Ping, Glass, Hero, etc.)
- **⚙️ Customizable** — Adjustable focus/break durations, auto-start breaks toggle
- **🎨 Appearance** — Pick an accent color (Clay, Fig, Kraft, Aqua, Violet, Graphite) and a display font (Serif, Sans, Rounded, Mono); changes apply instantly
- **🖥 Menu Bar App** — Lives in the menu bar with a live countdown and a mark showing where you are in the four-session round; click it for controls and today's stats. No Dock icon
- **💾 Persistent Stats** — 365 days of focus history saved via UserDefaults
- **📱 Remote Control** — Start, pause, stop, and skip sessions from your phone via a web UI

## Build & Run

No Xcode project needed — just a shell script:

```bash
git clone https://github.com/ivanenclonar/Pomodoro.git
cd Pomodoro
bash build.sh
open Pomodoro.app
```

### Requirements

- macOS 15 (Sequoia) or later
- Apple Silicon (arm64)
- Xcode Command Line Tools (`xcode-select --install`)

## Usage

1. **Start/Pause** — Click play/pause in the window or use the menu bar dropdown
2. **Show Window** — Click the menu bar item → "Open Pomodoro" (⌘O)
3. **Dashboard** — Switch to the Dashboard tab (⌘2) to see your stats, streak, and heatmap
4. **Settings** — ⌘, to configure durations, sounds, and streak minimum
5. **Quit** — Menu bar → "Quit Pomodoro" (⌘Q)

## Remote Control (Phone)

Control the timer from your phone browser using Supabase (real-time database) and Vercel (web UI). Both are free for personal use.

### 1. Set up Supabase

Create a free project at [supabase.com](https://supabase.com), then run this SQL in the editor:

```sql
create table timer_state (
  id int primary key default 1 check (id = 1),
  timer_state text not null default 'stopped',
  session_state text not null default 'focus',
  time_remaining int not null default 1500,
  session_count int not null default 0,
  command text default null,
  updated_at timestamptz default now()
);
insert into timer_state default values;
alter table timer_state enable row level security;
create policy "Allow all with anon key" on timer_state for all using (true) with check (true);
```

Note your **Project URL** and **anon public key** from Project Settings → API.

### 2. Configure the Mac app

Open Settings (⌘,) → **Remote Control**:
- Paste your Supabase URL and anon key
- Toggle **Enable Remote Control** on

### 3. Deploy the web UI

```bash
cd web
cp .env.local.example .env.local
# Fill in NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY,
# AUTH_PASSWORD (your chosen password), and AUTH_SECRET (see below)
```

Generate a random secret for `AUTH_SECRET`:
```bash
openssl rand -hex 32
```

Test locally first:
```bash
npm install
npm run dev   # open http://localhost:3000
```

Deploy to Vercel (add the same env vars in Vercel project settings):
```bash
npx vercel
```

Open the deployed URL on your phone, enter your password, and control the timer from anywhere.

## Project Structure

```
Sources/Pomodoro/
├── PomodoroApp.swift      # App entry, WindowGroup, MenuBarExtra
├── TimerManager.swift     # Timer logic, persistence, streak calculation
├── ContentView.swift      # Main window: Timer / Dashboard switcher and timer screen
├── StatsView.swift        # Dashboard: stats, weekly chart, heatmap
├── SettingsView.swift     # Preferences: durations, sound, streak min, remote control
├── MenuBarView.swift      # Menu bar label (live cycle mark + countdown) and popover
├── Paper.swift            # Warm "Paper" palette, type, and shared components
├── SupabaseSync.swift     # Remote control: pushes status, polls commands via URLSession
└── GlassEffect.swift      # macOS 26 glass / material view modifiers

scripts/make_icon.swift    # Renders AppIcon.icns and the web icon (swift scripts/make_icon.swift)

web/                       # Phone control UI (Next.js + Supabase)
├── app/
│   ├── page.tsx           # Timer control UI with real-time updates
│   ├── login/page.tsx     # Password login
│   └── api/auth/route.ts  # Auth API (sets/clears session cookie)
└── middleware.ts          # Protects all routes with cookie auth
```

## License

MIT
