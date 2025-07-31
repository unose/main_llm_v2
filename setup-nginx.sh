#!/usr/bin/env bash
set -euo pipefail

# Must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "Error: this script must be run with sudo or as root."
  exit 1
fi

# Server name or IP (first argument), default to this host's IP
SERVER_NAME=${1:-34.46.189.183}

# Install nginx if not already installed
if ! command -v nginx &> /dev/null; then
  apt update
  apt install -y nginx
fi

# Ensure nginx site directories exist
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

# Write the nginx reverse-proxy config
NGINX_CONF=/etc/nginx/sites-available/llm_api
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Enable the site
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/llm_api

# Test and reload nginx
nginx -t
systemctl restart nginx

# Enable and start the llm_api service
systemctl enable llm_api
systemctl start llm_api

echo "Nginx configured and llm_api service started. Proxy listening on port 80."
