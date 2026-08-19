#!/usr/bin/env python3
"""Run all EchoVox audit suites and print unified PASS/FAIL matrix."""

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TESTS = Path(__file__).resolve().parent

SUITES = [
    ("Mythos ASR (smoke)", [sys.executable, str(TESTS / "test_stt_mythos_ultimate.py")], {"MYTHOS_SMOKE": "1"}),
    ("Ultra Heavy (smoke)", [sys.executable, str(TESTS / "test_ultra_heavy_audit.py")], {"ULTRA_SMOKE": "1"}),
    ("Sherlock Adversarial", [sys.executable, str(TESTS / "test_sherlock_adversarial.py")], {"ADVERSARIAL_SMOKE": "1"}),
    ("STT Market Benchmark", [sys.executable, str(TESTS / "benchmark_stt_market.py")], {}),
]


def main() -> int:
    print("\n" + "=" * 70)
    print("  ECHOVOX AUDIT GATE")
    print("=" * 70)

    results = []
    for name, cmd, env_extra in SUITES:
        env = os.environ.copy()
        env.update(env_extra)
        print(f"\n>>> Running: {name}")
        r = subprocess.run(cmd, cwd=str(ROOT), env=env)
        ok = r.returncode == 0
        results.append((name, ok))
        print(f"    {'PASS' if ok else 'FAIL'}")

    print("\n" + "=" * 70)
    print("  AUDIT GATE MATRIX")
    print("=" * 70)
    for name, ok in results:
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")

    all_pass = all(ok for _, ok in results)
    print("-" * 70)
    print(f"  OVERALL: {'ALL PASS' if all_pass else 'FAILURES DETECTED'}")
    print("=" * 70)
    return 0 if all_pass else 1


if __name__ == "__main__":
    sys.exit(main())
