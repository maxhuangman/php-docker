FROM dunglas/frankenphp:latest

# 安装 pdo_mysql 扩展
RUN install-php-extensions pdo_mysql
