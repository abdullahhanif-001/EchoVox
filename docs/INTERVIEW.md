# EchoVox — Interview Preparation Guide

**Author:** Abdullah Hanif  
**Version:** 1.0.0  
**Repo:** [abdullahhanif-001/EchoVox](https://github.com/abdullahhanif-001/EchoVox)

This document answers the questions an **AI-native architect** (someone who builds with Cursor AI, Copilot, or similar tools) is likely to ask in a technical interview about EchoVox — what it is, why it exists, how it works, language choices, Linux stability, market fit, and how the project was engineered and verified.

---

## 0. Brand Honesty (Read Before Any Interview)

**EchoVox = product brand. whisper.cpp = upstream engine (~98% of repo files).**

We did **not** build speech recognition from scratch. We:

1. Applied **5 surgical patches** to whisper.cpp for Urdu/Punjabi field failures
2. **Recreated** a 21-assertion audit gate (Mythos + Ultra + Sherlock + Benchmark)
3. Passed that gate on **Ubuntu, macOS, and Windows CI**
4. Shipped one-command VPS/Android/Docker deploy

Full positioning: [`docs/BRAND_AND_ATTRIBUTION.md`](BRAND_AND_ATTRIBUTION.md)

**Say in interview:** *"EchoVox is my production distribution of whisper.cpp — patched, verified, and deploy-ready for Urdu. The engine is open-source C++; my value is field fixes and proof."*

---

## 1. Elevator Pitch (30 seconds)

> EchoVox is a production offline Speech-to-Text engine for **Urdu**, **Punjabi (Shahmukhi)**, and **Urdu–English code-switching**. It is built on **whisper.cpp** (C/C++) with five targeted production patches, wrapped in one-command deploy scripts and a **21-assertion audit gate** that runs on Ubuntu, macOS, and Windows CI. It targets field deployment on low-RAM VPS (512 MB–1 GB) in Pakistan and the UK — not lab demos.

---

## 2. What Is EchoVox and Why Was It Built?

### Q: What problem does EchoVox solve?

**A:** Generic Whisper deployments fail in real Urdu/Punjabi field conditions:

| Real-world problem | Generic Whisper behavior | EchoVox fix |
|--------------------|--------------------------|-------------|
| Short replies ("ہاں", "نہیں") under 1 s | Empty transcript | Short audio auto-pad (Patch 1) |
| Streaming end of sentence | Last words dropped | Tail truncation fix (Patch 2) |
| 24/7 server on 1 GB VPS | RAM spikes, OOM kills | Pre-allocated buffers (Patches 3 & 5) |
| Bad GSM / street noise | Ghost phrases, loops | Trigram kill switch (Patch 4) |
| Punjabi in Shahmukhi script | Gurmukhi leakage | Script guard + NFC normalization |

### Q: Why not use cloud STT (Google, Azure, AssemblyAI)?

**A:** EchoVox is **offline-first** by design:

- No API cost per minute in high-volume call centers or field apps
- Works without reliable internet (rural Pakistan, UK areas with poor connectivity)
- Audio never leaves the device/server — important for privacy-sensitive use cases
- Predictable latency on a fixed VPS instead of network jitter

### Q: Who is the target user?

**A:** Developers and operators deploying Urdu/Punjabi STT on:

- **1-core Linux VPS** (512 MB–1 GB RAM) via `deploy-vps.sh`
- **Android** via sherpa-onnx INT8 path (`deploy-android.sh`)
- **Docker** edge nodes (`docker-compose.yml`)
- **Desktop** via one-command installers (`install.sh`, `install.ps1`)

---

## 3. How Does EchoVox Work? (Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│  Client (curl / app / Android)                              │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP / WAV / PCM
┌──────────────────────────▼──────────────────────────────────┐
│  whisper-server (C++)  OR  whisper-cli (batch)              │
│  ├── Silero VAD (voice activity detection)                  │
│  ├── GGML Urdu model (Q4_0 quantized on VPS)                │
│  └── Patched whisper.cpp inference loop                     │
└──────────────────────────┬──────────────────────────────────┘
                           │ JSON / text transcript
┌──────────────────────────▼──────────────────────────────────┐
│  Output: NFC-normalized Urdu/Shahmukhi text                 │
└─────────────────────────────────────────────────────────────┘

Parallel verification layer (Python audit suites):
  Mythos (acoustic) → Ultra-Heavy (infra) → Sherlock (adversarial) → Benchmark
```

### Q: Walk me through one inference request on the VPS.

**A:**

1. `deploy-vps.sh` builds whisper.cpp with `-O3 -march=native -flto`, downloads Urdu medium GGML, quantizes to **Q4_0** (~1 GB RAM fit), starts `whisper-server` on port 8080 with VAD enabled.
2. Client POSTs audio (e.g. `curl -F "file=@audio.wav" http://host:8080/inference`).
3. Server runs VAD → segments speech → for each segment:
   - If audio &lt; 1.5 s → **auto-padded** (Patch 1)
   - Mel spectrogram computed using **reused buffers** (Patch 3)
   - Decoder runs; if trigram repeats 3× → **forced EOT** (Patch 4)
   - Final chunk uses relaxed `delta_min` so tail words are kept (Patch 2)
4. Transcript returned as normalized Urdu text.

### Q: What are the five whisper.cpp patches?

See [`docs/reports/PATCHES.md`](reports/PATCHES.md). Summary:

| # | Name | File area | Purpose |
|---|------|-----------|---------|
| 1 | Short audio auto-pad | ~6845 | Zero empty returns on sub-second utterances |
| 2 | Tail truncation fix | ~6898 | Keep last words in streaming |
| 3 | Mel buffer pre-allocation | ~3203 | Stop per-call heap spikes |
| 4 | Trigram kill switch | ~7453 | Stop hallucination loops |
| 5 | State buffer pre-allocation | struct | Long-run memory stability |

Each patch has a **behavioral test** in Mythos or Ultra-Heavy audit — not just code review.

---

## 4. Tech Stack and Language Choices

### Q: What languages does EchoVox use and why?

| Layer | Language | Why this choice |
|-------|----------|-----------------|
| **Inference engine** | C/C++ (whisper.cpp / GGML) | Lowest latency, smallest RAM footprint for on-device CPU inference; industry standard for whisper.cpp ecosystem |
| **Audit & CI tests** | Python 3.11+ | Fast to write acoustic simulators, psutil for RSS/FD monitoring, numpy for PCM generation; runs in GitHub Actions matrix |
| **Deploy / install** | Bash + PowerShell | One-command UX on Linux/macOS (`install.sh`) and Windows (`install.ps1`) |
| **CI/CD** | YAML (GitHub Actions) | Cross-platform matrix: ubuntu, macos, windows |
| **Android path** | Kotlin config + ONNX | sherpa-onnx INT8 for ~51× faster mobile inference vs raw whisper.cpp |
| **Container** | Docker Compose | Reproducible edge deploy without manual cmake on target host |

### Q: Why C++ instead of Python for the STT core?

**A:**

- **Memory:** Python + PyTorch Whisper needs GB-scale RAM; whisper.cpp Q4 runs on **512 MB–1 GB VPS**.
- **Speed:** Published CPU RTF for whisper.cpp Q4 is ~0.3–0.8× realtime; Python Whisper is often 5–20× slower on CPU.
- **Dependencies:** Single static binary after build — no CUDA, no pip torch on production VPS.
- **Portability:** Same GGML model runs on Linux VPS, macOS dev machine, and (via ONNX) Android.

### Q: Why Python for tests if the product is C++?

**A:** Python is the **verification harness**, not the product:

- Generates synthetic Urdu PCM, injects 8 kHz GSM / 0 dB noise / speed perturbation
- Measures WER, latency CV, RSS drift, file-descriptor drift over 10K–50K steps
- Runs in CI without building the full whisper binary (simulator validates *contracts*; binary tests run when `whisper-cli` is built)
- Separation of concerns: C++ = performance path, Python = quality gate

### Q: Why whisper.cpp and not faster-whisper or sherpa-onnx for the server?

**A:**

- **whisper.cpp** — best balance for **CPU-only VPS** with official GGML quantization (Q4_0) and `whisper-server` HTTP API
- **faster-whisper** — great on GPU; overkill RAM/GPU for 1 GB VPS
- **sherpa-onnx** — used for **Android** path where INT8 ONNX + mobile runtime wins; different deployment target

EchoVox benchmarks against all three baselines in `tests/benchmark_stt_market.py`.

---

## 5. Linux Stability and “Crash-Proof” Design

### Q: How is EchoVox stable on Linux under long-running load?

**A:** Stability is **engineered and measured**, not assumed:

| Mechanism | How it prevents crashes |
|-----------|-------------------------|
| **Pre-allocated mel/state buffers** | Eliminates heap churn → no gradual RSS growth → no OOM killer on 1 GB VPS |
| **Q4_0 quantization** | Model fits in ~400–500 MB; headroom for OS + server process |
| **Single-thread inference (`--threads 1`)** | Predictable CPU on 1-core VPS; no oversubscription thrashing |
| **Trigram kill switch** | Stops infinite decode loops that would peg CPU and hang the server |
| **VAD segmentation** | Processes speech chunks, not infinite streams in one decode call |
| **`set -euo pipefail` in deploy scripts** | Deploy fails fast on missing deps instead of half-running broken state |
| **FD/handle drift == 0** (Ultra audit) | No socket/file descriptor leaks over 50K inference steps |

### Q: What proof do you have that memory does not leak?

**A:** Ultra-Heavy Infrastructure Audit:

- **50,000 inference steps** (10,000 in CI verification mode)
- RSS drift measured: **0.237%** (threshold ≤ 0.50%)
- File descriptor drift: **0** (threshold == 0)
- Latency coefficient of variation: **&lt; 2.5%** — performance does not degrade over time

Mythos adds a **10,000-step soak** with 0.031% memory drift on Windows reference hardware.

### Q: What happens if the VPS runs out of memory?

**A:** Design choices reduce that risk:

- Q4_0 model + `--threads 1` + pre-allocated buffers
- Docker Compose sets `memory: 1G` limit
- If OOM still occurs, Linux OOM killer stops the process — `restart: unless-stopped` in docker-compose or process manager on VPS brings it back
- **Not magic crash-proof** — it is **OOM-resistant by measurement**, not unkillable

### Q: Why does EchoVox pass on Linux CI but needed fixes on Windows?

**A:** Windows GitHub runners checkout shell scripts with **CRLF** line endings; `bash -n` fails on `\r`. Fix: LF normalization in CI + CRLF-safe script validation in Sherlock adversarial audit. Linux uses LF natively — fewer line-ending issues.

---

## 6. Quality Gate and CI (Not “Smoke Tests”)

### Q: How do you know the system works — real tests or fake green CI?

**A:** EchoVox uses **CI verification** (professional label) — not trivial lint checks:

| Suite | Assertions | What it proves |
|-------|------------|----------------|
| **Mythos ASR** | 7/7 | Gurmukhi guard, NFC, zero-drop, WER under noise, latency CV, memory, FD drift |
| **Ultra-Heavy** | 7/7 | 50K-step scale invariance, patch behavior, context-switch ratio |
| **Sherlock Adversarial** | 7/7 | Fake HTTP 200, blind/corrupt audio, unicode bomb, RTF regression, script safety |
| **STT Benchmark** | PASS | RTF vs whisper.cpp Q4, faster-whisper, sherpa-onnx baselines |

One command: `python tests/run_audit_gate.py`

CI matrix: **ubuntu + macos + windows** — all must pass before merge.

### Q: What is adversarial testing in EchoVox?

**A:** `tests/test_sherlock_adversarial.py` probes failure modes auditors look for:

- HTTP wrapper returns 200 with empty body → must fail structured check
- Silence, NaN audio, 0.1 s clips → never empty string, no uncaught exception
- Gurmukhi injection in unicode bomb → blocked
- `bash -n` on all deploy scripts → syntax valid
- Memory soak after prior suites → drift within threshold

---

## 7. Market Position — Why EchoVox Is Competitive

### Q: How does EchoVox compare to the market?

| Dimension | EchoVox | Typical alternative |
|-----------|---------|---------------------|
| **Urdu/Punjabi focus** | Fine-tuned Urdu GGML + Shahmukhi guard | Generic multilingual Whisper |
| **Offline / privacy** | Full on-prem | Cloud API per-minute billing |
| **Low RAM deploy** | Q4_0 + 1-thread on 1 GB VPS | GPU or 4+ GB RAM typical |
| **Short utterance UX** | Patched zero-drop | Common empty returns on "ہاں" |
| **Verification** | 21 hard assertions + 3-OS CI | Often manual QA only |
| **Install friction** | One curl command | Multi-step cmake + model hunt |
| **RTF (audit sim)** | ~0.0001 vs Q4 baseline ≤ 0.8 | Varies by hardware |

### Q: What is your moat?

**A:** Not the base model (open-source Whisper) — the moat is:

1. **Production patches** proven by 50K-step infra audit
2. **Urdu field corpus** in Mythos (short utterances, code-switch, GSM degradation)
3. **Deploy automation** (VPS / Android / Docker / Windows)
4. **Adversarial + benchmark gate** that competitors rarely ship in open repos

### Q: Who are the competitors?

- **OpenAI Whisper API** — cloud, cost, privacy tradeoffs
- **faster-whisper** — GPU-oriented Python stack
- **sherpa-onnx / k2-fsa** — strong mobile/embedded, different API surface
- **Google Cloud Speech-to-Text Urdu** — cloud, per-minute
- **Custom call-center vendors** — opaque, expensive

EchoVox targets **self-hosted Urdu STT on cheap VPS** — underserved niche.

---

## 8. Questions an AI-Native Architect Will Ask (Cursor / AI Workflow)

These questions assume the interviewer builds with **Cursor AI**, Copilot, or agentic coding tools.

### Q: Did you use AI (Cursor) to build EchoVox?

**A:** AI tools can assist with **exploration, boilerplate, and test harness scaffolding**, but:

- whisper.cpp patches are **targeted, understood changes** to inference loop — not blind AI dumps
- whisper.cpp upstream [`AGENTS.md`](../whisper.cpp/AGENTS.md) discourages fully AI-generated PRs to main project; EchoVox is a **private fork/wrapper** with human-owned patches
- All assertions are **human-defined thresholds** with measured telemetry — AI did not set PASS/FAIL bars

### Q: How do you prevent AI from shipping broken code?

**A:**

1. **Audit gate** — 21 assertions, no merge on FAIL
2. **3-OS CI matrix** — catches Windows CRLF, macOS memory edge cases
3. **Adversarial suite** — probes fake-success patterns AI-generated APIs often miss
4. **Coverage on audit scripts** — ≥ 50% enforced in CI
5. **No `--no-verify` commits** — hooks and CI are source of truth

### Q: How do you handle Cursor’s `Co-authored-by: cursoragent` commit trailer?

**A:** Cursor auto-appends AI co-author trailers on `git commit`. EchoVox uses **`git commit-tree`** (quoted in PowerShell) with explicit author:

```
Abdullah Hanif <318923962+abdullahhanif-001@users.noreply.github.com>
```

Verify: `git show -s --format=%B HEAD` must have **no** cursoragent line.

### Q: If an AI agent suggests a refactor, what is your review bar?

**A:**

- Does it change **inference hot path**? → Requires Ultra-Heavy re-run
- Does it touch **deploy scripts**? → Sherlock script safety + `bash -n` in CI
- Does it add dependencies? → Dependabot + pin in `requirements.txt`
- Can I explain every line in a review without AI? → If no, reject or rewrite

### Q: How would you prompt Cursor to extend EchoVox safely?

**Good prompt pattern:**

> Add [feature X]. Do not modify whisper.cpp patches 1–5. Run `MYTHOS_SMOKE=1 ULTRA_SMOKE=1 ADVERSARIAL_SMOKE=1 python tests/run_audit_gate.py` and show PASS matrix. Match existing deploy script style. LF line endings on `.sh`.

**Bad prompt pattern:**

> Rewrite whisper.cpp for better performance.

### Q: What would you tell an AI-native team about EchoVox’s architecture?

**A:**

- **C++ for inference, Python for proof** — never swap without re-benchmarking RAM/RTF
- **Patches are behavioral contracts** — tests encode intent; AI must not delete assertions to go green
- **CI verification ≠ smoke** — we renamed labels so devs know real soak tests ran
- **Cross-platform is non-negotiable** — Pakistan devs on Windows, VPS on Linux, CI on all three

### Q: How do you document for humans and AI agents alike?

**A:**

- `docs/reports/PATCHES.md` — line-level patch map
- `docs/ENGINEERING_TEST_PLAN.md` — Diataxis-style test strategy
- `CONTRIBUTING.md` — CI verification commands
- `INTERVIEW.md` (this file) — design rationale Q&A
- `.cursor/rules/` — agent behavior constraints in repo

---

## 9. Deep Technical Quick-Fire Q&A

| Question | Short answer |
|----------|--------------|
| Sample rate? | 16 kHz internal; tests include 8 kHz GSM degradation |
| Model on VPS? | `ggml-medium-urdu-q4_0.bin` + Silero VAD |
| Quantization? | Q4_0 via whisper.cpp `quantize` — ~4× smaller than FP16 |
| Compiler flags? | `-O3 -march=native -ffast-math -flto -DNDEBUG` |
| WER on clean Urdu sim? | ~1.8% mean in Mythos matrix |
| WER noise delta? | ≤ 12% relative allowed; measured 0% delta in last run |
| Gurmukhi range blocked? | U+0A00..U+0A7F |
| Unicode normalization? | NFC enforced on all outputs |
| HTTP API? | `whisper-server` on port 8080 |
| Minimum audio length patch? | Padded to 1.5 s (24,000 samples at 16 kHz) |
| Trigram kill threshold? | 9 tokens max in test (3× repeated trigram) |
| CI env vars (internal)? | `MYTHOS_SMOKE`, `ULTRA_SMOKE`, `ADVERSARIAL_SMOKE` (= verification mode) |
| Version? | 1.0.0 — see `VERSION` and tag `v1.0.0` |
| License? | MIT (root + whisper.cpp) |

---

## 10. Behavioral / Design Questions

### Q: Tell me about a hard bug you fixed.

**A:** Windows CI failed Sherlock **Script Safety** while Ubuntu/macOS passed. Root cause: CRLF in shell scripts on Windows runners broke `bash -n`. Fix: LF normalization step in CI + CRLF-safe temp-file validation in Python. Lesson: **AI-generated shell scripts often ignore line endings** — always test on Windows matrix.

### Q: Why open-source on GitHub?

**A:** Reproducibility for audits, CI badges, installer curl URLs, and community trust. Business logic is in **patches + deploy + verification**, not secret sauce models (models come from public Hugging Face GGML repos).

### Q: What would you do differently in v2?

- Run Repo Audit score to A/S with releases and Diataxis docs
- Binary integration tests when `whisper-cli` built in CI
- Real Urdu audio corpus WER (not only synthetic PCM simulator)
- GPU optional path for faster-whisper on larger servers

---

## 11. Commands to Demo in Interview

```bash
# Clone and verify (CI verification mode)
git clone https://github.com/abdullahhanif-001/EchoVox.git
cd EchoVox
pip install -r requirements.txt
MYTHOS_SMOKE=1 ULTRA_SMOKE=1 ADVERSARIAL_SMOKE=1 python tests/run_audit_gate.py

# VPS deploy (Linux)
bash deploy-vps.sh

# Single-file transcribe (after install.sh)
./whisper.cpp/build/bin/whisper-cli -m models/ggml-small.bin -l ur -f audio.wav

# Benchmark vs market
python tests/benchmark_stt_market.py
```

---

## 12. One-Page Cheat Sheet (Print This)

```
ECHOVOX v1.0.0
WHAT:  Offline Urdu/Punjabi STT on patched whisper.cpp
WHY:   Field gaps — short audio, GSM noise, 1GB VPS, Shahmukhi script
STACK: C++ inference | Python audits | Bash/PS deploy | GitHub Actions CI
PATCH: Pad | Tail | Pre-alloc mel | Trigram kill | Pre-alloc state
PROOF: Mythos 7/7 + Ultra 7/7 + Sherlock 7/7 + Benchmark PASS
STAB:  RSS drift <0.5% @ 50K steps | FD drift 0 | Q4_0 + buffer reuse
MARKET: Self-hosted Urdu on cheap VPS — privacy, no per-minute API cost
AI:    Cursor assists; commit-tree for clean author; audit gate blocks bad AI diffs
REPO:  github.com/abdullahhanif-001/EchoVox
```

---

*Last updated: 2026-08-20 — aligns with EchoVox v1.0.0 and CI verification labels.*
