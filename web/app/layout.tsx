import type { Metadata, Viewport } from 'next'

export const metadata: Metadata = {
  title: 'Pomodoro Remote',
  description: 'Control your Pomodoro timer from your phone',
}

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#FAF9F5' },
    { media: '(prefers-color-scheme: dark)', color: '#1F1E1D' },
  ],
}

// Same warm "Paper" palette as the Mac app. ui-serif is New York on Apple devices.
const themeCss = `
:root {
  color-scheme: light dark;
  --bg: #FAF9F5;
  --surface: #FFFFFF;
  --text: #141413;
  --text-2: #3D3D3A;
  --muted: #5E5D59;
  --border: rgba(31, 30, 29, 0.15);
  --primary: #141413;
  --on-primary: #FAF9F5;
  --clay: #D97757;
  --olive: #788C5D;
  --sky: #6A9BCC;
  --idle: #B0AEA5;
  --danger: #B5532F;
  --serif: ui-serif, 'New York', Georgia, 'Times New Roman', serif;
  --sans: -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, 'Segoe UI', sans-serif;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #1F1E1D;
    --surface: #262624;
    --text: #FAF9F5;
    --text-2: #D1CFC5;
    --muted: #9C9A92;
    --border: rgba(250, 249, 245, 0.14);
    --primary: #FAF9F5;
    --on-primary: #141413;
    --olive: #8FA672;
    --sky: #7FAAD6;
    --idle: #5E5D59;
    --danger: #E8906F;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--sans);
  -webkit-font-smoothing: antialiased;
}
button { font: inherit; cursor: pointer; -webkit-tap-highlight-color: transparent; }
button:disabled { opacity: 0.4; cursor: default; }
input::placeholder { color: var(--muted); }
`

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <style dangerouslySetInnerHTML={{ __html: themeCss }} />
      </head>
      <body>{children}</body>
    </html>
  )
}
