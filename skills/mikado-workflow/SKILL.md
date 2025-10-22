---
name: Mikado-Workflow
description: Use when discovering a prerequisite during any work - provides workflow for tracking and implementing prerequisites using beads for state tracking and jj for code isolation, creating clean-room isolation for easier implementation
---

# Mikado Workflow

## Overview

**When you realize "This would be easier if I had Y first", use Mikado workflow to create Y in a clean-room environment.**

Clean-room = no failing tests, no incomplete work, just focused prerequisite implementation.

**Core principle:** Prerequisites created in isolation are faster and clearer than prerequisites created amid noise.

**State tracking:** Beads tracks dependencies, status, and progress. JJ provides code isolation.

**Announce at start:** "I'm using the Mikado Workflow skill to handle this prerequisite."

## The Workflow

### Setup (Initial Goal)
```bash
# Create beads issue for goal
bd create "Add feature X" -t task -p 2
# Note issue ID (e.g., proj-1)

# Set up jj structure with accumulator + working pattern
jj commit -m "proj-1: Add feature X"            # Create accumulator change
jj new                                           # Create working change on top
jj bookmark create proj-1-accumulator -r @-     # Bookmark the accumulator (parent)
jj bookmark create proj-1-working -r @          # Bookmark the working change (current)

# Mark issue as in progress
bd update proj-1 --status in_progress
```

### Discovering Prerequisites
When you realize "X would be easier if I had Y first":
```bash
# Create prerequisite issue
bd create "Add password hashing" -t task -p 1
# Note issue ID (e.g., HASH-1)

# Link dependency (HASH-1 blocks proj-1)
bd dep add proj-1 HASH-1

# Update statuses
bd update proj-1 --status blocked
bd update HASH-1 --status in_progress

# Create clean-room jj structure BEFORE the accumulator
# CRITICAL: Use --before on the ACCUMULATOR, not working
jj new --before proj-1-accumulator -m "HASH-1: Add password hashing"
jj new                                            # Create working change on top
jj bookmark create prereq-hashing-accumulator -r @-   # Bookmark the accumulator (parent)
jj bookmark create prereq-hashing-working -r @        # Bookmark the working change (current)

# FIRST: Verify clean starting state for prerequisite
# Run ALL tests (including integration tests, even if normally ignored)
npm test -- --run-ignored  # or your test command
# If ANY tests fail or warnings exist, fix them BEFORE implementing prerequisite
# Clean room means CLEAN - zero warnings, all tests green

# Work on password hashing in clean room (no failing tests from X)
# Fix ALL warnings and test failures before squashing
jj squash --from prereq-hashing-working --into prereq-hashing-accumulator

# Close prerequisite
bd close HASH-1

# Check what's ready
bd ready
# Shows: proj-1 is now ready

# Return to main work
jj edit proj-1-working
bd update proj-1 --status in_progress
```

### Nested Prerequisites
If Y needs Z first, repeat:
```bash
# Create nested prerequisite
bd create "Implement Z for Y" -t task -p 0
# Note issue ID (e.g., Z-1)

# Link dependency (Z-1 blocks HASH-1)
bd dep add HASH-1 Z-1

# Update statuses
bd update HASH-1 --status blocked
bd update Z-1 --status in_progress

# Create clean-room BEFORE HASH-1's accumulator
jj new --before prereq-hashing-accumulator -m "Z-1: Implement Z for Y"
jj new                                            # Create working change on top
jj bookmark create prereq-z-accumulator -r @-      # Bookmark the accumulator (parent)
jj bookmark create prereq-z-working -r @           # Bookmark the working change (current)

# FIRST: Verify clean starting state for prerequisite
# Run ALL tests (including integration tests, even if normally ignored)
npm test -- --run-ignored  # or your test command
# If ANY tests fail or warnings exist, fix them BEFORE implementing prerequisite
# Clean room means CLEAN - zero warnings, all tests green

# Work on Z, squash into accumulator
jj squash --from prereq-z-working --into prereq-z-accumulator
bd close Z-1

# Find next work
bd ready
# Shows: HASH-1 is now ready

# Return to Y
jj edit prereq-hashing-working
bd update HASH-1 --status in_progress
```

