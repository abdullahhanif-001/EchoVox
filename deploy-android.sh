#!/bin/bash
# One-click Android STT deploy using sherpa-onnx (51x faster than whisper.cpp)
# Requirements: Python 3.8+, pip, git, Android SDK+NDK, Java 17
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Step 1: Clone sherpa-onnx ==="
if [[ ! -d "$SCRIPT_DIR/sherpa-onnx" ]]; then
  git clone https://github.com/k2-fsa/sherpa-onnx "$SCRIPT_DIR/sherpa-onnx"
fi

echo "=== Step 2: Install Python dependencies ==="
python3 -m pip install --only-binary ":all:" torch openai-whisper onnxruntime onnx

echo "=== Step 3: Download fine-tuned Urdu Whisper Small ==="
if [[ ! -d "$SCRIPT_DIR/whisper-small-urdu" ]]; then
  git clone https://huggingface.co/khawajaaliarshad/whisper-small-urdu "$SCRIPT_DIR/whisper-small-urdu"
fi

echo "=== Step 4: Export to ONNX ==="
cd "$SCRIPT_DIR/sherpa-onnx"
python3 scripts/whisper/export-onnx.py \
  --model "$SCRIPT_DIR/whisper-small-urdu" \
  --output-dir "$SCRIPT_DIR/onnx-urdu"

echo "=== Step 5: Quantize to INT8 ==="
python3 -c "
import onnxruntime as ort
from onnxruntime.quantization import quantize_dynamic, QuantType
import os, glob

out = '$SCRIPT_DIR/onnx-urdu'
for f in glob.glob(os.path.join(out, '*.onnx')):
    base = os.path.splitext(f)[0]
    quantize_dynamic(f, base + '-int8.onnx', weight_type=QuantType.QInt8)
    print(f'Quantized: {f} -> {base}-int8.onnx')
"

echo "=== Step 6: Copy to Android assets ==="
ASSETS="$SCRIPT_DIR/sherpa-onnx/android/SherpaOnnx/app/src/main/assets"
mkdir -p "$ASSETS"
cp "$SCRIPT_DIR/onnx-urdu"/*-encoder*int8.onnx "$ASSETS/encoder.int8.onnx"
cp "$SCRIPT_DIR/onnx-urdu"/*-decoder*int8.onnx "$ASSETS/decoder.int8.onnx"
cp "$SCRIPT_DIR/onnx-urdu"/tokens.txt "$ASSETS/tokens.txt"

echo "=== Step 7: Build APK ==="
cd "$SCRIPT_DIR/sherpa-onnx/android/SherpaOnnx"
if command -v ./gradlew &> /dev/null; then
  ./gradlew assembleDebug
  echo ""
  echo "=== APK built successfully ==="
  echo "Location: app/build/outputs/apk/debug/app-debug.apk"
else
  echo ""
  echo "=== Models exported and placed in assets ==="
  echo "Open $SCRIPT_DIR/sherpa-onnx/android/SherpaOnnx in Android Studio"
  echo "Then Build -> Make Project to generate the APK"
fi

echo ""
echo "=== Android Config (use in Kotlin) ==="
cat << 'KOTLIN'
val config = OfflineRecognizerConfig(
    modelConfig = OfflineModelConfig(
        whisper = OfflineWhisperModelConfig(
            encoder = "encoder.int8.onnx",
            decoder = "decoder.int8.onnx",
            language = "ur",
            task = "transcribe"
        ),
        numThreads = 2,
        provider = "cpu",
    ),
    decodingMethod = "greedy_search",
)
KOTLIN
