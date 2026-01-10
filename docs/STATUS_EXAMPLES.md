# STATUS.md Examples

This document shows example STATUS.md formats for different stages of a project. Use these as templates when updating STATUS.md.

---

## Example 1: Brand New Project (Not Initialized Yet)

```markdown
# Project Status: [Folder Name]

**Last Updated**: [Date]

---

## 👉 WHAT TO DO NEXT

**Welcome!** This project hasn't been initialized yet.

**Your Next Step:**

1. Open `START_HERE.md` and fill out the form
2. Double-click `INITIALIZE_MY_PROJECT.bat` to set everything up

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | No |
| Ready to Start | No |

---

**Need help?** Check [README.md](../README.md) for detailed instructions.
```

---

## Example 2: Just Initialized (Ready to Start)

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10

---

## 👉 WHAT TO DO NEXT

**Setup Complete!** Your project is initialized and ready.

**Your Next Step:**

1. (Optional) Add reference files to `File_References_For_Your_Project\` folder
   - Sample files, docs, screenshots, or examples
   - Skip this if you don't have reference materials

2. Double-click `RUN_PROJECT.bat` to start Claude

3. When Claude starts, type: **"Generate a plan"**

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Claude Installed | Yes ✓ |
| Ready to Start | Yes ✓ |

---

## Project Workflow

Here's what happens when you run the project:

1. You run `RUN_PROJECT.bat`
2. Claude starts in the terminal
3. You say "Generate a plan" - Claude creates a plan
4. You say "Execute the plan" - Claude builds your project
5. Check `output\` folder for generated files
6. Check this file (STATUS.md) for progress updates

---

## Progress Log

Claude will update this section as work progresses.
```

---

## Example 3: Plan Generated (Ready to Execute)

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10

---

## 👉 WHAT TO DO NEXT

**Plan Generated!** I've created a 5-phase plan for your project.

**Your Next Step:** Type **"Execute the plan"** in the Claude terminal to start building.

Or, review the plan in `docs/planning/task-plan.md` first if you want to see details.

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Plan Generated | Yes ✓ |
| Execution Started | No |
| Phases Completed | 0 of 5 |

---

## The Plan

**Phase 1:** Project Setup & Structure
**Phase 2:** Homepage Layout & Styling
**Phase 3:** Contact Form Implementation
**Phase 4:** Email Integration
**Phase 5:** Testing & Deployment

See full details in [docs/planning/task-plan.md](docs/planning/task-plan.md)

---

## Progress Log

- ✓ Generated 5-phase plan
- ✓ Analyzed project requirements
- Ready to start execution!
```

---

## Example 4: Execution in Progress

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10 14:30

---

## 👉 WHAT TO DO NEXT

**Working on it!** I'm currently building Phase 2 of 5.

**Your Next Step:** Sit tight! I'll update this file as I complete each phase. Feel free to check back anytime.

Or just watch the terminal - I'll let you know when I'm done!

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Plan Generated | Yes ✓ |
| Execution Started | Yes ✓ |
| Current Phase | Phase 2 of 5 |
| Phases Completed | 1 of 5 |

---

## Recent Progress

- [x] Phase 1: Project Setup & Structure ✓ (Completed 14:15)
- [x] Phase 2: Homepage Layout & Styling (In Progress...)
- [ ] Phase 3: Contact Form Implementation
- [ ] Phase 4: Email Integration
- [ ] Phase 5: Testing & Deployment

---

## Progress Log

### Phase 1 Complete (14:15)
- Created project structure
- Set up basic HTML/CSS files
- Configured development environment

### Phase 2 Started (14:20)
- Designing homepage layout
- Implementing responsive CSS
- Creating navigation bar
```

---

## Example 5: Waiting for User Input

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10 14:45

---

## 👉 WHAT TO DO NEXT

**I need your input!** I have some questions about your project.

**Your Next Step:**

1. **Open** [Questions_For_You.md](Questions_For_You.md)
2. **Answer** the 3 questions I wrote there
3. **Save** the file
4. **Go back** to the Claude terminal and press **Enter**

Don't want to answer? Just press Enter and I'll make reasonable assumptions!

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Plan Generated | Yes ✓ |
| Current Phase | Phase 3 of 5 |
| Phases Completed | 2 of 5 |
| Waiting For | Your answers |

---

## Recent Progress

