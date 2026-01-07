# Smart Stamp 客戶端

提供給客戶的整合包，包含 Web SDK 與範例程式。

## 目錄結構

```
customer/
├── sdk/          # Web SDK (TypeScript + Vite Library Mode)
└── demo/         # 範例程式（HTML + Mock Backend）
```

## SDK

位於 `sdk/` 目錄，負責：
- 採集觸控事件
- 座標正規化（初步處理）
- 透過回調或自定義事件回傳座標

詳細說明請參考 [sdk/README.md](./sdk/README.md)

## Demo

位於 `demo/` 目錄，包含：
- 前端頁面：展示如何使用 SDK
- Mock Backend：模擬客戶後端，轉發請求並驗證 JWT

詳細說明請參考 [demo/README.md](./demo/README.md)

## 整合指南

### 1. 引入 SDK

將 SDK 建置後的檔案引入到您的專案中。

### 2. 初始化 SDK

```javascript
import { SmartStamp } from './sdk/dist/smart-stamp.es.js'

const stamp = new SmartStamp({
  targetElement: '#your-stamp-area',
  touchPoints: 5,
  onCoordinates: async (points) => {
    // 將座標傳送到您的後端
    const response = await fetch('/your-api/verify', {
      method: 'POST',
      body: JSON.stringify({ points })
    })
    // 處理回應...
  }
})

stamp.start()
```

### 3. 後端整合

您的後端需要：
1. 接收座標資料
2. 轉發到 `stamp-server` 的 `/api/v1/verify` 端點
3. 驗證回傳的 JWT 簽章（使用公鑰）
4. 處理驗證結果

參考 `demo/server.js` 的實作方式。

