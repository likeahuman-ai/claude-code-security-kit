# Claude Code Security Kit

Stop blindly installing repos. Audit them first.

This kit adds a security layer to Claude Code that automatically blocks `git clone` and forces a full security audit before any external code touches your machine.

## What's inside

| File | What it does |
|------|-------------|
| `setup.sh` | One-command installer — copies files and registers the hook |
| `repo-security-auditor.md` | Custom agent that performs deep security audits across 14 attack categories |
| `check-repo-before-install.sh` | Hook that blocks `git clone` and triggers the audit flow |
| `INSTALL.md` | Manual setup guide |

## How it works

1. You (or Claude) tries to `git clone` a repo
2. The hook blocks it
3. The repo gets cloned to `/tmp/` for inspection
4. The security auditor agent runs a full scan (14 categories, 50+ checks)
5. It searches the web for latest CVEs about that repo first
6. You get a verdict: **SAFE** / **CAUTION** / **DO NOT INSTALL**
7. You decide whether to proceed

## What it catches

| # | Category | Examples |
|---|----------|----------|
| 1 | Repository config attacks | Malicious hooks, MCP consent bypass, API key exfiltration |
| 2 | Path traversal | Arbitrary file read/write/delete via unvalidated paths |
| 3 | Credential harvesting | Code reading SSH keys, AWS creds, .env files, browser passwords |
| 4 | Code execution | `eval`, `exec`, `spawn` with user input |
| 5 | Data exfiltration | HTTP, DNS, markdown image, and service-based data theft |
| 6 | MCP tool poisoning | Hidden instructions in tool descriptions and outputs |
| 7 | Skill/agent injection | Prompt injection in .md files, SkillJect patterns |
| 8 | React/frontend attacks | Malicious hooks, keyloggers, CSS exfil, service workers, build tool injection |
| 9 | Supply chain | postinstall malware, typosquatting, obfuscated code, dependency confusion |
| 10 | Persistence | Shell profile modification, cron jobs, LaunchAgents, git hooks |
| 11 | Encoding/obfuscation | Base64, homoglyphs, zero-width Unicode, computed property access |
| 12 | Auth/network security | Missing auth, weak CORS, insecure cookies, no rate limiting |
| 13 | Indirect prompt injection | Hidden instructions in comments, README, API responses |
| 14 | OWASP Top 10 | Injection, XSS, broken auth, sensitive data exposure, misconfig |

## Install

```bash
git clone https://github.com/likeahuman-ai/claude-code-security-kit.git
cd claude-code-security-kit
./setup.sh
```

That's it. The setup script:
1. Copies the agent to `~/.claude/agents/`
2. Copies the hook to `~/.claude/hooks/`
3. Registers the hook in `~/.claude/settings.json` (merges with your existing config)

Requires `jq` for auto-registration (`brew install jq` on macOS).

See [INSTALL.md](INSTALL.md) for manual setup.

## Example output

```
# Security Audit: sketchy-mcp-server

## Verdict: DO NOT INSTALL

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 2     |
| HIGH     | 3     |
| MEDIUM   | 1     |

## Findings

### [CRITICAL] API Key Exfiltration via ANTHROPIC_BASE_URL
File: .claude/settings.json:4
Issue: Redirects all API calls to attacker-controlled server
Risk: Full API key capture + request/response interception

### [CRITICAL] Credential Harvesting
File: src/index.ts:42
Issue: Reads ~/.ssh/id_rsa and POSTs to external endpoint
Risk: SSH private key theft
```

## Why this exists

MCP servers, skills, agents, and random GitHub repos all run with your Claude Code permissions. A single malicious `postinstall` script or weaponized `.claude/settings.json` can steal your SSH keys, API tokens, or inject persistent backdoors.

This kit makes "audit first, install second" the default behavior.

## Built by

[Like a Human](https://likeahuman.ai) - AI development studio based in Barcelona.

## License

MIT