- [x] Phase 1: Project Setup & Structure ✓
- [x] Phase 2: Homepage Layout & Styling ✓
- [x] Phase 3: Contact Form Implementation (Paused - needs your input)
- [ ] Phase 4: Email Integration
- [ ] Phase 5: Testing & Deployment

---

## What I'm Asking About

I have questions about:
1. Email service preference (SendGrid, Mailgun, or SMTP?)
2. Required form fields
3. Success message text

See details in [Questions_For_You.md](Questions_For_You.md)
```

---

## Example 6: Execution Complete

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10 15:30

---

## 👉 WHAT TO DO NEXT

**All Done!** Your project is complete! 🎉

**Your Next Step:**

1. **Check** the `output/` folder for your generated files
2. **Read** the deployment instructions below
3. **Open** `output/INSTRUCTIONS.md` for how to run your website locally

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Plan Generated | Yes ✓ |
| Execution Complete | Yes ✓ |
| Phases Completed | 5 of 5 ✓ |
| All Tests Passing | Yes ✓ |

---

## What Was Built

Your complete website with:
- ✓ Responsive homepage layout
- ✓ Working contact form
- ✓ Email integration with SendGrid
- ✓ Mobile-friendly design
- ✓ All tests passing

---

## Output Files Generated

| File | Description |
|------|-------------|
| `output/index.html` | Homepage |
| `output/styles.css` | All styles |
| `output/script.js` | Form handling |
| `output/server.js` | Backend server (Node.js) |
| `output/package.json` | Dependencies |
| `output/INSTRUCTIONS.md` | How to run locally |
| `output/DEPLOYMENT.md` | How to deploy |

---

## How to Run Your Website

1. Open a terminal in the `output/` folder
2. Run: `npm install`
3. Run: `npm start`
4. Open browser to `http://localhost:3000`

See [output/INSTRUCTIONS.md](output/INSTRUCTIONS.md) for full details.

---

## Session Metrics

| Metric | Value |
|--------|-------|
| Total Phases | 5 |
| Files Created | 12 |
| Est. API Cost | $2.45 |
| Execution Time | ~35 minutes |

Full cost report: [output/cost_report.md](output/cost_report.md)
```

---

## Example 7: Error / Blocked

```markdown
# Project Status: My Website Project

**Last Updated**: 2026-01-10 14:50

---

## 👉 WHAT TO DO NEXT

**Stopped - Need Help!** I hit an issue and need your assistance.

**Your Next Step:**

**Problem:** SendGrid API key is required but not found in environment.

**How to fix:**
1. Get your SendGrid API key from https://sendgrid.com/
2. Create a file called `.env` in the output folder
3. Add this line: `SENDGRID_API_KEY=your_key_here`
4. Come back and type "Continue" to resume

---

## Quick Status

| Item | Status |
|------|--------|
| Project Initialized | Yes ✓ |
| Plan Generated | Yes ✓ |
| Current Phase | Phase 4 of 5 |
| Phases Completed | 3 of 5 |
| Status | Blocked - needs API key |

---

## Recent Progress

- [x] Phase 1: Project Setup & Structure ✓
- [x] Phase 2: Homepage Layout & Styling ✓
- [x] Phase 3: Contact Form Implementation ✓
- [ ] Phase 4: Email Integration (BLOCKED - needs API key)
- [ ] Phase 5: Testing & Deployment

---

## What Happened

I successfully created the email integration code, but it needs a SendGrid API key to work. This is a secret credential that you need to provide.

Don't have SendGrid? No problem! I can switch to:
- SMTP (Gmail, Outlook, etc.)
- Mailgun
- Another service

Just let me know in the terminal!
```

---

## Tips for Writing Good "WHAT TO DO NEXT" Sections

1. **Be Specific**: "Type 'Execute the plan'" is better than "Start execution"
2. **Use Action Verbs**: Open, Click, Type, Check, Run
3. **Number Steps**: 1, 2, 3 makes it easy to follow
4. **Be Encouraging**: "All Done! 🎉" or "Working on it!"
5. **Explain Why**: If blocked, clearly explain what's needed and why
6. **Provide Options**: "Don't want to answer? Just press Enter..."
7. **Link to Files**: Use markdown links to specific files

---

**Remember:** The goal is that a non-technical user can open STATUS.md at ANY time and immediately know exactly what to do next!
