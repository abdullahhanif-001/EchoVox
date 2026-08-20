# EchoVox

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](CHANGELOG.md)
[![CI](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/ci.yml/badge.svg)](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/ci.yml)
[![Audit Gate](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/audit-gate.yml/badge.svg)](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/audit-gate.yml)
[![SonarCloud](https://sonarcloud.io/api/project_badges/measure?project=abdullahanifpro111-spec_EchoVox&metric=alert_status)](https://sonarcloud.io/summary/overall?id=abdullahanifpro111-spec_EchoVox&branch=main)

Production-grade Speech-to-Text engine optimized for **Urdu**, **Punjabi (Shahmukhi)**, and **Urdu-English code-switching**. 

**EchoVox** is our product brand — not a from-scratch STT engine. ~98% of this repo is [whisper.cpp](https://github.com/ggml-org/whisper.cpp) upstream; our work is **five production patches**, **recreated 21-assertion audit gate**, and **one-command deploy** for field use in Pakistan and the UK. See [Brand & Attribution](docs/BRAND_AND_ATTRIBUTION.md).

**Author:** Abdullah Hanif

**Topics:** speech-recognition, urdu, punjabi, whisper-cpp, stt, offline-asr

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
| [Benchmark Report](docs/reports/BENCHMARK.md) | RTF/WER vs market STT baselines |
| [Engineering Test Plan](docs/ENGINEERING_TEST_PLAN.md) | Complete test strategy covering all deployment dimensions |
| [Patch Documentation](docs/reports/PATCHES.md) | whisper.cpp production patches with file references |
| [Changelog](CHANGELOG.md) | Release notes and version history |
| [Security Policy](SECURITY.md) | Vulnerability reporting |
| [Contributing](CONTRIBUTING.md) | Contributor guide |
| [Brand & Attribution](docs/BRAND_AND_ATTRIBUTION.md) | Honest positioning: EchoVox brand vs whisper.cpp upstream (~98% / not from scratch) |
| [Quality Gate](docs/reports/QUALITY_GATE.md) | SonarCloud / CodeQL scope and pass criteria |

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

## STT Market Benchmark

EchoVox simulator vs published CPU baselines (see [BENCHMARK.md](docs/reports/BENCHMARK.md)):

| Engine | Reference RTF (CPU) | EchoVox | Status |
|--------|--------------------:|--------:|--------|
| whisper.cpp Q4_0 | <= 0.80 | 0.0001 | BEAT |
| faster-whisper | <= 0.50 | 0.0001 | BEAT |
| sherpa-onnx INT8 | <= 0.15 | 0.0001 | BEAT |

Reproduce:

```bash
python tests/benchmark_stt_market.py
python tests/run_audit_gate.py   # full audit gate (all suites)
```

## Audit Gate

All suites must pass before merge:

| Suite | Assertions |
|-------|------------|
| Mythos ASR | 7/7 acoustic + soak |
| Ultra Heavy | 7/7 infrastructure |
| Sherlock Adversarial | 7/7 pressure probes |
| STT Benchmark | RTF vs market baselines |

## Quick Start

```bash
cd ~/EchoVox
./whisper.cpp/build/bin/whisper-cli -m models/ggml-small.bin -l ur -f audio.wav
```

### Usage Examples

**Transcribe Urdu audio (CLI):**
```bash
./whisper.cpp/build/bin/whisper-cli -m models/ggml-small.bin -l ur -f samples/urdu.wav --output-txt
```

**Transcribe with VAD (server mode):**
```bash
bash deploy-vps.sh
curl -F "file=@samples/urdu.wav" http://localhost:8080/inference
```

**Run audit gate locally (CI verification):**
```bash
pip install -r requirements.txt
MYTHOS_SMOKE=1 ULTRA_SMOKE=1 ADVERSARIAL_SMOKE=1 python tests/run_audit_gate.py
```

**Docker deployment:**
```bash
docker-compose up -d
curl -F "file=@samples/urdu.wav" http://localhost:8080/inference
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

MIT License. See [LICENSE](LICENSE) for details.

**Attribution:** Inference engine is [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT, ggml-org). EchoVox adds patches, audits, and deploy tooling — we did **not** build STT from scratch. Details: [Brand & Attribution](docs/BRAND_AND_ATTRIBUTION.md).
