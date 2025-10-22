---
name: using-superpowers
description: Use when starting any conversation - establishes mandatory workflows for finding and using skills, including using Read tool before announcing usage, following brainstorming before coding, and creating TodoWrite todos for checklists
---

# Getting Started with Skills

## Critical Rules

1. **Follow mandatory workflows.** Brainstorming before coding. Check for relevant skills before ANY task.

2. **Skills are documentation, not commands.** Read skills with the Read tool (`skills/skill-name/SKILL.md`). A few skills have slash commands (`/superpowers:brainstorm`, `/superpowers:write-plan`, `/superpowers:execute-plan`) but most don't - you read and follow them directly

## Mandatory: Before ANY Task

### The Skill Discovery Checklist

For EVERY user request, create these TodoWrite todos BEFORE any other action:

1. **Check available skills** (Look at Skill tool's available skills list)
2. **Match task to skills** (Does user's request match any skill's description?)
3. **If match found: Read the skill** (Use Read tool on skill file)
4. **If match found: Announce usage** ("I'm using [Skill] to [purpose]")
5. **Proceed with task** (Follow skill if found, or proceed directly)

**Create ALL five todos immediately. Mark them as you go.**

**Multiple tasks?** If user provides multiple distinct tasks (e.g., "Add auth, fix tests, write docs"), the FIRST task gets the 5-step checklist. After completing task 1, when you start task 2, you repeat the checklist. Each distinct task triggers skill discovery independently.

**Don't rationalize:**
- "I already know the skills" - The list grows. Check every time.
- "This will slow me down" - 10 seconds now vs hours debugging later.
- "I need context first" - Check skills THEN gather context.
- "This is too simple" - Simple tasks are where agents skip skills most.
- "I'll check if I get stuck" - By then you've already gone down wrong path.
- "Skills are for complex problems" - Skills apply to ALL matching problems.
- "The user wants speed" - Following proven approaches IS speed.
- "I'll batch skill checking for all tasks" - Each task needs independent discovery.

**Why this checklist matters:** Without external forcing function, agents skip skill discovery 80%+ of the time. TodoWrite makes it structurally impossible to skip.

**1. If a relevant skill exists, YOU MUST use it:**

- Announce: "I've read [Skill Name] skill and I'm using it to [purpose]"
- Follow it exactly

**Don't rationalize:**
- "I remember this skill" - Skills evolve. Read the current version.
- "This doesn't count as a task" - It counts. Find and read skills.

**Why:** Skills document proven techniques that save time and prevent mistakes. Not using available skills means repeating solved problems and making known errors.

If a skill for your task exists, you must use it or you will fail at your task.

## Skills with Checklists

If a skill has a checklist, YOU MUST create TodoWrite todos for EACH item.

**Don't:**
- Work through checklist mentally
- Skip creating todos "to save time"
- Batch multiple items into one todo
- Mark complete without doing them

**Why:** Checklists without TodoWrite tracking = steps get skipped. Every time. The overhead of TodoWrite is tiny compared to the cost of missing steps.

## Announcing Skill Usage

Before using a skill, announce that you are using it.
"I'm using [Skill Name] to [what you're doing]."

**Examples:**
- "I'm using the Brainstorming skill  to refine your idea into a design."
- "I'm using the Test-Driven Development skill  to implement this feature."

**Why:** Transparency helps your human partner understand your process and catch errors early. It also confirms you actually read the skill.

# About these skills

**Many skills contain rigid rules (TDD, debugging, verification).** Follow them exactly. Don't adapt away the discipline.

**Some skills are flexible patterns (architecture, naming).** Adapt core principles to your context.

The skill itself tells you which type it is.

## Instructions ≠ Permission to Skip Workflows

Your human partner's specific instructions describe WHAT to do, not HOW.

"Add X", "Fix Y" = the goal, NOT permission to skip brainstorming, TDD, or RED-GREEN-REFACTOR.

**Red flags:** "Instruction was specific" • "Seems simple" • "Workflow is overkill"

**Why:** Specific instructions mean clear requirements, which is when workflows matter MOST. Skipping process on "simple" tasks is how simple tasks become complex problems.

## Summary

**Starting any task:**
1. If relevant skill exists → Use the skill
3. Announce you're using it
4. Follow what it says

**Skill has checklist?** TodoWrite for every item.

**Finding a relevant skill = mandatory to read and use it. Not optional.**
