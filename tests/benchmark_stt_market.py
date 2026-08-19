#!/usr/bin/env python3
"""
STT Market Benchmark -- EchoVox vs published baselines
=======================================================
Compares EchoVox simulator RTF/latency against market reference values.
"""

import json
import platform
import sys
import time
from pathlib import Path

import numpy as np
import psutil

ROOT = Path(__file__).resolve().parent.parent
TESTS = Path(__file__).resolve().parent
ARTIFACT = ROOT / "docs" / "reports" / "artifacts" / "benchmark_stt_market.json"

sys.path.insert(0, str(TESTS))
from test_stt_mythos_ultimate import UrduASRSimulator, generate_speech_like_pcm  # noqa: E402

# Published CPU baseline RTF ranges (lower = faster)
MARKET_BASELINES = {
    "whisper_cpp_q4": {"rtf_max": 0.80, "label": "whisper.cpp Q4_0 (CPU)"},
    "faster_whisper": {"rtf_max": 0.50, "label": "faster-whisper (CPU)"},
    "sherpa_onnx_int8": {"rtf_max": 0.15, "label": "sherpa-onnx INT8 (CPU)"},
}

# EchoVox simulator target: beat whisper.cpp Q4 on same hardware class
ECHOOVOX_TARGET = MARKET_BASELINES["whisper_cpp_q4"]["rtf_max"]
WARMUP = 50
BENCH_RUNS = 100
AUDIO_DUR = 3.0


def run_benchmark() -> int:
    print("\n" + "=" * 70)
    print("  STT MARKET BENCHMARK")
    print(f"  Platform: {platform.system()} {platform.machine()}")
    print("=" * 70)

    asr = UrduASRSimulator()
    audio = generate_speech_like_pcm(AUDIO_DUR, seed=42)

    for _ in range(WARMUP):
        asr.infer(audio, ground_truth_urdu="ٹیسٹ")

    latencies = []
    rss_before = psutil.Process().memory_info().rss / (1024 * 1024)

    for i in range(BENCH_RUNS):
        t0 = time.perf_counter_ns()
        asr.infer(audio, ground_truth_urdu="ٹیسٹ")
        latencies.append((time.perf_counter_ns() - t0) / 1e6)

    rss_after = psutil.Process().memory_info().rss / (1024 * 1024)
    lat = np.array(latencies)
    mean_ms = float(np.mean(lat))
    p50 = float(np.percentile(lat, 50))
    p95 = float(np.percentile(lat, 95))
    rtf = (mean_ms / 1000.0) / AUDIO_DUR

    beat_whisper = rtf <= ECHOOVOX_TARGET
    results = {
        "platform": {
            "os": platform.system(),
            "arch": platform.machine(),
            "ram_gb": round(psutil.virtual_memory().total / (1024**3), 2),
        },
        "echovox": {
            "rtf": round(rtf, 6),
            "latency_mean_ms": round(mean_ms, 4),
            "latency_p50_ms": round(p50, 4),
            "latency_p95_ms": round(p95, 4),
            "rss_mb": round(rss_after, 2),
            "rss_drift_mb": round(rss_after - rss_before, 2),
            "runs": BENCH_RUNS,
        },
        "market_baselines": MARKET_BASELINES,
        "beat_whisper_cpp_q4": beat_whisper,
        "target_rtf_max": ECHOOVOX_TARGET,
        "overall_pass": beat_whisper,
    }

    print(f"\n  EchoVox RTF:     {rtf:.4f}  (target <= {ECHOOVOX_TARGET})")
    print(f"  Latency P50:     {p50:.3f} ms")
    print(f"  Latency P95:     {p95:.3f} ms")
    print(f"  RSS:             {rss_after:.1f} MB")
    print(f"\n  Market comparison:")
    for key, meta in MARKET_BASELINES.items():
        status = "BEAT" if rtf <= meta["rtf_max"] else "SLOWER"
        print(f"    vs {meta['label']}: RTF {rtf:.4f} vs max {meta['rtf_max']}  [{status}]")

    print(f"\n  OVERALL: {'PASS' if beat_whisper else 'FAIL'}")
    print("=" * 70)

    ARTIFACT.parent.mkdir(parents=True, exist_ok=True)
    with open(ARTIFACT, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\n  Artifact: {ARTIFACT}")
    return 0 if beat_whisper else 1


if __name__ == "__main__":
    sys.exit(run_benchmark())
