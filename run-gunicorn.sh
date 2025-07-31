pkill gunicorn        # stop any running instance
gunicorn api.index:app \
  --bind 0.0.0.0:8000 \
  --workers 2
