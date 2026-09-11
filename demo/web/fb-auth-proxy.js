import { createHmac } from 'node:crypto'

const AUTH_URL =
  process.env.FB_AUTH_V2_URL ||
  'https://facebetter.pixpark.net/facebetter/v2/auth'
const APP_ID = process.env.FB_APP_ID || 'dddb24155fd045ab9c2d8aad83ad3a4a'
const APP_KEY =
  process.env.FB_APP_KEY || '-VINb6KRgm5ROMR6DlaIjVBO9CDvwsxRopNvtIbUyLc'

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = []
    req.on('data', (chunk) => chunks.push(chunk))
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8') || '{}'
        resolve(JSON.parse(raw))
      } catch (err) {
        reject(err)
      }
    })
    req.on('error', reject)
  })
}

/**
 * Vite 开发服务器代理：浏览器只发 nonce challenge，app_id/app_key 留在 Node 侧。
 */
export function facebetterAuthProxy() {
  return {
    name: 'facebetter-auth-proxy',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const path = req.url?.split('?')[0]
        if (path !== '/api/fb-auth' || req.method !== 'POST') {
          next()
          return
        }

        try {
          const challenge = await readJsonBody(req)
          const nonce = String(challenge.nonce || '')
          const timestamp = Number(challenge.timestamp)
          const platform = String(challenge.platform || 'web')
          const userAgent = String(challenge.user_agent || '')
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
          res.statusCode = upstream.status
          res.setHeader('Content-Type', 'application/json')
          res.end(text)
        } catch (err) {
          res.statusCode = 500
          res.setHeader('Content-Type', 'application/json')
          res.end(
            JSON.stringify({
              success: false,
              error: 'proxy_error',
              message: err instanceof Error ? err.message : 'auth proxy failed',
            })
          )
        }
      })
    },
  }
}
