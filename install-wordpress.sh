#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 手动部署 WordPress 脚本
# ============================================================

echo "=========================================="
echo "WordPress 手动部署工具"
echo "=========================================="

# 检查数据目录
if [ ! -d "./data" ]; then
    echo "[1/3] 创建数据目录 ..."
    mkdir -p ./data
fi

# 检查是否已部署
if [ -f "./data/wp-settings.php" ]; then
    echo ""
    echo "⚠️  WordPress 已部署"
    echo "   如需重新部署，请先删除 ./data 目录"
    exit 0
fi

# 下载 WordPress
echo "[2/3] 下载 WordPress 最新版 ..."
cd ./data
wget -q --show-progress https://wordpress.org/latest.tar.gz

# 解压
echo "[3/3] 解压 WordPress ..."
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# 设置权限
echo ""
echo "设置权限 ..."
chmod -R 755 .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

echo ""
echo "✅ WordPress 部署完成！"
echo ""
echo "📋 后续步骤："
echo "  1. 启动容器: docker compose up -d"
echo "  2. 访问站点: http://localhost"
echo "  3. 按向导配置数据库连接"
echo ""
echo "💡 OPcache 已默认启用，无需额外配置"
echo ""