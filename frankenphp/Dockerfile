# ============================================================
# 多阶段构建 FrankenPHP + Coraza WAF + Souin Cache
# ============================================================

# Stage 1: 构建 FrankenPHP + Coraza WAF 模块
FROM dunglas/frankenphp:1-builder-php8.3-alpine AS builder

# 从官方 caddy builder 镜像复制 xcaddy
COPY --from=caddy:2.8-builder /usr/bin/xcaddy /usr/bin/xcaddy

ENV CGO_ENABLED=1 \
    XCADDY_SETCAP=1 \
    XCADDY_GO_BUILD_FLAGS="-ldflags='-w -s' -tags=nobadger,nomysql,nopgx"

# 构建带有 Coraza WAF、Souin Cache 模块的 FrankenPHP
# CGO 需要 PHP 头文件路径，从 php-config 动态获取
RUN CGO_CFLAGS="$(php-config --includes)" \
    CGO_LDFLAGS="$(php-config --ldflags) $(php-config --libs)" \
    xcaddy build \
      --output /usr/local/bin/frankenphp \
      --with github.com/dunglas/frankenphp=./ \
      --with github.com/dunglas/frankenphp/caddy=./caddy/ \
      --with github.com/dunglas/mercure/caddy \
      --with github.com/dunglas/vulcain/caddy \
      --with github.com/corazawaf/coraza-caddy/v2 \
      --with github.com/darkweak/souin/plugins/caddy

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
# Stage 3: 运行时镜像
# ============================================================
FROM dunglas/frankenphp:1-php8.3-alpine

# 安装系统依赖
RUN apk add --no-cache bash curl ghostscript imagemagick

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

# 复制编译好的 FrankenPHP 二进制
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