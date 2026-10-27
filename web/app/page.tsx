'use client'

import { useEffect, useRef, useState } from 'react'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

interface TimerState {
  timer_state: 'stopped' | 'running' | 'paused'
  session_state: 'focus' | 'shortBreak' | 'longBreak'
  time_remaining: number
  session_count: number
  updated_at: string
}

// The Mac pushes its status every 10 seconds; anything older means it's gone quiet.
const OFFLINE_AFTER_MS = 30_000

function formatTime(seconds: number) {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

const SESSION_LABELS: Record<string, string> = {
  focus: 'Focus',
  shortBreak: 'Short break',
  longBreak: 'Long break',
}

const SESSION_COLORS: Record<string, string> = {
  focus: 'var(--clay)',
  shortBreak: 'var(--olive)',
  longBreak: 'var(--sky)',
}

function sessionDetail(state: TimerState) {
  const inCycle = state.session_count % 4
  if (state.session_state === 'focus') return `Session ${inCycle + 1} of 4`
  if (state.session_state === 'shortBreak') return `After session ${inCycle}`
  return 'Cycle complete'
}

function upNext(state: TimerState) {
  if (state.session_state !== 'focus') return 'Focus'
  return (state.session_count + 1) % 4 === 0 ? 'Long break' : 'Short break'
}

async function sendCommand(command: string) {
  await supabase.from('timer_state').update({ command }).eq('id', 1)
}

export default function Page() {
  const [state, setState] = useState<TimerState | null>(null)
  const [displayTime, setDisplayTime] = useState(0)
  const [loading, setLoading] = useState(true)
  const [pending, setPending] = useState(false)
  const [now, setNow] = useState(() => Date.now())
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const pendingTimeout = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Snap display time to real value on every DB update
  useEffect(() => {
    if (state) setDisplayTime(state.time_remaining)
    setPending(false)
  }, [state])

  // Local 1-second tick — only while running
  useEffect(() => {
    if (intervalRef.current) clearInterval(intervalRef.current)
    if (state?.timer_state !== 'running') return
    intervalRef.current = setInterval(() => {
      setDisplayTime(t => Math.max(0, t - 1))
    }, 1000)
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current)
    }
  }, [state?.timer_state, state?.time_remaining])

  // Re-check whether the Mac is still reporting in
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 5000)
    return () => clearInterval(id)
  }, [])

  async function send(command: string) {
    setPending(true)
    if (pendingTimeout.current) clearTimeout(pendingTimeout.current)
    pendingTimeout.current = setTimeout(() => setPending(false), 15_000)
    await sendCommand(command)
  }

  async function logout() {
    await fetch('/api/auth', { method: 'DELETE' })
    window.location.href = '/login'
  }

  useEffect(() => {
    // Fetch initial state
    supabase
      .from('timer_state')
      .select('timer_state,session_state,time_remaining,session_count,updated_at')
      .eq('id', 1)
      .single()
      .then(({ data }) => {
        if (data) setState(data as TimerState)
        setLoading(false)
      })

    // Real-time subscription
    const channel = supabase
      .channel('timer')
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'timer_state' },
        (payload) => {
          setState(payload.new as TimerState)
        }
      )
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  if (loading || !state) {
    return (
      <main style={styles.message}>
        <h1 style={styles.brand}>Pomodoro</h1>
        <p style={styles.muted}>
          {loading
            ? 'Connecting…'
            : 'Mac app is not connected. Make sure remote control is enabled in settings.'}
        </p>
      </main>
    )
  }

  const accent = SESSION_COLORS[state.session_state] ?? 'var(--clay)'
  const isRunning = state.timer_state === 'running'
  const isPaused = state.timer_state === 'paused'
  const isStopped = state.timer_state === 'stopped'
  const connected = now - Date.parse(state.updated_at) < OFFLINE_AFTER_MS
  const primaryLabel = pending ? 'Sending…' : isRunning ? 'Pause' : isPaused ? 'Resume' : 'Start'

  return (
    <main style={styles.screen}>
      <header style={styles.header}>
        <h1 style={styles.brand}>Pomodoro</h1>
        <span style={styles.chip}>
          <span style={{ ...styles.dot, background: connected ? 'var(--olive)' : 'var(--idle)' }} />
          {connected ? 'Mac connected' : 'Mac offline'}
        </span>
      </header>

      <section style={styles.center}>
        <div style={styles.sessionRow}>
          <span style={{ ...styles.dot, width: 8, height: 8, background: accent }} />
          <span style={{ fontWeight: 500, color: 'var(--text-2)' }}>{SESSION_LABELS[state.session_state]}</span>
          <span style={styles.muted} aria-hidden="true">·</span>
          <span style={styles.muted}>{sessionDetail(state)}</span>
        </div>
        <div style={styles.timer} aria-live="off">{formatTime(displayTime)}</div>
        <p style={{ ...styles.muted, margin: 0 }}>Up next: {upNext(state)}</p>
      </section>

      <footer style={styles.controls}>
        <button
          style={styles.primary}
          disabled={pending}
          onClick={() => send(isRunning ? 'pause' : 'start')}
        >
          {!pending && (isRunning ? <PauseIcon /> : <PlayIcon />)}
          {primaryLabel}
        </button>

        <div style={styles.row}>
          <button style={styles.secondary} disabled={pending} onClick={() => send('skip')}>
            <SkipIcon />
            Skip
          </button>
          <button style={styles.secondary} disabled={pending || isStopped} onClick={() => send('stop')}>
            <StopIcon />
            Stop
          </button>
        </div>

        <p style={styles.footnote}>
          {isRunning ? 'Running' : isPaused ? 'Paused' : 'Stopped'}
          <span aria-hidden="true"> · </span>
          <button onClick={logout} style={styles.link}>Log out</button>
        </p>
      </footer>
    </main>
  )
}

function PlayIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
      <path d="M4.5 2.9v10.2a.7.7 0 0 0 1.05.6l8.2-5.1a.7.7 0 0 0 0-1.2l-8.2-5.1a.7.7 0 0 0-1.05.6z" fill="currentColor" />
    </svg>
  )
}

function PauseIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
      <rect x="3.5" y="2.5" width="3" height="11" rx="1" fill="currentColor" />
      <rect x="9.5" y="2.5" width="3" height="11" rx="1" fill="currentColor" />
    </svg>
  )
}

function SkipIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 16 16" aria-hidden="true">
      <path d="M3 3.2v9.6l7.2-4.8z" fill="currentColor" />
      <rect x="11.2" y="3" width="1.8" height="10" rx="0.9" fill="currentColor" />
    </svg>
  )
}

function StopIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 16 16" aria-hidden="true">
      <rect x="2.5" y="2.5" width="11" height="11" rx="2" fill="currentColor" />
    </svg>
  )
}

const styles: Record<string, React.CSSProperties> = {
  message: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    minHeight: '100dvh',
    padding: 24,
    textAlign: 'center',
  },
  screen: {
    display: 'flex',
    flexDirection: 'column',
    minHeight: '100dvh',
    maxWidth: 480,
    margin: '0 auto',
    padding: 'max(24px, env(safe-area-inset-top)) 24px max(28px, env(safe-area-inset-bottom))',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  brand: {
    margin: 0,
    fontFamily: 'var(--serif)',
    fontSize: 24,
    fontWeight: 400,
    lineHeight: 1.2,
  },
  chip: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 6,
    height: 28,
    padding: '0 11px',
    borderRadius: 14,
    background: 'var(--surface)',
    border: '1px solid var(--border)',
    fontSize: 12,
    color: 'var(--text-2)',
  },
  dot: {
    display: 'block',
    width: 7,
    height: 7,
    borderRadius: '50%',
  },
  center: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 28,
    padding: '32px 0',
  },
  sessionRow: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    fontSize: 15,
  },
  timer: {
    fontFamily: 'var(--serif)',
    fontSize: 'clamp(80px, 28vw, 120px)',
    fontWeight: 300,
    lineHeight: 0.9,
    fontVariantNumeric: 'tabular-nums lining-nums',
  },
  muted: {
    color: 'var(--muted)',
    fontSize: 14,
    margin: 0,
  },
  controls: {
    display: 'flex',
    flexDirection: 'column',
    gap: 10,
  },
  primary: {
    height: 56,
    border: 'none',
    borderRadius: 14,
    background: 'var(--primary)',
    color: 'var(--on-primary)',
    fontSize: 17,
    fontWeight: 500,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
  },
  row: {
    display: 'grid',
    gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
    gap: 10,
  },
  secondary: {
    height: 52,
    border: '1px solid var(--border)',
    borderRadius: 14,
    background: 'var(--surface)',
    color: 'var(--text-2)',
    fontSize: 16,
    fontWeight: 500,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  footnote: {
    margin: 0,
    paddingTop: 10,
    textAlign: 'center',
    fontSize: 13,
    color: 'var(--muted)',
  },
  link: {
    background: 'none',
    border: 'none',
    padding: 0,
    color: 'var(--muted)',
    textDecoration: 'underline',
    textUnderlineOffset: 3,
    fontSize: 13,
  },
}
