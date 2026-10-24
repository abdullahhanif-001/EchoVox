#!/usr/bin/env bash
# Verify EchoVox upstream patch series applies cleanly to ggml-org/whisper.cpp master.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PATCH_DIR="${ROOT}/upstream-whisper/patches"
WORK="${TMPDIR:-/tmp}/echovox-whisper-upstream-verify-$$"
REF="${1:-https://github.com/ggml-org/whisper.cpp.git}"

cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT

echo "Cloning ${REF} into ${WORK} ..."
git clone --depth 1 "${REF}" "${WORK}/whisper.cpp" >/dev/null

cd "${WORK}/whisper.cpp"
for p in \
  "${PATCH_DIR}/001-stream-chunk-short-audio-and-tail.patch" \
  "${PATCH_DIR}/002-mel-buffer-reuse.patch" \
  "${PATCH_DIR}/003-trigram-anti-hallucination.patch"
do
  echo "Applying $(basename "${p}") ..."
  git am "${p}"
done

echo "OK: all three patches applied on $(git rev-parse --short HEAD)"
