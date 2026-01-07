#!/bin/bash
# Smart Stamp Solution - 查看服務狀態腳本

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PID_DIR="./scripts/pids"

echo "=========================================="
echo "Smart Stamp Solution - 服務狀態"
echo "=========================================="
echo ""

# 檢查服務狀態函數
check_service() {
    local service_name=$1
    local pid_file="$PID_DIR/$2"
    local url=$3
    
    if [ ! -f "$pid_file" ]; then
        echo -e "  ${RED}✗${NC} $service_name: ${RED}未運行${NC}"
        return
    fi
    
    local pid=$(cat "$pid_file")
    
    if ps -p "$pid" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $service_name: ${GREEN}運行中${NC} (PID: $pid)"
        if [ -n "$url" ]; then
            echo -e "      URL: $url"
        fi
    else
        echo -e "  ${RED}✗${NC} $service_name: ${RED}已停止${NC} (PID 檔案存在但程序不存在)"
        rm -f "$pid_file"
    fi
}

# 檢查所有服務
check_service "stamp-server" "stamp-server.pid" "http://localhost:8000"
check_service "manager/backend" "manager-backend.pid" "http://localhost:8001"
check_service "manager/frontend" "manager-frontend.pid" "http://localhost:3000"
check_service "customer/demo" "customer-demo.pid" "http://localhost:3001"

echo ""
echo "=========================================="
echo ""

