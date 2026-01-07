# Smart Stamp 核心驗證伺服器

這是 Smart Stamp 系統的核心驗證伺服器，只負責一件事：**告訴客戶這個印章是否有效**。

## 技術棧

- Python 3.13
- FastAPI
- SQLAlchemy (同步模式)
- MariaDB
- PyJWT (RS256)

## 資料庫權限

使用 `verifier_app` 帳號：
- 對 `stamp_core_db` 的印章表：**只讀**
- 對 `app_business_db.stamping_logs`：**只寫**

## 專案結構

```
stamp-server/
├── app/
│   ├── main.py              # FastAPI 應用程式入口
│   ├── models.py            # 資料庫模型定義
│   └── core/
│       ├── database.py       # 資料庫連線配置
│       ├── security.py       # JWT 簽章與 API Key 驗證
│       └── math_utils.py     # 數學核心（指紋計算）
├── requirements.txt          # Python 依賴
├── .env.example             # 環境變數範例
└── README.md                # 本文件
```

## 安裝與執行

### 1. 安裝依賴

```bash
pip install -r requirements.txt
```

### 2. 設定環境變數

複製 `.env.example` 為 `.env` 並修改配置：

```bash
cp .env.example .env
```

### 3. 準備 RS256 密鑰對

```bash
# 建立 keys 目錄
mkdir -p keys

# 生成私鑰
openssl genrsa -out keys/private_key.pem 2048

# 生成公鑰（用於客戶端驗證）
openssl rsa -in keys/private_key.pem -pubout -out keys/public_key.pem
```

### 4. 執行伺服器

```bash
python -m app.main
# 或
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## API 端點

### POST /api/v1/verify

驗證印章有效性。

**請求標頭：**
```
X-API-Key: <your-api-key>
```

**請求體：**
```json
{
  "points": [
    [100.0, 200.0],
    [150.0, 250.0],
    [200.0, 300.0],
    [250.0, 350.0],
    [300.0, 400.0]
  ]
}
```

**成功回應（200）：**
```json
{
  "status": "valid",
  "stamp_id": 1,
  "jwt_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "印章驗證成功"
}
```

**失敗回應（400/403）：**
```json
{
  "detail": "指紋不匹配（MSE: 0.023456, 容差: 0.01）"
}
```

## 核心邏輯

1. **數學模組** (`math_utils.py`)：
   - 計算質心
   - 正規化指紋（相對於質心的距離比例，0.0~1.0）
   - 計算 MSE（均方誤差）

2. **驗證流程**：
   - 驗證 API Key
   - 將 5 點座標轉換為指紋
   - 查詢客戶可用的印章
   - 比對指紋（MSE < tolerance）
   - 簽發 JWT（RS256）
   - 記錄日誌

## 安全性

- 使用 RS256 非對稱加密簽署 JWT
- API Key 驗證
- 最小權限原則（只讀/只寫）
- 所有請求記錄日誌

