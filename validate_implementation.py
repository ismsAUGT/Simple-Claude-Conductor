"""
Validation script for Planning Questions Feature implementation
"""
import os
import re

def check_file_contains(filepath, patterns, description):
    """Check if file contains all patterns"""
    print(f"\nChecking {description}...")

    if not os.path.exists(filepath):
        print(f"  [FAIL] File not found: {filepath}")
        return False

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    all_found = True
    for pattern in patterns:
        if isinstance(pattern, str):
            found = pattern in content
        else:  # regex
            found = bool(re.search(pattern, content))

        status = "[OK]" if found else "[FAIL]"
        pattern_str = pattern if isinstance(pattern, str) else pattern.pattern
        print(f"  {status} {pattern_str[:60]}...")

        if not found:
            all_found = False

    return all_found

def main():
    print("="*60)
    print("VALIDATING PLANNING QUESTIONS FEATURE IMPLEMENTATION")
    print("="*60)

    checks = []

    # Phase 1: Backend State Machine
    checks.append(check_file_contains(
        'server/state_manager.py',
        [
            "'plan_questions'",
            "'questions_found': 'plan_questions'",
            "'refine_plan': 'planning'",
        ],
        "Phase 1: State Machine Extensions"
    ))

    # Phase 2: Backend API
    checks.append(check_file_contains(
        'server/app.py',
        [
            "def load_config():",
            "def detect_planning_questions():",
            "@app.route('/api/actions/refine-plan'",
            "@app.route('/api/questions/open')",
            "detect_planning_questions()",
        ],
        "Phase 2: Backend API Endpoints"
    ))

    # Phase 3: Frontend API
    checks.append(check_file_contains(
        'server/static/js/api.js',
        [
            "refinePlan(skipped)",
            "openQuestionsFile()",
        ],
        "Phase 3: Frontend API Integration"
    ))

    # Phase 3: Frontend App
    checks.append(check_file_contains(
        'server/static/js/app.js',
        [
            "allowPlanningQuestions:",
            "get showPlanQuestions()",
            "'plan_questions':",
            "continueAfterQuestions(skipped)",
            "openQuestionsFile()",
        ],
        "Phase 3: Frontend App Integration"
    ))

    # Phase 4: Frontend UI
    checks.append(check_file_contains(
        'server/templates/conductor.html',
        [
            "x-model=\"config.allowPlanningQuestions\"",
            "x-show=\"showPlanQuestions\"",
            "@click=\"openQuestionsFile()\"",
            "@click=\"continueAfterQuestions(false)\"",
            "@click=\"continueAfterQuestions(true)\"",
        ],
        "Phase 4: Frontend UI Components"
    ))

    # Phase 5: Documentation
    checks.append(check_file_contains(
        'CLAUDE.md',
        [
            "## Planning Questions Workflow",
            "**Your Answer:** _____",
            "allowPlanningQuestions",
            "plan_questions",
        ],
        "Phase 5: CLAUDE.md Documentation"
    ))

    # Summary
    print("\n" + "="*60)
    passed = sum(checks)
    total = len(checks)
    print(f"SUMMARY: {passed}/{total} phases validated")

    if passed == total:
        print("✓ All phases implemented successfully!")
        return 0
    else:
        print("✗ Some checks failed - review output above")
        return 1

if __name__ == '__main__':
    exit(main())
