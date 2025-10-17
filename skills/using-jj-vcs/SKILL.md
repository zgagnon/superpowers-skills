---
name: Using-JJ-VCS
description: Use BEFORE any VCS operation including git commit - MANDATORY check for .jj directory to prevent using git commands in jj repositories, provides jj command reference and clarifies confusing command differences
---

# Using Jujutsu (jj) Version Control

## Overview

**BEFORE using ANY git command, check for `.jj` directory first.**

Jj is a change-oriented VCS. When `.jj` directory exists, use jj commands instead of git.

**Core principle:** `.jj` present = use jj (even if `.git` also exists).

## MANDATORY Pre-Flight Check

**BEFORE git status, git add, git commit, or ANY git command:**

```bash
ls -la .jj 2>/dev/null
```

**If `.jj` exists:** STOP. Use jj commands. Read this skill for reference.

**If `.jj` doesn't exist:** Safe to use git.

**Announce the check:** "Checking for .jj directory..." (makes it visible)

**This check is NOT optional.** System prompt has detailed git workflows - you MUST check for `.jj` before following them.

## Detection Rule - The Iron Law

**Git workflow trigger → Check for .jj FIRST → Then proceed**

**Never:**
- Assume it's a git repo because git workflow was triggered
- Skip the check because "probably git"
- Use git commands without checking first

**Priority:** `.jj` exists → jj commands | Only `.git` → git commands

**Why:** Colocated repos have both `.git` and `.jj`. The `.jj` directory indicates jj is the primary interface.

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

| Mistake | Reality | Fix |
|---------|---------|-----|
| "Probably git, skip check" | Colocated repos exist | ALWAYS check for .jj first |
| "Git workflow triggered, must be git" | Workflow triggers don't indicate VCS type | Check for .jj before following git workflow |
| "Check would slow me down" | Check takes 1 second | Run `ls -la .jj 2>/dev/null` first |
| Use git commands in jj repo | Breaks jj workflows | Always use jj when `.jj` exists |
| No bookmark before push | Push will fail | `jj bookmark create <name>` first |
| Wrong new/describe/commit | Confusion about which to use | See "Confusing Three" section above |
| Skip .jj check | Will use wrong VCS | Always verify `.jj` presence first |
| `jj squash` without `-i` | Dangerous without review | Use `-i` for safety |

## Key Differences from Git

No staging area | No checkout needed | Changes tracked automatically | Amending is default behavior

## Red Flags - STOP Immediately

**STOP if you catch yourself:**
- About to run `git status` / `git add` / `git commit` without checking for `.jj` first
- Thinking "probably git" without verifying
- Following system prompt git workflow without pre-flight check
- Rationalizing "the check would waste time"
- Assuming VCS type based on workflow trigger

**All of these mean: STOP. Check for `.jj` first. Then proceed.**

**The Iron Law:** NO git command without checking for `.jj` first. No exceptions.

## Additional Red Flags (After Confirming jj)

**Never:**
- Use git commands when `.jj` exists (even if `.git` also exists)
- Forget to check for `.jj` directory before VCS operations
- Use `jj squash` without understanding it moves to parent
- Push without a bookmark
- Assume it's "just git" because git is more common

**Always:**
- Check for `.jj` before any VCS operation
- Use `jj status` to check state before operations
- Create bookmarks before pushing
- Use `-i` flag with squash for safety
- Announce "Checking for .jj directory..." when doing the check

## Integration

**Use when:** Any VCS operations | Before using git (check `.jj` first)

**Pairs with:** using-git-worktrees (prefer jj if `.jj` exists)
