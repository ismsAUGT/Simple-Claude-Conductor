# Findings

## Domain Understanding

### What is the Job to Be Done?
Build a local web UI (localhost:8080) that guides non-technical users through the Simple Claude Conductor workflow without requiring them to:
- Open a terminal manually
- Edit markdown files
- Remember any commands
- Switch between multiple files

### Domain Familiarity Assessment
**Level**: Medium → High (after research)

**Reasoning**:
- Flask/Python web servers: High familiarity
- Windows batch scripting: High familiarity
- Claude Code CLI integration: High familiarity
- Portable Python on Windows: Researched - now understood

### Key Terminology
- **Embeddable Python**: Official minimal Python distribution (~15MB) from python.org designed to be bundled with applications
- **WinPython**: Third-party portable Python distribution with scientific packages
- **Flask**: Lightweight Python web framework for building HTTP APIs and serving HTML
- **settings.local.json**: Claude Code's per-project permission configuration file

### Research Conducted
1. **Search**: "Python embeddable package Windows portable distribution 2025"
   - Key finding: Python.org provides official "Windows embeddable package" that runs without installation
   - Source: https://www.python.org/downloads/windows/

2. **Search**: "WinPython portable Python Windows no install required 2025"
   - Key finding: WinPython offers portable distributions but are larger
   - Source: https://winpython.github.io/

### Decision: Python Embeddable Package

**Chosen approach**: Use official Python Embeddable Package because:
- Smaller footprint (~15MB base + Flask deps = ~25-30MB total)
- Official, well-documented
- Sufficient for our needs (just Flask)
- Fits within ~50MB budget

### Assumptions Made
1. Python 3.12.x is acceptable
2. 64-bit only
3. Flask is sufficient (no need for FastAPI)
4. Permissions file goes in .claude/settings.local.json
5. Terminal window stays open for Claude output visibility

## References
- [UI_OVERHAUL_PLAN.md](UI_OVERHAUL_PLAN.md) - Main plan document
- [COMPREHENSIVE_PERMISSIONS.md](COMPREHENSIVE_PERMISSIONS.md) - Full permissions list
- [Python Downloads](https://www.python.org/downloads/windows/) - Embeddable package source
