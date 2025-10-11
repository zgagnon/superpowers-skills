---
name: Getting Started with Skills
description: Skills wiki intro - mandatory workflows, search tool, brainstorming triggers, personal skills
when_to_use: Read this FIRST at start of each conversation when skills are active
version: 3.2.0
---

# Getting Started with Skills

## Mandatory Workflow 1: Brainstorming Before Coding

**When your human partner wants to start a project, no matter how big or small:**

**FIRST: Read the brainstorming skill**
- Use the Read tool to load `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/brainstorming/SKILL.md`
- Read the full file before proceeding

**THEN: Announce and follow it**
- "I've read the Brainstorming skill and I'm using it to [refine your idea/understand requirements/etc]"
- Follow the skill's process exactly

**Don't:**
- Jump straight to code
- Wait for /brainstorm command
- Skip brainstorming because you "understand the idea"
- Announce before reading the skill file

**Why:** Just jumping into implementation is almost never the right first step. We always understand requirements and plan first.

## Mandatory Workflow 2: Before ANY Task

**1. Check the skills list** shown at session start, or run `find-skills [PATTERN]` to filter.

**2. Check if historical context would help:**
Review Workflow 3 conditions. If applicable, dispatch subagent to search past work.

**If a relevant skill exists, you MUST use it. The workflow is:**

**FIRST: Read the skill file**
- Use the Read tool to load `${SUPERPOWERS_SKILLS_ROOT}/skills/path/SKILL.md`
- Read the ENTIRE file, not just frontmatter or overview
- **You cannot announce or use the skill until you've actually read it**

**THEN: Announce you're using it**
- "I've read the [Skill Name] skill and I'm using it to [what you're doing]"
- This announcement confirms you've completed the Read step

**THEN: Follow what it says**
- Many skills contain rigid requirements you must follow exactly
- If there's a checklist, create TodoWrite todos for each item

**Don't:**
- Announce before reading the full skill file with the Read tool
- Assume you know what the skill says without reading it
- Read just the frontmatter or overview
- Skip reading because "I remember this skill"
- Work from memory of what the skill used to say

**Why:** Skills evolve. The current version might have critical updates. You must actually use the Read tool before proceeding.

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

**After you've read a skill with the Read tool, announce you're using it:**

"I've read the [Skill Name] skill and I'm using it to [what you're doing]."

**Examples:**
- "I've read the Brainstorming skill and I'm using it to refine your idea into a design."
- "I've read the Test-Driven Development skill and I'm using it to implement this feature."
- "I've read the Systematic Debugging skill and I'm using it to find the root cause."
- "I've read the Refactoring Safely skill and I'm using it to extract these methods."

**The announcement confirms you've completed the Read step.** Never announce before reading the full SKILL.md file.

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
