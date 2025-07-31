FROM python:3.10-slim

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt ./
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install gunicorn

# Copy application code and scripts
COPY api                 ./api
COPY setup-main-llm.sh   ./
COPY setup-nginx.sh      ./
COPY setup-service.sh    ./
COPY trace_log.sh        ./
COPY run-api.sh          ./
COPY run-gunicorn.sh     ./
COPY reload.sh           ./
COPY git-proc.sh         ./
COPY README.md           ./

# Expose the Flask port
EXPOSE 8000

# Launch the API using Gunicorn
CMD ["gunicorn", "api.index:app", "--bind", "0.0.0.0:8000", "--workers", "2", "--capture-output"]
