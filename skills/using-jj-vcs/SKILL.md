---
name: Using-JJ-VCS
description: Use when a .jj directory is present in the repository - provides jj command workflows and clarifies confusing command differences (new vs describe vs commit) to prevent git fallback
---

# Using Jujutsu (jj) Version Control

## Overview

Jj is a change-oriented VCS. When `.jj` directory exists, use jj commands instead of git.

**Core principle:** `.jj` present = use jj (even if `.git` also exists).

**Announce at start:** "I'm using the Using JJ VCS skill for version control operations."

## Detection Rule

**ALWAYS check for `.jj` before using VCS commands.**

**Priority:** `.jj` exists → jj commands | Only `.git` → git commands

**Why:** Colocated repos have both. `.jj` indicates jj is primary interface.

## The Confusing Three: new vs describe vs commit

**`jj describe -m "msg"`** - Updates current change description only (rename)

**`jj new -m "msg"`** - Creates new empty change on top with description (start fresh on top)

**`jj commit -m "msg"`** - Describes current AND creates new on top (finish current, start new) = `describe` + `new`

## Quick Reference

| Task | Command |
|------|---------|
| Check status | `jj status` |
| View history | `jj log` |
| View change | `jj show <revision>` |
| Rename current | `jj describe -m "msg"` |
| New on top | `jj new -m "msg"` |
| Finish & new | `jj commit -m "msg"` |
| Squash to parent | `jj squash -i` |
| Discard files | `jj restore` |
| Create bookmark | `jj bookmark create <name>` |
| Push | `jj git push` |
| Fetch | `jj git fetch` |

## Common Workflows

**Starting:** `jj commit -m "Done"` → `jj describe -m "New work"`
**Pushing:** `jj bookmark create <name>` → `jj git push`
**Fix prev:** `jj describe <id> -m "msg"` or `jj edit <id>`

## Revset Syntax

`@` = current | `@-` = parent | `@--` = grandparent | `main` = bookmark | `abc123` = change ID | `all()` = all changes | `main..@` = range

## Common Mistakes

- **Git commands in jj repo** → Always use jj when `.jj` exists
- **No bookmark before push** → `jj bookmark create <name>` first
- **Wrong new/describe/commit** → See "Confusing Three" section above
- **Skip .jj check** → Always verify `.jj` presence first
- **`jj squash` without `-i`** → Use `-i` for safety

## Key Differences from Git

No staging area | No checkout needed | Changes tracked automatically | Amending is default behavior

## Red Flags

**Never:**
- Use git commands when `.jj` exists
- Forget to check for `.jj` directory
- Use `jj squash` without understanding it moves to parent
- Push without a bookmark

**Always:**
- Check for `.jj` before any VCS operation
- Use `jj status` to check state before operations
- Create bookmarks before pushing
- Use `-i` flag with squash for safety

## Integration

**Use when:** Any VCS operations | Before using git (check `.jj` first)

**Pairs with:** using-git-worktrees (prefer jj if `.jj` exists)
