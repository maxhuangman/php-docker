<?php
declare(strict_types=1);

$host = $_SERVER['HTTP_HOST'] ?? 'unknown';
$version = phpversion();
$time = date('Y-m-d H:i:s T');
$documentRoot = $_SERVER['DOCUMENT_ROOT'] ?? '未设置';

echo <<<HTML
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to $host</title>
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
    <h1>🎉 欢迎访问 <code>$host</code></h1>
    <div class="info">
      <p><strong>PHP 版本:</strong> <code>$version</code></p>
      <p><strong>服务器时间:</strong> <code>$time</code></p>
      <p><strong>文档根目录:</strong> <code></code></p>
    </div>
    <p>这是由 FrankenPHP 驱动的站点。请将你的应用入口文件放在 <code>public/</code> 目录下。</p>
  </div>
</body>
</html>
HTML;
