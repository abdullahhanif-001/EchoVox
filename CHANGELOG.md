# Changelog

All notable changes to EchoVox are documented in this file.

## [Unreleased]

### Added
- Track 3 upstream kit: three `git am` patches for ggml-org/whisper.cpp, verify/push scripts, and [`docs/TRACK3_WHISPER_UPSTREAM.md`](docs/TRACK3_WHISPER_UPSTREAM.md)

## [1.0.0] - 2026-08-20

### Added
- Production whisper.cpp patches for Urdu/Punjabi STT (short audio pad, tail fix, trigram kill, memory pre-allocation)
- Mythos Ultimate ASR audit suite (70 acoustic tests + 10K soak)
- Ultra-Heavy infrastructure audit (50K inference soak)
- Sherlock adversarial test harness
- STT market benchmark suite
- One-command installers for macOS, Linux, and Windows
- VPS, Android, and Docker deployment scripts
- GitHub Actions CI (ubuntu, macos, windows matrix)
- Engineering reports and audit telemetry

### Security
- SECURITY.md vulnerability reporting policy
- CodeQL static analysis workflow
- Dependabot dependency updates

### Fixed
- Windows CI Script Safety failure (CRLF line endings on shell scripts)
- Git commit author corrected to GitHub noreply identity
- CI step labels renamed from "smoke" to "CI verification" for clarity
