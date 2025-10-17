
---
name: Mikado Method
description: Manage complex refactorings using JJ's change graph to discover
when_to_use: when attempting large refactorings with unclear dependencies, o
version: 1.0.0
---

# Mikado Method

## Overview

Use JJ's change graph to represent the Mikado dependency graph, where each r

**Core principle:** Try → Discover blockers → Mark blocked → Insert prerequi

**Result:** Clean commit history where all prerequisites are properly ordere

**Announce at start:** "I'm using the Mikado Method skill to manage this ref

## The Pattern

**Try implementation** → Hit blocker → **Mark `[BLOCKED]`** → **Insert prere

The code stays working (tests pass) at every accumulator checkpoint. Working

## Prerequisites

This skill **extends** the JJ Task Workflow. You should already know:
- Basic JJ operations (`new`, `squash`, `commit`, `log`, `edit`)
- The accumulator + working change pattern
- How to checkpoint progress with `jj squash`

**New concepts this skill adds:**
- Discovering prerequisites through attempted implementation
- Using `jj new --before` and `jj new --after` to insert prerequisites
- Managing a dependency graph instead of linear tasks
- The explore-revert-map cycle from traditional Mikado Method
- Using change descriptions to track state

**Related skill:** `skills/collaboration/jj-task-workflow`

## State Management

### Change Description Conventions

Use consistent prefixes to make state clear in `jj log`:

