## 1. Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker.io
```

This will pull in the Docker engine and CLI.

## 2. Enable and start the Docker service

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Verify it’s running:

```bash
sudo systemctl status docker
```

You should see “active (running)”.

## 3. (Optional) Allow your user to run Docker without sudo

```bash
sudo usermod -aG docker $USER
```

After running that, **log out and back in** (or reboot) so your session picks up the new group.

Verify you can run Docker commands without `sudo`:

```bash
docker version
```

## 4. Build and run your image

Now that Docker is installed, from the `main_llm_v2` directory:

```bash
sudo docker build -t main_llm_v2 .
sudo docker run --rm -p 8000:8000 main_llm_v2
```

In a separate terminal, you can then hit your API:

```bash
curl -X POST http://localhost:8000/api/codecomplete \
  -H "Content-Type: application/json" \
  --data-binary @- <<'EOF'
{
  "function": "public static void writeJson(Object data, String filePath) throws IOException {\n    Gson gson = new GsonBuilder()\n                   .setPrettyPrinting()\n                   .create();\n    try (Writer writer = new FileWriter(filePath)) {\n        gson.<mask0>(data, writer);\n    }\n}",
  "beam_size": 5,
  "max_length": 64,
  "mask_token": "<mask0>"
}
EOF
```
