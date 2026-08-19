# Contributing to EchoVox

Thank you for your interest in contributing to EchoVox.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/EchoVox.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Install dependencies: `pip install numpy psutil`

## Development Workflow

```bash
# Run smoke audits (fast)
MYTHOS_SMOKE=1 python tests/test_stt_mythos_ultimate.py
ULTRA_SMOKE=1 python tests/test_ultra_heavy_audit.py
python tests/test_sherlock_adversarial.py

# Run full audit gate
python tests/run_audit_gate.py
```

## Pull Request Guidelines

- Keep PRs focused on a single concern
- Ensure all CI checks pass (ubuntu, macos, windows)
- Add tests for new behavior
- Update documentation if behavior changes
- Follow existing code style and conventions

## Code of Conduct

Be respectful and constructive. Focus on technical merit.

## Questions

Open a GitHub issue for questions or feature requests.
