# Smart Stamp SaaS Solution

智慧印章 SaaS 解決方案 - 三個獨立專案架構

## 專案結構

```
Smart-Stamp-SaaS-Solution/
├── stamp-server/      # [核心] 驗證伺服器 (對外 API, 唯讀權限, 簽章)
├── manager/           # [後台] 管理端系統 (CRUD, 印章校正, 完整權限)
│   ├── backend/       # FastAPI 後端
│   └── frontend/      # Vue3 前端
├── customer/          # [客戶] 前端 SDK 與範例程式
│   ├── sdk/           # TypeScript SDK
│   └── demo/          # 範例程式
├── database/          # 資料庫初始化腳本
└── MVP.md             # 開發規格書
```

## 快速開始

### 方式一：使用自動安裝腳本（推薦）

```bash
# 1. 安裝所有系統依賴並建立虛擬環境
./scripts/install.sh

# 2. 快速設定資料庫（包含製表和權限）
./scripts/quick_setup.sh <mysql_root_password>

# 3. 生成 RS256 密鑰對
./scripts/generate_keys.sh
```

### 方式二：手動安裝

#### 1. 資料庫初始化

```bash
# 使用完整初始化腳本
cd database
mysql -u root -p < init.sql

# 或使用快速製表腳本
mysql -u root -p < scripts/setup_tables.sql
mysql -u root -p < scripts/setup_users.sql
```

### 2. 啟動核心驗證伺服器

```bash
cd stamp-server
pip install -r requirements.txt
# 設定 .env 檔案
python -m app.main
```

### 3. 啟動管理後台

**後端：**
```bash
cd manager/backend
pip install -r requirements.txt
# 設定 .env 檔案
python -m app.main
```

**前端：**
```bash
cd manager/frontend
npm install
npm run dev
```

### 4. 測試客戶端 SDK

```bash
cd customer/demo
npm install
npm start
# 開啟 index.html 進行測試
```

## 專案說明

### stamp-server（核心驗證伺服器）

- **職責**：驗證印章有效性
- **技術**：Python 3.13, FastAPI, SQLAlchemy, MariaDB, PyJWT (RS256)
- **權限**：只讀（印章表）+ 只寫（日誌表）
- **API**：`POST /api/v1/verify`

詳細說明請參考 [stamp-server/README.md](./stamp-server/README.md)

### manager（管理端系統）

- **職責**：印章校正、客戶管理、權限管理
- **技術**：
  - 後端：Python FastAPI
  - 前端：Vue 3 + Vite + Ant Design Vue
- **權限**：完整 CRUD 權限

詳細說明請參考：
- [manager/backend/README.md](./manager/backend/README.md)
- [manager/frontend/README.md](./manager/frontend/README.md)

### customer（客戶端 SDK）

- **職責**：提供給客戶的整合包
- **技術**：TypeScript, Vite (Library Mode)
- **功能**：觸控採集、座標正規化

詳細說明請參考 [customer/README.md](./customer/README.md)

## 系統流程

1. **印章校正**（管理後台）：
   - 管理員使用 5 指觸控記錄印章
   - 系統計算指紋並存入資料庫

2. **客戶註冊**（管理後台）：
   - 建立客戶並生成 API Key
   - 綁定客戶與印章權限

3. **印章驗證**（客戶端）：
   - 客戶使用 SDK 採集 5 點觸控
   - 座標傳送到客戶後端
   - 客戶後端轉發到 `stamp-server`
   - `stamp-server` 驗證並簽發 JWT
   - 客戶後端驗證 JWT 簽章

## 安全性

- **最小權限原則**：驗證伺服器只有只讀/只寫權限
- **非對稱加密**：使用 RS256 簽署 JWT
- **API Key 驗證**：所有請求需提供有效的 API Key
- **日誌記錄**：所有驗證請求都記錄日誌

## 開發規範

請參考 [MVP.md](./MVP.md) 了解詳細的開發規格與架構設計。

## 授權

請參考 [LICENSE](./LICENSE) 檔案。
