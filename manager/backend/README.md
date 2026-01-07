# Smart Stamp 管理後台 - 後端 API

管理端系統的後端 API，提供印章校正、客戶管理、權限管理等功能。

## 技術棧

- Python 3.13
- FastAPI
- SQLAlchemy
- MariaDB

## 資料庫權限

使用 `admin_dashboard` 帳號，擁有 `stamp_core_db` 的完整 CRUD 權限。

## 安裝與執行

### 1. 安裝依賴

```bash
pip install -r requirements.txt
```

### 2. 設定環境變數

```bash
cp .env.example .env
# 編輯 .env 檔案
```

### 3. 執行伺服器

```bash
python -m app.main
# 或
uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
```

## API 端點

### 印章管理

- `POST /admin/stamps/calibrate` - 印章校正
- `GET /admin/stamps` - 列出所有印章
- `GET /admin/stamps/{stamp_id}` - 取得單一印章
- `DELETE /admin/stamps/{stamp_id}` - 刪除印章

### 客戶管理

- `POST /admin/clients` - 建立新客戶（自動生成 API Key）
- `GET /admin/clients` - 列出所有客戶
- `GET /admin/clients/{client_id}` - 取得單一客戶
- `PUT /admin/clients/{client_id}/toggle` - 切換客戶啟用狀態

### 權限管理

- `POST /admin/permissions` - 綁定客戶與印章
- `GET /admin/permissions` - 列出權限（可過濾）
- `DELETE /admin/permissions/{permission_id}` - 刪除權限