### Parallel Prerequisites
If a task needs multiple independent prerequisites:
```bash
# Example: WebSocket needs BOTH Redis AND auth service
# Neither blocks the other

# Create both prerequisites
bd create "Add Redis for pub/sub" -t task -p 0
bd create "Add auth service" -t task -p 0
# Note IDs (e.g., REDIS-1, AUTH-1)

# Both block the parent
bd dep add HASH-1 REDIS-1
bd dep add HASH-1 AUTH-1

# Update statuses
bd update HASH-1 --status blocked
bd update REDIS-1 --status in_progress
bd update AUTH-1 --status in_progress

# Work on first (Redis) - create BEFORE HASH-1's accumulator
jj new --before prereq-hashing-accumulator -m "REDIS-1: Add Redis for pub/sub"
jj new                                            # Create working change on top
jj bookmark create prereq-redis-accumulator -r @-      # Bookmark the accumulator (parent)
jj bookmark create prereq-redis-working -r @           # Bookmark the working change (current)

# FIRST: Verify clean starting state for prerequisite
# Run ALL tests (including integration tests, even if normally ignored)
npm test -- --run-ignored  # or your test command
# If ANY tests fail or warnings exist, fix them BEFORE implementing prerequisite
# Clean room means CLEAN - zero warnings, all tests green

# Complete, squash, close
jj squash --from prereq-redis-working --into prereq-redis-accumulator
bd close REDIS-1

# Work on second (auth) - create BEFORE HASH-1's accumulator
jj new --before prereq-hashing-accumulator -m "AUTH-1: Add auth service"
jj new                                            # Create working change on top
jj bookmark create prereq-auth-accumulator -r @-      # Bookmark the accumulator (parent)
jj bookmark create prereq-auth-working -r @           # Bookmark the working change (current)

# FIRST: Verify clean starting state for prerequisite
# Run ALL tests (including integration tests, even if normally ignored)
npm test -- --run-ignored  # or your test command
# If ANY tests fail or warnings exist, fix them BEFORE implementing prerequisite
# Clean room means CLEAN - zero warnings, all tests green

# Complete, squash, close
jj squash --from prereq-auth-working --into prereq-auth-accumulator
bd close AUTH-1

# Both done? Check with bd ready
bd ready
# Shows: HASH-1 is ready (all blockers resolved)
```

### Finding Ready Work
Use beads to discover what you can work on:
```bash
bd ready          # Shows issues with no blockers
bd show proj-1    # See dependencies and status
bd dep tree proj-1  # Visualize dependency tree
```

### Removing Unneeded Prerequisites
If you realize a prerequisite isn't actually needed:
```bash
# Remove the dependency link
bd dep rm proj-1 proj-2

# Close the unnecessary prerequisite
bd close proj-2 --reason "Not needed after all"

# Delete the jj bookmark
jj bookmark delete proj-2

# Update parent status if now unblocked
bd ready  # Check if parent is ready
bd update proj-1 --status in_progress
```

### Completion
When goal is achieved:
```bash
bd close proj-1
jj bookmark delete proj-1 proj-2 proj-3
# Resume jj-change-workflow
```

## Why Clean Room Matters

**Problem:** Implementing Y while X has 5 failing tests and incomplete code is hard. Noise distracts focus.

**Solution:** Create Y in isolation where tests pass and code is clean. Then apply it to X.

**Result:** Faster implementation, clearer thinking, better tests.

## Accumulator + Working Pattern

**Every task has TWO bookmarks:**

1. **Accumulator** (`proj-X-accumulator`): Collects completed, clean work
2. **Working** (`proj-X-working`): Active work-in-progress

