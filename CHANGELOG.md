# Changelog

All notable changes to EchoVox are documented in this file.

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
