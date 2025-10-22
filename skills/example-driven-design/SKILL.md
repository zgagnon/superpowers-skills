---
name: example-driven-design
description: Use when creating or developing anything and before writing code or implementation plans - discovers design through iterative examples in EXAMPLE → RED → GREEN → REFACTOR → CHECK cycle, with mandatory architectural critique enabling full design evolution
---

# Example-Driven Design

## Overview

Discover design through examples. Start from a user story, write wished-for API usage, evolve architecture through mandatory refactoring.

**Core principle:** Design emerges from examples, not upfront planning. Write how you wish it worked, make it real, critique and evolve.

**This skill REPLACES:** brainstorming skill
**This skill EXTENDS:** test-driven-development skill

**Announce at start:** "I'm using the example-driven design skill to discover the design through examples."

## When to Use

**Always use when:**
- Starting a new feature from a user story
- You have a rough idea but no clear design
- You want to explore API design options
- Creating anything where the "right" design isn't obvious

**Instead of:**
- Brainstorming designs upfront
- Writing implementation before examples
- Assuming you know the right architecture
- Skipping straight to TDD without design exploration

**Exceptions (ask your human partner):**
- Implementing a precisely specified external API
- Following a mandated architecture pattern
- Prototypes that will be thrown away

## The Iron Law

```
NO IMPLEMENTATION WITHOUT EXAMPLES FIRST
NO PROGRESSION WITHOUT COMPLETING ALL PHASES
```

## The Cycle

```
EXAMPLE → RED → GREEN → REFACTOR → CHECK
   ↓       ↓      ↓         ↓          ↓
 Design  Verify Minimal  Critique   Done or
  API    Fails   Code    Evolve     Recurse
```

Each phase MUST be completed before proceeding to the next.

### Phase 1: EXAMPLE - Write Wished-For Usage

Write example code showing how you wish the API worked.

**Checklist (use TodoWrite for each item):**

- [ ] **Understand user story** - Ask your human partner to clarify acceptance criteria if unclear
- [ ] **Write wished-for usage code** - Write 2-3 different API designs, ignoring implementation constraints
- [ ] **Present alternatives to partner** - Show the different API shapes you explored: "Here are 3 ways we could design this API. Which feels most natural?"
- [ ] **Iterate based on feedback** - Refine the chosen design with partner input
- [ ] **Show final example to partner** - "Does this example clearly show what the feature should do?"
- [ ] **Convert to test** - Add assertions and wrap in test function
- [ ] **Confirm test structure with partner** - "This test captures the example. Ready to proceed to RED phase?"

**Key conversations:**
- "What does this feature need to do?" (clarifying story)
- "Here are 3 API designs - which feels clearest?" (exploring alternatives)
- "Does this example feel natural to use?" (validating design)

**Good Example:**
```typescript
// EXAMPLE phase - exploring the API
const user = await authenticate({
  email: 'user@example.com',
  password: 'secret'
});
// This feels clean. Email/password object is clear.

// Now convert to test for RED phase
test('authenticates valid user', async () => {
  const user = await authenticate({
    email: 'user@example.com',
    password: 'secret'
  });
  expect(user.email).toBe('user@example.com');
  expect(user).toHaveProperty('id');
});
```

**Bad Example:**
```typescript
// Skipping straight to test without design exploration
test('auth works', async () => {
  const svc = new AuthService(
    new DatabaseConnection(),
    new Logger(),
    new ConfigManager()
  );
  const result = await svc.processAuthenticationRequest(request);
  // Never asked: "Is this the API we want?"
});
```

**Why this matters:**
- Design before constraints: Explore ideal API without implementation limits
- Multiple iterations: First idea rarely best
- Clarity test: If example is confusing, API is wrong

### Phase 2: RED - Verify Test Fails

Follow TDD skill RED phase exactly.

**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for RED phase details.

**Checklist (use TodoWrite for each item):**

- [ ] **Run the test** - Execute the test you just wrote
- [ ] **Verify it fails correctly** - Confirm failure message is expected (e.g., "function not defined")
- [ ] **Show failure to partner** - "The test fails with [error message]. This confirms we're testing the right thing."
- [ ] **If wrong failure** - Fix test and re-run until failure is correct

**Key conversation:**
- "Test fails as expected - ready to implement minimal code?"

### Phase 3: GREEN - Minimal Implementation

Follow TDD skill GREEN phase exactly.

**REQUIRED SUB-SKILL:** Use superpowers:test-driven-development for GREEN phase details.

**Checklist (use TodoWrite for each item):**

- [ ] **Write minimal implementation** - Simplest code to pass the test, no extra features
- [ ] **Run test** - Confirm it passes
- [ ] **Run all tests** - Verify no regressions
- [ ] **Show implementation to partner** - "Here's the minimal implementation. Test passes."
- [ ] **Resist feature creep** - If partner suggests additions, note them for future examples

