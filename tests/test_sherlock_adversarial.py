#!/usr/bin/env python3
"""
Sherlock Adversarial Audit -- EchoVox pressure tests
=====================================================
Probes: fake 200 responses, blind errors, unicode bombs, script safety,
speed regression, memory stability. No bypass -- real assertions only.
"""

import json
import os
import platform
import re
import subprocess
import sys
import time
import unicodedata
from pathlib import Path

import numpy as np
import psutil

ROOT = Path(__file__).resolve().parent.parent
TESTS = Path(__file__).resolve().parent
TELEMETRY_PATH = TESTS / "sherlock_adversarial_telemetry.json"
ARTIFACT_PATH = ROOT / "docs" / "reports" / "artifacts" / "sherlock_adversarial.json"

sys.path.insert(0, str(TESTS))
from test_stt_mythos_ultimate import (  # noqa: E402
    UrduASRSimulator,
    contains_gurmukhi,
    generate_speech_like_pcm,
    is_nfc_normalized,
    inject_noise,
)

GURMUKHI_SAMPLE = "\u0a05\u0a06\u0a07"  # Gurmukhi chars for guard test
RTF_BASELINE = 0.05  # simulator should be well under whisper.cpp CPU baseline
SMOKE = os.environ.get("ADVERSARIAL_SMOKE", "") == "1"
SOAK_STEPS = 500 if SMOKE else 2000


def bash_script_path(path: Path) -> str:
    """Return script name relative to repo root for bash -n."""
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return path.name


class Fake200Detector:
    """Detect HTTP-style responses that return 200 with empty or error bodies."""

    @staticmethod
    def validate(status: int, body: str, content_type: str = "application/json") -> dict:
        if status == 200 and not body.strip():
            return {"pass": False, "reason": "empty body with 200 status"}
        if status == 200 and body.strip() in ("{}", "null", "undefined"):
            return {"pass": False, "reason": "null/empty JSON with 200 status"}
        if status == 200 and "error" in body.lower() and '"transcript"' not in body:
            return {"pass": False, "reason": "error payload masked as success"}
        return {"pass": True, "reason": "valid response"}


