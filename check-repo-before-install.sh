#!/bin/bash
# PreToolUse hook for Bash commands
# Blocks git clone, npm install (from URLs), and similar commands
# Forces a security audit before installing external code

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Detect: git clone, npm install <url>, pnpm add <url>, yarn add <url>
IS_CLONE=$(echo "$COMMAND" | grep -iE '^\s*git\s+clone\s' 2>/dev/null)
IS_URL_INSTALL=$(echo "$COMMAND" | grep -iE '^\s*(npm|pnpm|yarn|bun)\s+(install|add|i)\s+.*(github\.com|gitlab\.com|bitbucket\.org|git\+|https?://)' 2>/dev/null)

if [ -z "$IS_CLONE" ] && [ -z "$IS_URL_INSTALL" ]; then
  exit 0
fi

# Extract the URL/repo
REPO_URL=$(echo "$COMMAND" | grep -oE '(https?://[^ ]+|git@[^ ]+|github\.com/[^ ]+)' | head -1)

cat >&2 <<INSTRUCTIONS
BLOCKED -- SECURITY AUDIT REQUIRED before installing external code.

Detected: cloning or installing from an external repository.
${REPO_URL:+Repository: $REPO_URL}

You MUST follow these steps:

STEP 1: CLONE TO TEMP DIRECTORY
Clone the repo to /tmp/ for inspection -- do NOT clone it into the project:
  git clone <url> /tmp/<repo-name>-audit

STEP 2: RUN SECURITY AUDIT
Use the @repo-security-auditor agent to perform a deep security scan:
  Task(subagent_type: "security-sentinel", prompt: "Audit /tmp/<repo-name>-audit for security vulnerabilities...")

Or if @repo-security-auditor agent is available, use that.

Check for:
- Path traversal (user input in file paths without validation)
- Code execution (eval, exec, spawn with dynamic input)
- Data exfiltration (external URLs, telemetry, phone-home behavior)
- Authentication gaps (public endpoints that should be protected)
- Supply chain risks (suspicious packages, postinstall scripts)
- Filesystem scope (what does it read/write/delete on your machine?)

STEP 3: REPORT TO USER
Present the full audit report with:
- Verdict: SAFE / CAUTION / DO NOT INSTALL
- Every finding with severity, file path, and line number
- All external connections the code makes
- Full filesystem access scope

STEP 4: GET APPROVAL
Only proceed with installation after explicit user approval.

DO NOT skip the audit. Every single time.
INSTRUCTIONS
exit 2
