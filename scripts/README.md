# 安裝與設定腳本

本目錄包含用於快速安裝和設定 Smart Stamp Solution 的腳本。

## 腳本說明

### install.sh
Ubuntu 系統安裝腳本，會安裝所有必要依賴並建立 Python 虛擬環境。

**使用方法：**
```bash
./scripts/install.sh
```

**功能：**
- 安裝 MariaDB
- 安裝 Node.js 和 npm
- 安裝 Python 3.13 和相關套件
- 安裝系統依賴（編譯工具、SSL 庫等）
- 建立 Python 虛擬環境（stamp-server 和 manager/backend）
- 安裝所有 Python 和 Node.js 依賴

### setup_tables.sql
快速 SQL 製表腳本，僅建立資料表結構。

**使用方法：**
```bash
mysql -u root -p < scripts/setup_tables.sql
```

**功能：**
- 建立 `stamp_core_db` 和 `app_business_db` 資料庫
- 建立所有必要的資料表
- 不包含使用者權限設定

### setup_users.sql
使用者與權限設定腳本。

**使用方法：**
```bash
mysql -u root -p < scripts/setup_users.sql
```

**功能：**
- 建立 `verifier_app` 使用者（只讀權限）
- 建立 `admin_dashboard` 使用者（完整權限）
- 設定對應的資料庫權限

### generate_keys.sh
生成 RS256 密鑰對腳本。

**使用方法：**
```bash
./scripts/generate_keys.sh
```

**功能：**
- 生成私鑰：`stamp-server/keys/private_key.pem`
- 生成公鑰：`stamp-server/keys/public_key.pem`
- 自動複製公鑰到 `customer/demo/keys/`

### quick_setup.sh
快速資料庫設定腳本（包含製表和權限設定）。

**使用方法：**
```bash
./scripts/quick_setup.sh <mysql_root_password>
```

**功能：**
- 執行 `setup_tables.sql`
- 執行 `setup_users.sql`
- 可選：插入測試資料

## 完整安裝流程

### 方式一：逐步執行

```bash
# 1. 安裝系統依賴
./scripts/install.sh

# 2. 設定資料庫（需要輸入 MySQL root 密碼）
mysql -u root -p < scripts/setup_tables.sql
mysql -u root -p < scripts/setup_users.sql

# 3. 生成密鑰對
./scripts/generate_keys.sh
```

### 方式二：使用快速設定腳本

```bash
# 1. 安裝系統依賴
./scripts/install.sh

# 2. 快速設定資料庫（包含製表和權限）
./scripts/quick_setup.sh <mysql_root_password>

# 3. 生成密鑰對
./scripts/generate_keys.sh
```

## 服務管理

### start_all.sh
啟動所有服務腳本（預設所有前置條件已完成）。

**使用方法：**
```bash
./scripts/start_all.sh
```

**功能：**
- 啟動 stamp-server（端口 8000）
- 啟動 manager/backend（端口 8001）
- 啟動 manager/frontend（端口 3000）
- 啟動 customer/demo（端口 3001）
- 所有服務在後台執行
- 記錄 PID 和日誌檔案

**注意事項：**
- 預設所有前置條件已完成（依賴已安裝、資料庫已設定、密鑰已生成）
- PID 檔案保存在 `scripts/pids/` 目錄
- 日誌檔案保存在 `scripts/logs/` 目錄
- 如果服務已在運行，會跳過啟動

### stop_all.sh
停止所有服務腳本。

**使用方法：**
```bash
./scripts/stop_all.sh
```

**功能：**
- 停止所有正在運行的服務
- 清理 PID 檔案
- 優雅停止（SIGTERM），必要時強制停止（SIGKILL）

### status.sh
查看服務狀態腳本。

**使用方法：**
```bash
./scripts/status.sh
```

**功能：**
- 顯示所有服務的運行狀態
- 顯示 PID 和 URL
- 自動清理無效的 PID 檔案

## 快速啟動流程

```bash
# 1. 安裝所有依賴
./scripts/install.sh

# 2. 設定資料庫
./scripts/quick_setup.sh <mysql_root_password>

# 3. 生成密鑰對
./scripts/generate_keys.sh

# 4. 啟動所有服務
./scripts/start_all.sh

# 5. 查看服務狀態
./scripts/status.sh

# 6. 停止所有服務
./scripts/stop_all.sh
```

## 注意事項

1. **install.sh** 不會進行任何檢測，會直接執行安裝
2. **start_all.sh** 預設所有前置條件已完成，不會進行檢測
3. 所有腳本都需要適當的權限（使用 `chmod +x`）
4. 資料庫腳本需要 MySQL root 權限
5. 生產環境請修改預設密碼和使用者設定
6. 服務日誌保存在 `scripts/logs/` 目錄，可用於故障排除

## 故障排除

### MariaDB 無法啟動
```bash
sudo systemctl status mariadb
sudo systemctl start mariadb
```

### Python 虛擬環境問題
```bash
# 重新建立虛擬環境
rm -rf stamp-server/venv manager/backend/venv
./scripts/install.sh
```

### 權限問題
```bash
# 確保腳本有執行權限
chmod +x scripts/*.sh
```

