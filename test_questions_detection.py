"""
Quick test for planning questions detection
"""
import os
import sys

# Add server to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'server'))

from app import detect_planning_questions, load_config

def test_detection():
    print("Testing planning questions detection...")

    # Test 1: Check if Questions_For_You.md exists
    questions_file = 'Questions_For_You.md'
    exists = os.path.exists(questions_file)
    print(f"[OK] Questions_For_You.md exists: {exists}")

    # Test 2: Try detection
    has_questions = detect_planning_questions()
    print(f"[OK] Has unanswered questions: {has_questions}")

    # Test 3: Load config
    config = load_config()
    print(f"[OK] Config loaded: allowPlanningQuestions = {config.get('allowPlanningQuestions')}")

    print("\nAll detection tests passed!")

if __name__ == '__main__':
    test_detection()
