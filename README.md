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

Create a repository on Docker Hub (e.g. myoungkyu/main-llm-v2).

Log in locally:
docker login --username myoungkyu

sudo usermod -aG docker $USER

# This re‐evaluates your groups without logging out
exec newgrp docker

# Tag the image for Docker Hub:
docker tag main_llm_v2 myoungkyu/main-llm-v2:latest

# Push the image (ubuntu on gcloud):
docker push myoungkyu/main-llm-v2:latest

# Pull or deploy from anywhere:
docker pull myoungkyu/main-llm-v2:latest


Docker Hub’s free tier allows public repositories; private repos require a paid plan.

You run on local (mac):

```bash
docker pull myoungkyu/main-llm-v2:latest
```

Docker doesn’t write a tarball into your current directory—instead it stores the layers and metadata inside its own storage area.

---

## Where pulled images live

* **On Linux (Docker Engine):**
  By default all images, containers, volumes and build cache live under

  ```
  /var/lib/docker
  ```

  Inside there you’ll find subdirectories for each storage driver (e.g. `overlay2`) that hold the unpacked layers and metadata.

* **On macOS (Docker Desktop):**
  Docker Desktop runs a lightweight Linux VM under the hood. All images live inside that VM’s filesystem (in its internal `/var/lib/docker`), not directly on your macOS host filesystem.

* **On Windows (Docker Desktop):**
  Same story: images reside in the VM’s virtual disk.

---

# HOW TO WORK WITH MAIN_LLM_V2 DOCKER IMAGE

A containerized UniXcoder-based intelligent code API, deployable via Docker. This version is portable and can be run anywhere Docker is available.

## Overview

- REST API for masked intelligent code
- Based on Flask + Gunicorn + HuggingFace Transformers
- CPU-only version (optimized for lightweight deployment)
- Dockerized for platform-independent usage

## Quick Start with Docker

### 1. Clone the repository

```bash
git clone https://github.com/unose/main_llm_v2.git
cd main_llm_v2
````

### 2. Install Docker (Ubuntu example)

```bash
sudo apt update
sudo apt install -y docker.io
```

### 3. Enable Docker for your user

```bash
sudo usermod -aG docker $USER
exec newgrp docker
```

### 4. Pull the Docker image

```bash
docker pull myoungkyu/main-llm-v2:latest
```

### 5. Run the container

```bash
docker run --rm -p 8000:8000 myoungkyu/main-llm-v2:latest
```

The API will now be accessible at `http://localhost:8000`.

## Test the API

In a separate terminal, run the following:

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

You should receive output similar to:

```json
{"completions":["toJson","fromJson","serialize","write",""]}
```

## Image Information

* Docker Hub: [myoungkyu/main-llm-v2](https://hub.docker.com/r/myoungkyu/main-llm-v2)
* Exposed port: `8000`
* Entry point: `gunicorn api.index:app`

