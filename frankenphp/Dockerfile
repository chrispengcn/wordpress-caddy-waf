# ============================================================
# 多阶段构建 FrankenPHP + Coraza WAF
# 基于 dunglas/frankenphp:1.12.0-php8.3-bookworm，仅添加 Coraza WAF 模块
# ============================================================

# Stage 1: 重新编译 FrankenPHP，仅添加 Coraza WAF 模块（不含 Souin，节省编译时间）
FROM dunglas/frankenphp:1.12.0-builder-php8.3-bookworm AS builder

ENV CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s'"

# 只添加 Coraza WAF 模块，不再编译 Souin
RUN CGO_CFLAGS="$(php-config --includes)" \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
      --output /usr/local/bin/frankenphp \
      --with github.com/dunglas/frankenphp=./ \
      --with github.com/dunglas/frankenphp/caddy=./caddy/ \
      --with github.com/dunglas/mercure/caddy \
      --with github.com/dunglas/vulcain/caddy \
      --with github.com/corazawaf/coraza-caddy/v2

# ============================================================
# Stage 2: 下载 OWASP CRS 规则集
# ============================================================
FROM alpine:3.20 AS rules

RUN apk add --no-cache git

WORKDIR /rules

# OWASP Core Rule Set v4.7.0
RUN git clone --depth=1 --branch v4.7.0 \
      https://github.com/coreruleset/coreruleset /rules/crs && \
    cp /rules/crs/crs-setup.conf.example /rules/crs/crs-setup.conf

# WordPress 规则排除插件
RUN git clone --depth=1 \
      https://github.com/coreruleset/wordpress-rule-exclusions-plugin \
      /rules/wp-exclusions

# ============================================================
# Stage 3: 运行时镜像（基于官方预编译镜像，无需重新编译 PHP）
# ============================================================
FROM dunglas/frankenphp:1.12.0-php8.3-bookworm

# 安装系统依赖 (Debian bookworm)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl ghostscript imagemagick \
  && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展 (WordPress 推荐)
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    opcache \
    zip \
    redis \
    imagick

# 复制编译好的 FrankenPHP 二进制（含 Coraza WAF 模块）
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp

# 复制 WAF 规则
COPY --from=rules /rules/crs /etc/caddy/crs
COPY --from=rules /rules/wp-exclusions /etc/caddy/wp-exclusions

# ============================================================
# PHP 配置 (OPcache 默认启用)
# ============================================================
# 推荐的 php.ini 设置
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 128M'; \
    echo 'max_input_vars = 5000'; \
    echo 'date.timezone = Asia/Shanghai'; \
  } > /usr/local/etc/php/conf.d/wordpress.ini; \
  # OPcache 默认启用 (生产环境优化配置)
  { \
    echo 'opcache.enable=1'; \
    echo 'opcache.enable_cli=0'; \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.max_wasted_percentage=10'; \
    echo 'opcache.revalidate_freq=120'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.load_comments=1'; \
    echo 'opcache.fast_shutdown=0'; \
    echo 'opcache.enable_file_override=1'; \
    echo 'opcache.log_verbosity_level=1'; \
    echo 'opcache.optimization_level=0x7FFFBFFF'; \
  } > /usr/local/etc/php/conf.d/opcache.ini

# ============================================================
# 入口脚本
# ============================================================
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile"]
