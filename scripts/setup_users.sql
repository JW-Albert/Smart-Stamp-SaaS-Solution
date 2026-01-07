-- Smart Stamp Solution - 使用者與權限設定腳本
-- 此腳本建立資料庫使用者並設定權限

-- ==================== 建立使用者與權限 ====================

-- 驗證伺服器帳號（只讀權限）
CREATE USER IF NOT EXISTS 'verifier_app'@'%' IDENTIFIED BY 'verifier_pass';

-- 授予 verifier_app 對 stamp_core_db 的只讀權限
GRANT SELECT ON stamp_core_db.* TO 'verifier_app'@'%';

-- 授予 verifier_app 對 app_business_db.stamping_logs 的只寫權限
GRANT INSERT ON app_business_db.stamping_logs TO 'verifier_app'@'%';

-- 管理後台帳號（完整 CRUD 權限）
CREATE USER IF NOT EXISTS 'admin_dashboard'@'%' IDENTIFIED BY 'admin_pass';

-- 授予 admin_dashboard 對 stamp_core_db 的完整權限
GRANT ALL PRIVILEGES ON stamp_core_db.* TO 'admin_dashboard'@'%';

-- 刷新權限
FLUSH PRIVILEGES;

-- ==================== 完成 ====================

SELECT '使用者與權限設定完成！' AS message;
SELECT '帳號資訊：' AS info;
SELECT '  - verifier_app / verifier_pass (只讀)' AS account1;
SELECT '  - admin_dashboard / admin_pass (完整權限)' AS account2;

