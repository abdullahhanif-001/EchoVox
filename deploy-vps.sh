#!/bin/bash
# One-click VPS deploy for Urdu/Punjabi STT
# Requirements: Linux x86_64, 1GB+ RAM, cmake, gcc/g++, curl
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHISPER_DIR="$SCRIPT_DIR/whisper.cpp"
MODEL_DIR="$WHISPER_DIR/models"
CURL_TLS=(curl -fsSL --proto '=https' --tlsv1.2)

echo "=== Building whisper.cpp with maximum optimization ==="
cd "$WHISPER_DIR"
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-O3 -march=native -ffast-math -flto -DNDEBUG" \
  -DCMAKE_CXX_FLAGS="-O3 -march=native -ffast-math -flto -DNDEBUG" \
  -DGGML_NATIVE=ON \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=ON
cmake --build build --config Release -j"$(nproc)"

echo "=== Downloading Urdu GGML model (pre-trained, ~1.4GB) ==="
if [[ ! -f "$MODEL_DIR/ggml-medium-urdu.bin" ]]; then
  "${CURL_TLS[@]}" -o "$MODEL_DIR/ggml-medium-urdu.bin" \
    "https://huggingface.co/CodeWithAhsan/whisper-medium-urdu-ggml/resolve/main/ggml-medium-urdu.bin"
fi

echo "=== Downloading Silero VAD model ==="
if [[ ! -f "$MODEL_DIR/silero-v5.1.2-ggml.bin" ]]; then
  cd "$WHISPER_DIR"
  bash models/download-silero-vad-model.sh
fi

echo "=== Quantizing to Q4_0 for 1GB VPS ==="
if [[ ! -f "$MODEL_DIR/ggml-medium-urdu-q4_0.bin" ]]; then
  "$WHISPER_DIR/build/bin/quantize" \
    "$MODEL_DIR/ggml-medium-urdu.bin" \
    "$MODEL_DIR/ggml-medium-urdu-q4_0.bin" \
    q4_0
fi

echo "=== Starting whisper-server with all production fixes ==="
exec "$WHISPER_DIR/build/bin/whisper-server" \
  --host 0.0.0.0 --port 8080 \
  -m "$MODEL_DIR/ggml-medium-urdu-q4_0.bin" \
  -l ur \
  --threads 1 \
  --max-tokens 0 \
  --max-context 0 \
  --no-speech-thold 0.4 \
  --beam-size 5 \
  --best-of 5 \
  --vad \
  --vad-model "$MODEL_DIR/silero-v5.1.2-ggml.bin" \
  --vad-min-speech-duration-ms 200 \
  --vad-min-silence-duration-ms 500 \
  --vad-speech-pad-ms 400 \
  --vad-samples-overlap 0.1
