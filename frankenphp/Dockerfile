# 基于 FrankenPHP 的自定义镜像
FROM dunglas/frankenphp:latest

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    vim \
    nano \
    build-essential \
    autoconf \
    pkg-config \
    libpq-dev \
    libsqlite3-dev \
    libmariadb-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libgd-dev \
    libmcrypt-dev \
    libreadline-dev \
    libsodium-dev \
    libicu-dev \
    libmemcached-dev \
    libmagickwand-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展（简化列表，只保留最常用的扩展）
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install \
    bcmath \
    calendar \
    ctype \
    curl \
    dom \
    exif \
    fileinfo \
    filter \
    ftp \
    gd \
    hash \
    iconv \
    intl \
    json \
    libxml \
    mbstring \
    mysqli \
    opcache \
    openssl \
    pcntl \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    phar \
    posix \
    readline \
    reflection \
    session \
    shmop \
    simplexml \
    soap \
    sockets \
    spl \
    standard \
    tokenizer \
    xml \
    xmlreader \
    xmlwriter \
    xsl \
    zip \
    zlib \
    || true

# 安装 PECL 扩展
RUN pecl install \
    redis \
    memcached \
    imagick \
    xdebug \
    && docker-php-ext-enable \
    redis \
    memcached \
    imagick \
    xdebug

# 配置 PHP
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini \
    && echo "date.timezone = Asia/Shanghai" >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini

# 配置 Xdebug（开发环境）
RUN echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# 安装 Composer（使用官方安装脚本）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 设置权限
RUN chown -R www-data:www-data /app

EXPOSE 80 443

CMD ["frankenphp", "run", "--config", "/etc/frankenphp/Caddyfile"] 