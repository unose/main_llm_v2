#!/usr/bin/env bash
set -euo pipefail

# This script must be run with sudo
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo)"
  exit 1
fi

SERVICE_PATH=/etc/systemd/system/llm_api.service

# 1. Write (or overwrite) the systemd unit file
cat > "$SERVICE_PATH" <<'EOF'
[Unit]
Description=UniXcoder Flask API
After=network.target

[Service]
Type=simple
User=myoungkyu
WorkingDirectory=/home/myoungkyu/main_llm_v1
Environment="PATH=/home/myoungkyu/main_llm_v1/venv/bin"
ExecStart=/home/myoungkyu/main_llm_v1/venv/bin/gunicorn \
  api.index:app \
  --bind 0.0.0.0:8000 \
  --workers 2 \
  --capture-output \
  --reload
Restart=always
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 2. Reload systemd, enable and restart the service
systemctl daemon-reload
systemctl enable llm_api
systemctl restart llm_api

# 3. Show status and begin streaming logs
systemctl status llm_api --no-pager
echo "Streaming llm_api logs (Ctrl+C to exit):"
journalctl -u llm_api -f

# 2. Stream the logs
# Tail the journal for the llm_api service in real time:
# 
# sudo journalctl -u llm_api -f
# 
# When the /api/codecomplete endpoint runs, the two
# 
# print("[DBG] completions:")
# print(completions)
# lines will appear in this log stream.

