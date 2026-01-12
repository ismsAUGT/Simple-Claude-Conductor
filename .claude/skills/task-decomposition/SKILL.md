---
name: task-decomposition
description: Break work into phases with explicit, verifiable success criteria.
---

## Purpose

Transform the understood job-to-be-done into an actionable plan where:
1. Work is broken into logical, manageable phases
2. Each phase has clear success criteria (not just descriptions)
3. Dependencies between phases are explicit
4. "What does done look like?" is answerable for every phase

## When to Run This Skill

Run this skill:
- After completing the `prompt-understanding` skill
- When generating or updating the plan in task-plan.md

**Prerequisite**: findings.md must have a populated "Domain Understanding" section.

## Process

### Step 1: Identify Major Phases

Based on the job to be done, identify the logical chunks of work:

1. **What are the natural breakpoints?**
   - Different types of work (research, implementation, testing)
   - Different outputs (document A, then document B)
   - Dependencies (X must happen before Y)

2. **How granular should phases be?**
   - Each phase should be completable in roughly 2-10 minutes
   - Too granular: Overhead of tracking exceeds value
   - Too coarse: Hard to validate, easy to miss issues

3. **What's the logical order?**
   - What depends on what?
   - What can be done in parallel vs sequentially?

### Step 2: Define Success Criteria for Each Phase

**This is the most important step.** For each phase, define how you'll know it's complete AND correct.

Success criteria must be:

| Property | Description | Example |
|----------|-------------|---------|
| **Specific** | Precise, not vague | "Report contains sections A, B, C" NOT "Report is complete" |
| **Verifiable** | Can be objectively checked | "All tests pass" NOT "Code works well" |
| **Relevant** | Actually indicates success | "User can log in" NOT "Login button exists" |

**Questions to derive success criteria:**
- What outputs will this phase produce?
- How will I verify each output is correct?
- What would make this phase a failure?
- What would a reviewer check?

### Step 3: Document the Plan

Update `task-plan.md` with the phase structure:

```markdown
## Phases

### Phase 1: [Phase Name]

**Status**: Not Started | In Progress | Complete

**Description**: [What work will be done in this phase]

**Success Criteria**:
- [ ] [Specific, verifiable criterion 1]
- [ ] [Specific, verifiable criterion 2]
- [ ] [Specific, verifiable criterion 3]

**Outputs**:
- [Output 1]: [Description]
- [Output 2]: [Description]

**Dependencies**: [What must be complete before this phase can start, or "None"]

---

### Phase 2: [Phase Name]
...
```

## Success Criteria Examples

### Good Success Criteria

**For a data processing phase:**
```markdown
**Success Criteria**:
- [ ] Script reads all rows from input CSV without errors
- [ ] Output contains exactly the columns: customer_id, last_purchase_date, days_inactive
- [ ] All dates are in YYYY-MM-DD format
- [ ] No null values in required fields
- [ ] Row count in output matches filtered count from input
```

**For a documentation phase:**
```markdown
**Success Criteria**:
- [ ] README contains: installation steps, usage examples, configuration options
- [ ] All code examples in README are tested and working
- [ ] No placeholder text (e.g., "TODO", "TBD") remains
```

**For an implementation phase:**
```markdown
**Success Criteria**:
- [ ] Function handles all specified input types (string, int, list)
- [ ] Function returns expected output format (dict with keys: status, data, error)
- [ ] Edge cases handled: empty input, null values, oversized input
- [ ] No unhandled exceptions possible with valid inputs
```

### Bad Success Criteria (Don't Do This)

```markdown
**Success Criteria**:
- [ ] Phase is complete
- [ ] Code works
- [ ] Output looks good
- [ ] No major issues
```

These are useless because they're not verifiable. Anyone can check a box and claim "code works."

## Phase Template

Copy this template for each phase:

```markdown
### Phase N: [Descriptive Name]

**Status**: Not Started

**Description**:
[2-3 sentences explaining what work will be done]

**Success Criteria**:
- [ ] [Criterion 1 - specific and verifiable]
- [ ] [Criterion 2 - specific and verifiable]
- [ ] [Criterion 3 - specific and verifiable]

**Outputs**:
- [File/artifact 1]: [What it contains]
- [File/artifact 2]: [What it contains]

**Dependencies**: [Phase X must be complete] or [None]

---
```

## Outputs

After running this skill, task-plan.md must have:

1. **Goal section** - Clear statement of job to be done
2. **Phases section** - All phases with the required structure
3. **Each phase must include**:
   - Descriptive name
   - Status indicator
   - Description of work
   - Specific success criteria (not vague)
   - Expected outputs
   - Dependencies

## Quality Checklist

Before proceeding to execution, verify:

- [ ] Every phase has 2+ specific success criteria
- [ ] Success criteria are verifiable (can be objectively checked)
- [ ] Dependencies are documented
- [ ] Phases are appropriately sized (2-10 minutes each)
- [ ] "What does done look like?" is clear for each phase
- [ ] No vague criteria like "works correctly" or "is complete"

## Common Mistakes to Avoid

1. **Skipping success criteria** - Phases without criteria can't be validated
2. **Vague criteria** - "Works well" isn't verifiable
3. **Too many phases** - Overhead of tracking exceeds value
4. **Too few phases** - Hard to validate large chunks of work
5. **Missing dependencies** - Causes confusion about execution order
6. **Criteria that don't match the phase** - Criteria should verify this phase's work specifically
