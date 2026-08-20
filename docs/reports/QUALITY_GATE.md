# EchoVox Quality Gate Proof

**Author:** Abdullah Hanif  
**Scope:** EchoVox product files only (`whisper.cpp/**` excluded from Sonar/CodeQL)

## Scanner configuration

- [`sonar-project.properties`](../../sonar-project.properties) — `sonar.exclusions=whisper.cpp/**`
- [`.github/workflows/sonar.yml`](../../.github/workflows/sonar.yml) — coverage.xml upload + SonarCloud scan
- [`.github/workflows/codeql.yml`](../../.github/workflows/codeql.yml) — Python only, `paths-ignore: whisper.cpp/**`

## Live SonarCloud (product key)

```
https://sonarcloud.io/summary/overall?id=abdullahanifpro111-spec_EchoVox&branch=main
```

```bash
curl.exe -s "https://sonarcloud.io/api/measures/component?component=abdullahanifpro111-spec_EchoVox&metricKeys=alert_status,security_rating,reliability_rating,sqale_rating,ncloc,bugs,vulnerabilities,coverage"
```

**Pass criteria (after next analysis with exclusions):**

| Metric | Target |
|--------|--------|
| ncloc | << 471000 (EchoVox scripts/docs/tests only) |
| security_rating | 1.0 (A) |
| reliability_rating | 1.0 (A) |
| sqale_rating | 1.0 (A) |
| vulnerabilities | 0 on analyzed files |
| bugs | 0 on analyzed files |
| alert_status | OK |

**Pre-exclude baseline (b24dc804, full whisper.cpp scan):** ncloc=470823, security_rating=4.0 (D), reliability_rating=5.0 (E), code_smells=13936. Those grades measured ggml-org upstream, not EchoVox original work. See [BRAND_AND_ATTRIBUTION.md](../BRAND_AND_ATTRIBUTION.md).

## EchoVox-owned findings (fixed in this change)

| Cluster | Fix |
|---------|-----|
| githubactions:S8544 | Pin Actions to commit SHAs; pin pip==25.1.1 and requirements.txt |
| shelldre:S7688 | `[[` conditionals in install/deploy scripts |
| shell:S6506 | `curl --proto '=https' --tlsv1.2` |
| shell:S8541 | `pip install --only-binary :all:` in deploy-android.sh |

## GitHub CI / nightly

- CI matrix: [ci.yml](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/ci.yml)
- Audit gate: [audit-gate.yml](https://github.com/abdullahanifpro111-spec/EchoVox/actions/workflows/audit-gate.yml)
- Nightly 50K soak: Linux RSS threshold **0.50%** (Python simulator GC; FD drift still 0)

```bash
gh api repos/abdullahanifpro111-spec/EchoVox/code-scanning/alerts --jq "[.[]|select(.state==\"open\")]|length"
```
