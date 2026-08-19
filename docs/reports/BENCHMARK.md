# STT Market Benchmark Report

**Author:** Abdullah Hanif  
**Last Updated:** 2026-08-20

## Summary

EchoVox is benchmarked against published CPU Real-Time Factor (RTF) baselines for major offline STT engines.

| Engine | Reference RTF (CPU) | EchoVox Result | Status |
|--------|--------------------:|---------------:|--------|
| whisper.cpp Q4_0 | <= 0.80 | See artifact | Target |
| faster-whisper | <= 0.50 | See artifact | Stretch |
| sherpa-onnx INT8 | <= 0.15 | See artifact | Mobile path |

## Methodology

```bash
python tests/benchmark_stt_market.py
```

- 100 inference runs after 50 warmup steps
- 3-second synthetic Urdu audio segment
- Metrics: RTF, latency P50/P95, peak RSS

## Artifacts

- [`artifacts/benchmark_stt_market.json`](artifacts/benchmark_stt_market.json) -- machine-readable results

## Reproducibility

Full audit gate (all suites):

```bash
python tests/run_audit_gate.py
```

Smoke mode (CI):

```bash
MYTHOS_SMOKE=1 ULTRA_SMOKE=1 ADVERSARIAL_SMOKE=1 python tests/run_audit_gate.py
```
