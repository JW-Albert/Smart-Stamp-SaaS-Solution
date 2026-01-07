#!/bin/bash
# Smart Stamp Solution - 停止所有服務腳本

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PID_DIR="./scripts/pids"

echo "=========================================="
echo "Smart Stamp Solution - 停止所有服務"
echo "=========================================="
echo ""

# 停止服務函數
stop_service() {
    local service_name=$1
    local pid_file="$PID_DIR/$2"
    
    if [ ! -f "$pid_file" ]; then
        echo -e "${YELLOW}  $service_name: 未找到 PID 檔案${NC}"
        return
    fi
    
    local pid=$(cat "$pid_file")
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${YELLOW}  $service_name: 程序不存在 (PID: $pid)${NC}"
        rm -f "$pid_file"
        return
    fi
    
    echo -e "${YELLOW}  停止 $service_name (PID: $pid)...${NC}"
    kill "$pid" 2>/dev/null || true
    
    # 等待程序結束
    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
        sleep 0.5
        count=$((count + 1))
    done
    
    if ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}  強制停止 $service_name (PID: $pid)...${NC}"
        kill -9 "$pid" 2>/dev/null || true
        sleep 1
    fi
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ $service_name 已停止${NC}"
        rm -f "$pid_file"
    else
        echo -e "${RED}  ✗ $service_name 停止失敗${NC}"
    fi
}

# 停止所有服務
stop_service "stamp-server" "stamp-server.pid"
echo ""
stop_service "manager/backend" "manager-backend.pid"
echo ""
stop_service "manager/frontend" "manager-frontend.pid"
echo ""
stop_service "customer/demo" "customer-demo.pid"

echo ""
echo "=========================================="
echo -e "${GREEN}所有服務已停止！${NC}"
echo "=========================================="
echo ""

