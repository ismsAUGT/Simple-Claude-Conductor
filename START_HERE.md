# Welcome to Simple Claude Conductor!

This tool helps you build software projects using Claude AI, even if you have no coding experience!

## What To Do

1. **Fill out this form below** (replace the `_____` blanks with your answers)
2. **Save this file** (press Ctrl+S or File > Save)
3. **Double-click INITIALIZE_MY_PROJECT.bat** to set everything up
4. **Double-click RUN_PROJECT.bat** to start working with Claude

That's it! Let's get started.

---

## Step 1: How Will You Use Claude?

You need either a Claude subscription OR an API key (not both).

**Option A: I have a Claude Pro or Max subscription** (Recommended - easier!)
If you pay for Claude at claude.ai, use this option.

    USE_SUBSCRIPTION: YES

**Option B: I have an Anthropic API key**
If you have a developer API key from console.anthropic.com, enter it below.

    USE_SUBSCRIPTION: NO
    API_KEY: _____

---

## Step 2: What Do You Want to Build?

**Project Name:** (Give your project a short name)

    PROJECT_NAME: _____

**Describe What You Want:** (Be as detailed as possible - the more detail, the better!)

    PROJECT_DESCRIPTION: _____

**Example descriptions:**
- "Build a simple website with a contact form that sends emails"
- "Create a Python script that organizes my photos by date"
- "Make a to-do list app where I can add, complete, and delete tasks"

---

## Step 3: How Should Claude Work? (Optional - defaults are fine!)

These settings control how Claude builds your project. The defaults work great for most people.

**Should Claude ask you questions before starting?**
- YES = Claude will ask clarifying questions first (Recommended for complex projects)
- NO = Claude will make reasonable assumptions and start immediately

    ASK_QUESTIONS: NO

**AI Model to Use:**
- SONNET = Balanced speed and quality (Recommended)
- HAIKU = Faster and cheaper, good for simple projects
- OPUS = Most capable, best for complex projects

    MODEL: SONNET

---

## Step 4: Code Quality Checks (Optional - for developers)

These are for people who know about testing and code quality.
**Skip this section if you're not sure - leaving them as NO is perfectly fine!**

**Run automated tests?** (Checks if your code works correctly)

    RUN_TESTS: NO

**Check for type errors?** (Finds potential bugs in code)

    TYPECHECK: NO

**Run code style checker?** (Makes code follow best practices)

    LINT: NO

---

## Step 5: Do You Have Sample Files? (Optional)

If you have **example files, documentation, or samples** you want Claude to reference, put them in the **File_References_For_Your_Project** folder.

**Examples of helpful files:**
- Sample documents or templates to mimic
- API documentation
- Screenshots of desired layouts
- Example code
- Data files to process

**Where to put them:** Open the `File_References_For_Your_Project` folder and drop your files there.

**Don't have any reference files?** No problem! Just skip this step. Claude will work from your description alone.

---

## Step 6: You're Ready!

1. **Save this file** (Ctrl+S or File > Save)

2. **Run the setup:**
   - Find **INITIALIZE_MY_PROJECT.bat** in this folder
   - Double-click it to run
   - Follow the prompts in the window that opens

3. **What happens next:**
   - The setup will configure everything for you
   - If you chose subscription login, a browser will open to sign in
   - Once complete, you'll see instructions for starting your project

---

## Need Help?

- **Stuck?** Check the README.md file for detailed documentation
- **Questions?** Visit https://github.com/anthropics/claude-code for Claude Code help
- **Found a bug?** Report it at the project's GitHub issues page
