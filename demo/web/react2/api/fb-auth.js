const { createHmac } = require('node:crypto')

const AUTH_URL =
  process.env.FB_AUTH_V2_URL ||
  'https://facebetter.pixpark.net/facebetter/v2/auth'
const APP_ID = process.env.FB_APP_ID || 'dddb24155fd045ab9c2d8aad83ad3a4a'
const APP_KEY =
  process.env.FB_APP_KEY || '-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
}

module.exports = async function handler(req, res) {
  Object.entries(cors).forEach(([key, value]) => res.setHeader(key, value))

  if (req.method === 'OPTIONS') {
    res.status(204).end()
    return
  }

  if (req.method !== 'POST') {
    res.status(405).json({
      success: false,
      error: 'method_not_allowed',
      message: 'POST required',
    })
    return
  }

  try {
    const challenge =
      typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {}
    const nonce = String(challenge.nonce || '')
    const timestamp = Number(challenge.timestamp)
    const platform = String(challenge.platform || 'web')
    const userAgent = String(challenge.user_agent || '')

    if (!nonce || !Number.isFinite(timestamp)) {
      res.status(400).json({
        success: false,
        error: 'invalid_challenge',
        message: 'nonce and timestamp required',
      })
      return
    }

    const payload = `v2|${APP_ID}|${timestamp}|${nonce}|${platform}`
    const hmac = createHmac('sha256', APP_KEY).update(payload).digest('hex')
    const upstream = await fetch(AUTH_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        app_id: APP_ID,
        hmac_signature: hmac,
        timestamp,
        nonce,
        platform,
        user_agent: userAgent,
      }),
    })

    const text = await upstream.text()
    res.status(upstream.status)
    res.setHeader('Content-Type', 'application/json')
    res.send(text)
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'proxy_error',
      message: err instanceof Error ? err.message : 'auth proxy failed',
    })
  }
}
