#!/bin/bash
# Smart Stamp Solution - 生成 RS256 密鑰對腳本

set -e

echo "=========================================="
echo "生成 RS256 密鑰對"
echo "=========================================="
echo ""

# 建立目錄
mkdir -p stamp-server/keys
mkdir -p customer/demo/keys

# 生成私鑰
echo "[1/2] 生成私鑰..."
openssl genrsa -out stamp-server/keys/private_key.pem 2048
echo "  ✓ 私鑰已生成: stamp-server/keys/private_key.pem"

# 生成公鑰
echo "[2/2] 生成公鑰..."
openssl rsa -in stamp-server/keys/private_key.pem -pubout -out stamp-server/keys/public_key.pem
echo "  ✓ 公鑰已生成: stamp-server/keys/public_key.pem"

# 複製公鑰到 customer/demo
cp stamp-server/keys/public_key.pem customer/demo/keys/public_key.pem
echo "  ✓ 公鑰已複製到: customer/demo/keys/public_key.pem"

echo ""
echo "=========================================="
echo "密鑰生成完成！"
echo "=========================================="
echo ""
echo "私鑰路徑: stamp-server/keys/private_key.pem"
echo "公鑰路徑: stamp-server/keys/public_key.pem"
echo ""
echo "注意：請妥善保管私鑰，不要提交到版本控制系統！"
echo ""

