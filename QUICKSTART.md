# 快速開始指南

本指南將幫助您快速啟動 Smart Stamp SaaS Solution 的三個專案。

## 前置需求

- Python 3.13+
- Node.js 18+
- MariaDB/MySQL 10.5+
- npm 或 yarn

## 步驟 1：資料庫初始化

```bash
# 登入 MySQL/MariaDB
mysql -u root -p

# 執行初始化腳本
source database/init.sql

# 或直接執行
mysql -u root -p < database/init.sql
```

## 步驟 2：準備 RS256 密鑰對

```bash
# 建立 keys 目錄
mkdir -p stamp-server/keys

# 生成私鑰
openssl genrsa -out stamp-server/keys/private_key.pem 2048

# 生成公鑰（用於客戶端驗證）
openssl rsa -in stamp-server/keys/private_key.pem -pubout -out stamp-server/keys/public_key.pem

# 複製公鑰到 customer/demo（用於 JWT 驗證）
mkdir -p customer/demo/keys
cp stamp-server/keys/public_key.pem customer/demo/keys/
```

## 步驟 3：啟動核心驗證伺服器

```bash
cd stamp-server

# 安裝依賴
pip install -r requirements.txt

# 設定環境變數（可選，或直接使用預設值）
# cp .env.example .env
# 編輯 .env 檔案

# 啟動伺服器
python -m app.main
# 或
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

伺服器將在 http://localhost:8000 啟動

## 步驟 4：啟動管理後台

### 4.1 啟動後端

```bash
cd manager/backend

# 安裝依賴
pip install -r requirements.txt

# 設定環境變數（可選）
# cp .env.example .env

# 啟動後端
python -m app.main
# 或
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

後端將在 http://localhost:8001 啟動

### 4.2 啟動前端

```bash
cd manager/frontend

# 安裝依賴
npm install

# 啟動開發伺服器
npm run dev
```

前端將在 http://localhost:3000 啟動

## 步驟 5：測試客戶端 SDK

### 5.1 啟動 Demo 後端

```bash
cd customer/demo

# 安裝依賴
npm install

# 設定環境變數（建立 .env 檔案）
cat > .env << EOF
STAMP_SERVER_URL=http://localhost:8000/api/v1/verify
API_KEY=sk_test_client_1_key_12345678901234567890
PUBLIC_KEY_PATH=./keys/public_key.pem
PORT=3001
EOF

# 啟動後端
npm start
```

### 5.2 開啟 Demo 前端

使用任何靜態檔案伺服器開啟 `customer/demo/index.html`：

```bash
cd customer/demo

# 使用 Python
python3 -m http.server 8080

# 或使用 Node.js
npx serve .
```

然後在瀏覽器中開啟 http://localhost:8080

## 測試流程

1. **建立客戶與印章**（管理後台）：
   - 開啟 http://localhost:3000
   - 進入「印章校正」頁面
   - 使用 5 指觸控（或點擊 5 次）記錄印章
   - 進入「客戶管理」頁面，建立新客戶（會自動生成 API Key）
   - 進入「權限管理」，綁定客戶與印章

2. **測試驗證**（Demo）：
   - 開啟 http://localhost:8080
   - 點擊「開始」按鈕
   - 在觸控區域使用 5 指觸控（或點擊 5 次）
   - 查看驗證結果和 JWT Token

## 常見問題

### Q: 無法連線資料庫

A: 請確認：
- MariaDB/MySQL 服務正在運行
- 資料庫已初始化（執行 `database/init.sql`）
- 連線資訊正確（檢查 `.env` 檔案）

### Q: JWT 驗證失敗

A: 請確認：
- 公鑰檔案路徑正確
- 公鑰與私鑰是配對的
- 客戶端使用的是正確的公鑰

### Q: API Key 無效

A: 請確認：
- 使用管理後台建立的客戶 API Key
- API Key 已綁定到對應的印章
- 客戶狀態為「啟用」

## 下一步

- 閱讀各專案的 README 了解詳細功能
- 參考 [MVP.md](./MVP.md) 了解系統架構
- 根據需求調整配置和參數

