# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| main    | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in EchoVox, please report it responsibly.

**Email:** Open a private security advisory via GitHub:
https://github.com/abdullahhanif-001/EchoVox/security/advisories/new

**Do not** open a public issue for security vulnerabilities.

## Response Timeline

- **Acknowledgment:** Within 48 hours
- **Initial assessment:** Within 7 days
- **Fix or mitigation:** Within 30 days for confirmed issues

## Scope

In scope:
- EchoVox deployment scripts (`deploy-vps.sh`, `deploy-android.sh`, `install.sh`, `install.ps1`)
- Docker configuration (`docker-compose.yml`)
- whisper.cpp patches in this repository
- Audit test suite and CI workflows

Out of scope:
- Upstream whisper.cpp vulnerabilities (report to [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp))
- Third-party model files downloaded at runtime

## Safe Harbor

We support good-faith security research. Do not access data you do not own, perform destructive testing on production systems, or publicly disclose before a fix is available.