**Why this pattern:**
- Working change can be messy (failing tests, incomplete code)
- Accumulator stays clean (only squash when tests pass, no warnings)
- Prerequisites go BEFORE accumulator, not before working
- This keeps prerequisites isolated from your messy WIP

**Flow:**
```
main → accumulator (clean) → working (messy WIP)
                  ↑
         Prerequisites insert here
```

## JJ Semantics Notes

**Work-in-progress handling:**
- `jj new` automatically saves your current change before creating new one
- Your work is never lost - it's in the change you were just working on
- `jj new --before` preserves your work and creates prerequisite below it

**Priority in beads:**
- Lower number = higher priority (0 is highest, 4 is lowest)
- Nested prerequisites typically get higher priority (lower numbers)
- Goal typically has lower priority (higher number)
- Example: Goal=2, Prereq=1, Nested=0

## Clean Room Standard: No Warnings, No Failing Tests

Before squashing a prerequisite, it MUST be completely clean:

**Required:**
- All tests pass (unit AND integration tests for the prerequisite)
- Zero warnings (TypeScript, linter, compiler warnings)
- Code is complete and ready to use

**Do NOT squash with:**
- "Minor" warnings that "can be fixed later"
- Failing tests that "aren't critical"
- "Quick fixes" that can wait

**Why this matters:**
- Warnings are debt - they multiply when you ignore them
- Failed tests mean incomplete work - don't pretend it's done
- Clean prerequisites integrate cleanly - dirty ones cause friction

**Pre-existing issues (before you started):**
- Unrelated failing tests elsewhere: Ignore for your prerequisite
- Warnings in other files: Not your problem right now
- These shouldn't block your work

**Your new code must be clean. No exceptions.**

## "But It's Just a 1-Line Function!"

**Rationalization:** "This helper is trivial, Mikado is overkill."

**Reality:** Even 1-line functions benefit from clean room:
- Write it without X's failing tests distracting you
- Test it independently before using it in X
- Takes 20 seconds to set up Mikado, saves mental context-switching
- Separate commit makes history clearer

**The workflow is not ceremony.** It's 4 commands total:
```bash
jj new --before accumulator -m "PREREQ: Add formatDate helper"
jj new
# write 1-line function, test it
jj squash
```

**Don't rationalize:** "Too simple" is never a reason to skip clean room. Use it for ALL prerequisites.

## Quick Reference

| Situation | Commands |
|-----------|----------|
| Start Mikado | `bd create "Goal"` → `jj commit -m "ID: Goal"` → `jj new` → `jj bookmark create ID-accumulator -r @-` → `jj bookmark create ID-working -r @` → `bd update ID --status in_progress` |
| Hit prerequisite | `bd create "Prereq description"` → `bd dep add GOAL PREREQ` → `bd update GOAL --status blocked` → `bd update PREREQ --status in_progress` → `jj new --before GOAL-accumulator -m "PREREQ: ..."` → `jj new` → `jj bookmark create prereq-reason-accumulator -r @-` → `jj bookmark create prereq-reason-working -r @` → **Run all tests + fix warnings** |
| Save checkpoint | `jj squash --from prereq-reason-working --into prereq-reason-accumulator` → `bd close PREREQ` |
| Find next work | `bd ready` |
| Return to work | `jj edit ID-working` → `bd update ID --status in_progress` |
| Check structure | `bd dep tree ID` (shows full dependency chain) |
| Check status | `bd show ID` (shows blockers and status) |
| Finish | `bd close ID` → `jj bookmark delete ID-accumulator ID-working prereq-*` |

## Visualization

**JJ structure:**
```bash
jj log
# Shows:
@  (empty)                                    # prereq-z-working bookmark
○  Z-1: Implement Z                           # prereq-z-accumulator bookmark
○  (empty)                                    # prereq-hashing-working bookmark
○  HASH-1: Implement Y                        # prereq-hashing-accumulator bookmark
○  (empty)                                    # proj-1-working bookmark (blocked)
○  proj-1: Add feature X                      # proj-1-accumulator bookmark
○  main
```

