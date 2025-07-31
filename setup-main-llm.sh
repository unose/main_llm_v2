#!/usr/bin/env bash
set -euo pipefail

#--- 
# The bootstrap script will create (or update) the following files and directories on your system:
# ---
# ### 1. Application Code Directory
# **Path:** `/home/<USERNAME>/main_llm_v1/`
# * Populated by `git clone` (or `git pull`) of the repository.
# * All files tracked in the GitHub repo end up here.

# ### 2. Python Virtual Environment
# **Path:** `/home/<USERNAME>/main_llm_v1/venv/`
# * Created by `python3 -m venv venv`.
# * Contains the isolated Python interpreter, site-packages, pip, etc.

# ### 3. systemd Service Unit
# **Path:** `/etc/systemd/system/llm_api.service`
# * Defines how systemd launches the Gunicorn server.
# * Includes the `ExecStart`, working directory, user, and logging settings.

# ### 4. Nginx Site Configuration
# **Path:** `/etc/nginx/sites-available/llm_api`
# * Contains the `server { … }` block proxying port 80 → `127.0.0.1:8000`.

# ### 5. Nginx Enabled‐Sites Symlink
# **Path:** `/etc/nginx/sites-enabled/llm_api`
# * A symbolic link pointing back to the `sites-available/llm_api` file, activating the site.
#---

# Must run as root
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# If a hostname/IP was passed in, use it; otherwise attempt to fetch from GCP metadata
if [[ -n "${1:-}" ]]; then
  SERVER_NAME="$1"
else
  # Attempt GCP metadata server for external IP
  if command -v curl &> /dev/null; then
    METADATA_URL="http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip"
    EXTERNAL_IP=$(curl -fs -H "Metadata-Flavor: Google" "$METADATA_URL" || true)
  fi

  # Fallback to first non-loopback address
  if [[ -z "$EXTERNAL_IP" ]]; then
    EXTERNAL_IP=$(hostname -I | awk '{print $1}')
  fi

  # If still empty, use wildcard
  SERVER_NAME="${EXTERNAL_IP:-_}"
fi

echo "Configuring Nginx with server_name: $SERVER_NAME"

# ---------- Configuration ----------
# Adjust these if needed before running
USERNAME=${SUDO_USER:-$(whoami)}                 # user who will own the files
HOME_DIR="/home/${USERNAME}"
INSTALL_DIR="${HOME_DIR}/main_llm_v1"
REPO_URL="https://github.com/unose/main_llm_v1.git"
SERVICE_NAME="llm_api"

# ---------- Step 1: Clone or update repo ----------
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "🔄 Updating existing repo in $INSTALL_DIR"
  sudo -u "$USERNAME" git -C "$INSTALL_DIR" pull
else
  echo "📥 Cloning repo into $INSTALL_DIR"
  sudo -u "$USERNAME" git clone "$REPO_URL" "$INSTALL_DIR"
fi

 # ---------- Step 2: Python venv and dependencies ----------
 echo "🐍 Ensuring Python venv support and installing dependencies"

# Install OS packages required for virtual environments and builds
apt update
apt install -y python3-venv python3-pip build-essential

 pushd "$INSTALL_DIR" >/dev/null
 sudo -u "$USERNAME" python3 -m venv venv
 # activate and install as the non-root user
 sudo -u "$USERNAME" bash -c "
   source \"$INSTALL_DIR/venv/bin/activate\" && \
   pip install --upgrade pip && \
   pip install -r requirements.txt
 "
 popd >/dev/null

# ---------- Step 3: systemd service unit ----------
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
echo "⚙️  Writing systemd unit to $SERVICE_PATH"
cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=UniXcoder Flask API
After=network.target

[Service]
Type=simple
User=${USERNAME}
WorkingDirectory=${INSTALL_DIR}
Environment="PATH=${INSTALL_DIR}/venv/bin"
ExecStart=${INSTALL_DIR}/venv/bin/gunicorn \
  api.index:app \
  --bind 0.0.0.0:8000 \
  --workers 2 \
  --capture-output
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd, enabling & starting ${SERVICE_NAME}"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# ---------- Step 4: Nginx reverse proxy ----------
echo "🌐 Installing/configuring Nginx reverse proxy"
if ! command -v nginx &> /dev/null; then
  apt update
  apt install -y nginx
fi

# Write nginx site
NGINX_CONF="/etc/nginx/sites-available/${SERVICE_NAME}"
cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name ${SERVER_NAME};

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/${SERVICE_NAME}
ln -s /etc/nginx/sites-available/${SERVICE_NAME} /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

echo "🔓 Allowing HTTP through the firewall (UFW)"
ufw allow 'Nginx Full'
ufw reload

echo "✅ Setup complete!"
echo " • Service: http://<${SERVER_NAME:-server_ip}>/api/codecomplete"
echo " • To watch logs: sudo journalctl -u ${SERVICE_NAME} -f"

