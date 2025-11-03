# 使用較新的 Alpine 版本
FROM nginx:alpine3.19

# 維護者資訊
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
LABEL org.opencontainers.image.description="井字遊戲 - 靜態網頁應用"
LABEL org.opencontainers.image.licenses="MIT"

# 安裝並更新必要套件
RUN apk update && \
    apk upgrade busybox openssl libxml2 expat libxslt curl && \
    apk add --no-cache libxml2-dev expat-dev libxslt-dev openssl-dev curl-dev && \
    apk del perl perl-module-runtime && \
    # 創建非 root 使用者
    addgroup -S appgroup && \
    adduser -S -G appgroup appuser

# 移除預設的 Nginx 網頁
RUN rm -rf /usr/share/nginx/html/*

# 複製靜態檔案到 Nginx 目錄
COPY app/ /usr/share/nginx/html/

# 建立自訂的 Nginx 配置（監聽 8080 端口以支援非 root 用戶）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 修改 Nginx 配置以支援非 root 用戶運行
RUN sed -i 's/listen\s*80;/listen 8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i '/user\s*nginx;/d' /etc/nginx/nginx.conf && \
    sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf && \
    sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf

# 暴露 8080 端口（非特權端口）
EXPOSE 8080

# 啟動 Nginx
CMD ["nginx", "-g", "daemon off;"]

# 加強安全配置
RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    chmod -R 755 /usr/share/nginx/html && \
    chmod 644 /usr/lib/libexpat.so* && \
    chmod 644 /usr/lib/libxslt.so* && \
    chmod 644 /usr/lib/libssl.so* && \
    chmod 644 /usr/lib/libcurl.so* && \
    chmod 755 /bin/busybox && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appgroup /var/run/nginx.pid && \
    rm -rf /var/cache/apk/* /tmp/*

# 切換到非 root 使用者
USER appuser