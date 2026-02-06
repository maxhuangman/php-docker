FROM rabbitmq:3.13-management

# 下载并安装延迟消息插件
RUN apt-get update && \
    apt-get install -y wget && \
    wget -O /opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-3.13.0.ez \
    https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v3.13.0/rabbitmq_delayed_message_exchange-3.13.0.ez && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 启用延迟消息插件
RUN rabbitmq-plugins enable --offline rabbitmq_delayed_message_exchange

# 复制插件配置文件
COPY enabled_plugins /etc/rabbitmq/enabled_plugins

# 设置权限
RUN chown rabbitmq:rabbitmq /etc/rabbitmq/enabled_plugins
