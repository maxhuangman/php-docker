# Docker FrankenPHP 服务环境

基于 Docker Compose 的多服务开发环境，集成 Webman开发环境、Web 服务器(FrankenPHP)、数据库(MySQL、PostgreSQL、MongoDB)、缓存(Redis)、搜索引擎(Elasticsearch)、文档服务(Docsify)、反向代理(Caddy)、Docker 管理面板(DPanel，MacOS系统最优解)等常用服务。

开箱即用，无需额外配置即可快速启动和运行。
- Webman 项目直接使用使用自定义镜像（`./webman/Dockerfile`）
- 支持传统PHP-FPM项目，如Laravel、Thinkphp、WordPress等，使用FrankenPHP服务进行优化，相同配置能提升约3～5倍性能
- Hyperf (后续计划支持)
- Mysql
- PostgreSQL
- MongoDB
- Redis
- Elasticsearch
- DPanel
- Docsify

## 🚀 服务概览

| 服务 | 端口 | 描述 |
|------|------|------|
| **Webman** | 8787 | PHP 高性能 Web 框架 |
| **FrankenPHP** | 80, 443 | PHP Web 服务器 |
| **MySQL** | 3306 | 数据库服务 |
| **PostgreSQL** | 5432 | 数据库服务 |
| **MongoDB** | 27017 | 数据库服务 |
| **Redis** | 6379 | 缓存服务 |
| **DPanel** | 100, 8807 | Docker 管理面板 |
| **Elasticsearch** | 9200, 9300 | 搜索引擎 |
| **Docsify** | 3000 | 文档服务 |

## 📋 系统要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存

## 🛠️ 快速开始

### 1. 创建必要目录

```bash
mkdir -p mysql/{data,logs,conf.d}
mkdir -p postgresql/{data,logs}
mkdir -p mongodb/{data,logs,config}
mkdir -p redis/{data,logs}
mkdir -p elasticsearch/data
mkdir -p caddy/{certs,logs}
mkdir -p frankenphp/{data,config} dpanel wwwroot
mkdir -p docs webman/www
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
docker-compose up -d webman frankenphp mysql postgresql mongodb redis dpanel elasticsearch docsify
docker-compose up -d mongodb
docker-compose up -d elasticsearch
docker-compose up -d postgresql
docker-compose up -d rabbitmq
docker-compose up -d dpanel
docker-compose up -d frankenphp
docker-compose up -d docsify
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
- 1、默认随机容器名称
```bash
docker run --rm -it -p 8787:8787 -v ./:/app docker-webman:1.0
```
- 2、指定随机容器名称（后台运行 自动重启）
```bash
docker run -it -d -p 8787:8787 -v ./:/app --name maxadmin-webman --restart=always docker-webman:1.0
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

### 4. PostgreSQL 数据库
- **端口**: 5432
- **用户名**: default
- **密码**: 123456
- **数据库**: default
- **连接**: `psql -h localhost -p 5432 -U default -d default`

### 5. MongoDB 数据库
- **端口**: 27017
- **用户名**: admin
- **密码**: 123456
- **数据库**: default
- **连接**: `mongosh mongodb://admin:123456@localhost:27017/default`

### 6. Redis 缓存
- **端口**: 6379
- **连接**: `redis-cli -h localhost -p 6379`

### 7. DPanel (Docker 管理面板)
- **端口**: 8807
- **访问**: `http://localhost:8807`

### 8. Elasticsearch
- **端口**: 9200 (HTTP), 9300 (节点通信)
- **密码**: 123456
- **健康检查**: `curl -u elastic:123456 http://localhost:9200/_cluster/health`

### 9. Docsify (文档服务)
- **端口**: 3000
- **文档目录**: `./docs`
- **访问**: `http://localhost:3000`

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

# 连接数据库
docker-compose exec mysql mysql -u root -p
docker-compose exec postgresql psql -U default -d default
docker-compose exec mongodb mongosh -u admin -p 123456
```

## 🔒 安全配置

### 修改默认密码

**MySQL**:
```bash
docker-compose exec mysql mysql -u root -p
ALTER USER 'root'@'%' IDENTIFIED BY 'new_password';
```

**PostgreSQL**:
```bash
docker-compose exec postgresql psql -U default -d default
ALTER USER default PASSWORD 'new_password';
```

**MongoDB**:
```bash
docker-compose exec mongodb mongosh -u admin -p 123456
use admin
db.changeUserPassword("admin", "new_password")
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
docker-compose exec postgresql pg_dumpall -U default > backup.sql
docker-compose exec mongodb mongodump --uri="mongodb://admin:123456@localhost:27017" --out=./backup
```

## 🐛 故障排除

### 常见问题

1. **端口冲突**: 修改 `docker-compose.yml` 中的端口映射
2. **权限问题**: `sudo chown -R 1000:1000 mysql/data postgresql/data mongodb/data redis/data`
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
├── postgresql/                 # PostgreSQL 数据
├── mongodb/                    # MongoDB 数据
├── redis/                      # Redis 数据
├── elasticsearch/              # Elasticsearch 数据
├── docs/                        # Docsify 文档
├── caddy/                      # Caddy 配置
├── frankenphp/                 # FrankenPHP 配置
└── dpanel/                     # DPanel 数据
```

---

## 📋 服务概览

您的环境包含以下服务：

| 服务 | 端口 | 描述 |
|------|------|------|
| **Webman** | 8787 | PHP 高性能 Web 框架 |
| **FrankenPHP** | 80, 443 | PHP Web 服务器 |
| **MySQL** | 3306 | 数据库服务 |
| **PostgreSQL** | 5432 | 数据库服务 |
| **MongoDB** | 27017 | 数据库服务 |
| **Redis** | 6379 | 缓存服务 |
| **DPanel** | 100, 8807 | Docker 管理面板 |
| **Elasticsearch** | 9200, 9300 | 搜索引擎 |
| **Docsify** | 3000 | 文档服务 |

## 💡 使用建议

1. **启动服务**：`docker-compose up -d`
2. **查看状态**：`docker-compose ps`
3. **查看日志**：`docker-compose logs -f`

## 💡 安全提醒

- 请修改默认密码（MySQL: 123456, PostgreSQL: 123456, MongoDB: 123456, Elasticsearch: 123456）
- 生产环境建议配置 SSL 证书
- 考虑限制端口访问范围

## 🙏 感谢清单
- [tinywan/docker-php-webman](https://github.com/Tinywan/docker-php-webman)