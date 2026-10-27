import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const { password } = await request.json()

  if (!process.env.AUTH_PASSWORD || !process.env.AUTH_SECRET) {
    return NextResponse.json({ error: 'Auth not configured' }, { status: 500 })
  }

  if (password !== process.env.AUTH_PASSWORD) {
    return NextResponse.json({ error: 'Incorrect password' }, { status: 401 })
  }

  const response = NextResponse.json({ ok: true })
  response.cookies.set('pomodoro-auth', process.env.AUTH_SECRET, {
    httpOnly: true,
    sameSite: 'strict',
    secure: true,
    path: '/',
    maxAge: 60 * 60 * 24 * 30, // 30 days
  })

  return response
}

export async function DELETE() {
  const response = NextResponse.json({ ok: true })
  response.cookies.delete('pomodoro-auth')
  return response
}
