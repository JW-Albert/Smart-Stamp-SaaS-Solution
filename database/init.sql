-- Smart Stamp Solution - 資料庫初始化腳本
-- 日期: 2026-01-08

-- ==================== 建立資料庫 ====================

-- 核心 DB（存放印章、客戶、權限資料）
CREATE DATABASE IF NOT EXISTS stamp_core_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 業務 Log DB（存放驗證日誌）
CREATE DATABASE IF NOT EXISTS app_business_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE stamp_core_db;

-- ==================== 建立資料表 ====================

-- API 客戶表
CREATE TABLE IF NOT EXISTS api_clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT '客戶名稱',
    api_key VARCHAR(255) NOT NULL UNIQUE COMMENT 'API Key',
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否啟用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
    INDEX idx_api_key (api_key),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='API 客戶表';

-- 印章註冊表
CREATE TABLE IF NOT EXISTS stamp_registry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL COMMENT '印章名稱',
    fingerprint JSON NOT NULL COMMENT '正規化指紋（JSON 陣列）',
    description TEXT COMMENT '印章描述',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新時間',
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='印章註冊表';

-- 印章權限表（綁定客戶與印章）
CREATE TABLE IF NOT EXISTS stamp_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL COMMENT '客戶 ID',
    stamp_id INT NOT NULL COMMENT '印章 ID',
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否啟用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
    INDEX idx_client_id (client_id),
    INDEX idx_stamp_id (stamp_id),
    INDEX idx_is_active (is_active),
    UNIQUE KEY uk_client_stamp (client_id, stamp_id),
    FOREIGN KEY (client_id) REFERENCES api_clients(id) ON DELETE CASCADE,
    FOREIGN KEY (stamp_id) REFERENCES stamp_registry(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='印章權限表';

USE app_business_db;

-- 印章驗證日誌表
CREATE TABLE IF NOT EXISTS stamping_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL COMMENT '客戶 ID',
    stamp_id INT NULL COMMENT '印章 ID（驗證失敗時為 NULL）',
    status VARCHAR(50) NOT NULL COMMENT '狀態：valid, invalid, error',
    fingerprint JSON NULL COMMENT '驗證時使用的指紋',
    error_message TEXT NULL COMMENT '錯誤訊息',
    ip_address VARCHAR(45) NULL COMMENT 'IP 位址',
    user_agent VARCHAR(500) NULL COMMENT 'User Agent',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
    INDEX idx_client_id (client_id),
    INDEX idx_stamp_id (stamp_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='印章驗證日誌表';

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

-- ==================== 測試資料（可選） ====================

-- 插入測試客戶
USE stamp_core_db;
INSERT INTO api_clients (name, api_key, is_active) VALUES
    ('測試客戶 1', 'sk_test_client_1_key_12345678901234567890', TRUE),
    ('測試客戶 2', 'sk_test_client_2_key_09876543210987654321', TRUE)
ON DUPLICATE KEY UPDATE name=name;

-- 插入測試印章（指紋為範例值，實際使用時需透過校正功能產生）
INSERT INTO stamp_registry (name, fingerprint, description) VALUES
    ('測試印章 1', '[0.1, 0.2, 0.3, 0.4, 0.5]', '這是一個測試印章'),
    ('測試印章 2', '[0.2, 0.3, 0.4, 0.5, 0.6]', '這是另一個測試印章')
ON DUPLICATE KEY UPDATE name=name;

-- 插入測試權限（綁定客戶與印章）
INSERT INTO stamp_permissions (client_id, stamp_id, is_active) VALUES
    (1, 1, TRUE),
    (1, 2, TRUE),
    (2, 1, TRUE)
ON DUPLICATE KEY UPDATE is_active=TRUE;

-- ==================== 完成 ====================

SELECT '資料庫初始化完成！' AS message;
SELECT '請記住以下帳號密碼：' AS reminder;
SELECT '  - verifier_app / verifier_pass (只讀)' AS account1;
SELECT '  - admin_dashboard / admin_pass (完整權限)' AS account2;

