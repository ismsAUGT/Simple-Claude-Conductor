---
name: prompt-understanding
description: Understand the user's request before planning. Assess domain familiarity, research if needed, clarify ambiguities.
---

## Purpose

Before planning any task, ensure you truly understand:
1. What the user actually wants (the "job to be done")
2. Whether you're familiar enough with the domain to proceed
3. What ambiguities need clarification

This skill prevents "garbage in, garbage out" by catching misunderstandings before they propagate through planning and execution.

## When to Run This Skill

**ALWAYS** run this skill:
- At the start of any new project or task
- Before generating phases in task-plan.md
- When resuming work after a long pause

**DO NOT** skip this skill, even for seemingly simple tasks.

## Process

### Step 1: Analyze the Request

Read the user's request carefully and answer:

1. **What is being asked for?**
   - What is the desired end result?
   - What form should the output take?

2. **What are the inputs?**
   - What materials, data, or context has the user provided?
   - What's in `File_References_For_Your_Project/`?

3. **What are the constraints?**
   - Are there time, cost, or quality requirements?
   - Are there specific technologies or approaches required?

4. **What is ambiguous or unclear?**
   - What assumptions would I need to make?
   - What could be interpreted multiple ways?

### Step 2: Assess Domain Familiarity

Ask yourself honestly:

> "Do I understand this domain well enough to produce expert-quality work?"

Rate your familiarity:

| Level | Description | Action |
|-------|-------------|--------|
| **High** | I know the terminology, best practices, and common pitfalls | Proceed to planning |
| **Medium** | I recognize the domain but have gaps in specialized knowledge | Light research (3 WebSearches) |
| **Low** | This domain has unfamiliar terminology or concepts | Full research (5+ WebSearches) |

**Key questions to assess familiarity:**
- Can I define the key terms in this domain?
- Do I know what "good" looks like for this type of work?
- Would a domain expert approve my approach?
- What would an expert know that I might not?

### Step 3: Research (If Needed)

If familiarity is Medium or Low:

1. **Identify knowledge gaps**
   - List specific terms, concepts, or practices you're unsure about

2. **Conduct targeted research**
   - Use WebSearch for each knowledge gap
   - Focus on: terminology definitions, best practices, common mistakes
   - Time limit: 2 minutes maximum

3. **Document findings**
   - Record what you learned in findings.md
   - Note sources for reference

### Step 4: Clarify Ambiguities

Check `project.yaml` for the `interrupt_for_questions` setting:

**If `interrupt_for_questions: true`:**
- Write questions to `Questions_For_You.md`
- Format each question clearly with context for why it matters
- Wait for user response before proceeding

**If `interrupt_for_questions: false`:**
- Document your assumptions in findings.md
- Proceed with the most reasonable interpretation
- Flag assumptions for user review later

### Step 5: Document Understanding

Update `findings.md` with a **Domain Understanding** section:

```markdown
## Domain Understanding

### What is the Job to Be Done?
[Clear, specific statement of what the user actually needs - not just a copy of their request]

### Domain Familiarity Assessment
**Level**: [High / Medium / Low]
**Reasoning**: [Why you rated it this way]

### Key Terminology
[If researched, list important terms and their meanings]
- **Term 1**: Definition
- **Term 2**: Definition

### Research Conducted
[If applicable, list WebSearches performed]
- Search: "[query]" - Key finding: [what you learned]

### Assumptions Made
[List any assumptions, especially if questions weren't asked]
- Assumption 1: [what you assumed and why]

### Remaining Uncertainties
[What you still don't know - be honest]
- [Uncertainty 1]
- [Uncertainty 2]
```

## Outputs

After running this skill, you must have:

1. **findings.md** with populated "Domain Understanding" section
2. **Clear statement** of the job to be done (in findings.md and task-plan.md Goal)
3. **Questions_For_You.md** with clarifying questions (if applicable)
4. **Documented assumptions** (if questions were skipped)

## Quality Checklist

Before proceeding to planning, verify:

- [ ] Domain Understanding section exists in findings.md
- [ ] Job to be done is clearly stated (not just copied from user request)
- [ ] Familiarity level is honestly assessed
- [ ] Research was conducted if familiarity was Medium or Low
- [ ] Ambiguities are either clarified or documented as assumptions
- [ ] Remaining uncertainties are acknowledged

## Examples

### Good Domain Understanding

```markdown
## Domain Understanding

### What is the Job to Be Done?
Create a Python script that reads customer transaction data from a CSV file,
identifies customers who haven't made a purchase in 90+ days, and generates
a formatted report for the marketing team to use for re-engagement campaigns.

### Domain Familiarity Assessment
**Level**: High
**Reasoning**: Standard data processing task using familiar tools (Python, pandas, CSV).
No specialized domain knowledge required beyond basic business logic.

### Assumptions Made
- "90+ days" means 90 calendar days from today's date
- Report format should be CSV (user didn't specify, but mentioned "for marketing team")
- "Transaction data" includes at minimum: customer ID, transaction date, amount

### Remaining Uncertainties
- Should the report include customer contact information? (Proceeding without it, can add later)
```

### Bad Domain Understanding (Don't Do This)

```markdown
## Domain Understanding

### What is the Job to Be Done?
Help user with their request.

### Domain Familiarity Assessment
**Level**: High
**Reasoning**: I can do this.
```

This is checkbox compliance, not genuine understanding. It provides no value.

## Common Mistakes to Avoid

1. **Copying the user's request verbatim** - Restate it in your own words to prove understanding
2. **Claiming high familiarity without justification** - Be honest about gaps
3. **Skipping research to save time** - 2 minutes of research prevents hours of rework
4. **Not documenting assumptions** - Undocumented assumptions cause problems later
5. **Asking obvious questions** - Only ask questions that genuinely affect the approach
