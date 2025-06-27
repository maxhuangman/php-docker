# Docker FrankenPHP 服务环境

基于 Docker Compose 的多服务开发环境，集成 Webman开发环境、Web 服务器(FrankenPHP)、数据库(MySQL)、缓存(Redis)、搜索引擎(Elasticsearch)、文件管理服务(Alist)、反向代理(Caddy)、Docker 管理面板(DPanel，MacOS系统最优解)等常用服务。

开箱即用，无需额外配置即可快速启动和运行。
- Webman 项目直接使用使用自定义镜像（`./webman/Dockerfile`）
- 支持传统PHP-FPM项目，如Laravel、Thinkphp、WordPress等，使用FrankenPHP服务进行优化，相同配置能提升约3～5倍性能
- Hyperf (后续计划支持)
- Mysql
- Redis
- Elasticsearch
- DPanel
- Alist

## 🚀 服务概览

| 服务 | 端口 | 描述 |
|------|------|------|
| **Webman** | 8787 | PHP 高性能 Web 框架 |
| **FrankenPHP** | 80, 443 | PHP Web 服务器 |
| **MySQL** | 3306 | 数据库服务 |
| **Redis** | 6379 | 缓存服务 |
| **DPanel** | 100, 8807 | Docker 管理面板 |
| **Elasticsearch** | 9200, 9300 | 搜索引擎 |
| **Alist** | 5244 | 文件管理服务 |

## 📋 系统要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存

## 🛠️ 快速开始

### 1. 创建必要目录

```bash
mkdir -p mysql/{data,logs,conf.d}
mkdir -p redis/{data,logs}
mkdir -p elasticsearch/data
mkdir -p alist caddy/{certs,logs}
mkdir -p frankenphp/{data,config} dpanel wwwroot
mkdir -p webman/www
```

### 2. 配置 Redis

```bash
cat > redis/redis.conf << EOF
bind 0.0.0.0
port 6379
daemonize no
databases 16
save 900 1
save 300 10
save 60 10000
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF
```

### 3. 启动服务

```bash
docker-compose up -d
```

### 4. 按需配置服务

```bash
docker-compose up -d webman frankenphp mysql redis dpanel elasticsearch alist 
```

## 🔧 服务配置

### 1. Webman (PHP 高性能框架)
- **端口**: 8787
- **应用目录**: `./webman/www`
- **基础镜像**: PHP 8.3.22-cli-alpine
- **访问地址**: `http://localhost:8787`

#### 使用说明
1. **项目部署**: 将您的 Webman 项目放置在 `./webman/www` 目录下
2. **配置文件**: 
   - PHP 配置: `webman/config/php.ini`
   - Supervisor 配置: `webman/config/supervisord.conf`
3. **扩展安装**: 预装了常用 PHP 扩展，如需添加可修改 `webman/extension/install.sh`
4. **Composer**: 容器内已安装 Composer，可直接使用

#### 构建自定义镜像

```bash
docker build -t docker-webman:1.0 .
```
#### 使用镜像(在项目根目录下)
```bash
docker run --rm -it -p 8787:8787 -v ./:/app docker-webman:1.0
```
#### 访问服务
```bash
curl http://localhost:8787
```

#### 示例访问
```bash
# 检查服务状态
curl http://localhost:8787

# 进入容器调试
docker-compose exec webman bash

# 查看日志
docker-compose logs -f webman
```

### 2. FrankenPHP (Web 服务器)
- **端口**: 80 (HTTP), 443 (HTTPS)
- **网站根目录**: `./frankenphp/wwwroot`

#### 站点配置
- **Caddy 配置文件**: `caddy/Caddyfile`
- **站点域名**: `web1.test`
- **站点目录**: `/app/web1/public`
```bash
{
	# 启用调试模式，生成详细日志用于故障排除
	debug
	# 为本地域名使用本地证书
	local_certs
	frankenphp
	order php_server before file_server
}

# 站点配置
web1.test {
  root * /app/web1/public
  # 启用压缩(可选)
  encode zstd br gzip
  # 使用 FrankenPHP 内置的 PHP 处理，不需要 php_fastcgi
  php_server
  file_server
  # 添加日志记录
  log {
    output file /var/log/caddy/web1.test.log
  }
}

```

