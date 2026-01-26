# Planning Questions Feature - Quick Reference

## What Is This?

A new feature for Simple Claude Conductor that allows Claude to ask clarifying questions during plan generation. Users can answer questions to get a more refined plan, or skip them to let Claude proceed with reasonable assumptions.

## Quick Start

### Enable the Feature

1. Open the conductor UI: `http://localhost:5002`
2. In the "Configure Project" section, check the box:
   - ☑ "Allow Claude to ask clarifying questions when generating the plan"
3. Save configuration

### How It Works

1. **Generate Plan** - Click "Generate Plan" as usual
2. **Questions Appear** - If Claude has questions, you'll see a new card
3. **Choose Action:**
   - **Open Questions File** - Opens `Questions_For_You.md` in your editor
   - **Continue (I've Answered)** - Refine plan with your answers
   - **Skip Questions** - Let Claude proceed with assumptions

### Question Format

When Claude writes questions, they look like this:

```markdown
### Question 1: Database Choice
Which database do you want to use?

**Your Answer:** _____
```

Fill in the blank after `**Your Answer:**` and save the file.

## Configuration

**File:** `config/project-config.json`

```json
{
  "allowPlanningQuestions": true
}
```

Set to `false` to disable the feature entirely.

## Technical Details

### New State

- **State:** `plan_questions`
- **Trigger:** Questions detected after plan generation
- **Next States:** `planning` (refinement) or `planned` (skip)

### API Endpoints

- `POST /api/actions/refine-plan` - Refine plan with answers
- `GET /api/questions/open` - Open questions file

### Files Modified

1. `server/state_manager.py` - State machine
2. `server/app.py` - Backend logic
3. `server/static/js/api.js` - API client
4. `server/static/js/app.js` - Frontend logic
5. `server/templates/conductor.html` - UI
6. `CLAUDE.md` - Documentation

## Testing

### Automated Tests

```bash
# Test question detection
python test_questions_detection.py

# Validate implementation
python validate_implementation.py
```

### Manual Testing

See `test_planning_questions.md` for comprehensive checklist.

## Troubleshooting

### Questions not appearing?

1. Check if `allowPlanningQuestions: true` in config
2. Verify `Questions_For_You.md` has unanswered questions
3. Check format: `**Your Answer:** _____` (3+ underscores)

### Can't open questions file?

- Windows: File opens with default `.md` editor
- Mac: Opens with default app for `.md` files
- Linux: Uses `xdg-open`

### Refinement not working?

1. Check console for errors
2. Verify questions file exists
3. Look for error state in UI
4. Check Flask server logs

## Known Limitations

1. Must use external editor (no in-browser editing)
2. Questions only detected once (not iterative)
3. Format-dependent (specific markdown syntax required)

## Future Enhancements

- In-browser question forms
- Multiple question rounds
- Question templates
- Answer validation
- Question analytics

## Documentation

- **Full Implementation Details:** `IMPLEMENTATION_SUMMARY.md`
- **Testing Checklist:** `test_planning_questions.md`
- **User Documentation:** `CLAUDE.md` (Planning Questions Workflow section)
- **Status:** `STATUS.md`

## Support

For issues or questions:
1. Check `CLAUDE.md` for workflow details
2. Review `IMPLEMENTATION_SUMMARY.md` for technical details
3. Use `test_planning_questions.md` for testing guidance

---

**Status:** ✅ Complete and Ready for Testing
**Last Updated:** 2026-01-26
