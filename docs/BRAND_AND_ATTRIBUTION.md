# EchoVox — Brand & Attribution

**Author:** Abdullah Hanif  
**Product brand:** EchoVox  
**Upstream engine:** [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT)

---

## Honest Positioning (Read This First)

### EchoVox is our brand. whisper.cpp is the engine we hardened.

| Statement | True / False |
|-----------|--------------|
| EchoVox is a **personal/product brand** for Urdu/Punjabi field STT | **True** |
| We built speech recognition **from scratch** | **False** |
| More than **70%** of this repository is whisper.cpp upstream code | **True (~98% by files, ~99% by source lines)** |
| We **patched** whisper.cpp to fix real production failures | **True** (5 targeted patches) |
| We **recreated** a full audit/test gate and passed it on 3-OS CI | **True** (21 hard assertions) |

**One line for interviews and README:**

> EchoVox is not a from-scratch STT engine. It is Abdullah Hanif’s production distribution of whisper.cpp — fixed with five inference patches, Urdu deploy tooling, and a recreated 21-assertion verification gate that generic Whisper deployments do not ship.

---

## Codebase Split (Measured)

| Layer | Files (git tracked) | Source lines (approx.) | Role |
|-------|--------------------:|-----------------------:|------|
| `whisper.cpp/` upstream | ~2,055 (~98%) | ~534K (~99%) | GGML inference, models tooling, examples |
| EchoVox original (root) | ~43 (~2%) | ~6K (~1%) | Patches, tests, deploy, docs, CI |

**EchoVox-original work includes (not exhaustive):**

- 5 production patches in `whisper.cpp/src/whisper.cpp` (documented in [`PATCHES.md`](reports/PATCHES.md))
- `tests/` — Mythos, Ultra-Heavy, Sherlock adversarial, market benchmark, audit gate
- `deploy-vps.sh`, `deploy-android.sh`, `install.sh`, `install.ps1`, `docker-compose.yml`
- `docs/` engineering reports, `INTERVIEW.md`, CI workflows
- Repo hygiene: LICENSE, SECURITY.md, CONTRIBUTING.md, CODEOWNERS, CHANGELOG

We **do not** claim ownership of the Whisper model architecture, GGML, or the bulk of whisper.cpp. We claim ownership of **field fixes, verification, and deployment** for Urdu/Punjabi production use.

---

## When to Say “EchoVox” vs “whisper.cpp”

| Context | Say | Do not say |
|---------|-----|------------|
| Product / GitHub repo / deploy | **EchoVox** | “Our proprietary STT model” |
| Technical engine credit | **whisper.cpp** (ggml-org) | Hide upstream dependency |
| Paper / audit / interview | “EchoVox — patched whisper.cpp distribution” | “Built from scratch” |
| npm/docker image name | `echovox` | `whisper` alone (trademark confusion) |
| License footer | MIT + whisper.cpp MIT | Proprietary all-rights-reserved |

---

## What We Actually Built (Our ~2% — High Impact)

### 1. Production patches (C++)

Not a rewrite — **surgical fixes** to the inference loop:

1. Short audio auto-pad — zero empty returns on “ہاں” / “نہیں”
2. Tail truncation fix — last words kept in streaming
3. Mel buffer pre-allocation — no RAM spikes on 1 GB VPS
4. Trigram kill switch — stop hallucination loops
5. State buffer pre-allocation — 50K-step stability

See [`docs/reports/PATCHES.md`](reports/PATCHES.md) for line references.

### 2. Recreated verification gate (Python)

Generic whisper.cpp has upstream tests; **EchoVox adds a production gate** we wrote and enforce in CI:

| Suite | Assertions | Purpose |
|-------|------------|---------|
| Mythos ASR | 7/7 | Urdu acoustic matrix + 10K soak |
| Ultra-Heavy | 7/7 | 50K infra + patch behavior |
| Sherlock Adversarial | 7/7 | Fake-200, blind audio, script safety |
| STT Benchmark | PASS | RTF vs market baselines |

Command: `python tests/run_audit_gate.py`  
CI: Ubuntu + macOS + Windows — all must pass.

We **recreated** these tests to encode field requirements; passing them is our quality bar, not upstream’s default bar.

### 3. Deploy & ops (Bash / PowerShell / Docker)

One-command paths for Pakistan/UK field deployment on low-RAM Linux VPS — not part of stock whisper.cpp.

---

## Why Personal Brand Still Makes Sense

Even at >70% upstream code, **EchoVox** is the right product name because buyers and interviewers care about:

- Urdu/Punjabi **field readiness** (not generic multilingual demo)
- **Proven** stability numbers (RSS drift, FD drift, WER under GSM noise)
- **One-command** VPS/Android/Docker deploy
- **Adversarial CI** that catches regressions

That bundle is **EchoVox**. The engine inside remains whisper.cpp — credited and MIT-licensed.

---

## Attribution (Required)

```
Speech inference engine: whisper.cpp
Copyright (c) Georgi Gerganov and contributors — MIT License
https://github.com/ggml-org/whisper.cpp

EchoVox patches, audits, deploy tooling:
Copyright (c) Abdullah Hanif — MIT License
```

Whisper® and OpenAI® are trademarks of their respective owners. EchoVox is an independent project and is not affiliated with OpenAI or ggml-org.

---

## FAQ (Interview / Investor)

**Q: Did you build your own STT model?**  
A: No. We use open Whisper weights via GGML and whisper.cpp. Our work is production hardening and verification.

**Q: Why not fork and rename whisper.cpp completely?**  
A: Honesty and maintainability. We track upstream, apply minimal patches, and brand the **distribution + ops + audits** as EchoVox.

**Q: What if someone asks “is this just whisper.cpp?”**  
A: “The core inference is whisper.cpp. EchoVox is the Urdu/Punjabi production layer — patches, 21-assertion audit gate, VPS deploy, and measured field stability that stock whisper.cpp does not guarantee out of the box.”

**Q: Can we remove the whisper name from marketing?**  
A: Use **EchoVox** as the product name publicly. Always disclose whisper.cpp in docs, LICENSE, and technical interviews — never imply from-scratch STT.

---

*See also: [`INTERVIEW.md`](INTERVIEW.md) · [`PATCHES.md`](reports/PATCHES.md) · [`AUDIT_REPORT.md`](reports/AUDIT_REPORT.md)*
