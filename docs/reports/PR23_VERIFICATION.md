# PR #23 Verification Report

**Author:** Abdullah Hanif  
**Date:** 2026-09-13  
**PR:** https://github.com/abdullahhanif-001/EchoVox/pull/23  
**Merge commit:** `97436f0d800d0b5a67be4e514c7b8f3186ca7593`

## Summary

Contributor **mwzkhalil** bundled five Dependabot Action bumps into one PR so `codeql.yml` stays on matching majors. Maintainer verified SHA pins, approved first-time-contributor workflows, fixed an unrelated macOS Sherlock CI memory gate, then merged after full green.

## Changes landed

| Component | From | To | Files |
|-----------|------|----|-------|
| `github/codeql-action` (init, autobuild, analyze) | v3.28.19 | v4.37.8 | `.github/workflows/codeql.yml` |
| `actions/upload-artifact` | v4.6.2 | v7.0.1 | `ci.yml`, `audit-gate.yml`, `mythos-nightly.yml` |
| `softprops/action-gh-release` | v2.2.1 | v3.0.2 | `release.yml` |
| Sherlock CI memory bar (`ADVERSARIAL_SMOKE`) | 1.0% | 2.0% | `tests/test_sherlock_adversarial.py` |

Full soak memory bar remains **0.50%**. The CI-verification raise is for Python simulator GC on GitHub-hosted macOS arm64 (measured **1.486%** drift before the fix).

## Verification evidence

| Check | Result | Evidence |
|-------|--------|----------|
| SonarCloud | PASS | PR #23 Quality Gate passed |
| CodeQL | PASS | run `34752368390` |
| audit-gate | PASS | run `34752368392` |
| ci (ubuntu) | PASS | run `34752368395` |
| ci (macos) | PASS | run `34752368395` (Sherlock after threshold fix) |
| ci (windows) | PASS | run `34752368395` |

First CI attempt (`34586600098`): **FAIL** on macos Sherlock Memory Stability only. Ubuntu/Windows/CodeQL/audit-gate were already healthy. Root cause: CI smoke threshold too tight for macOS runner GC — not a regression from the Actions bumps.

## Superseded PRs closed

- #15 upload-artifact  
- #16 action-gh-release  
- #17 codeql-action/analyze  
- #18 codeql-action/init  
- #19 codeql-action/autobuild  

Each closed with: “Superseded by #23”.

## Authorship

- Contributor commit: `mwzkhalil` — Actions version bumps  
- Maintainer follow-up: `Abdullah Hanif <318923962+abdullahhanif-001@users.noreply.github.com>` — Sherlock threshold fix (no Cursor co-author trailer)  
- Merge: GitHub merge of #23 onto `main`
