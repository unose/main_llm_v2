# curl -X POST https://main-llm-v1.vercel.app/api/codecomplete \
curl -X POST http://127.0.0.1:5000/api/codecomplete \
  -H "Content-Type: application/json" \
  -d '{
    "function": "public static void writeJson(Object data, String filePath) throws IOException {\n    Gson gson = new GsonBuilder()\n                   .setPrettyPrinting()\n                   .create();\n    try (Writer writer = new FileWriter(filePath)) {\n        gson.<mask0>(data, writer);\n    }\n}",
    "beam_size": 5,
    "max_length": 64,
    "mask_token": "<mask0>"
  }'

curl -X POST http://34.46.189.183/api/codecomplete \
  -H "Content-Type: application/json" \
  --data-binary @- <<'EOF'
{
  "function": "public static void writeJson(Object data, String filePath) throws IOException {\n    Gson gson = new GsonBuilder()\n                   .setPrettyPrinting()\n                   .create();\n    try (Writer writer = new FileWriter(filePath)) {\n        gson.<mask0>(data, writer);\n    }\n}",
  "beam_size": 5,
  "max_length": 64,
  "mask_token": "<mask0>"
}
EOF
