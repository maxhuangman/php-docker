# FrankenPHP 多 PHP 版本配置指南

## 概述

这个配置允许你像 Valet 一样为每个站点配置不同的 PHP 版本。系统会自动读取每个站点根目录下的`.php-version`文件，并使用对应的 PHP 容器来处理 PHP 请求。

## 支持的 PHP 版本

- **php74** - PHP 7.4
- **php80** - PHP 8.0
- **php81** - PHP 8.1
- **php82** - PHP 8.2
- **php83** - PHP 8.3（默认版本）

## 使用方法

### 1. 创建站点目录

在 `frankenphp/wwwroot/` 目录下创建你的站点目录：

```bash
mkdir -p frankenphp/wwwroot/mysite/public
```

### 2. 配置 PHP 版本

在站点根目录创建 `.php-version` 文件，指定要使用的 PHP 版本：

```bash
echo "php81" > frankenphp/wwwroot/mysite/.php-version
```

### 3. 放置网站文件

将你的 PHP 网站文件放置在 `public` 目录下：

```
frankenphp/wwwroot/mysite/
├── .php-version    # 包含 "php81"
└── public/
    ├── index.php
    ├── css/
    └── js/
```

### 4. 配置本地 hosts

在本地 hosts 文件中添加域名映射：

```
127.0.0.1 mysite.caddy
```

### 5. 访问网站

通过浏览器访问：`http://mysite.caddy`

## 配置示例

### 使用 PHP 7.4 的站点

```bash
# 创建站点目录
mkdir -p frankenphp/wwwroot/legacy-site/public

# 配置PHP版本
echo "php74" > frankenphp/wwwroot/legacy-site/.php-version

# 放置网站文件
cp -r legacy_php_files/* frankenphp/wwwroot/legacy-site/public/

# 配置hosts
echo "127.0.0.1 legacy-site.caddy" | sudo tee -a /etc/hosts
```

### 使用 PHP 8.3 的站点（默认）

```bash
# 创建站点目录
mkdir -p frankenphp/wwwroot/modern-site/public

# 可选：创建.php-version文件（默认就是php83）
echo "php83" > frankenphp/wwwroot/modern-site/.php-version

# 放置网站文件
cp -r modern_php_files/* frankenphp/wwwroot/modern-site/public/

# 配置hosts
echo "127.0.0.1 modern-site.caddy" | sudo tee -a /etc/hosts
```

## 工作原理

### Caddyfile 配置

Caddyfile 会自动：

1. **提取站点名称**：从域名中提取站点名称（如 `mysite.caddy` → `mysite`）
2. **读取 PHP 版本配置**：查找 `/app/{site_name}/.php-version` 文件
3. **选择 PHP 容器**：使用文件中指定的 PHP 容器名称
4. **处理 PHP 请求**：将 PHP 请求转发到对应的 PHP-FPM 容器
5. **容错机制**：如果指定的容器不可用，会自动回退到默认的 php83 容器

### 容器网络

所有 PHP 容器都连接到同一个 Docker 网络 `maxhuang_network`，可以通过容器名称相互通信。

## 故障排除

### 检查 PHP 版本配置

```bash
# 检查.php-version文件内容
cat frankenphp/wwwroot/mysite/.php-version

# 检查容器是否运行
docker ps | grep php
```

### 查看 Caddy 日志

```bash
# 查看Caddy访问日志
docker logs frankenphp

# 查看特定PHP容器的日志
docker logs php81
```

### 验证 PHP 版本

创建一个简单的 PHP 文件来验证版本：

```php
<?php
phpinfo();
?>
```

访问 `http://mysite.caddy/info.php` 查看 PHP 版本信息。

## 扩展配置

### 添加新的 PHP 版本

1. 在 `docker-compose.yml` 中添加新的 PHP 服务
2. 确保容器名称与 `.php-version` 文件中使用的名称一致
3. 重启服务：`docker-compose up -d`

### 自定义 PHP 配置

每个 PHP 容器都可以通过挂载自定义配置文件来调整 PHP 设置：

```yaml
php81:
  image: php:8.1-fpm
  volumes:
    - ./frankenphp/wwwroot:/app
    - ./config/php81/php.ini:/usr/local/etc/php/php.ini:ro
```

## 注意事项

1. **文件权限**：确保 PHP 容器有权限读取站点文件
2. **容器健康检查**：系统会定期检查 PHP 容器健康状态
3. **内存限制**：默认 PHP 内存限制为 512MB，可在 Caddyfile 中调整
4. **文件上传限制**：默认最大上传文件大小为 100MB

## 性能优化建议

1. **OPcache 启用**：确保 PHP 容器启用了 OPcache
2. **静态文件缓存**：使用 Caddy 的缓存功能优化静态文件服务
3. **连接池**：考虑使用 PHP-FPM 连接池提高性能

这个配置提供了类似 Valet 的体验，让你可以轻松管理多个 PHP 版本的站点开发环境。
