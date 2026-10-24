# Track 3 — ggml-org/whisper.cpp (EchoVox Engine Upstream)

**Author:** Abdullah Hanif  
**Status:** Patch series ready · EchoVox audit gate green (smoke) · native build blocked on this VM (missing `libstdc++` dev symlink)

EchoVox runs on whisper.cpp (~98% upstream). Track 3 ships **production fixes** back to [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp) as **three small PRs** (memory, streaming/chunk behavior, anti-hallucination). SIMD stays in **ggml** upstream; EchoVox does not fork SIMD kernels.

## What EchoVox contributes

| PR | Branch (fork) | Upstream theme | EchoVox patch |
|----|---------------|----------------|---------------|
| 1 | `echovox/pr1-stream-chunk-short-audio` | Stream / chunk APIs | Short PCM pad (1.5s), relaxed `delta_min` on final chunk |
| 2 | `echovox/pr2-mel-buffer-reuse` | Core memory arrays | Reuse `mel_pad_buf` in `log_mel_spectrogram` |
| 3 | `echovox/pr3-trigram-kill-switch` | Decoder stability | Trigram repetition → force segment complete |

Patch files (generated against upstream `231638a`):

- [`upstream-whisper/patches/001-stream-chunk-short-audio-and-tail.patch`](../upstream-whisper/patches/001-stream-chunk-short-audio-and-tail.patch)
- [`upstream-whisper/patches/002-mel-buffer-reuse.patch`](../upstream-whisper/patches/002-mel-buffer-reuse.patch)
- [`upstream-whisper/patches/003-trigram-anti-hallucination.patch`](../upstream-whisper/patches/003-trigram-anti-hallucination.patch)

Combined series: [`000-series-all-three.patch`](../upstream-whisper/patches/000-series-all-three.patch)

## Upstream issues to link in PR descriptions

| Fix | Issues / discussions |
|-----|----------------------|
| Short audio empty output | [#1603](https://github.com/ggml-org/whisper.cpp/issues/1603), [#2065](https://github.com/ggml-org/whisper.cpp/issues/2065) |
| Streaming tail drop | [#2065](https://github.com/ggml-org/whisper.cpp/issues/2065), examples/stream |
| Repetition / hallucination loops | [#3744](https://github.com/ggml-org/whisper.cpp/issues/3744), [#1017](https://github.com/ggml-org/whisper.cpp/issues/1017), [#1724](https://github.com/ggml-org/whisper.cpp/issues/1724) |

Read [whisper.cpp/AGENTS.md](../whisper.cpp/AGENTS.md): maintainers expect **human-authored**, narrowly scoped PRs. Use the patch series as the implementation you already run in EchoVox; write the PR body yourself and disclose any AI assist per their policy.

## Verify locally

```bash
bash scripts/upstream/verify-patches.sh
```

## Push to your fork (open 3 PRs to ggml-org/whisper.cpp)

```bash
export UPSTREAM_FORK=git@github.com:YOUR_USER/whisper.cpp.git
bash scripts/upstream/push-to-fork.sh
```

Then on GitHub: three PRs **into `master`**, each one commit, titles matching the patch subjects.

## EchoVox regression proof (already in CI)

These map 1:1 to [`docs/reports/PATCHES.md`](reports/PATCHES.md):

| Assertion | Suite | Patch |
|-----------|-------|-------|
| Zero-drop short utterances | Mythos A2a | PR1 |
| Tail / stream chunk | Deploy + Mythos | PR1 |
| Memory drift ≤ 0.5% | Ultra-Heavy A4a | PR2 |
| Trigram kill at 9 tokens | Ultra-Heavy #6 | PR3 |

Smoke run (this repo):

```bash
MYTHOS_SMOKE=1 ULTRA_SMOKE=1 ADVERSARIAL_SMOKE=1 python3 tests/run_audit_gate.py
```

Native whisper build (install `build-essential` and `libstdc++-dev` on Debian/Ubuntu — required on minimal CI images):

```bash
cmake -S whisper.cpp -B whisper.cpp/build -DCMAKE_BUILD_TYPE=Release
cmake --build whisper.cpp/build -j
```

## SIMD (scope note)

**No EchoVox SIMD patch** in this series. Acceleration lives in `whisper.cpp/ggml` (AVX/NEON/SYCL). Track 3 credit for SIMD = stay on ggml releases + optional future PRs only if you profile a Urdu-specific hotspot. Do not duplicate ggml work in `whisper.cpp/src/whisper.cpp`.

## Fork sync checklist (EchoVox repo)

1. Merge upstream whisper.cpp periodically.
2. Re-run `bash scripts/upstream/verify-patches.sh` — if conflicts, refresh patches from EchoVox `whisper.cpp/src/whisper.cpp` and regenerate with the same 3-commit split.
3. Keep EchoVox-only behavior (Urdu deploy flags, Python audit gate) in repo root — not in upstream PRs.
