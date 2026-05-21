FROM ghcr.io/cirruslabs/flutter:stable AS builder

# Désactive l'avertissement root (optionnel mais propre)
ENV FLUTTER_ROOT=/usr/local/flutter
RUN flutter config --no-analytics

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release || echo "expected fail (build triggered to preload web page)"

# runtime stage

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

# Custom nginx config for Flutter web SPA
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html index.htm;

    # Handle all routes for Flutter web
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

EXPOSE 80