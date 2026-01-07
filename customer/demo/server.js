/**
 * Smart Stamp Demo - Mock Backend Server
 * 模擬客戶的後端，轉發請求給 stamp-server 並驗證 JWT
 */
import express from 'express'
import jwt from 'jsonwebtoken'
import fs from 'fs'
import path from 'path'
import { fileURLToPath } from 'url'
import dotenv from 'dotenv'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// 載入環境變數
dotenv.config({ path: path.join(__dirname, '.env') })

const app = express()
app.use(express.json())

// 提供靜態檔案服務（HTML、CSS、JS）
app.use(express.static(__dirname))

// 配置
const CONFIG = {
  STAMP_SERVER_URL: process.env.STAMP_SERVER_URL || 'http://localhost:8000/api/v1/verify',
  API_KEY: process.env.API_KEY || 'sk_your_api_key_here', // 請替換為實際的 API Key
  PUBLIC_KEY_PATH: process.env.PUBLIC_KEY_PATH || path.join(__dirname, 'keys/public_key.pem'),
  PORT: process.env.PORT || 3001
}

// 載入公鑰（用於驗證 JWT）
let publicKey = null
try {
  // 處理相對路徑
  let keyPath = CONFIG.PUBLIC_KEY_PATH
  if (keyPath.startsWith('./')) {
    keyPath = path.join(__dirname, keyPath.substring(2))
  } else if (!path.isAbsolute(keyPath)) {
    keyPath = path.join(__dirname, keyPath)
  }

  // 確保路徑存在
  if (!fs.existsSync(keyPath)) {
    throw new Error(`公鑰檔案不存在: ${keyPath}`)
  }

  publicKey = fs.readFileSync(keyPath, 'utf8')
  if (!publicKey || publicKey.trim().length === 0) {
    throw new Error('公鑰檔案為空')
  }
  console.log('✓ 公鑰載入成功:', keyPath)
} catch (error) {
  console.warn('⚠ 無法載入公鑰，JWT 驗證將被跳過')
  console.warn('  嘗試的路徑:', CONFIG.PUBLIC_KEY_PATH)
  console.warn('  解析後路徑:', keyPath || 'N/A')
  console.warn('  錯誤:', error.message)
  console.warn('  請將 stamp-server 的公鑰放置在:', path.join(__dirname, 'keys/public_key.pem'))
}

// 驗證 JWT
function verifyJWT(token) {
  if (!publicKey) {
    return { valid: false, error: '公鑰未載入' }
  }

  try {
    const decoded = jwt.verify(token, publicKey, { algorithms: ['RS256'] })
    return { valid: true, payload: decoded }
  } catch (error) {
    return { valid: false, error: error.message }
  }
}

// 轉發驗證請求到 stamp-server
app.post('/api/verify', async (req, res) => {
  try {
    const { points } = req.body

    if (!points || !Array.isArray(points) || points.length !== 5) {
      return res.status(400).json({
        error: '必須提供 5 個觸控點座標'
      })
    }

    // 轉換座標格式（從正規化座標轉為絕對座標）
    // 注意：這裡需要根據實際情況調整
    // 如果 SDK 已經傳送絕對座標，則不需要轉換
    const coordinates = points.map(p => [p.x, p.y])

    // 轉發到 stamp-server
    const response = await fetch(CONFIG.STAMP_SERVER_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': CONFIG.API_KEY
      },
      body: JSON.stringify({ points: coordinates })
    })

    const data = await response.json()

    if (!response.ok) {
      return res.status(response.status).json(data)
    }

    // 驗證 JWT 簽章
    if (data.jwt_token) {
      const verification = verifyJWT(data.jwt_token)

      if (!verification.valid) {
        console.error('JWT 驗證失敗:', verification.error)
        return res.status(500).json({
          error: 'JWT 驗證失敗',
          detail: verification.error
        })
      }

      console.log('✓ JWT 驗證成功:', verification.payload)

      // 返回驗證結果（包含 JWT 和驗證資訊）
      return res.json({
        ...data,
        jwt_verified: true,
        jwt_payload: verification.payload
      })
    }

    return res.json(data)

  } catch (error) {
    console.error('驗證請求錯誤:', error)
    return res.status(500).json({
      error: '伺服器錯誤',
      detail: error.message
    })
  }
})

// API 資訊端點（保留 JSON 格式供 API 調用）
app.get('/api/info', (req, res) => {
  res.json({
    service: 'Smart Stamp Demo Backend',
    status: 'running',
    endpoints: {
      'POST /api/verify': '驗證印章',
      'GET /health': '健康檢查'
    },
    public_key_loaded: publicKey !== null
  })
})

// 健康檢查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    public_key_loaded: publicKey !== null
  })
})

// 提供靜態檔案服務（HTML、CSS、JS）- 放在最後，作為 fallback
// 明確指定 index.html 作為預設檔案
app.use(express.static(__dirname, { index: 'index.html' }))

// 啟動伺服器（綁定到所有網路介面）
app.listen(CONFIG.PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Demo Backend Server 已啟動`)
  console.log(`   端口: ${CONFIG.PORT}`)
  console.log(`   綁定: 0.0.0.0 (所有網路介面)`)
  console.log(`   Stamp Server: ${CONFIG.STAMP_SERVER_URL}`)
  console.log(`   公鑰狀態: ${publicKey ? '✓ 已載入' : '✗ 未載入'}\n`)
})

