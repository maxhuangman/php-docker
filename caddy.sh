#!/bin/bash
set -e

# 默认配置
DEFAULT_PHP_VERSION="php83"
SITES_ROOT="./frankenphp/wwwroot"
CADDYFILE="./frankenphp/Caddyfile"

# 用法提示
usage() {
  echo "用法: $0 <站点名称> [php容器名称]"
  echo "示例:"
  echo "  $0 myapp          # 使用默认 PHP 容器 ($DEFAULT_PHP_VERSION)"
  echo "  $0 blog php82     # 使用 php82 容器"
  exit 1
}

# 参数检查
if [[ $# -lt 1 ]]; then
  usage
fi

SITE_NAME="$1"
PHP_VERSION="${2:-$DEFAULT_PHP_VERSION}"
DOMAIN="${SITE_NAME}.caddy"
SITE_PATH="${SITES_ROOT}/${SITE_NAME}"
PUBLIC_PATH="${SITE_PATH}/public"

# 自动创建站点目录（如果不存在）
if [[ ! -d "$SITE_PATH" ]]; then
  echo "📁 正在创建站点目录: $SITE_PATH"
  mkdir -p "$PUBLIC_PATH"
  
  # 创建默认的 public/index.php
  cat > "${PUBLIC_PATH}/index.php" <<EOF
<?php
declare(strict_types=1);

\$host = \$_SERVER['HTTP_HOST'] ?? 'unknown';
\$version = phpversion();
\$time = date('Y-m-d H:i:s T');
\$documentRoot = \$_SERVER['DOCUMENT_ROOT'] ?? '未设置';

echo <<<HTML
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to \$host</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 2rem; }
    .container { max-width: 600px; margin: 0 auto; }
    h1 { color: #2c3e50; }
    .info { background: #f8f9fa; padding: 1rem; border-radius: 0.5rem; margin: 1rem 0; }
    code { background: #e9ecef; padding: 0.2rem 0.4rem; border-radius: 0.25rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎉 欢迎访问 <code>\$host</code></h1>
    <div class="info">
      <p><strong>PHP 版本:</strong> <code>\$version</code></p>
      <p><strong>服务器时间:</strong> <code>\$time</code></p>
      <p><strong>文档根目录:</strong> <code>$documentRoot</code></p>
    </div>
    <p>这是由 FrankenPHP 驱动的站点。请将你的应用入口文件放在 <code>public/</code> 目录下。</p>
  </div>
</body>
</html>
HTML;
EOF

  echo "✅ 已创建测试页面: $PUBLIC_PATH/index.php"
else
  # 如果站点已存在，但 public/index.php 不存在，则创建
  if [[ ! -f "${PUBLIC_PATH}/index.php" ]]; then
    echo "📄 站点已存在，但缺少 public/index.php，正在创建默认页面..."
    mkdir -p "$PUBLIC_PATH"
    # 复用上面的模板（使用 heredoc + 变量需转义）
    cat > "${PUBLIC_PATH}/index.php" <<'EOF'
<?php
declare(strict_types=1);

$host = $_SERVER['HTTP_HOST'] ?? 'unknown';
$version = phpversion();
$time = date('Y-m-d H:i:s T');

echo <<<HTML
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to {$host}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 2rem; }
    .container { max-width: 600px; margin: 0 auto; }
    h1 { color: #2c3e50; }
    .info { background: #f8f9fa; padding: 1rem; border-radius: 0.5rem; margin: 1rem 0; }
    code { background: #e9ecef; padding: 0.2rem 0.4rem; border-radius: 0.25rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎉 欢迎访问 <code>{$host}</code></h1>
    <div class="info">
      <p><strong>PHP 版本:</strong> <code>{$version}</code></p>
      <p><strong>服务器时间:</strong> <code>{$time}</code></p>
      <p><strong>文档根目录:</strong> <code>\$documentRoot</code></p>
    </div>
    <p>这是由 FrankenPHP 驱动的站点。请将你的应用入口文件放在 <code>public/</code> 目录下。</p>
  </div>
</body>
</html>
HTML;
EOF
    echo "✅ 已补充默认页面: $PUBLIC_PATH/index.php"
  else
    echo "ℹ️  站点目录和 index.php 已存在，跳过创建。"
  fi
fi

# 检查 Caddyfile 是否存在，不存在则创建基础结构
if [[ ! -f "$CADDYFILE" ]]; then
  echo "📝 创建新的 Caddyfile..."
  cat > "$CADDYFILE" <<EOF
{
  debug
  frankenphp
  order php_server before file_server
  # Disable automatic HTTPS, only use HTTP
  auto_https off
}

# Listen on port 80
:80 {
  # Logging configuration
  log {
    output file /var/log/caddy/access.log
    format json
  }

  # Handle favicon requests to prevent 404 errors
  @favicon path /favicon.ico
  handle @favicon {
    respond "" 204
  }
}

# Additional global settings
# Improve performance by adjusting buffer sizes
http_port 80
EOF
fi

# 检查是否已存在该站点配置（避免重复）
if grep -q "@${SITE_NAME} host" "$CADDYFILE"; then
  echo "⚠️  警告: 站点 $DOMAIN 已存在，跳过添加。"
  echo "如需更新，请手动编辑 Caddyfile 或先删除旧配置。"
  exit 0
fi

# 查找:80块的开始和结束位置
START_LINE=$(grep -n "^:80 {" "$CADDYFILE" | cut -d: -f1)
if [[ -z "$START_LINE" ]]; then
  echo "❌ 错误: 无法在 Caddyfile 中找到:80块的开始位置"
  exit 1
fi

# 找到:80块的结束位置（匹配大括号的层级）
BRACE_COUNT=1
INSERT_LINE=$((START_LINE + 1))
while [[ $BRACE_COUNT -gt 0 && $INSERT_LINE -le $(wc -l < "$CADDYFILE") ]]; do
  LINE_CONTENT=$(sed -n "${INSERT_LINE}p" "$CADDYFILE")
  if [[ "$LINE_CONTENT" =~ ^[[:space:]]*\{ ]]; then
    BRACE_COUNT=$((BRACE_COUNT + 1))
  elif [[ "$LINE_CONTENT" =~ ^[[:space:]]*\} ]]; then
    BRACE_COUNT=$((BRACE_COUNT - 1))
  fi
  INSERT_LINE=$((INSERT_LINE + 1))
done

if [[ $BRACE_COUNT -ne 0 ]]; then
  echo "❌ 错误: 无法在 Caddyfile 中找到匹配的:80块结束位置"
  exit 1
fi

# 在:80块的结束大括号之前插入新站点配置
INSERT_LINE=$((INSERT_LINE - 1))

# 创建临时文件来存储新站点配置
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" <<EOF

  # ${DOMAIN} -> 使用${PHP_VERSION}容器
  @${SITE_NAME} host ${DOMAIN}
  handle @${SITE_NAME} {
    root * /app/${SITE_NAME}/public
    
    # Enable compression
    encode zstd br gzip
    
    # Serve static files
    file_server
    
    # Handle PHP files
    try_files {path} {path}/ /index.php?{query}
    
    # PHP FastCGI configuration - 连接到${PHP_VERSION}容器
    php_fastcgi ${PHP_VERSION}:9000 {
      root /app/${SITE_NAME}/public
      env PHP_VALUE "memory_limit=512M"
      env PHP_VALUE "max_execution_time=300"
      env PHP_VALUE "post_max_size=100M"
      env PHP_VALUE "upload_max_filesize=100M"
      resolve_root_symlink
    }
    
    # Security headers
    header {
      # Prevent XSS attacks
      X-Content-Type-Options nosniff
      # Prevent clickjacking
      X-Frame-Options DENY
      # Enable XSS protection
      X-XSS-Protection "1; mode=block"
    }
  }
EOF

# 在:80块内部插入新站点配置
sed -i "" "${INSERT_LINE}r $TEMP_CONFIG" "$CADDYFILE"

# 清理临时文件
rm -f "$TEMP_CONFIG"

echo "✅ 成功添加站点: $DOMAIN"
echo "   - 根目录: $SITE_PATH"
echo "   - 入口: $PUBLIC_PATH/index.php"
echo "   - PHP 容器: $PHP_VERSION"
echo "   - 配置文件: $CADDYFILE"
echo ""

# 重启 FrankenPHP 服务以使配置生效
echo "🔄 正在重启 FrankenPHP 服务以应用新配置..."
if docker-compose restart frankenphp; then
  echo "✅ FrankenPHP 服务重启成功，配置已生效"
else
  echo "⚠️  FrankenPHP 服务重启失败，请手动执行: docker-compose restart frankenphp"
fi

echo ""
echo "ℹ️  提示:"
echo "   - 站点已添加为独立配置"
echo "   - 请确保对应的 PHP 容器已启动: docker-compose up -d $PHP_VERSION"
echo "   - 访问地址: http://$DOMAIN"