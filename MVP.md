# Smart Stamp Solution - 開發規格書
專案結構: 三獨立專案 (Three Isolated Codebases) 日期: 2026-01-08

本文件定義了三個獨立的程式目錄及其職責、架構與開發指令。

## 1. 總體目錄結構 (Project Directory)

請在您的開發環境中建立以下三個主目錄：

```
/smart-stamp-project
├── /stamp-server      # [核心] 驗證伺服器 (對外 API, 唯讀權限, 簽章)
├── /manager           # [後台] 管理端系統 (CRUD, 印章校正, 完整權限)
└── /customer          # [客戶] 前端 SDK 與 範例程式
```

## 2. 目錄一：stamp-server (核心驗證伺服器)
這是系統的心臟，只做一件事：「告訴客戶這個印章是否有效」。它不包含任何管理介面，攻擊面最小。
技術棧: Python 3.13, FastAPI, SQLAlchemy (Async), MariaDB, PyJWT (RS256).
資料庫權限: 使用 verifier_app 帳號 (對印章表只讀，對 Log 表只寫)。

### 2.1 核心邏輯

- **數學模組**: 內建 `math_utils.py` (質心計算、正規化、歐幾里得距離)
- **API 接口**: `POST /api/v1/verify`
- **安全性**: 載入 RS256 私鑰，簽發 JWT

### 2.2 給 Cursor 的開發指令 (Prompt)
請在 `stamp-server/` 目錄下執行：

> 我要開發「Smart Stamp 核心驗證伺服器」。技術棧：Python 3.13, FastAPI, SQLAlchemy, MariaDB。
>
> 1. **專案結構**：請建立 `app/main.py`, `app/models.py`, `app/core/security.py`, `app/core/math_utils.py`
>
> 2. **數學核心** (`math_utils.py`)：實作 `get_normalized_fingerprint(points)`：輸入 5 點座標，計算相對於質心的距離比例 (0.0~1.0) 並排序
>
> 3. **資料庫模型** (`models.py`)：對應 MariaDB 的 `stamp_registry` (ReadOnly) 和 `stamping_logs` (InsertOnly)。注意：此程式無權修改印章資料
>
> 4. **驗證 API** (`POST /api/v1/verify`)：
>    - **Input**: API Key (Header), 5點座標 (Body)
>    - **Logic**: 
>      a. 驗證 API Key
>      b. 呼叫 math_utils 轉指紋
>      c. 從 DB 撈取該 Client 可用的印章指紋進行比對 (MSE 誤差 < tolerance)
>    - **Output**: 若成功，使用 RS256 私鑰簽署 JWT (Payload: `stamp_id`, `status='valid'`, `nonce`)。若失敗，回傳 400/403
>    - **Logging**: 每一筆請求都必須寫入 SQL `stamping_logs`
>
> 請幫我生成完整的專案骨架與程式碼。

## 3. 目錄二：manager (管理端系統)
這是給內部人員使用的後台。包含後端 API 與前端 Dashboard。

**技術棧**:

- **Backend**: Python FastAPI (使用 `admin_dashboard` 帳號，具備完整 CRUD 權限)
- **Frontend**: Vue 3 + Vite + Ant Design Vue

### 3.1 核心邏輯

- **印章校正 (Calibration)**: 這是此目錄最獨特的功能。接收原始座標 → 轉指紋 → 存入資料庫
- **客戶管理**: 發放 API Key

### 3.2 給 Cursor 的開發指令 (Prompt)
請在 `manager/` 目錄下執行：

> 我要開發「Smart Stamp 管理後台」。包含 FastAPI 後端與 Vue3 前端。
>
> **後端需求 (Backend)**：
>
> - 連線資料庫 `stamp_core_db`，擁有完整 CRUD 權限
> - 實作 `math_utils.py` (邏輯需與 Server 端一致)
> - **API**:
>   - `POST /admin/stamps/calibrate`: 接收 5 點座標，計算指紋並儲存為新印章
>   - `POST /admin/clients`: 建立新客戶並生成 API Key
>   - `POST /admin/permissions`: 綁定客戶與印章
>
> **前端需求 (Frontend - Vue3)**：
>
> - 使用 Ant Design Vue
> - 頁面：客戶列表、印章列表
> - **校正元件** (`CalibrationPad.vue`)：
>   - 全螢幕 Canvas
>   - 監聽 `touchstart` (5指)
>   - 畫出觸控點回饋
>   - 按下「註冊」按鈕呼叫後端 API
>
> 請先幫我建立後端的 `main.py` 和 CRUD Router。

## 4. 目錄三：customer (面向客戶端)
這是提供給客戶的整合包。

**技術棧**: TypeScript (無依賴), Vite (Library Mode)

### 4.1 核心邏輯

- **Web SDK** (`smart-stamp.js`): 負責採集觸控、座標正規化 (初步處理)、轉發給客戶後端
- **Demo App**: 模擬客戶的網頁與後端，展示如何驗證簽章

### 4.2 給 Cursor 的開發指令 (Prompt)
請在 `customer/` 目錄下執行：

> 我要開發「Smart Stamp 前端 SDK」。
>
> 1. **SDK** (`/sdk` 目錄)：
>    - 使用 TypeScript + Vite (Library Mode)
>    - **Class SmartStamp**:
>      - `constructor(config)`: 設定 `targetElement`
>      - `start()`: 監聽 `touchstart`
>      - 當偵測到 5 點觸控時，取得座標 `[{x,y}...]`
>      - 透過 `CustomEvent` 或 `Callback` 將座標回傳給宿主網頁 (不負責呼叫 API，只負責採集)
>
> 2. **範例程式** (`/demo` 目錄)：
>    - 一個簡單的 HTML 頁面引入上述 SDK
>    - 當收到 SDK 的座標資料時，透過 `fetch` 傳送到自己的後端 (Mock Backend)
>    - 後端轉發給 `stamp-server` 並驗證回傳的 JWT 簽章 (需使用公鑰驗證)
>
> 請給我 SDK 的 TypeScript 原始碼結構。

## 5. 資料庫初始化 (Shared Infrastructure)
無論哪個程式執行前，請確保 MariaDB 已建立以下結構：

```sql
-- 核心 DB
CREATE DATABASE stamp_core_db;
-- 業務 Log DB
CREATE DATABASE app_business_db;

-- 表結構 (由 manager 或手動建立)
USE stamp_core_db;
CREATE TABLE api_clients (...);
CREATE TABLE stamp_registry (...); -- 存指紋 JSON
CREATE TABLE stamp_permissions (...);

-- 權限設定 (極重要！)
CREATE USER 'verifier_app'@'%' IDENTIFIED BY 'verifier_pass';
GRANT SELECT ON stamp_core_db.* TO 'verifier_app'@'%';
GRANT INSERT ON app_business_db.stamping_logs TO 'verifier_app'@'%';

CREATE USER 'admin_dashboard'@'%' IDENTIFIED BY 'admin_pass';
GRANT ALL PRIVILEGES ON stamp_core_db.* TO 'admin_dashboard'@'%';
```