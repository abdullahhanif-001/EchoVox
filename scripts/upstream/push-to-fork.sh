#!/usr/bin/env bash
# Apply EchoVox upstream patches on a fork and push three PR branches.
# Usage: UPSTREAM_FORK=git@github.com:YOU/whisper.cpp.git ./scripts/upstream/push-to-fork.sh
set -euo pipefail

if [[ -z "${UPSTREAM_FORK:-}" ]]; then
  echo "Set UPSTREAM_FORK to your ggml-org/whisper.cpp fork URL." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PATCH_DIR="${ROOT}/upstream-whisper/patches"
WORK="${TMPDIR:-/tmp}/echovox-whisper-fork-$$"

cleanup() { rm -rf "${WORK}"; }
trap cleanup EXIT

git clone "${UPSTREAM_FORK}" "${WORK}/whisper.cpp"
cd "${WORK}/whisper.cpp"
git remote add upstream https://github.com/ggml-org/whisper.cpp.git
git fetch upstream master
git checkout -B echovox/upstream-base upstream/master

git am "${PATCH_DIR}/001-stream-chunk-short-audio-and-tail.patch"
git push -f origin HEAD:echovox/pr1-stream-chunk-short-audio

git am "${PATCH_DIR}/002-mel-buffer-reuse.patch"
git push -f origin HEAD:echovox/pr2-mel-buffer-reuse

git am "${PATCH_DIR}/003-trigram-anti-hallucination.patch"
git push -f origin HEAD:echovox/pr3-trigram-kill-switch

echo "Pushed three branches to ${UPSTREAM_FORK}"
echo "Open PRs against ggml-org/whisper.cpp master (see docs/TRACK3_WHISPER_UPSTREAM.md)."
