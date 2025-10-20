# Superpowers Skills

Community-editable skills for Claude Code's superpowers plugin.

## Structure

- `skills/` - Core skills library
- `scripts/` - Utility scripts for skill management

## Installation

This repository is automatically cloned by the superpowers plugin to `~/.config/superpowers/skills/`.

## Recommended Configuration

### Jujutsu (jj) Protection Hook

If you use Jujutsu (jj) version control, add this hook to your `~/.claude/settings.json` to prevent accidentally using git commands in jj repositories:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if echo \"$CLAUDE_TOOL_PARAMS\" | jq -r '.command // empty' | grep -qE '^git (add|commit|status|diff|log|push|pull|checkout|branch|merge|rebase)'; then if jj root >/dev/null 2>&1; then echo '⚠️  BLOCKED: jj repository detected. Use jj commands instead of git.' >&2; exit 1; fi; fi"
          }
        ]
      }
    ]
  }
}
```

This hook:
- Runs before any Bash command executes
- Detects git commands (add, commit, status, diff, log, push, pull, checkout, branch, merge, rebase)
- Checks if this is a jj repository by running `jj root`
- Blocks the command with a clear error message if both conditions are true

This provides system-level protection that works alongside the `using-jj-vcs` and `jj-change-workflow` skills.

## Contributing

Users can fork this repo and submit PRs with new skills or improvements to existing ones.
