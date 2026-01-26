# Planning Questions Feature - Testing Checklist

## Test Environment Setup
- [ ] Flask server running on port 5002
- [ ] Browser open to http://localhost:5002
- [ ] config/project-config.json has allowPlanningQuestions: true

## Phase 1: Backend State Machine Extensions

### State Machine Tests
- [ ] `plan_questions` exists in VALID_STATES (check state_manager.py)
- [ ] Transitions defined: planning → plan_questions
- [ ] Transitions defined: plan_questions → planning
- [ ] Transitions defined: plan_questions → planned
- [ ] Transitions defined: plan_questions → error

### Detection Functions
- [ ] `load_config()` successfully reads project-config.json
- [ ] `load_config()` returns default allowPlanningQuestions=true if not set
- [ ] `detect_planning_questions()` returns True for unanswered questions
- [ ] `detect_planning_questions()` returns False if no Questions_For_You.md
- [ ] `detect_planning_questions()` returns False if all questions answered

### On-Exit Callback
- [ ] After planning, checks for questions when allowPlanningQuestions=true
- [ ] Transitions to plan_questions when questions detected
- [ ] Transitions to planned when no questions detected
- [ ] Transitions to planned when allowPlanningQuestions=false

## Phase 2: Backend API Endpoints

### /api/actions/refine-plan Endpoint
- [ ] POST request accepted
- [ ] Accepts `skipped: false` parameter
- [ ] Accepts `skipped: true` parameter
- [ ] Returns 400 if Claude already running
- [ ] Returns 200 with PID on success
- [ ] Starts Claude subprocess
- [ ] Uses correct prompt when skipped=false
- [ ] Uses correct prompt when skipped=true
- [ ] On exit, transitions to planned with phase count

### /api/questions/open Endpoint
- [ ] GET request accepted
- [ ] Opens Questions_For_You.md in default editor
- [ ] Returns 404 if file doesn't exist
- [ ] Returns 200 on success

## Phase 3: Frontend State & API Integration

### API Client (api.js)
- [ ] `api.refinePlan(false)` calls /api/actions/refine-plan with skipped=false
- [ ] `api.refinePlan(true)` calls /api/actions/refine-plan with skipped=true
- [ ] `api.openQuestionsFile()` calls /api/questions/open

### Alpine App (app.js)
- [ ] `showPlanQuestions` computed property returns true when state=plan_questions
- [ ] `showPlanQuestions` returns false for other states
- [ ] `statusTitle` shows "Questions About Your Project" for plan_questions
- [ ] `config.allowPlanningQuestions` persists in config
- [ ] `openQuestionsFile()` method calls API without errors
- [ ] `continueAfterQuestions(false)` calls API with skipped=false
- [ ] `continueAfterQuestions(true)` shows confirmation and calls API with skipped=true

## Phase 4: Frontend UI Components

### Configuration Checkbox
- [ ] Checkbox visible in config form
- [ ] Checkbox bound to config.allowPlanningQuestions
- [ ] Checkbox state persists after save
- [ ] Checkbox state persists after page reload
- [ ] Help text explains the feature

### Planning Questions Card
- [ ] Card visible when state=plan_questions
- [ ] Card hidden when state is not plan_questions
- [ ] Header shows "Claude Has Questions About Your Project"
- [ ] Subtitle explains the workflow
- [ ] Activity box shows state.activity message
- [ ] "Open Questions File" button visible
- [ ] "Continue (I've Answered)" button visible
- [ ] "Skip Questions" button visible
- [ ] Buttons disabled when loading=true
- [ ] Card styling matches other cards

## Phase 5: CLAUDE.md Documentation

- [ ] Planning Questions Workflow section exists
- [ ] Format requirements documented (`**Your Answer:** _____`)
- [ ] When to ask questions guidance provided
- [ ] Examples included
- [ ] State flow diagram documented
- [ ] Questions_For_You.md section updated

## Phase 6: Integration Testing & Edge Cases

### Happy Path Test
1. [ ] Enable allowPlanningQuestions in config
2. [ ] Configure project (name, description)
3. [ ] Click "Generate Plan"
4. [ ] State transitions to planning
5. [ ] Create Questions_For_You.md with unanswered questions during planning
6. [ ] State transitions to plan_questions
7. [ ] Card displays with buttons
8. [ ] Click "Open Questions File" - file opens
9. [ ] Answer questions in file
10. [ ] Click "Continue (I've Answered)"
11. [ ] State transitions back to planning
12. [ ] Plan gets refined
13. [ ] State transitions to planned
14. [ ] Plan shows phases

### Skip Flow Test
1. [ ] Follow happy path steps 1-7
2. [ ] Click "Skip Questions"
3. [ ] Confirmation dialog appears
4. [ ] Confirm skip
5. [ ] State transitions to planning
6. [ ] Plan gets finalized
7. [ ] State transitions to planned

### Disabled Flow Test
1. [ ] Disable allowPlanningQuestions in config
2. [ ] Configure project
3. [ ] Click "Generate Plan"
4. [ ] Even if questions written, state skips to planned directly
5. [ ] No plan_questions card shown

### Edge Cases

#### Missing Questions File
- [ ] If Questions_For_You.md doesn't exist, no crash
- [ ] State transitions to planned normally

#### Empty Questions File
- [ ] If Questions_For_You.md is empty, no crash
- [ ] State transitions to planned normally

#### Malformed Questions File
- [ ] If file has invalid format, no crash
- [ ] Detection returns false gracefully

#### Partial Answers
- [ ] If some questions answered, some blank, detection works
- [ ] Can still refine with partial answers

#### Refinement Failure
- [ ] If refinement exits with error code, state → error
- [ ] Error message shown to user
- [ ] Can retry from error state

#### Server Restart
- [ ] Stop server while in plan_questions state
- [ ] Restart server
- [ ] State persists (from STATUS.md YAML)
- [ ] Buttons still work

#### No Phases After Refinement
- [ ] If refinement doesn't produce phases, state → error
- [ ] Error message shown

## Test Results Summary

**Date Tested:** ___________
**Tester:** ___________

**Total Tests:** 80+
**Passed:** ___________
**Failed:** ___________
**Blocked:** ___________

**Critical Issues Found:**
1.
2.
3.

**Notes:**
