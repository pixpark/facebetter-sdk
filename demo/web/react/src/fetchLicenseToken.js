/**
 * Demo: ask our backend proxy for a license token (no AppID / AppKey in the page).
 *
 * Production: implement the same proxy on YOUR server — see api/facebetter/auth.js
 * and https://facebetter.net/docs/intro/license
 */

export async function fetchDemoLicenseToken() {
  const response = await fetch('/api/facebetter/auth', { method: 'POST' })
  const text = await response.text()
  if (!response.ok) {
    throw new Error(`license fetch failed: ${response.status} ${text}`)
  }
  return text
}
