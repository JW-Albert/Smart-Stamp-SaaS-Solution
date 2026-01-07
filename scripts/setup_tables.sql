-- Smart Stamp Solution - 快速 SQL 製表腳本
-- 此腳本僅建立資料表結構，不包含使用者權限設定

-- ==================== 建立資料庫 ====================

CREATE DATABASE IF NOT EXISTS stamp_core_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
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

-- ==================== 完成 ====================

SELECT '資料表建立完成！' AS message;
SELECT '請執行 scripts/setup_users.sql 來建立使用者與權限' AS next_step;