### 3. MySQL 数据库
- **端口**: 3306
- **Root 密码**: 123456
- **连接**: `mysql -h localhost -P 3306 -u root -p`

### 4. Redis 缓存
- **端口**: 6379
- **连接**: `redis-cli -h localhost -p 6379`

### 5. DPanel (Docker 管理面板)
- **端口**: 8807
- **访问**: `http://localhost:8807`

### 6. Elasticsearch
- **端口**: 9200 (HTTP), 9300 (节点通信)
- **密码**: 123456
- **健康检查**: `curl -u elastic:123456 http://localhost:9200/_cluster/health`

### 7.Alist (文件管理)
- **端口**: 5244
- **访问**: `http://localhost:5244`

## 🚀 常用命令

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启特定服务
docker-compose restart mysql
```

## 🔒 安全配置

### 修改默认密码

**MySQL**:
```bash
docker-compose exec mysql mysql -u root -p
ALTER USER 'root'@'%' IDENTIFIED BY 'new_password';
```

**Redis**: 编辑 `redis/redis.conf` 添加 `requirepass your_password`

**Elasticsearch**: 修改 `docker-compose.yml` 中的 `ELASTIC_PASSWORD`

## 📊 监控维护

```bash
# 检查服务状态
docker-compose ps

# 查看资源使用
docker stats

# 备份数据库
docker-compose exec mysql mysqldump -u root -p123456 --all-databases > backup.sql
```

## 🐛 故障排除

### 常见问题

1. **端口冲突**: 修改 `docker-compose.yml` 中的端口映射
2. **权限问题**: `sudo chown -R 1000:1000 mysql/data redis/data`
3. **内存不足**: 增加 Docker 内存限制
4. **服务启动失败**: `docker-compose logs service_name`

### 日志分析

```bash
# 查看错误日志
docker-compose logs | grep ERROR

# 实时监控
docker-compose logs -f --tail=100
```

## 📁 目录结构

```
service/
├── docker-compose.yml          # Docker Compose 配置
├── wwwroot/                    # FrankenPHP 网站根目录
├── webman/                     # Webman 应用目录
│   ├── www/                    # Webman 项目文件
│   ├── config/                 # PHP 和 Supervisor 配置
│   ├── extension/              # PHP 扩展安装脚本
│   └── Dockerfile              # Webman 镜像构建文件
├── mysql/                      # MySQL 数据
├── redis/                      # Redis 数据
├── elasticsearch/              # Elasticsearch 数据
├── alist/                      # Alist 数据
├── caddy/                      # Caddy 配置
├── frankenphp/                 # FrankenPHP 配置
└── dpanel/                     # DPanel 数据
```

---

## ⚠️ 注意
# Docker 服务环境检查结果

我已经检查了您的 `docker-compose.yml` 文件，发现并修复了以下错误：

## 📋 服务概览

您的环境包含以下服务：

| 服务 | 端口 | 描述 |
|------|------|------|
| **Webman** | 8787 | PHP 高性能 Web 框架 |
| **FrankenPHP** | 80, 443 | PHP Web 服务器 |
| **MySQL** | 3306 | 数据库服务 |
| **Redis** | 6379 | 缓存服务 |
| **DPanel** | 100, 8807 | Docker 管理面板 |
| **Elasticsearch** | 9200, 9300 | 搜索引擎 |
| **Alist** | 5244 | 文件管理服务 |

## 💡 使用建议

1. **启动服务**：`docker-compose up -d`
2. **查看状态**：`docker-compose ps`
3. **查看日志**：`docker-compose logs -f`

## 💡 安全提醒

- 请修改默认密码（MySQL: 123456, Elasticsearch: 123456）
- 生产环境建议配置 SSL 证书
- 考虑限制端口访问范围

## 🙏 感谢清单
- [tinywan/docker-php-webman](https://github.com/Tinywan/docker-php-webman)