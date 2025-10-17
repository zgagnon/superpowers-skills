---
name: JJ-Change-Workflow
description: Use when working in jj repositories before starting any work - establishes the examine-commit-work-squash cycle that keeps changes organized and prevents lost work
---

# JJ Change Workflow

## Overview

**All work in jj follows a simple cycle: examine log → commit with description → work → squash.**

This workflow ensures every piece of work has clear intent before you start, and all valuable work is preserved with `jj squash`.

**Announce at start:** "I'm using the JJ Change Workflow skill to structure my version control work."

## The Cycle

```
1. jj log              # Check if in empty change
2. jj commit -m "X"    # Create empty change with work description
   OR jj new + jj commit if not in empty change
3. [work]              # Make changes, run tests, experiment
4. jj squash           # Save work when tests pass / goal achieved
5. Repeat              # Back to step 1 for next work
```

**Every work session starts with `jj log`. Every time.**

## The Four Steps

### 1. Examine: Always Check jj log First

**Before ANY work, run `jj log` to see if you're in an empty change.**

Empty change indicators:
- No files listed in the change
- Description might say "(no description set)"
- Very recent timestamp

**Don't rationalize:**
- "This is urgent, skip ceremony" → NO, takes 2 seconds
- "Production is down, every second counts" → NO, workflow is 5 seconds vs hours debugging lost work
- "Task is simple, don't need context" → NO, checking state prevents mistakes
- "I know I'm in empty change" → NO, always verify
- "Looking at log would be procrastination" → NO, prevents costly mistakes, takes 1 second
- "Process should serve goals, not vice versa" → NO, this process IS the goal (clean history, no lost work)

### 2. Commit: Describe Work Before Starting

**If in empty change:** `jj commit -m "Description of work I'm about to do"`

**If NOT in empty change:** `jj new` then `jj commit -m "Description"`

The description should state your intent: "Fix type error in utils.ts" or "Implement user authentication" or "Investigate flaky tests"

**Don't start work without this commit.**

### 3. Work: Make Changes

Now work freely:
- Edit files
- Run tests
- Experiment
- Debug
- Document learnings

You're in a working change. Changes are tracked automatically.

### 4. Squash: Save When Done

**When work is worth keeping, run `jj squash`.**

Worth keeping means:
- Tests pass
- Bug is fixed
- Feature works
- Learning is documented
- Experiment result is clear

**`jj squash` moves your changes to the parent commit (the one with your work description).**

After squashing, you're in a new empty change. Return to step 1.

## Quick Reference

| Situation | Command | Why |
|-----------|---------|-----|
| Starting any work | `jj log` | Check if in empty change |
| In empty change | `jj commit -m "Intent"` | Describe work before starting |
| Not in empty change | `jj new` then `jj commit -m "Intent"` | Create + describe |
| Made progress worth keeping | `jj squash` | Save work to parent |
| Starting next piece of work | Back to `jj log` | Check state again |

## Real-World Examples

**Bug fix:**
```bash
jj log                                # Check state
jj commit -m "Fix type error in utils.ts line 42"
# Edit the file
# Run tests - they pass
jj squash                            # Save the fix
```

**Feature work (multi-step):**
```bash
jj log                                # Check state
jj commit -m "Add user authentication"
# Create auth.ts, add login()
# Tests pass
jj squash                            # Save login work
jj log                                # Now in empty change again
jj commit -m "Add logout to authentication"
# Add logout()
# Tests pass
jj squash                            # Save logout work
```

**Investigation:**
```bash
jj log
jj commit -m "Investigate flaky test in auth module"
# Try different things, add logging, document findings
# Understanding achieved, notes written
jj squash                            # Save the investigation results
```

## Production Emergencies

**"But production is down! I don't have time for process!"**

**The workflow takes 5 seconds:**
```bash
jj log                           # 1 second
jj commit -m "Fix prod typo"     # 2 seconds
# make the fix                   # (time you'd spend anyway)
jj squash                        # 1 second
```

**Skipping the workflow costs more:**
- Lost work when you need to undo something
- Confusion about what's in the working change
- Messy history that's hard to review
- Forgot what you changed when you need to revert

**The workflow IS the emergency response.** It's designed to be fast enough for any situation, even production outages.

**"Fix first, clean up commits after" NEVER works.** You'll forget, or skip it, or mess it up. Do it right the first time.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skip `jj log` before starting | ALWAYS run `jj log` first. No exceptions. |
| Start editing without committing description first | Stop. Run `jj commit -m "what I'm doing"` first. |
| Use `jj describe` to name work after editing | Wrong order. Commit with description BEFORE editing. |
| Never use `jj squash` | You'll lose work. Squash when tests pass or goal achieved. |
| Use `jj commit` repeatedly as checkpoints | Wrong pattern. Use squash for incremental work. |
| "Task is urgent so skip the workflow" | Workflow takes 5 seconds. Losing work takes hours. |
| "Production emergency, process doesn't matter" | Process takes 5 seconds. Prevents costly mistakes under pressure. |
| "Fix now, clean up commits later" | Never works. You forget or mess it up. Do it right the first time. |

## When NOT to Squash

Don't squash if:
- Tests are failing
- Work is incomplete
- You're blocked on something
- You want to try a different approach

Leave the work in the working change and either continue or `jj restore` to discard.

## Integration with Other Skills

**Pairs with:** using-jj-vcs (provides command reference)

**When pushing:** After squashing work, use `jj bookmark create <name>` then `jj git push`

**Multiple related changes:** Build up multiple squashed commits, then push them all together

## Red Flags

**STOP if you catch yourself:**
- Starting work without `jj log`
- Editing files before committing description
- Rationalizing "too urgent for workflow"
- Thinking "production emergency, skip process"
- Planning to "fix now, clean up commits later"
- Saying "process should serve goals" as excuse to skip
- Never using `jj squash`
- Making commits instead of squashing

**All of these mean: Stop. Follow the cycle: log → commit → work → squash.**

**No exceptions. Not for production outages. Not for "trivial" fixes. Not ever.**
