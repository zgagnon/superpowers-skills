---
name: Getting Started with Skills
description: Skills wiki intro - mandatory workflows, search tool, brainstorming triggers, personal skills
when_to_use: Read this FIRST at start of each conversation when skills are active
version: 3.1.0
---

# Getting Started with Skills

## Mandatory Workflow 1: Brainstorming Before Coding

**When your human partner wants to start a project, no matter how big or small:**

**YOU MUST immediately read:** skills/collaboration/brainstorming

**Don't:**
- Jump straight to code
- Wait for /brainstorm command
- Skip brainstorming because you "understand the idea"

**Why:** Just jumping into implementation is almost never the right first step. We always understand requirements and plan first.

## Mandatory Workflow 2: Before ANY Task

**1. Check the skills list** shown at session start, or run `find-skills [PATTERN]` to filter.

**2. Check if historical context would help:**
Review Workflow 3 conditions. If applicable, dispatch subagent to search past work.

**If a relevant skill exists, you MUST use it. Using a skill means:**

1. **READ the full skill file** - `${SUPERPOWERS_SKILLS_ROOT}/skills/path/SKILL.md`
2. **ANNOUNCE usage** - "I'm using the [Skill Name] skill to [what you're doing]"
3. **FOLLOW the skill** - Many contain rigid requirements you must follow exactly

**Don't:**
- Assume you know what the skill says without reading it
- Read just the frontmatter or overview
- Skip reading because "I remember this skill"
- Work from memory of what the skill used to say

**Why:** Skills evolve. The current version might have critical updates. Reading the full skill file is non-negotiable.

**"This doesn't count as a task" is rationalization.** Skills exist and you didn't search for them or didn't use them = failed task.

## Workflow 3: Historical Context Search (Conditional)

**When:** Your human partner mentions past work, issue feels familiar, starting task in familiar domain, stuck/blocked, before reinventing

**When NOT:** Info in current convo, codebase state questions, first encounter, partner wants fresh thinking

**How (use subagent for 50-100x context savings):**
1. Dispatch subagent with template: `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/remembering-conversations/tool/prompts/search-agent.md`
2. Receive synthesis (200-1000 words) + source pointers
3. Apply insights (never load raw .jsonl files)

**Example:**
```
Partner: "How did we handle auth errors in React Router?"
You: Searching past conversations...
[Dispatch subagent → 350-word synthesis]
[Apply without loading 50k tokens]
```

**Red flags:** Reading .jsonl files directly, pasting excerpts, asking "which conversation?", browsing archives

**Pattern:** Search → Subagent synthesizes → Apply. Fast, focused, context-efficient.

## Announcing Skill Usage

**Every time you start using a skill, announce it:**

"I'm using the [Skill Name] skill to [what you're doing]."

**Examples:**
- "I'm using the Brainstorming skill to refine your idea into a design."
- "I'm using the Test-Driven Development skill to implement this feature."
- "I'm using the Systematic Debugging skill to find the root cause."
- "I'm using the Refactoring Safely skill to extract these methods."

**Why:** Transparency helps your human partner understand your process and catch errors early.

## Skills with Checklists

**If a skill contains a checklist, you MUST create TodoWrite todos for EACH checklist item.**

**Don't:**
- Work through checklist mentally
- Skip creating todos "to save time"
- Batch multiple items into one todo
- Mark complete without doing them

**Why:** Checklists without TodoWrite tracking = steps get skipped. Every time.

**Examples:** TDD (write test, watch fail, implement, verify), Systematic Debugging (4 phases), Writing Skills (RED-GREEN-REFACTOR)

## Writing Skills

**Want to document a technique, pattern, or tool for reuse?**

See skills/meta/writing-skills for the complete TDD process for documentation.

## How to Read a Skill

1. **Frontmatter** - `when_to_use` match your situation?
2. **Overview** - Core principle relevant?
3. **Quick Reference** - Scan for your pattern
4. **Implementation** - Full details
5. **Supporting files** - Load only when implementing

**Many skills contain rigid rules (TDD, debugging, verification).** Follow them exactly. Don't adapt away the discipline.

**Some skills are flexible patterns (architecture, naming).** Adapt core principles to your context.

The skill itself tells you which type it is.

## Instructions ≠ Permission to Skip Workflows

Your human partner's specific instructions describe WHAT to do, not HOW.

"Add X", "Fix Y" = the goal, NOT permission to skip brainstorming, TDD, or RED-GREEN-REFACTOR.

**Red flags:** "Instruction was specific" • "Seems simple" • "Workflow is overkill"

## Summary

**Starting conversation?** You just read this. Good.

**Starting any task?**
1. Run find-skills to check for relevant skills
2. If relevant skill exists → READ the full SKILL.md file
3. Announce you're using the skill
4. Follow what it says

**Skill has checklist?** TodoWrite for every item.

**Finding a relevant skill = mandatory to read and use it. Not optional.**
