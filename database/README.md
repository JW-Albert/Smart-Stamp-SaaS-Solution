# 資料庫初始化

本目錄包含資料庫初始化 SQL 腳本。

## 執行方式

### 使用 MySQL/MariaDB 命令列

```bash
mysql -u root -p < init.sql
```

### 或使用 MySQL Client

```bash
mysql -u root -p
source init.sql
```

## 資料庫結構

### stamp_core_db（核心資料庫）

- `api_clients` - API 客戶表
- `stamp_registry` - 印章註冊表
- `stamp_permissions` - 印章權限表（綁定客戶與印章）

### app_business_db（業務日誌資料庫）

- `stamping_logs` - 印章驗證日誌表

## 使用者權限

### verifier_app（驗證伺服器帳號）

- 密碼：`verifier_pass`
- 權限：
  - `stamp_core_db.*`：**只讀** (SELECT)
  - `app_business_db.stamping_logs`：**只寫** (INSERT)

### admin_dashboard（管理後台帳號）

- 密碼：`admin_pass`
- 權限：
  - `stamp_core_db.*`：**完整權限** (ALL PRIVILEGES)

## 注意事項

1. **生產環境**：請務必修改預設密碼
2. **安全性**：建議限制 IP 範圍（將 `'%'` 改為特定 IP）
3. **備份**：定期備份資料庫
4. **測試資料**：腳本中包含測試資料，生產環境請移除

## 範例：限制 IP 範圍

```sql
-- 只允許本地連線
CREATE USER 'verifier_app'@'localhost' IDENTIFIED BY 'verifier_pass';
CREATE USER 'admin_dashboard'@'localhost' IDENTIFIED BY 'admin_pass';

-- 或允許特定 IP
CREATE USER 'verifier_app'@'192.168.1.%' IDENTIFIED BY 'verifier_pass';
```

