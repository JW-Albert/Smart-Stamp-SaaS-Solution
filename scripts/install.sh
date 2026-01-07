#!/bin/bash
# Smart Stamp SaaS Solution - Ubuntu 安裝腳本
# 此腳本會安裝所有必要依賴並建立 Python 虛擬環境

set -e  # 遇到錯誤立即退出

# 取得腳本所在目錄的父目錄（專案根目錄）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 切換到專案根目錄
cd "$PROJECT_ROOT"

echo "=========================================="
echo "Smart Stamp SaaS Solution - 安裝腳本"
echo "=========================================="
echo "專案根目錄: $PROJECT_ROOT"
echo ""

# 更新套件列表
echo "[1/8] 更新套件列表..."
sudo apt update

# 安裝 MariaDB
echo "[2/8] 安裝 MariaDB..."
sudo apt install -y mariadb-server mariadb-client

# 啟動並啟用 MariaDB 服務
echo "[3/8] 啟動 MariaDB 服務..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# 安裝 Node.js 和 npm
echo "[4/8] 安裝 Node.js 和 npm..."
sudo apt install -y nodejs npm

# 安裝 Python 3.13 相關套件
echo "[5/8] 安裝 Python 3.13 和相關套件..."
sudo apt install -y python3.13 python3.13-venv python3.13-dev python3-pip

# 安裝系統依賴（用於 Python 套件編譯）
echo "[6/8] 安裝系統依賴..."
sudo apt install -y build-essential libssl-dev libffi-dev libmariadb-dev pkg-config

# 安裝 OpenSSL（用於生成密鑰）
echo "[7/8] 安裝 OpenSSL..."
sudo apt install -y openssl

# 建立 Python 虛擬環境
echo "[8/8] 建立 Python 虛擬環境..."

# stamp-server venv
if [ ! -d "stamp-server/venv" ]; then
    echo "  建立 stamp-server/venv..."
    python3.13 -m venv stamp-server/venv
fi

# manager/backend venv
if [ ! -d "manager/backend/venv" ]; then
    echo "  建立 manager/backend/venv..."
    python3.13 -m venv manager/backend/venv
fi

# 安裝 Python 依賴
echo ""
echo "安裝 Python 依賴..."

# stamp-server
if [ -d "stamp-server/venv" ]; then
    echo "  安裝 stamp-server 依賴..."
    stamp-server/venv/bin/pip install --upgrade pip setuptools wheel
    stamp-server/venv/bin/pip install -r stamp-server/requirements.txt
fi

# manager/backend
if [ -d "manager/backend/venv" ]; then
    echo "  安裝 manager/backend 依賴..."
    manager/backend/venv/bin/pip install --upgrade pip setuptools wheel
    manager/backend/venv/bin/pip install -r manager/backend/requirements.txt
fi

# 安裝 Node.js 依賴
echo ""
echo "安裝 Node.js 依賴..."

# manager/frontend
if [ -f "manager/frontend/package.json" ]; then
    echo "  安裝 manager/frontend 依賴..."
    (cd manager/frontend && npm install)
fi

# customer/demo
if [ -f "customer/demo/package.json" ]; then
    echo "  安裝 customer/demo 依賴..."
    (cd customer/demo && npm install)
fi

# customer/sdk
if [ -f "customer/sdk/package.json" ]; then
    echo "  安裝 customer/sdk 依賴..."
    (cd customer/sdk && npm install)
fi

echo ""
echo "=========================================="
echo "安裝完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 執行資料庫初始化腳本："
echo "   mysql -u root -p < database/init.sql"
echo ""
echo "2. 或使用快速 SQL 製表腳本："
echo "   mysql -u root -p < scripts/setup_tables.sql"
echo ""
echo "3. 生成 RS256 密鑰對："
echo "   ./scripts/generate_keys.sh"
echo ""
echo "4. 啟動服務："
echo "   - stamp-server: cd stamp-server && source venv/bin/activate && python -m app.main"
echo "   - manager/backend: cd manager/backend && source venv/bin/activate && python -m app.main"
echo "   - manager/frontend: cd manager/frontend && npm run dev"
echo ""