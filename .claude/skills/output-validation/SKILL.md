---
name: output-validation
description: Verify outputs meet success criteria and make semantic sense before marking work complete.
---

## Purpose

Before marking any phase complete, verify:
1. Success criteria from task-plan.md are actually met
2. Outputs make semantic sense (not just well-formatted)
3. You can justify why each output is correct
4. Issues are flagged for user review

This skill prevents false completion and catches errors before they compound.

## When to Run This Skill

**ALWAYS** run this skill:
- After completing execution work for a phase
- Before marking any phase as "Complete" in task-plan.md
- Before moving to the next phase

**DO NOT** mark a phase complete without running validation.

## Process

### Step 1: Retrieve Success Criteria

1. Open task-plan.md
2. Find the current phase
3. List all success criteria for this phase

### Step 2: Check Each Criterion

For each success criterion:

| Check | Action |
|-------|--------|
| **Met** | Document specific evidence that it's met |
| **Not Met** | Document what's missing, fix before proceeding |
| **Partial** | Document what's done and what remains |

**Evidence format:**
```markdown
- [x] Criterion: "Script reads all rows from input CSV"
  - **Evidence**: Tested with sample.csv (1,247 rows), all parsed successfully, log shows "1247 rows processed"
```

Do not just check boxes. Provide evidence.

### Step 3: Semantic Spot-Check

Select 5-10 representative outputs and verify they make sense:

1. **Pick diverse samples** - Not just the first few, but varied examples
2. **For each sample, ask:**
   - Does this output make sense for the task?
   - Can I explain WHY this is correct?
   - Would a domain expert approve this?

3. **Document your reasoning:**
```markdown
**Spot-Check Results:**

Sample 1: [identifier]
- Output: [what was produced]
- Justification: [why this is correct]
- Status: Justified / Flagged

Sample 2: [identifier]
- Output: [what was produced]
- Justification: [why this is correct]
- Status: Justified / Flagged
```

4. **If you cannot justify an output:**
   - Flag it explicitly
   - Do NOT claim it's correct
   - Document your uncertainty

### Step 4: Confidence Assessment

For the overall phase, assess your confidence:

| Confidence | Criteria | Action |
|------------|----------|--------|
| **High (80-100%)** | All criteria met with evidence, all samples justified | Can mark complete |
| **Medium (60-79%)** | Most criteria met, some samples flagged | Review flagged items, may mark complete with caveats |
| **Low (<60%)** | Multiple criteria not met or many samples unjustified | Do NOT mark complete, fix issues first |

**Confidence rules:**
- Only claim >80% if you can cite specific evidence
- If you have doubts, lower your confidence
- Better to flag and be wrong than miss real issues

### Step 5: Document Validation Results

Add a validation entry to progress.md:

```markdown
## Validation: Phase N - [Phase Name]

**Date**: [timestamp]
**Overall Confidence**: [X%]
**Status**: Pass / Pass with Caveats / Fail

### Success Criteria Check

- [x] Criterion 1
  - Evidence: [specific evidence]
- [x] Criterion 2
  - Evidence: [specific evidence]
- [ ] Criterion 3 (NOT MET)
  - Issue: [what's missing]

### Spot-Check Results

| Sample | Output | Justification | Status |
|--------|--------|---------------|--------|
| 1 | [output] | [why correct] | Justified |
| 2 | [output] | [why correct] | Justified |
| 3 | [output] | [uncertain] | FLAGGED |

### Flagged Items for Review

- [Item 1]: [why it's flagged, what's uncertain]
- [Item 2]: [why it's flagged, what's uncertain]

### Conclusion

[Summary: Is this phase ready to mark complete? What caveats exist?]
```

### Step 6: Decide Next Action

Based on validation results:

| Result | Action |
|--------|--------|
| **Pass** | Mark phase complete, proceed to next phase |
| **Pass with Caveats** | Mark complete, document caveats in STATUS.md, user should review flagged items |
| **Fail** | Do NOT mark complete, fix issues, re-run validation |

## Outputs

After running this skill:

1. **progress.md** - Contains validation entry for this phase
2. **STATUS.md** - Updated with validation results and any flagged items
3. **Clear decision** - Phase marked complete OR issues documented for fixing

## Quality Checklist

Before marking a phase complete:

- [ ] All success criteria checked with evidence (not just checkmarks)
- [ ] 5-10 outputs spot-checked with justification
- [ ] Flagged items clearly documented
- [ ] Confidence level is honest and justified
- [ ] Validation entry added to progress.md

## Examples

### Good Validation

```markdown
## Validation: Phase 2 - Data Processing

**Date**: 2026-01-11 14:30
**Overall Confidence**: 85%
**Status**: Pass with Caveats

### Success Criteria Check

- [x] Script reads all rows from input CSV without errors
  - Evidence: Processed customers.csv with 15,847 rows, log shows "15847 rows read, 0 errors"
- [x] Output contains required columns
  - Evidence: Verified output.csv headers: customer_id, last_purchase_date, days_inactive
- [x] All dates in YYYY-MM-DD format
  - Evidence: Sampled 100 random rows, all dates match pattern \d{4}-\d{2}-\d{2}
- [x] No null values in required fields
  - Evidence: Ran null check, 0 nulls in customer_id and last_purchase_date. 3 nulls in days_inactive (expected for new customers)

### Spot-Check Results

| Sample | customer_id | days_inactive | Justification | Status |
|--------|-------------|---------------|---------------|--------|
| Row 1 | C-10045 | 127 | Last purchase 2025-09-07, today is 2026-01-12. 127 days correct. | Justified |
| Row 2 | C-28891 | 45 | Last purchase 2025-11-27. 45 days correct. | Justified |
| Row 3 | C-00012 | 892 | Last purchase 2023-08-03. 892 days = ~2.4 years. Seems high but mathematically correct. | Justified |
| Row 4 | C-55123 | NULL | New customer, no purchases. NULL is expected per spec. | Justified |
| Row 5 | C-99001 | 0 | Last purchase today. 0 days correct. | Justified |

### Flagged Items for Review

- None. All samples justified.

### Conclusion

Phase complete. Data processing working correctly. Minor note: 3 customers have NULL days_inactive because they're new customers with no purchase history. This is expected behavior.
```

### Bad Validation (Don't Do This)

```markdown
## Validation: Phase 2

- [x] Done
- [x] Works
- [x] Looks good

Confidence: 95%
```

This provides no evidence. It's checkbox compliance, not validation.

## Common Mistakes to Avoid

1. **Checking boxes without evidence** - Always document HOW you verified
2. **Only checking easy cases** - Sample diverse outputs, including edge cases
3. **Claiming high confidence without justification** - Evidence required for >80%
4. **Not flagging uncertainties** - When in doubt, flag it
5. **Skipping validation to save time** - Validation catches errors early, saving time overall
6. **Copying success criteria as evidence** - Evidence must show the criterion is MET, not just repeat it
