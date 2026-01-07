#!/bin/bash
# Smart Stamp Solution - 快速設定腳本
# 此腳本會執行完整的資料庫初始化（包含製表和權限設定）

set -e

echo "=========================================="
echo "Smart Stamp Solution - 快速資料庫設定"
echo "=========================================="
echo ""

# 檢查是否提供 MySQL root 密碼
if [ -z "$1" ]; then
    echo "使用方法: $0 <mysql_root_password>"
    echo "範例: $0 mypassword"
    exit 1
fi

MYSQL_ROOT_PASSWORD=$1

echo "[1/3] 建立資料表..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" < scripts/setup_tables.sql

echo "[2/3] 設定使用者與權限..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" < scripts/setup_users.sql

echo "[3/3] 插入測試資料（可選）..."
read -p "是否插入測試資料？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
USE stamp_core_db;

-- 插入測試客戶
INSERT INTO api_clients (name, api_key, is_active) VALUES
    ('測試客戶 1', 'sk_test_client_1_key_12345678901234567890', TRUE),
    ('測試客戶 2', 'sk_test_client_2_key_09876543210987654321', TRUE)
ON DUPLICATE KEY UPDATE name=name;

-- 插入測試印章
INSERT INTO stamp_registry (name, fingerprint, description) VALUES
    ('測試印章 1', '[0.1, 0.2, 0.3, 0.4, 0.5]', '這是一個測試印章'),
    ('測試印章 2', '[0.2, 0.3, 0.4, 0.5, 0.6]', '這是另一個測試印章')
ON DUPLICATE KEY UPDATE name=name;

-- 插入測試權限
INSERT INTO stamp_permissions (client_id, stamp_id, is_active) VALUES
    (1, 1, TRUE),
    (1, 2, TRUE),
    (2, 1, TRUE)
ON DUPLICATE KEY UPDATE is_active=TRUE;

SELECT '測試資料插入完成！' AS message;
EOF
fi

echo ""
echo "=========================================="
echo "資料庫設定完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 生成 RS256 密鑰對："
echo "   ./scripts/generate_keys.sh"
echo ""
echo "2. 啟動服務"
echo ""

