# Smart Stamp Demo

展示如何使用 Smart Stamp SDK 的範例程式。

## 結構

- `index.html` - 前端頁面
- `demo.js` - 前端 JavaScript（使用 SDK）
- `server.js` - Mock Backend（轉發請求並驗證 JWT）

## 安裝與執行

### 1. 安裝依賴

```bash
npm install
```

### 2. 設定環境變數

建立 `.env` 檔案：

```env
STAMP_SERVER_URL=http://localhost:8000/api/v1/verify
API_KEY=sk_your_api_key_here
PUBLIC_KEY_PATH=../keys/public_key.pem
PORT=3001
```

### 3. 準備公鑰

從 `stamp-server` 複製公鑰到 `../keys/public_key.pem`：

```bash
mkdir -p ../keys
cp ../../stamp-server/keys/public_key.pem ../keys/
```

### 4. 執行後端伺服器

```bash
npm start
```

### 5. 開啟前端頁面

使用任何靜態檔案伺服器開啟 `index.html`，或使用：

```bash
# 使用 Python
python3 -m http.server 8080

# 或使用 Node.js
npx serve .
```

然後在瀏覽器中開啟 http://localhost:8080

## 使用流程

1. 點擊「開始」按鈕啟動 SDK
2. 在觸控區域使用 5 指同時觸控（或點擊 5 次）
3. SDK 會採集座標並傳送到後端
4. 後端轉發請求到 `stamp-server`
5. 驗證 JWT 簽章
6. 顯示驗證結果

## 注意事項

- 請確保 `stamp-server` 正在運行
- 請替換 `API_KEY` 為實際的 API Key（從管理後台取得）
- 請確保公鑰檔案路徑正確