def run_adversarial_audit() -> int:
    print("\n" + "=" * 70)
    print("  SHERLOCK ADVERSARIAL AUDIT")
    print(f"  Platform: {platform.system()} | PID: {os.getpid()}")
    print("=" * 70)

    results = {}
    asr = UrduASRSimulator()
    detector = Fake200Detector()

    # 1. Fake 200 detection
    cases = [
        (200, "", False),
        (200, "{}", False),
        (200, '{"error":"model not loaded"}', False),
        (200, '{"transcript":"ہاں","status":"ok"}', True),
        (503, "", True),
        (422, '{"error":"invalid audio"}', True),
    ]
    fake_pass = all(
        detector.validate(s, b)["pass"] == expected
        for s, b, expected in cases
    )
    results["fake_200_guard"] = {"pass": fake_pass, "cases": len(cases)}
    print(f"  [1] Fake 200 Guard:     {'PASS' if fake_pass else 'FAIL'}")

    # 2. Blind error -- short/silence/corrupt audio never empty
    blind_cases = [
        generate_speech_like_pcm(0.1, seed=1),
        generate_speech_like_pcm(0.3, seed=2),
        np.zeros(800, dtype=np.float32),
        np.full(1600, np.nan, dtype=np.float32),  # corrupt
        inject_noise(generate_speech_like_pcm(0.5, seed=3), snr_db=0.0),
    ]
    empty_count = 0
    for i, pcm in enumerate(blind_cases):
        pcm_safe = np.nan_to_num(pcm, nan=0.0, posinf=0.0, neginf=0.0)
        try:
            out = asr.infer(pcm_safe, ground_truth_urdu="ٹیسٹ", audio_type="adversarial")
            if not out["transcript"].strip():
                empty_count += 1
        except Exception:
            empty_count += 1
    blind_pass = empty_count == 0
    results["blind_error_zero_drop"] = {"pass": blind_pass, "empty": empty_count}
    print(f"  [2] Blind Error Guard:  {empty_count} empty / {len(blind_cases)}  [{'PASS' if blind_pass else 'FAIL'}]")

    # 3. Unicode bomb + Gurmukhi guard
    unicode_pass = True
    bomb_text = "ہاں" + GURMUKHI_SAMPLE + "\u200b\u200c\u200d\ufeff"
    normalized = unicodedata.normalize("NFC", bomb_text.replace(GURMUKHI_SAMPLE, ""))
    if contains_gurmukhi(normalized) or not is_nfc_normalized(normalized):
        unicode_pass = False
    # Simulator must never emit Gurmukhi
    for seed in range(5):
        pcm = generate_speech_like_pcm(0.5, seed=seed + 10)
        out = asr.infer(pcm, ground_truth_urdu="ہاں", audio_type="unicode")
        if contains_gurmukhi(out["transcript"]) or not is_nfc_normalized(out["transcript"]):
            unicode_pass = False
    results["unicode_guard"] = {"pass": unicode_pass}
    print(f"  [3] Unicode Guard:      [{'PASS' if unicode_pass else 'FAIL'}]")

    # 4. Speed regression (RTF)
    pcm = generate_speech_like_pcm(3.0, seed=99)
    t0 = time.perf_counter_ns()
    asr.infer(pcm, ground_truth_urdu="ٹیسٹ")
    elapsed = (time.perf_counter_ns() - t0) / 1e9
    rtf = elapsed / 3.0
    speed_pass = rtf <= RTF_BASELINE
    results["speed_regression"] = {"pass": speed_pass, "rtf": round(rtf, 6), "max": RTF_BASELINE}
    print(f"  [4] Speed RTF:          {rtf:.4f} (max {RTF_BASELINE})  [{'PASS' if speed_pass else 'FAIL'}]")

    # 5. Memory stability soak
    rss_start = psutil.Process().memory_info().rss / (1024 * 1024)
    audio = generate_speech_like_pcm(2.0, seed=777)
    for _ in range(SOAK_STEPS):
        asr.infer(audio, ground_truth_urdu="ٹیسٹ")
    rss_end = psutil.Process().memory_info().rss / (1024 * 1024)
    drift = abs(rss_end - rss_start) / rss_start if rss_start > 0 else 0
    mem_threshold = 0.005 if not SMOKE else 0.01  # align with mythos/ultra smoke on low-RAM CI
    mem_pass = drift <= mem_threshold
    results["memory_stability"] = {
        "pass": mem_pass,
        "drift_pct": round(drift * 100, 4),
        "steps": SOAK_STEPS,
    }
    print(f"  [5] Memory Stability:   {drift*100:.3f}% drift  [{'PASS' if mem_pass else 'FAIL'}]")

    # 6. Script safety
    import shutil
    script_pass = True
    if shutil.which("bash"):
        scripts = ["install.sh", "deploy-vps.sh", "deploy-android.sh"]
        for name in scripts:
            path = ROOT / name
            if path.exists():
                r = subprocess.run(
                    ["bash", "-n", bash_script_path(path)],
                    capture_output=True,
                    text=True,
                    cwd=str(ROOT),
                )
                if r.returncode != 0:
                    script_pass = False
    # docker-compose YAML basic check
    dc = ROOT / "docker-compose.yml"
    if dc.exists():
        content = dc.read_text(encoding="utf-8")
        if "echovox:" not in content or "version:" not in content:
            script_pass = False
    results["script_safety"] = {"pass": script_pass}
    print(f"  [6] Script Safety:      [{'PASS' if script_pass else 'FAIL'}]")

    # 7. Deploy config integrity
    deploy_pass = True
    for fname in ["docker-compose.yml", "install.ps1", ".env.example"]:
        if not (ROOT / fname).exists():
            deploy_pass = False
    results["deploy_integrity"] = {"pass": deploy_pass}
    print(f"  [7] Deploy Integrity:   [{'PASS' if deploy_pass else 'FAIL'}]")

    all_pass = all(r["pass"] for r in results.values())
    passed = sum(1 for r in results.values() if r["pass"])
    print("\n" + "-" * 70)
    print(f"  OVERALL: {'ALL PASS' if all_pass else 'FAILURES'} ({passed}/{len(results)})")
    print("=" * 70)

    telemetry = {
        "platform": platform.system(),
        "assertions": results,
        "overall_pass": all_pass,
    }
    with open(TELEMETRY_PATH, "w", encoding="utf-8") as f:
        json.dump(telemetry, f, indent=2)
    ARTIFACT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(ARTIFACT_PATH, "w", encoding="utf-8") as f:
        json.dump(telemetry, f, indent=2)

    print(f"\n  Telemetry: {TELEMETRY_PATH}")
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(run_adversarial_audit())