**Accumulators:**
- Goal: `"Refactor X to use Y"` (imperative, describes the change)
- Prerequisite: `"Prerequisite: Extract interface for Z"` (prefix with "Prer

**Working Changes:**
- Active (at `@`): `"(empty) (no description set)"` or no description
- Blocked/Waiting: `"[BLOCKED] Refactor X to use Y"` (prefix with "[BLOCKED]

### Example Graph

```
@  working-on-prereq   (empty) (no description set)
○  prereq-accumulator  Prerequisite: Extract interface B
│ ○  blocked-working   [BLOCKED] Refactor class A to use interface
│ ○  goal-accumulator  Refactor class A to use interface
├─╯
○  main
```

This shows the dependency chain: **main → prereq-accumulator → goal-accumula

The prerequisite was inserted before the goal using `jj new --before <goal>`
- Goal accumulator depends on prerequisite accumulator
- Currently working on prerequisite (at `@`)
- Prerequisite accumulator (waiting for squash)
- Blocked working change branches from goal (waiting for prerequisite to com
- Goal accumulator sits between prerequisite and main

## The Mikado Cycle

### Starting a Mikado Refactoring

1. **Create goal accumulator:**
   ```bash
   jj new main -m "Refactor X to use Y"
   ```

2. **Create working change:**
   ```bash
   jj new
   ```

3. **Verify setup:**
   ```bash
   jj log -n 3
   ```
   Expected: `main -> [goal] -> [working@]`

### Attempting Implementation (Explore)

1. Make changes in working change to achieve the goal
2. Run tests
3. Discover what breaks or what's missing
4. **Timebox: 5-10 minutes** before deciding something is a prerequisite

**Red flags for thrashing:**
- Trying multiple variations of the same fix
- "Maybe if I just..." thinking
- Same compilation errors coming back
- Temptation to "just fix this one thing"

**When thrashing:** Stop immediately, identify prerequisite, switch to prere

### When Blocked by Prerequisites

1. **Identify the prerequisite:** What needs to exist first?

2. **Check dependency:** Does this prerequisite depend on another open prere

3. **Mark current work as blocked:**
   ```bash
   jj describe -m "[BLOCKED] <what you were trying>"
   ```

4. **Insert prerequisite:**
   - If depends on another prereq:
     ```bash
     jj new --after <other-prereq-id> -m "Prerequisite: <description>"
     ```
   - If independent:
     ```bash
     jj new --before <goal-id> -m "Prerequisite: <description>"
     ```

5. **Create working change on prerequisite:**
   ```bash
   jj new
   ```

6. **Switch focus:** Now work on the prerequisite using the same cycle

### Completing a Prerequisite

1. **When tests pass, checkpoint:**
   ```bash
   jj squash
   ```

2. **Verify complete:** Check tests still pass at the prerequisite accumulat

3. **Return to blocked work:**
   ```bash
   jj edit <blocked-working-change-id>
   ```

4. **Remove blocked marker:**
   ```bash
   jj describe -m ""
   ```

5. **Try again:** Implementation may now succeed, or reveal more prerequisit

### Completing the Goal

1. **When all prerequisites done:** All accumulators have content, no `[BLOC

2. **Tests pass at goal accumulator**

3. **Final checkpoint:**
   ```bash
   jj squash
   ```

4. **Result:** Clean commit history with prerequisites properly ordered

## Graph Structures

### Linear Prerequisites (Dependent)

When prerequisite B depends on prerequisite A, create a chain:

```
main -> [Prereq A] -> [Prereq B] -> [Goal]
```

Command sequence:
```bash
jj new --before <goal> -m "Prerequisite: A"
# Work on A, complete it
jj new --after <prereq-A> -m "Prerequisite: B"
# Work on B, complete it
```

### Octopus Prerequisites (Independent)

When prerequisites A and B are independent, insert both before goal:

```
main -> [Prereq A] ⟍
     -> [Prereq B] --> [Goal]
```

Command sequence:
```bash
jj new --before <goal> -m "Prerequisite: A"
# Work on A, complete it
jj new --before <goal> -m "Prerequisite: B"
# Work on B, complete it
```

**Git Compatibility Note:** This creates an octopus merge in Git (commit wit

### Deep Prerequisites (Recursive)

When a prerequisite itself has prerequisites:

```
main -> [Prereq B] -> [Prereq A] -> [BLOCKED A]
                            ⟍
                              -> [Goal] -> [BLOCKED Goal]
```

Just apply the same cycle recursively - mark A's work as blocked, insert B b

### Hybrid Example

Real refactorings often mix linear and octopus:

```
main -> [Prereq A] -> [Prereq B] ⟍
                  -> [Prereq C] --> [Goal]
```

Here B depends on A (linear), but C is independent of both (octopus).

## Common Patterns

### Pattern 1: Simple Prerequisite Chain

**Scenario:** Try to refactor class A, discover you need to extract interfac

**Steps:**
1. Start: `main -> [Refactor class A] -> [@]`
2. Try refactoring, discover blocker
3. Mark blocked: `jj describe -m "[BLOCKED] Refactor class A"`
4. Insert prerequisite: `jj new --before <refactor-A> -m "Prerequisite: Extr
5. Create working change: `jj new`
6. Work on interface, complete: `jj squash`
7. Resume: `jj edit <blocked-change>`, `jj describe -m ""`
8. Try again, succeed: `jj squash` into goal

### Pattern 2: Multiple Independent Prerequisites

**Scenario:** Refactoring needs both a new interface AND a helper function,

**Steps:**
1. Try goal, discover need interface
2. Insert: `jj new --before <goal> -m "Prerequisite: Extract interface"`
3. Work on interface, discover also need helper
4. Check: Does helper depend on interface? No.
5. Insert parallel: `jj new --before <goal> -m "Prerequisite: Add helper fun
6. Work both prerequisites to completion
7. Resume goal (now has both prerequisites available)

**Result:** Octopus merge in Git with 2 independent prerequisites.

### Pattern 3: Deep Prerequisite Discovery

**Scenario:** While working on Prerequisite A, discover it needs Prerequisit

**Steps:**
1. Working on Prerequisite A, discover need B
2. Mark A blocked: `jj describe -m "[BLOCKED] Prerequisite A"`
3. Insert B: `jj new --before <prereq-A> -m "Prerequisite: B"`
4. Create working change: `jj new`
5. Complete B: `jj squash`
6. Resume A: `jj edit <blocked-A>`, `jj describe -m ""`
7. Complete A: `jj squash`
8. Resume goal: Now has both B and A available

**Result:** Linear chain `main -> [B] -> [A] -> [Goal]`

## Guidelines and Best Practices

### When to Use Mikado vs Simple Task Workflow

**Use Mikado when:**
- You try a change and discover unexpected blockers
- Working in unfamiliar/legacy code with unclear dependencies
- Refactoring affects multiple modules/layers
- You want to explore before committing to an approach

**Use Simple Task Workflow when:**
- Requirements are clear and sequential
- You know the steps ahead of time
- Working in familiar code
- Implementing features vs refactoring structure

### Keeping the Graph Manageable

**Do:**
- Timebox exploration: 5-10 minutes trying before marking blocked
- One level deep: Discover immediate blockers, don't recurse endlessly
- Limit parallel prerequisites: More than 3-4 parallel becomes unwieldy
- Descriptive names: "Prerequisite: X" should be specific
- Visualize often: `jj log` frequently to see graph structure

**Don't:**
- Thrash on implementation when blocked
- Create prerequisites for minor refactorings
- Mix Mikado and Task Workflow patterns in same graph
- Forget to mark changes as `[BLOCKED]` when switching

### Recognizing Prerequisites vs Bugs

**It's a prerequisite when:**
- Missing abstraction/interface
- Circular dependency needs breaking
- Module coupling too tight
- Tests reveal architectural issues

**It's a bug/mistake when:**
- Typo or syntax error
- Logic error in your implementation
- Forgot to import something
- Wrong function signature

Fix bugs immediately; turn missing architecture into prerequisites.

### Helpful Commands

```bash
# See the full Mikado graph
jj log

# See just your current branch
jj log -r ::@

# Find blocked working changes
jj log -r 'description(BLOCKED)'

# Return to a specific change
jj edit <change-id>

# See what changed in a prerequisite
jj diff -r <prereq-id>
```

## Related Skills

**Builds directly on:**
- `skills/collaboration/jj-task-workflow` - Core accumulator/working change pattern
- `skills/collaboration/using-jj-version-control` - Basic JJ operations

**Complements:**
- `skills/testing/test-driven-development` - Tests reveal blockers quickly
- `skills/debugging/systematic-debugging` - When stuck, debug vs add prerequisite
- `skills/architecture/preserving-productive-tensions` - Some "prerequisites" might be design alternatives

**When to switch skills:**
- Prerequisites become long list → Reconsider refactoring approach
- Thrashing on implementation → Use `systematic-debugging` to understand blocker
- Discovering fundamental design issues → Restart with `brainstorming`

## Success Criteria

**You've successfully used Mikado when:**
- All accumulators have content (prerequisites completed)
- No `[BLOCKED]` working changes remain
- Tests pass at goal accumulator
- Graph shows clean dependency structure in `jj log`
- Commit history is linear or simple octopus (not tangled)

**Signs you might be misusing Mikado:**
- More than 5-6 parallel prerequisites (octopus overload)
- Prerequisites that are really just "refactor everything"
- Graph depth more than 3-4 levels (might need better goal decomposition)
- Spending more time managing graph than coding