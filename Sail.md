## 我做了什么（简要）

我在你的仓库里为 Laravel Sail 风格的 FrankenPHP 环境做了最小修改，使其能在 Orbstack/Docker 下运行并默认连接你宿主机上的 MySQL/Redis（使用 host.docker.internal）。变更已验证过 compose 文件语法。

以下改动已完成并可直接使用：

- 在 `docker-compose.yml` 中新增并调整了服务配置：
  - 为现有 `frankenphp` 服务添加了默认的 DB/REDIS 环境变量（`DB_HOST=host.docker.internal`、`REDIS_HOST=host.docker.internal`）。
  - 新增 `laravel_sail_frankenphp` 服务，**现已支持多个站点**（挂载整个 `frankenphp/wwwroot` 目录，同 `frankenphp` 一致），默认映射到宿主 `8080` 端口（避免与主 frankenphp 的 80/443 冲突）。
- 在 `frankenphp/wwwroot/laravel12` 中添加了 `.env.docker` 示例，预设为连接宿主机的 MySQL/Redis（端口、用户名示例都已填）。

我运行了 `docker compose config` 来校验语法，输出正常（PASS）。

## 具体文件/改动

- 编辑：`docker-compose.yml`
  - 目的：添加 `laravel_sail_frankenphp` 服务（支持多站点）；为 `frankenphp` 添加主机连接的环境变量。
- 新增：`frankenphp/wwwroot/laravel12/.env.docker`
  - 目的：提供容器中运行 Laravel 时的 `.env` 示例，默认通过 `host.docker.internal` 连接宿主 MySQL/Redis。
- 更新：`frankenphp/Dockerfile`
  - 目的：启用 `pdo_pgsql` 与 `pgsql` 扩展，重建镜像后容器可连接 PostgreSQL

（你可以在项目里查看这些文件以确认细节）

## 如何启动（建议步骤）

### 单独启动 Laravel Sail FrankenPHP（含多站点支持）

在仓库根目录运行（zsh）：

```bash
docker compose up -d laravel_sail_frankenphp
```

访问：

- 单站点（直接 IP）：http://localhost:8080
- 多站点（需在 hosts 文件中配置域名）：
  - http://laravel12.test:8080
  - http://web2.test:8080
  - 等等（取决于 `frankenphp/wwwroot` 下有哪些应用目录）

### 配置多站点域名（macOS/Linux）

编辑宿主 `/etc/hosts` 文件，添加解析：

```bash
sudo nano /etc/hosts

# 添加以下行
127.0.0.1 laravel12.test
127.0.0.1 web2.test
127.0.0.1 yoursite.test
```

保存后，`laravel_sail_frankenphp` 容器会通过 Caddy 自动识别这些域名并路由到对应的应用目录（基于容器内的 Caddy 配置）。

### 同时启动其他服务

如果你希望容器连接 compose 中定义的 `mysql` / `redis` 容器（而不是宿主），运行：

```bash
docker compose up -d laravel_sail_frankenphp mysql redis
```

### 容器内初始化 Laravel

进入容器并初始化单个 Laravel 应用：

```bash
# 进入容器
docker exec -it laravel_sail_frankenphp bash

# 在容器中（以 laravel12 为例）
cd /app/laravel12
cp /app/laravel12/.env.docker .env
composer install --no-interaction --prefer-dist --optimize-autoloader
php artisan key:generate
php artisan migrate --force   # 若需要
```

### 添加新的 Laravel 应用

1. 在 `frankenphp/wwwroot` 下新增应用目录（例如 `myapp`）：

   ```bash
   mkdir -p frankenphp/wwwroot/myapp
   # 或者 git clone 一个 Laravel 项目到该目录
   ```

2. 在宿主 `/etc/hosts` 中添加域名解析：

   ```bash
   127.0.0.1 myapp.test
   ```

3. 重启容器（使 Caddy 重新加载配置）：

   ```bash
   docker compose restart laravel_sail_frankenphp
   ```

4. 访问 http://myapp.test:8080 即可。

## 工作原理（多站点支持）

- `laravel_sail_frankenphp` 现已挂载**整个 `frankenphp/wwwroot` 目录**到容器内的 `/app`，因此：
  - `/app/laravel12` → http://laravel12.test:8080
  - `/app/web2` → http://web2.test:8080
  - 其他应用类似
- Caddy 会根据请求的 `Host` 头自动路由到对应的应用目录
- 通过在宿主 `/etc/hosts` 配置域名，容器能识别并处理这些请求

## 与 `frankenphp` 服务的区别

| 特性       | `frankenphp`            | `laravel_sail_frankenphp`       |
| ---------- | ----------------------- | ------------------------------- |
| 监听端口   | 80, 443                 | 8080                            |
| 用途       | 生产/多应用             | 开发/多应用（Sail 风格）        |
| 挂载目录   | `./frankenphp/wwwroot`  | `./frankenphp/wwwroot`          |
| 数据库连接 | 支持本地或 compose      | 支持本地或 compose              |
| 调试模式   | 可配置                  | `APP_DEBUG=true`                |
| 默认启动   | 是（`restart: always`） | 否（`restart: unless-stopped`） |

## 注意事项

- 在 macOS + Orbstack 上，`host.docker.internal` 用于容器连接宿主服务（MySQL/Redis）。如果使用 Linux + Docker，需改为主机 IP。
- 已在 `frankenphp/Dockerfile` 中启用 PostgreSQL 扩展（`pdo_pgsql`、`pgsql`）；请在修改后重建镜像以使扩展生效：
  ```bash
  docker compose build frankenphp laravel_sail_frankenphp
  docker compose up -d laravel_sail_frankenphp
  ```
- Caddy 的多站点配置通过容器内的自动化保存（autosave.json）完成，首次访问新域名时会自动添加。
- 如需手动编辑 Caddy 配置，可创建 `frankenphp/config/caddy/Caddyfile` 或通过 Caddy Admin API 操作。

## 快速参考

```bash
# 启动 Laravel Sail FrankenPHP（支持多站点）
docker compose up -d laravel_sail_frankenphp

# 停止
docker compose stop laravel_sail_frankenphp

# 重启（更新 Caddy 配置）
docker compose restart laravel_sail_frankenphp

# 进入容器
docker exec -it laravel_sail_frankenphp bash

# 查看日志
docker compose logs -f laravel_sail_frankenphp

# 删除容器（保留数据卷）
docker compose down laravel_sail_frankenphp
```

## 后续建议

- 如需纯 HTTP（不使用 HTTPS/Caddy），可修改 Dockerfile 或改用轻量级 PHP 容器。
- 如想快速生成新项目脚本，可在项目根创建 `scripts/new-laravel-app.sh`，自动创建目录并初始化。
- 考虑为多个开发者创建独立的 `laravel_sail_frankenphp` 实例（不同端口），便于并行开发。