**Key insight:** Prerequisites (HASH-1, Z-1) are inserted BEFORE their parent's accumulator, creating clean isolation.

**Beads structure:**
```bash
bd dep tree proj-1
# Shows:
proj-1: Add feature X [blocked]
└─ blocks ← HASH-1: Implement Y [blocked]
   └─ blocks ← Z-1: Implement Z [in_progress]

bd ready
# Shows:
In progress:
  Z-1 (in_progress) - Implement Z
```

## Common Mistakes

| Mistake | Reality | Fix |
|---------|---------|-----|
| "Do prerequisite in current messy change" | Working with failing tests is slow | Use clean-room via Mikado |
| "It's just 1 line, skip Mikado" | Even 1-liners benefit from clean room | Use Mikado for ALL prerequisites |
| "No exploration needed, too simple" | Clean room helps even when you know what to do | Workflow takes 30 seconds, always worth it |
| "This is pure ceremony" | 6 commands total, not ceremony | Follow the workflow |
| **Create prerequisite on top of working** | **Prerequisite includes broken code, unavailable to blocked work** | **Always use `--before ACCUMULATOR` bookmark** |
| Forget accumulator/working bookmarks | Can't squash cleanly, lose isolation | Every task needs both bookmarks |
| Use `--before working` instead of `--before accumulator` | Prerequisite in wrong place | Prerequisites go BEFORE accumulator |
| **Skip verification after creating prerequisite** | **Start implementing on unclean base, propagate existing issues** | **Run all tests + fix warnings IMMEDIATELY after creating prerequisite** |
| Squash with warnings present | "Minor" warnings multiply into major debt | Fix ALL warnings before squashing |
| Squash with failing tests | Tests exist to define "done" - failing = not done | All tests must pass before squashing |
| "Warnings aren't blocking" | Ignoring warnings trains bad habits | Zero warnings or don't squash |
| Refactor before GREEN | Refactoring while RED is dangerous | RED → GREEN → REFACTOR, always |
| Forget to create beads issue | Can't track state or dependencies | Always create issue first |
| Forget to link dependency | Can't use `bd ready` to find work | Always `bd dep add` |
| Forget to update status | Beads shows wrong state | Always update after state changes |
| Forget to close issue | Prerequisites appear still in progress | Always `bd close` when done |
| Skip `bd ready` check | Might work on blocked tasks | Always check what's ready first |
| Forget issue ID in commit | Can't link git to beads | Always include ID in commit message |

## When to Use

**Use Mikado when:** ANY time you think "would be easier if I had Y first"

**Why:** Even single prerequisites benefit from clean-room isolation. Creating Y without X's failing tests is faster.

**Integration:** Pairs with jj-change-workflow, using-jj-vcs

## Red Flags

**STOP if you catch yourself thinking:**
- "It's just 1 line, skip the workflow"
- "No exploration needed, too simple"
- "This is pure ceremony"
- "Too much overhead for a trivial helper"
- Implementing prerequisite with failing tests in background
- Using linear changes instead of `--before`
- **Creating prerequisite without `--before` (stacking on top)**
- **Using `--before working` instead of `--before accumulator`**
- **Forgetting to create accumulator/working bookmarks**
- **"I'll check tests after I start implementing"**
- **"Skip verification, the base is probably clean"**
- **"Just start coding, verify later"**
- Not creating beads issues for prerequisites
- Not linking dependencies with `bd dep add`
- Guessing what to work on instead of using `bd ready`
- **"These warnings are minor, I'll fix them later"**
- **"Tests pass for the core functionality, warnings don't matter"**
- **"I'll squash now and clean up in a follow-up"**
- **"Let me refactor before fixing the test"**
- **"I don't need to track this in beads, it's obvious"**
- **"I'll update the beads status later"**

**All of these mean: Stop rationalizing. Follow the Mikado workflow.**

**No exceptions. Not for 1-liners. Not for "trivial" helpers. Not for "minor" warnings. Not ever.**
