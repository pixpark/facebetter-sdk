/**
 * Demo auth proxy for customers to copy.
 *
 * Keep FB_APP_ID / FB_APP_KEY in server env only. Docs:
 * https://facebetter.net/docs/intro/license
 */
const { createHmac, randomBytes } = require('node:crypto')

const AUTH_URL = 'https://facebetter.pixpark.net/facebetter/v2/auth'

module.exports = async function handler(req, res) {
  if (req.method !== 'GET' && req.method !== 'POST') {
    res.setHeader('Allow', 'GET, POST')
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  const appId = process.env.FB_APP_ID
  const appKey = process.env.FB_APP_KEY
  if (!appId || !appKey) {
    res.status(500).json({ error: 'FB_APP_ID / FB_APP_KEY not configured' })
    return
  }

  const nonce = randomBytes(16).toString('hex')
  const timestamp = Math.floor(Date.now() / 1000)
  const platform = 'web'
  const payload = `v2|${appId}|${timestamp}|${nonce}|${platform}`
  const hmac = createHmac('sha256', appKey).update(payload).digest('hex')
  const userAgent = req.headers['user-agent'] || ''

  try {
    const upstream = await fetch(AUTH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        app_id: appId,
        hmac_signature: hmac,
        timestamp,
        nonce,
        platform,
        user_agent: userAgent,
      }),
    })
    const text = await upstream.text()
    res.status(upstream.status)
    res.setHeader(
      'Content-Type',
      upstream.headers.get('content-type') || 'application/json; charset=utf-8'
    )
    res.send(text)
  } catch {
    res.status(502).json({ error: 'Upstream auth failed' })
  }
}
