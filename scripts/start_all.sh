#!/bin/bash
# Smart Stamp Solution - 啟動所有服務腳本
# 預設所有前置條件已完成（依賴已安裝、資料庫已設定、密鑰已生成）

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# PID 檔案目錄
PID_DIR="./scripts/pids"
mkdir -p "$PID_DIR"

# 日誌目錄
LOG_DIR="./scripts/logs"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "Smart Stamp Solution - 啟動所有服務"
echo "=========================================="
echo ""

# 檢查並啟動 stamp-server
start_stamp_server() {
    echo -e "${YELLOW}[1/4] 啟動 stamp-server...${NC}"
    
    if [ -f "$PID_DIR/stamp-server.pid" ]; then
        OLD_PID=$(cat "$PID_DIR/stamp-server.pid")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}  stamp-server 已在運行中 (PID: $OLD_PID)${NC}"
            return
        fi
    fi
    
    cd stamp-server
    
    if [ ! -d "venv" ]; then
        echo -e "${RED}  錯誤: venv 不存在，請先執行 ./scripts/install.sh${NC}"
        exit 1
    fi
    
    nohup venv/bin/python -m app.main > "../$LOG_DIR/stamp-server.log" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "../$PID_DIR/stamp-server.pid"
    cd ..
    
    sleep 2
    if ps -p "$SERVER_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ stamp-server 已啟動 (PID: $SERVER_PID)${NC}"
        echo -e "  日誌: $LOG_DIR/stamp-server.log"
        echo -e "  URL: http://localhost:8000"
    else
        echo -e "${RED}  ✗ stamp-server 啟動失敗，請檢查日誌${NC}"
    fi
}

# 檢查並啟動 manager/backend
start_manager_backend() {
    echo -e "${YELLOW}[2/4] 啟動 manager/backend...${NC}"
    
    if [ -f "$PID_DIR/manager-backend.pid" ]; then
        OLD_PID=$(cat "$PID_DIR/manager-backend.pid")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}  manager/backend 已在運行中 (PID: $OLD_PID)${NC}"
            return
        fi
    fi
    
    cd manager/backend
    
    if [ ! -d "venv" ]; then
        echo -e "${RED}  錯誤: venv 不存在，請先執行 ./scripts/install.sh${NC}"
        exit 1
    fi
    
    nohup venv/bin/python -m app.main > "../../$LOG_DIR/manager-backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "../../$PID_DIR/manager-backend.pid"
    cd ../..
    
    sleep 2
    if ps -p "$BACKEND_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ manager/backend 已啟動 (PID: $BACKEND_PID)${NC}"
        echo -e "  日誌: $LOG_DIR/manager-backend.log"
        echo -e "  URL: http://localhost:8001"
    else
        echo -e "${RED}  ✗ manager/backend 啟動失敗，請檢查日誌${NC}"
    fi
}

# 檢查並啟動 manager/frontend
start_manager_frontend() {
    echo -e "${YELLOW}[3/4] 啟動 manager/frontend...${NC}"
    
    if [ -f "$PID_DIR/manager-frontend.pid" ]; then
        OLD_PID=$(cat "$PID_DIR/manager-frontend.pid")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}  manager/frontend 已在運行中 (PID: $OLD_PID)${NC}"
            return
        fi
    fi
    
    cd manager/frontend
    
    if [ ! -d "node_modules" ]; then
        echo -e "${RED}  錯誤: node_modules 不存在，請先執行 ./scripts/install.sh${NC}"
        exit 1
    fi
    
    nohup npm run dev > "../../$LOG_DIR/manager-frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "../../$PID_DIR/manager-frontend.pid"
    cd ../..
    
    sleep 3
    if ps -p "$FRONTEND_PID" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ manager/frontend 已啟動 (PID: $FRONTEND_PID)${NC}"
        echo -e "  日誌: $LOG_DIR/manager-frontend.log"
        echo -e "  URL: http://localhost:3000"
    else
        echo -e "${RED}  ✗ manager/frontend 啟動失敗，請檢查日誌${NC}"
    fi
}

# 檢查並啟動 customer/demo
start_customer_demo() {
    echo -e "${YELLOW}[4/4] 啟動 customer/demo...${NC}"
    
    if [ -f "$PID_DIR/customer-demo.pid" ]; then
        OLD_PID=$(cat "$PID_DIR/customer-demo.pid")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}  customer/demo 已在運行中 (PID: $OLD_PID)${NC}"
            return
        fi
    fi
    
    cd customer/demo
    
    if [ ! -d "node_modules" ]; then
        echo -e "${RED}  錯誤: node_modules 不存在，請先執行 ./scripts/install.sh${NC}"
        exit 1
    fi
    
    nohup node server.js > "../../$LOG_DIR/customer-demo.log" 2>&1 &
    DEMO_PID=$!
    echo $DEMO_PID > "../../$PID_DIR/customer-demo.pid"
    cd ../..
    
    sleep 3
    # 檢查進程是否存在，或檢查端口是否被占用
    if ps -p "$DEMO_PID" > /dev/null 2>&1 || lsof -ti:3001 > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ customer/demo 已啟動 (PID: $DEMO_PID)${NC}"
        echo -e "  日誌: $LOG_DIR/customer-demo.log"
        echo -e "  URL: http://localhost:3001"
    else
        echo -e "${RED}  ✗ customer/demo 啟動失敗，請檢查日誌${NC}"
        echo -e "  日誌位置: $LOG_DIR/customer-demo.log"
    fi
}

# 執行啟動
start_stamp_server
echo ""
start_manager_backend
echo ""
start_manager_frontend
echo ""
start_customer_demo

echo ""
echo "=========================================="
echo -e "${GREEN}所有服務啟動完成！${NC}"
echo "=========================================="
echo ""
echo "服務狀態："
echo "  - stamp-server:      http://localhost:8000"
echo "  - manager/backend:    http://localhost:8001"
echo "  - manager/frontend:  http://localhost:3000"
echo "  - customer/demo:     http://localhost:3001"
echo ""
echo "PID 檔案: $PID_DIR/"
echo "日誌檔案: $LOG_DIR/"
echo ""
echo "停止所有服務: ./scripts/stop_all.sh"
echo "查看服務狀態: ./scripts/status.sh"
echo ""