**Key conversation:**
- "Implementation is minimal and tests pass - ready for REFACTOR phase?"

### Phase 4: REFACTOR - Design Critique and Evolution

**MANDATORY. This is where example-driven design differs from TDD.**

After tests pass, perform design critique to enable architectural evolution.

**Checklist (use TodoWrite for each item):**

- [ ] **Critique current design** - Examine against SRP, DRY, coupling, complexity
- [ ] **Share critique with partner** - "Looking at the current design: [observations]. Here are potential improvements..."
- [ ] **Consider alternatives** - Present 2-3 refactoring options if patterns emerged
- [ ] **Discuss with partner** - "Should we refactor now, or is this appropriate for the current examples?"
- [ ] **If refactoring** - Make changes while keeping all tests green
- [ ] **Show refactored code to partner** - "Here's the refactored design. Tests still pass."
- [ ] **Document decision** - Even if no refactor: explain why current design is appropriate

**Key conversations:**
- "Current design has [this structure]. I see opportunities to [refactoring options]. What do you think?" (proposing changes)
- "For just one example, this design is appropriate. We'll revisit when we add more examples." (conscious decision to defer)
- "The design now [how it changed] because [pattern that emerged]." (explaining refactoring)

**When to make big architectural changes:**
- After 2-3 examples: Patterns become visible
- When new example doesn't fit: Current architecture might be wrong
- When refactor keeps growing: Missing abstraction or wrong boundaries
- When code feels awkward: Listen to the pain

**Contrast with TDD refactor:**

| TDD Refactor | Example-Driven Refactor |
|--------------|------------------------|
| "Clean up duplication" | "Does this architecture serve the design?" |
| "Improve names" | "Should I restructure components?" |
| "Extract methods" | "Are these the right boundaries?" |
| Tactical cleanup | Strategic design evolution |

**Example Refactor Progression:**

```typescript
// After example 1: Simple function
async function authenticate(creds) { ... }

// After example 2: Errors emerge, extract validator
async function authenticate(creds) {
  validateCredentials(creds);
  ...
}

// After example 3: Multiple auth methods, restructure
class Authenticator {
  async withPassword(email, password) { ... }
  async withToken(token) { ... }
}
// Different architecture - listen to examples
```

**Don't skip this phase:**
- Can't say "nothing to refactor" without examining
- Must consciously critique design after every cycle
- Missing this = treating skill like plain TDD

### Phase 5: CHECK - Done or Recurse

**MANDATORY. Creates self-reinforcing loop.**

After REFACTOR, check if work is complete.

**Checklist (use TodoWrite for each item):**

- [ ] **List acceptance criteria** - Write out all criteria from the user story
- [ ] **Mark coverage** - Which criteria are covered by examples so far?
- [ ] **Discuss with partner** - "We've covered [X, Y]. Remaining: [Z]. Should we continue?"
- [ ] **Decision:**
  - **All covered?** → Ask partner: "All acceptance criteria met. Ready for completion checklist?"
  - **Some remain?** → **Use example-driven design skill again** for next example

**Key conversation:**
- "User story acceptance criteria: [list]. Covered: [X, Y]. Remaining: [Z]. Let's write the next example."

**Recursion pattern:**
```
Start with user story
↓
Use example-driven design skill
↓ (complete one full cycle)
REFACTOR done
↓
CHECK: Story satisfied?
  NO → Use skill again
  YES → Completion checklist
```

**Why explicit recursion matters:**
- Forces conscious decision: "Am I done?"
- Prevents premature completion
- Self-reinforcing: skill invokes itself until complete
- Creates natural checkpoints

**Example CHECK:**
```
User story: "Users can authenticate with email/password or OAuth"

After cycle 1: Email/password authentication
CHECK: OAuth not covered → Use skill again

After cycle 2: OAuth authentication
CHECK: All criteria covered → Completion checklist
```

## Completion Checklist

Before claiming work complete:

- [ ] Every acceptance criterion has examples
- [ ] Each example went through full EXAMPLE → RED → GREEN → REFACTOR → CHECK cycle
- [ ] EXAMPLE phase explored API design (not just wrote test)
- [ ] Every test failed before implementing
- [ ] Minimal code written (no YAGNI violations)
- [ ] REFACTOR phase performed design critique every cycle
- [ ] Final architecture feels appropriate for examples
- [ ] All tests pass
- [ ] No skipped phases

Can't check all boxes? You violated the process. Review and fix.

## Red Flags - STOP and Follow Process

If you catch yourself thinking:

