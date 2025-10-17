---
name: Mikado-Workflow
description: Use when discovering a prerequisite during any work - provides workflow for tracking and implementing prerequisites using jj bookmarks and --before flag, creating clean-room isolation for easier implementation
---

# Mikado Workflow

## Overview

**When you realize "This would be easier if I had Y first", use Mikado workflow to create Y in a clean-room environment.**

Clean-room = no failing tests, no incomplete work, just focused prerequisite implementation.

**Core principle:** Prerequisites created in isolation are faster and clearer than prerequisites created amid noise.

**Announce at start:** "I'm using the Mikado Workflow skill to handle this prerequisite."

## The Workflow

### Setup (Initial Goal)
```bash
jj commit -m "Add feature X"          # Describe goal
jj bookmark create accumulator @-     # Mark goal change
jj bookmark create working            # Mark current empty as working
```

### Discovering Prerequisites
When you realize "X would be easier if I had Y first":
```bash
jj describe -m "[BLOCKED] Add feature X"                    # Mark working as blocked
jj new --before accumulator -m "PREREQ: Implement Y"       # Insert before goal
jj new                                                       # Anonymous working change
# Work on Y in clean room (no failing tests from X)
jj squash                                                    # Save when done
jj edit working                                              # Return to main work
jj describe -m ""                                            # Clear [BLOCKED]
```

### Nested Prerequisites
If Y needs Z first, repeat:
```bash
jj describe -m "[BLOCKED] PREREQ: Implement Y"
jj new --before accumulator -m "PREREQ: Implement Z for Y"
jj new
# Work on Z, squash
jj edit working
jj describe -m ""
```

### Completion
When working is empty (goal achieved):
```bash
jj bookmark delete working accumulator
# Resume jj-change-workflow
```

## Why Clean Room Matters

**Problem:** Implementing Y while X has 5 failing tests and incomplete code is hard. Noise distracts focus.

**Solution:** Create Y in isolation where tests pass and code is clean. Then apply it to X.

**Result:** Faster implementation, clearer thinking, better tests.

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

| Situation | Command |
|-----------|---------|
| Start Mikado | `jj commit -m "Goal"` → `jj bookmark create accumulator @-` → `jj bookmark create working` |
| Hit prerequisite | `jj describe -m "[BLOCKED] ..."` → `jj new --before accumulator -m "PREREQ: ..."` → `jj new` |
| Save checkpoint | `jj squash` |
| Return to work | `jj edit working` → `jj describe -m ""` |
| Check structure | `jj log` (PREREQs before accumulator, working marked [BLOCKED] when blocked) |
| Finish | `jj bookmark delete working accumulator` |

## Visualization

```bash
jj log
# Shows:
@  (empty)                          # Current work
○  PREREQ: Z
○  PREREQ: Y
│ ○  [BLOCKED] Add feature X        # Waiting (working bookmark)
│ ○  Add feature X                  # Goal (accumulator bookmark)
├─╯
○  main
```

## Common Mistakes

| Mistake | Reality | Fix |
|---------|---------|-----|
| "Do prerequisite in current messy change" | Working with failing tests is slow | Use clean-room via Mikado |
| "It's just 1 line, skip Mikado" | Even 1-liners benefit from clean room | Use Mikado for ALL prerequisites |
| "No exploration needed, too simple" | Clean room helps even when you know what to do | Workflow takes 20 seconds, always worth it |
| "This is pure ceremony" | 4 commands total, not ceremony | Follow the workflow |
| Forget "PREREQ:" prefix | Can't identify prerequisites in jj log | Always prefix prerequisites |
| Forget "[BLOCKED]" marker | Lose track of state | Mark working when switching |
| Work in prerequisite change directly | Leaves change dirty | Always `jj new` after `jj new --before` |
| Forget `jj edit working` | Get lost | Always return to working bookmark |
| Delete bookmarks early | Lose navigation | Only when working is empty |

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
- No bookmarks to track goal vs work
- Working change has content when switching

**All of these mean: Stop rationalizing. Follow the Mikado workflow.**

**No exceptions. Not for 1-liners. Not for "trivial" helpers. Not ever.**
