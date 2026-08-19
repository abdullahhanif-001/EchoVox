# EchoVox

[![CI](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/ci.yml/badge.svg)](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/ci.yml)

Production-grade Speech-to-Text engine optimized for **Urdu**, **Punjabi (Shahmukhi)**, and **Urdu-English code-switching**. Built on whisper.cpp with critical patches for real-world field deployment in Pakistan and the UK.

**Author:** Abdullah Hanif

## One-Command Install

**macOS / Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/abdullahanifpro111-spec/EchoVox/main/install.sh | bash
```

**Windows (PowerShell as Admin):**
```powershell
irm https://raw.githubusercontent.com/abdullahanifpro111-spec/EchoVox/main/install.ps1 | iex
```

This installs all dependencies, builds the engine, and downloads the model automatically.

## Engineering Reports

| Document | Description |
|----------|-------------|
| [Audit Report](docs/reports/AUDIT_REPORT.md) | Executive summary with assertion matrix and measured values |
| [Engineering Test Plan](docs/ENGINEERING_TEST_PLAN.md) | Complete test strategy covering all deployment dimensions |
| [Patch Documentation](docs/reports/PATCHES.md) | whisper.cpp production patches with file references |

## Features

- **Short Utterance Detection** -- Handles sub-second responses (common Urdu affirmatives/negatives) with zero empty returns
- **Anti-Hallucination** -- Trigram repetition kill switch stops infinite loops and ghost phrases
- **Zero Memory Leak** -- Pre-allocated buffers prevent RAM spikes during continuous streaming
- **Tail Truncation Fix** -- Final words are never dropped at end of stream
- **Shahmukhi Script Guard** -- Guarantees Arabic/Shahmukhi script output, blocks Gurmukhi leakage
- **NFC Unicode Normalization** -- All output is properly normalized
- **8kHz GSM Resilience** -- Tested under 2G/3G phone call quality degradation
- **Code-Switching** -- Handles mixed Urdu-English sentences naturally

## Audit Results

All 7 assertions passed across 70 acoustic tests + 10,000-step soak:

| Assertion | Result |
|-----------|--------|
| Gurmukhi Guard (zero U+0A00..U+0A7F) | PASS |
| NFC Unicode Normalization | PASS |
| Zero-Drop Rate (short audio) | PASS |
| WER Noise Degradation <= 12% | PASS |
| Latency CV < 2.5% (10K inferences) | PASS |
| Memory Drift <= 0.5% | PASS |
| FD/Handle Drift == 0 | PASS |

See [docs/reports/AUDIT_REPORT.md](docs/reports/AUDIT_REPORT.md) for full telemetry and reproducibility commands.

## Quick Start

```bash
cd ~/EchoVox
./whisper.cpp/build/bin/whisper-cli -m models/ggml-small.bin -l ur -f audio.wav
```

## Deployment

**VPS (1 Core, 512MB RAM):**
```bash
bash deploy-vps.sh
```

**Android (sherpa-onnx):**
```bash
bash deploy-android.sh
```

**Docker:**
```bash
docker-compose up -d
```

## Project Structure

```
EchoVox/
  whisper.cpp/         # Patched whisper.cpp with Urdu/Punjabi fixes
  tests/               # Acoustic and performance audit suite
  docs/                # Engineering reports and test plan
  deploy-vps.sh        # One-click VPS deployment
  deploy-android.sh    # One-click Android deployment
  docker-compose.yml   # Docker deployment
  install.sh           # macOS/Linux installer
  install.ps1          # Windows installer
```

## License

whisper.cpp is MIT licensed. See `whisper.cpp/LICENSE` for details.
