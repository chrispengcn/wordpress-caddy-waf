#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# 快速部署脚本
# ============================================================

echo "=========================================="
echo "FrankenPHP + PHP + WAF 部署"
echo "=========================================="

# 创建数据目录
mkdir -p ./data

echo ""
echo "📦 项目结构:"
echo "  ./data/              - WordPress 站点文件"
echo "  ./frankenphp/        - FrankenPHP 配置"
echo "  ./docker-compose.yml - 容器配置"
echo ""
echo "💡 使用方式:"
echo "  方式1 - 自动安装 WordPress:"
echo "    ./install-wordpress.sh"
echo ""
echo "  方式2 - 手动部署:"
echo "    cd ./data && wget https://wordpress.org/latest.tar.gz"
echo "    tar -xzf latest.tar.gz --strip-components=1"
echo ""

echo ""
echo "[1/2] 构建 Docker 镜像 ..."
docker compose build

echo ""
echo "[2/2] 启动服务 ..."
docker compose up -d

echo ""
echo "✅ 容器启动完成！"
echo ""
echo "📋 服务信息："
echo "  - 访问地址: http://localhost"
echo "  - 容器日志: docker compose logs -f"
echo "  - 停止服务: docker compose down"
echo ""
echo "💡 OPcache 已默认启用，PHP 性能自动优化"
echo ""

# 检查 WordPress 是否已部署
if [ ! -f "./data/wp-settings.php" ]; then
    echo "⚠️  注意: ./data 目录为空，请先部署 WordPress"
    echo "   运行 ./install-wordpress.sh 自动安装"
    echo ""
fi