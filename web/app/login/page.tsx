'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const res = await fetch('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ password }),
    })

    if (res.ok) {
      router.replace('/')
    } else {
      const { error } = await res.json()
      setError(error ?? 'Incorrect password')
      setLoading(false)
    }
  }

  return (
    <main style={styles.container}>
      <div style={styles.card}>
        <div style={styles.heading}>
          <h1 style={styles.title}>Pomodoro</h1>
          <p style={styles.subtitle}>Enter your password to control the timer on your Mac.</p>
        </div>
        <form onSubmit={handleSubmit} style={styles.form}>
          <label htmlFor="password" style={styles.label}>Password</label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={styles.input}
            autoFocus
            autoComplete="current-password"
          />
          {error && <p role="alert" style={styles.error}>{error}</p>}
          <button type="submit" disabled={loading || !password} style={styles.button}>
            {loading ? 'Checking…' : 'Unlock'}
          </button>
        </form>
      </div>
    </main>
  )
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100dvh',
    padding: 24,
  },
  card: {
    display: 'flex',
    flexDirection: 'column',
    gap: 28,
    width: '100%',
    maxWidth: 340,
  },
  heading: {
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
  },
  title: {
    margin: 0,
    fontFamily: 'var(--serif)',
    fontSize: 32,
    fontWeight: 400,
    lineHeight: 1.2,
  },
  subtitle: {
    margin: 0,
    fontSize: 15,
    lineHeight: 1.5,
    color: 'var(--muted)',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: 8,
    width: '100%',
  },
  label: {
    fontSize: 13,
    fontWeight: 500,
    color: 'var(--text-2)',
  },
  input: {
    height: 48,
    padding: '0 14px',
    borderRadius: 12,
    border: '1px solid var(--border)',
    background: 'var(--surface)',
    color: 'var(--text)',
    fontSize: 16,
    width: '100%',
  },
  button: {
    height: 52,
    marginTop: 8,
    borderRadius: 14,
    border: 'none',
    background: 'var(--primary)',
    color: 'var(--on-primary)',
    fontSize: 16,
    fontWeight: 500,
  },
  error: {
    margin: 0,
    color: 'var(--danger)',
    fontSize: 14,
  },
}
