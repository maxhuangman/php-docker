## 构建自定义镜像
```bash
docker build -t docker-webman:1.0 .
```
## 使用镜像
### 1. 启动服务
```bash
docker run --rm -it -p 8787:8787 -v ./:/app docker-webman:1.0
```
### 2. 访问服务
```bash
curl http://localhost:8787
```