**EXAMPLE phase violations:**
- "I know what API I want" → You're assuming, not exploring
- "Skip to test" → Missing design discovery
- "First design is fine" → Didn't iterate on API
- "Examples feel awkward but let's continue" → API is wrong, fix now
- "Start with the data structure" → Implementation before API exploration
- "Start with the basics" → You're coding before designing
- "Create the class first" → Skipped EXAMPLE phase

**RED/GREEN violations (inherit from TDD):**
- Code before test fails
- Test passes immediately
- "While I'm here" improvements

**REFACTOR phase violations:**
- "Nothing to refactor" without examining → Must critique design
- "Refactor later" → Mandatory now
- "Design is fine" after 1 example → Can't know yet
- Tests break during refactor → Steps too big
- "Current structure is good enough" → Did you consider alternatives?
- "Implementation complete" without refactoring → Skipped REFACTOR phase
- "Simple, clean, production-ready" without critique → No design examination

**CHECK phase violations:**
- "Probably done" → Check criteria explicitly
- "Just one more feature" without using skill → Must use skill
- Implementing without examples → Back to EXAMPLE phase
- "Ready for production" without checking criteria → Skipped CHECK phase
- "All tests pass" ≠ done → Must verify acceptance criteria coverage

**All of these mean: STOP. Return to appropriate phase.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I know the API already" | First idea rarely best. Explore alternatives. |
| "Example phase is just writing test" | No. Example explores design, test adds assertions. |
| "Start with the data structure/basics" | You're implementing before exploring API. Skipped EXAMPLE phase. |
| "Create the class first because I need it" | Implementation before design. Must write wished-for usage first. |
| "Nothing to refactor after 1 test" | Can't know if design is right with 1 example. Document reasoning. |
| "This is just TDD with extra steps" | TDD implements known design. This discovers unknown design. |
| "REFACTOR phase slows me down" | Continuous architecture evolution prevents big rewrites later. |
| "I'll refactor when I see duplication" | Wait for pain = wrong. Critique proactively. |
| "Simple, clean, production-ready" without critique | You haven't examined alternatives or considered evolution. |
| "Write comprehensive tests" after implementation | Tests after don't discover design. Examples first, then tests. |
| "Design is obvious from user story" | If obvious, examples will be quick. If not, you need this. |
| "Ready for production" without CHECK | Must explicitly verify acceptance criteria coverage. |
| "All tests pass" means done | Tests passing ≠ acceptance criteria met. Must CHECK explicitly. |
| "Can skip CHECK, I know what's left" | Explicit criteria check prevents premature completion. |

## Integration with Other Skills

**This skill requires:**
- **test-driven-development** - For RED and GREEN phase details (REQUIRED)

**This skill replaces:**
- **brainstorming** - No separate design phase, design emerges from examples

**Complementary skills:**
- **verification-before-completion** - After CHECK says done, verify everything works
- **requesting-code-review** - After completion, have design reviewed
- **systematic-debugging** - When tests fail unexpectedly during refactor

## Example: Complete Feature Flow

**User story:** "Users can search for products by name"

**Cycle 1:**

**EXAMPLE:**
```typescript
// What API do I want?
const results = await searchProducts('laptop');
// Simple! Just pass the term.

// Convert to test
test('finds products by name', async () => {
  const results = await searchProducts('laptop');
  expect(results).toHaveLength(2);
  expect(results[0].name).toContain('laptop');
});
```

**RED:** Run test → "searchProducts is not defined" ✓

**GREEN:**
```typescript
async function searchProducts(term: string) {
  return db.query('SELECT * FROM products WHERE name LIKE ?', `%${term}%`);
}
```

**REFACTOR:**
- Design critique: SQL in function is fine for 1 example
- Will this need to change? Probably, but wait for next example
- Decision: "Design appropriate for 1 example"

**CHECK:**
- Criteria: Search by name ✓
- Criteria: Filter results, pagination, etc.? (check story)
- If more criteria → Use skill again

**Cycle 2 (if needed):**

**EXAMPLE:**
```typescript
// What about filtering by price?
const results = await searchProducts('laptop', {
  minPrice: 500,
  maxPrice: 1500
});
// Hmm, second param for options feels natural
```

**RED/GREEN/REFACTOR:** Now patterns emerge, maybe restructure as class or separate query builder

**CHECK:** Continue until all criteria met

## Why This Works

**Design discovery:**
- Writing wished-for usage reveals what you actually want
- Multiple iterations find clearer APIs
- Examples expose design problems early

**Continuous evolution:**
- Mandatory refactor prevents design debt
- Architecture emerges from real usage patterns
- Small adjustments beat big rewrites

**Self-reinforcing:**
- CHECK phase creates explicit loop
- Can't skip phases without violating process
- Recursion prevents premature completion

## Final Rule

```
Feature idea → Use example-driven design skill
Complete cycle → CHECK
If not done → Use example-driven design skill again
```

No separate design phase. No implementation without examples. Design emerges.
