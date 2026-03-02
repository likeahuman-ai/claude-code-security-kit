# Claude Code Security Kit - Installation

## What's included

1. **`repo-security-auditor.md`** - An agent that performs deep security audits on any repo, MCP server, or npm package before you install it. Covers 14 attack categories including React/frontend attacks, MCP tool poisoning, supply chain risks, and more. Uses web search to check for latest CVEs before each audit.
2. **`check-repo-before-install.sh`** - A hook that automatically blocks `git clone` and forces a security audit first.

## Installation

### Step 1: Install the agent

Copy `repo-security-auditor.md` to your Claude Code agents directory:

```bash
mkdir -p ~/.claude/agents
cp repo-security-auditor.md ~/.claude/agents/
```

### Step 2: Install the hook

Copy `check-repo-before-install.sh` to your hooks directory and make it executable:

```bash
mkdir -p ~/.claude/hooks
cp check-repo-before-install.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/check-repo-before-install.sh
```

### Step 3: Register the hook

Add the following to your `~/.claude/settings.json` inside the `"hooks"` > `"PreToolUse"` array:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/check-repo-before-install.sh"
    }
  ]
}
```

If you don't have a hooks section yet, add this to your settings.json:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/check-repo-before-install.sh"
          }
        ]
      }
    ]
  }
}
```

## How it works

1. When you (or Claude) tries to `git clone` a repo, the hook blocks it
2. The hook instructs Claude to clone to `/tmp/` instead and run a full security audit
3. The `repo-security-auditor` agent runs through 14 security categories
4. It searches the web for latest CVEs and known issues about the repo first
5. You get a full report with verdict (SAFE / CAUTION / DO NOT INSTALL) before anything touches your machine

## What it catches (14 categories)

1. **Repository config attacks** - malicious hooks, MCP consent bypass, API key exfiltration
2. **Path traversal** - arbitrary file read/write/delete via unvalidated paths
3. **Credential harvesting** - code that reads SSH keys, AWS creds, .env files, browser passwords
4. **Code execution** - eval, exec, spawn with user input
5. **Data exfiltration** - HTTP, DNS, markdown image, and service-based data theft
6. **MCP tool poisoning** - hidden instructions in tool descriptions and outputs
7. **Skill/agent injection** - prompt injection in .md files, SkillJect patterns
8. **React/frontend attacks** - malicious hooks, event handlers, keyloggers, CSS exfil, service workers, build tool injection
9. **Supply chain** - postinstall malware, typosquatting, obfuscated code, dependency confusion
10. **Persistence** - shell profile modification, cron jobs, LaunchAgents, git hooks
11. **Encoding/obfuscation** - base64, homoglyphs, zero-width Unicode, computed property access
12. **Auth/network security** - missing auth, weak CORS, insecure cookies, no rate limiting
13. **Indirect prompt injection** - hidden instructions in code comments, README, API responses
14. **OWASP Top 10** - injection, XSS, broken auth, sensitive data exposure, misconfig
