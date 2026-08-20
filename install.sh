#!/usr/bin/env bash
set -euo pipefail

# EchoVox Installer -- macOS & Linux
# Usage: curl -sSL https://raw.githubusercontent.com/abdullahhanif-001/EchoVox/main/install.sh | bash

ECHOVOX_DIR="${ECHOVOX_DIR:-$HOME/EchoVox}"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
MODEL_NAME="ggml-small.bin"
CURL_TLS=(curl -fsSL --proto '=https' --tlsv1.2)

info()  { printf "\033[1;34m[EchoVox]\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m[EchoVox]\033[0m %s\n" "$1"; }
err()   { printf "\033[1;31m[EchoVox]\033[0m %s\n" "$1" >&2; exit 1; }

OS="$(uname -s)"
ARCH="$(uname -m)"
info "Detected: $OS $ARCH"

# --- Install dependencies ---
install_deps() {
    if [[ "$OS" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            info "Installing Homebrew..."
            /bin/bash -c "$("${CURL_TLS[@]}" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        command -v cmake &>/dev/null || brew install cmake
        command -v git   &>/dev/null || brew install git
    elif [[ "$OS" == "Linux" ]]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq build-essential cmake git wget
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y gcc g++ cmake git wget
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm base-devel cmake git wget
        else
            err "Unsupported Linux distro. Install cmake, git, and a C++ compiler manually."
        fi
    else
        err "Unsupported OS: $OS"
    fi
}

info "Checking dependencies..."
install_deps

# --- Clone / update ---
if [[ -d "$ECHOVOX_DIR" ]]; then
    info "Updating existing installation at $ECHOVOX_DIR..."
    cd "$ECHOVOX_DIR"
    git pull --ff-only 2>/dev/null || true
else
    info "Cloning EchoVox..."
    git clone https://github.com/abdullahhanif-001/EchoVox.git "$ECHOVOX_DIR"
    cd "$ECHOVOX_DIR"
fi

# --- Build whisper.cpp ---
info "Building whisper.cpp..."
cd whisper.cpp
mkdir -p build && cd build

CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DWHISPER_NO_ACCELERATE=OFF"

if [[ "$OS" == "Darwin" ]]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DWHISPER_COREML=OFF -DWHISPER_METAL=ON"
fi

if [[ "$ARCH" == "x86_64" ]]; then
    CMAKE_FLAGS="$CMAKE_FLAGS -DCMAKE_CXX_FLAGS=-march=native"
fi

cmake $CMAKE_FLAGS ..
cmake --build . --config Release -j "$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"

ok "Build complete."

# --- Download model ---
cd "$ECHOVOX_DIR"
if [[ ! -f "models/$MODEL_NAME" ]]; then
    info "Downloading Whisper small model (~466MB)..."
    mkdir -p models
    "${CURL_TLS[@]}" -o "models/$MODEL_NAME" "$MODEL_URL"
    ok "Model downloaded."
else
    ok "Model already exists."
fi

# --- Verify ---
info "Running quick verification..."
WHISPER_BIN="whisper.cpp/build/bin/whisper-cli"
if [[ -f "$WHISPER_BIN" ]]; then
    ok "whisper-cli binary found at $WHISPER_BIN"
else
    WHISPER_BIN="whisper.cpp/build/whisper-cli"
    if [[ -f "$WHISPER_BIN" ]]; then
        ok "whisper-cli binary found at $WHISPER_BIN"
    else
        info "Binary location may vary. Check whisper.cpp/build/ for the executable."
    fi
fi

echo ""
ok "============================================"
ok "  EchoVox installed at: $ECHOVOX_DIR"
ok "  Model: models/$MODEL_NAME"
ok "============================================"
echo ""
info "Quick start:"
echo "  cd $ECHOVOX_DIR"
echo "  ./whisper.cpp/build/bin/whisper-cli -m models/$MODEL_NAME -l ur -f your_audio.wav"
