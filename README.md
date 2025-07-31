# main\_llm\_v1 Setup

This project includes `setup-main-llm.sh`, a bootstrap script that automates deploying the UniXcoder Flask API:

* Clones or updates the repository
* Creates a Python 3 virtual environment and installs dependencies (`requirements.txt`)
* Configures and starts the `llm_api` systemd service (runs Gunicorn)
* Installs and configures Nginx as a reverse proxy on port 80
* Opens HTTP (UFW) on port 80

## Prerequisites

* Ubuntu 22.04 LTS (or similar)
* `sudo` privileges
* `git` installed

## Usage

- Note: make sure 1) this repo is public; 2) gcloud authorization for new instance creation by clicking ssh button.
```bash
git clone https://github.com/unose/main_llm_v1.git
cp main_llm_v1/setup-main-llm.sh ~
chmod +x ~/setup-main-llm.sh
sudo ~/setup-main-llm.sh [SERVER_IP|HOSTNAME]
```

* The optional `SERVER_IP|HOSTNAME` argument sets Nginx's `server_name`.
* If omitted, the script attempts to detect the external IP via GCP metadata or `hostname -I`, then falls back to a wildcard (`_`).

## Post-setup

* Stream service logs:

  ```bash
  sudo journalctl -u llm_api -f
  ```

## Test the API

After setup, verify the endpoint with a sample curl request:
* Access the API at: `http://<SERVER>/api/codecomplete`

```bash
curl -X POST http://<SERVER>/api/codecomplete \
  -H "Content-Type: application/json" \
  --data-binary @- <<'EOF'
{
  "function": "public static void writeJson(Object data, String filePath) throws IOException {
    Gson gson = new GsonBuilder()
                   .setPrettyPrinting()
                   .create();
    try (Writer writer = new FileWriter(filePath)) {
        gson.<mask0>(data, writer);
    }
}",
  "beam_size": 5,
  "max_length": 64,
  "mask_token": "<mask0>"
}
EOF
```

## Re-running the Script

Simply re-run with `sudo` to pull updates, reinstall dependencies, and restart services.
