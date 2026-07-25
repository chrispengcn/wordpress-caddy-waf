# WordPress + FrankenPHP + Coraza WAF

[简体中文](#简体中文) | [English](#english)

---

## 简体中文

基于 Docker Compose 的现代化 WordPress 部署方案，集成了完整的 WAF 防护和性能优化。

### ✨ 技术栈

| 组件 | 说明 |
|------|------|
| **FrankenPHP** | Caddy + 嵌入式 PHP 8.3，高性能现代 PHP 运行时 |
| **Coraza WAF** | Go 原生 ModSecurity 兼容 WAF + OWASP CRS 4.x 规则 |
| **Souin Cache** | 全页 HTTP 缓存，大幅提升 WordPress 响应速度 |
| **HTML Minifier** | 实时压缩 PHP 生成的 HTML 输出 |
| **imgproxy** | 实时图片格式转换 (JPG/PNG → WebP/AVIF) |
| **MariaDB 10.11** | 官方推荐的 WordPress 数据库 |

### 🚀 快速部署

#### 1. 克隆项目到服务器
在服务器上克隆本仓库：

```bash
git clone https://github.com/chrispengcn/wordpress-caddy-waf.git /opt/wordpress-caddy-waf
cd /opt/wordpress-caddy-waf
```

> 后续更新代码只需在服务器上执行 `git pull` 即可。

#### 2. 初始化配置

```bash
cd /opt/wordpress-caddy-waf
chmod +x deploy.sh
./deploy.sh build
```

首次运行会自动：
- 从 `.env.example` 复制生成 `.env`
- 生成随机密码和 imgproxy 密钥
- 构建 Docker 镜像（约 5-8 分钟）

#### 3. 编辑配置

```bash
nano .env
```

修改：
- `MYSQL_ROOT_PASSWORD` - 数据库 root 密码
- `MYSQL_PASSWORD` - WordPress 数据库密码
- `WORDPRESS_DB_PASSWORD` - 与上面相同
- （可选）设置 `SERVER_NAME` 为你的域名启用 HTTPS

#### 4. 启动服务

```bash
./deploy.sh start
```

#### 5. 完成 WordPress 安装

浏览器访问：`http://your-server-ip/`

### 📁 项目结构

```
wordpress-caddy-waf/
├── docker-compose.yml          # Docker Compose 主配置
├── deploy.sh                   # 部署脚本 (一键管理)
├── .env.example                # 环境变量模板
├── .env                        # 你的实际配置 (自动生成)
└── frankenphp/
    ├── Dockerfile              # 多阶段构建 FrankenPHP + WAF
    ├── docker-entrypoint.sh    # 自动初始化脚本
    ├── Caddyfile               # Caddy 服务器配置
    └── coraza/
        ├── coraza.conf         # WAF 基础配置
        └── wp-exclusions.conf  # WordPress 排除规则
```

### 🔧 常用命令

```bash
./deploy.sh build     # 只构建镜像
./deploy.sh start     # 启动所有服务
./deploy.sh stop      # 停止所有服务
./deploy.sh restart   # 重启 (修改配置后执行)
./deploy.sh logs      # 查看实时日志
./deploy.sh status    # 查看服务状态
./deploy.sh test-waf  # 测试 WAF 防护效果
./deploy.sh clean     # 清理所有数据 (谨慎!)
```

### 🛡️ WAF 防护说明

#### 防护能力
- ✅ SQL 注入攻击
- ✅ XSS 跨站脚本
- ✅ 路径遍历
- ✅ 命令注入
- ✅ RFI/LFI 远程文件包含
- ✅ 扫描器/爬虫识别
- ✅ HTTP 协议异常检测

#### WAF 模式切换

编辑 `frankenphp/coraza/coraza.conf`：

```apache
# 仅检测模式（推荐初期使用）
SecRuleEngine DetectionOnly

# 拦截模式（确认无误后启用）
SecRuleEngine On
```

修改后重启生效：
```bash
./deploy.sh restart
```

#### 测试 WAF

```bash
./deploy.sh test-waf
```

预期结果：
- 正常请求 → 200 / 3xx
- SQL 注入 → 403
- XSS 攻击 → 403
- 路径遍历 → 403

### ⚡ 性能优化

#### 已启用的优化

1. **全页缓存 (Souin)**
   - 匿名用户 GET 请求缓存 15 分钟
   - 绕过 wp-admin、wp-login 等动态页面

2. **HTML 实时压缩**
   - 移除注释、空白字符、冗余引号
   - CSS/JS 不处理（由主题/插件预压缩）

3. **图片优化 (imgproxy)**
   - 自动转换为 WebP/AVIF 格式
   - 根据浏览器支持智能选择
   - 图片大小减少 30-50%

4. **静态资源缓存**
   - CSS/JS/字体/图标 30 天强缓存
   - 正确的 Cache-Control 头

5. **PHP OPcache**
   - 预编译 PHP 字节码
   - 内存缓存，减少磁盘 IO

#### 额外推荐

- 使用 [Cloudflare](https://www.cloudflare.com/) 提供全球 CDN 和额外 DDoS 防护
- 安装 WordPress 插件：[Redis Object Cache](https://wordpress.org/plugins/redis-cache/)
- 安装 WordPress 插件：[Autoptimize](https://wordpress.org/plugins/autoptimize/) 优化 CSS/JS

### 🔒 安全头

已配置的 HTTP 安全头：
- `Strict-Transport-Security` - HSTS
- `X-Frame-Options` - 防点击劫持
- `X-XSS-Protection` - XSS 防护
- `X-Content-Type-Options` - MIME 嗅探防护
- `Referrer-Policy` - 来源信息控制
- `Permissions-Policy` - 浏览器权限控制

### 📊 查看 WAF 日志

```bash
# 查看所有日志
./deploy.sh logs wordpress

# 只看 WAF 拦截日志
docker logs wp-frontend 2>&1 | grep -i 'ModSecurity\|coraza'
```

### ⚠️ 常见问题

#### 首次构建很慢？
正常，第一次需要：
- 下载 Go 依赖并编译 Coraza/Souin/Minifier 模块
- 编译 PHP 扩展
- Git 克隆 OWASP CRS 规则集
- 后续构建有缓存，只需几秒

#### WAF 误拦截正常操作？
1. 先用 `DetectionOnly` 模式观察
2. 查看 WAF 日志确认误拦截的规则 ID
3. 在 `wp-exclusions.conf` 中添加排除规则

#### 图片不显示？
imgproxy 需要 WordPress 插件配合重写图片 URL，或者可以直接用默认方式，imgproxy 作为可选增强。

#### HTTPS/SSL 证书？
设置 `SERVER_NAME` 为你的域名并在 `Caddyfile` 中启用 `auto_https on`，Caddy 会自动从 Let's Encrypt 申请证书。

### 📝 配置修改后

任何配置文件修改后都需要执行：
```bash
./deploy.sh restart
```

### 📄 许可证

MIT License - 自由使用、自由修改

作者: https://shopaii.net

---

## English

A modern WordPress deployment solution based on Docker Compose, integrating comprehensive WAF protection and performance optimization.

### ✨ Tech Stack

| Component | Description |
|-----------|-------------|
| **FrankenPHP** | Caddy + embedded PHP 8.3, high-performance modern PHP runtime |
| **Coraza WAF** | Go-native ModSecurity-compatible WAF + OWASP CRS 4.x rules |
| **Souin Cache** | Full-page HTTP cache, significantly boosting WordPress response speed |
| **HTML Minifier** | Real-time compression of PHP-generated HTML output |
| **imgproxy** | Real-time image format conversion (JPG/PNG → WebP/AVIF) |
| **MariaDB 10.11** | Officially recommended WordPress database |

### 🚀 Quick Deployment

#### 1. Clone the project to your server
Clone this repository on your server:

```bash
git clone https://github.com/chrispengcn/wordpress-caddy-waf.git /opt/wordpress-caddy-waf
cd /opt/wordpress-caddy-waf
```

> To update the code later, simply run `git pull` on the server.

#### 2. Initialize Configuration

```bash
cd /opt/wordpress-caddy-waf
chmod +x deploy.sh
./deploy.sh build
```

The first run will automatically:
- Copy `.env.example` to generate `.env`
- Generate random passwords and imgproxy keys
- Build the Docker image (about 5-8 minutes)

#### 3. Edit Configuration

```bash
nano .env
```

Modify:
- `MYSQL_ROOT_PASSWORD` - Database root password
- `MYSQL_PASSWORD` - WordPress database password
- `WORDPRESS_DB_PASSWORD` - Same as above
- (Optional) Set `SERVER_NAME` to your domain to enable HTTPS

#### 4. Start Services

```bash
./deploy.sh start
```

#### 5. Complete WordPress Installation

Visit in your browser: `http://your-server-ip/`

### 📁 Project Structure

```
wordpress-caddy-waf/
├── docker-compose.yml          # Docker Compose main config
├── deploy.sh                   # Deployment script (one-click management)
├── .env.example                # Environment variables template
├── .env                        # Your actual configuration (auto-generated)
└── frankenphp/
    ├── Dockerfile              # Multi-stage build for FrankenPHP + WAF
    ├── docker-entrypoint.sh    # Auto-initialization script
    ├── Caddyfile               # Caddy server configuration
    └── coraza/
        ├── coraza.conf         # WAF base configuration
        └── wp-exclusions.conf  # WordPress exclusion rules
```

### 🔧 Common Commands

```bash
./deploy.sh build     # Build images only
./deploy.sh start     # Start all services
./deploy.sh stop      # Stop all services
./deploy.sh restart   # Restart (run after config changes)
./deploy.sh logs      # View real-time logs
./deploy.sh status    # View service status
./deploy.sh test-waf  # Test WAF protection
./deploy.sh clean     # Clean all data (use with caution!)
```

### 🛡️ WAF Protection

#### Protection Capabilities
- ✅ SQL Injection
- ✅ XSS (Cross-Site Scripting)
- ✅ Path Traversal
- ✅ Command Injection
- ✅ RFI/LFI (Remote/Local File Inclusion)
- ✅ Scanner/Crawler Detection
- ✅ HTTP Protocol Anomaly Detection

#### WAF Mode Switching

Edit `frankenphp/coraza/coraza.conf`:

```apache
# Detection-only mode (recommended for initial use)
SecRuleEngine DetectionOnly

# Blocking mode (enable after confirming no false positives)
SecRuleEngine On
```

Restart to apply changes:
```bash
./deploy.sh restart
```

#### Test WAF

```bash
./deploy.sh test-waf
```

Expected results:
- Normal requests → 200 / 3xx
- SQL injection → 403
- XSS attacks → 403
- Path traversal → 403

### ⚡ Performance Optimization

#### Enabled Optimizations

1. **Full-Page Cache (Souin)**
   - Cache anonymous user GET requests for 15 minutes
   - Bypass dynamic pages like wp-admin, wp-login

2. **Real-time HTML Compression**
   - Remove comments, whitespace, redundant quotes
   - CSS/JS not processed (pre-compressed by themes/plugins)

3. **Image Optimization (imgproxy)**
   - Auto-convert to WebP/AVIF formats
   - Smart selection based on browser support
   - Image size reduced by 30-50%

4. **Static Asset Caching**
   - 30-day strong caching for CSS/JS/fonts/icons
   - Proper Cache-Control headers

5. **PHP OPcache**
   - Pre-compiled PHP bytecode
   - In-memory cache, reducing disk IO

#### Additional Recommendations

- Use [Cloudflare](https://www.cloudflare.com/) for global CDN and additional DDoS protection
- Install WordPress plugin: [Redis Object Cache](https://wordpress.org/plugins/redis-cache/)
- Install WordPress plugin: [Autoptimize](https://wordpress.org/plugins/autoptimize/) to optimize CSS/JS

### 🔒 Security Headers

Configured HTTP security headers:
- `Strict-Transport-Security` - HSTS
- `X-Frame-Options` - Clickjacking protection
- `X-XSS-Protection` - XSS protection
- `X-Content-Type-Options` - MIME sniffing protection
- `Referrer-Policy` - Referrer information control
- `Permissions-Policy` - Browser permissions control

### 📊 View WAF Logs

```bash
# View all logs
./deploy.sh logs wordpress

# View only WAF block logs
docker logs wp-frontend 2>&1 | grep -i 'ModSecurity\|coraza'
```

### ⚠️ FAQ

#### First build is slow?
Normal, the first time requires:
- Downloading Go dependencies and compiling Coraza/Souin/Minifier modules
- Compiling PHP extensions
- Git cloning the OWASP CRS ruleset
- Subsequent builds have cache and take only seconds

#### WAF blocking normal operations?
1. First use `DetectionOnly` mode to observe
2. Check WAF logs to confirm the rule ID causing false positives
3. Add exclusion rules in `wp-exclusions.conf`

#### Images not displaying?
imgproxy requires a WordPress plugin to rewrite image URLs, or you can use the default method. imgproxy is an optional enhancement.

#### HTTPS/SSL Certificate?
Set `SERVER_NAME` to your domain and enable `auto_https on` in the `Caddyfile`. Caddy will automatically request a certificate from Let's Encrypt.

### 📝 After Configuration Changes

After modifying any configuration file, run:
```bash
./deploy.sh restart
```

### 📄 License

MIT License - Free to use, free to modify

Author: https://shopaii.net
