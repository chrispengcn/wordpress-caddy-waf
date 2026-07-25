#!/usr/bin/env bash
set -euo pipefail

# FrankenPHP 初始化入口脚本
# 功能:
#   1. 检查 /var/www/html 目录权限
#   2. 设置正确的文件权限

echo "=========================================="
echo "FrankenPHP + PHP + Coraza WAF"
echo "=========================================="

# -----------------------------------------------------------------------------
# Step 1: 检查 /var/www/html 目录
# -----------------------------------------------------------------------------
if [ -z "$(ls -A /var/www/html)" ]; then
    echo "[init] /var/www/html 目录为空"
    echo "[init] 请将 WordPress 源码放入 ./data 目录"
    echo "[init] 示例: wget https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz --strip-components=1 -C ./data"
fi

# -----------------------------------------------------------------------------
# Step 2: 修复文件权限
# -----------------------------------------------------------------------------
echo "[init] 设置文件权限 ..."
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \; 2>/dev/null || true

echo "[init] 初始化完成，启动 FrankenPHP ..."
echo "=========================================="

exec "$@"