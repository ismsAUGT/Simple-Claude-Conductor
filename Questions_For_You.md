# Questions For You

**Status**: Awaiting your input on folder reorganization

---

## Questions

### Question 1: Folder Structure Approach

I've analyzed the current structure and have a proposal. The project is actually already well-organized! Most files users don't touch are already in subfolders (.claude/, docs/, scripts/).

**My recommendation**: Keep it simple with minimal changes:
- Add `File_References_For_Your_Project/` folder at root (for user input files)
- Keep all other files where they are
- Update CLAUDE.md to reference the new folder

**Alternative**: Create a more dramatic reorganization by moving system files around, but this may complicate the batch scripts and documentation unnecessarily.

**Your Answer:** Do you prefer the minimal approach (just add the reference folder) or a more dramatic reorganization? If dramatic, please describe what structure you envision.

---

### Question 2: Naming Convention

For the user reference folder, which name do you prefer?

A. `File_References_For_Your_Project/` (descriptive, clear purpose)
B. `reference_files/` (shorter, lowercase)
C. `input_files/` (simple, matches output/)
D. `project_files/` (generic)
E. Something else?

**Your Answer:** _____

---

### Question 3: README Location

Should I update the README.md to include a "What Files Do I Use?" section that clearly lists:
- Files you interact with (START_HERE.md, batch files, etc.)
- Files you don't need to touch (system files)

**Your Answer:** Yes / No / Other suggestion

---

## Instructions

1. Read each question above
2. Type your answers below each question
3. Save this file (Ctrl+S)
4. Go back to the terminal and press Enter to continue

Don't want to answer? Just press Enter in the terminal and I'll make reasonable assumptions.
