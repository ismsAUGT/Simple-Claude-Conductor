# Task Plan: Simple Claude Conductor Web UI Documentation

## Goal

Create comprehensive technical documentation for the Simple Claude Conductor Web UI system in `docs/SimpleClaudeConductorDocumentation/`. The documentation will serve as the authoritative reference for developers maintaining and extending the web-based project management interface.

## Overview

The Simple Claude Conductor Web UI is a Flask-based web application that provides a GUI for non-technical users to manage Claude Code projects. The system consists of:
- Flask backend with StateManager and ProcessManager
- Alpine.js frontend with SSE-driven real-time updates
- REST API with 30+ endpoints
- File-based state persistence using YAML frontmatter

This project will create 8 documentation files covering architecture, API reference, state machine, process management, frontend design, configuration, and deployment.

## Model Selection

**Model**: Sonnet (documentation task - medium complexity)

## Execution Strategy

**Mode**: In-session (all phases share the same source files - cache reuse valuable)

All phases will be executed in the main session since they all need access to the same source files in `server/` directory. Reading these files once and keeping them cached will be more efficient than spawning subagents.

---

## Phase 1: Read and Catalog Source Files

**Objective**: Read all source files completely and create a comprehensive catalog of components, endpoints, and patterns.

**Tasks**:
1. Read remaining portions of app.py, state_manager.py, process_manager.py
2. Read frontend files: api.js, conductor.css (full files)
3. Read configuration: REBUILD_ARCHITECTURE.md, ARCHITECTURE.md
4. Catalog all API endpoints with their routes, methods, and purposes
5. Document all state machine transitions
6. List all frontend components and Alpine.js methods
7. Update references.md with file catalog

**Success Criteria**:
- [ ] All 7+ source files read in full (verified by having complete understanding of all API endpoints)
- [ ] references.md contains table of all files with descriptions
- [ ] findings.md contains complete list of all 30+ API endpoints with HTTP methods
- [ ] findings.md contains state machine diagram in Mermaid format
- [ ] findings.md contains list of all Alpine.js methods and computed properties

**Estimated Outputs**: 1 file updated (references.md), findings.md expanded

---

## Phase 2: Create Core Architecture Documentation

**Objective**: Write README, ARCHITECTURE, and STATE_MACHINE documentation files.

**Tasks**:
1. Write `README.md` - Overview, features, quick start, file structure
2. Write `ARCHITECTURE.md` - Component diagram, data flow, state persistence
3. Write `STATE_MACHINE.md` - All states, transitions, StateManager implementation, YAML format

**Success Criteria**:
- [ ] README.md exists and contains: what/why/how sections, feature list, file structure tree
- [ ] ARCHITECTURE.md exists and contains: Mermaid diagram showing Flask→StateManager→ProcessManager→Claude flow
- [ ] ARCHITECTURE.md explains YAML frontmatter as single source of truth
- [ ] STATE_MACHINE.md exists and contains: Mermaid state diagram with all 8 states and transitions
- [ ] STATE_MACHINE.md documents YAML frontmatter format with all fields explained
- [ ] STATE_MACHINE.md includes code example showing how StateManager.get_state() works
- [ ] All 3 files validate as proper Markdown (no syntax errors)

**Estimated Outputs**: 3 files created

---

## Phase 3: Document Process Management and API

**Objective**: Write PROCESS_MANAGEMENT and API_REFERENCE documentation files.

**Tasks**:
1. Write `PROCESS_MANAGEMENT.md` - ProcessManager design, PID tracking, exit callbacks, Windows considerations
2. Write `API_REFERENCE.md` - All 30+ endpoints with method, path, request, response, examples

**Success Criteria**:
- [ ] PROCESS_MANAGEMENT.md exists and explains why direct subprocess.Popen is used (not cmd /c start)
- [ ] PROCESS_MANAGEMENT.md documents CREATE_NEW_CONSOLE flag and Windows-specific behavior
- [ ] PROCESS_MANAGEMENT.md explains exit callbacks and timeout monitoring
- [ ] API_REFERENCE.md exists and documents all endpoints found in app.py (minimum 30)
- [ ] Each endpoint has: HTTP method, path, description, request body (if POST), response format, curl example
- [ ] API_REFERENCE.md includes SSE endpoint with example event format
- [ ] All endpoints are grouped logically (Actions, Resources, System)

**Estimated Outputs**: 2 files created

---

## Phase 4: Document Frontend and Configuration

**Objective**: Write FRONTEND, CONFIGURATION, and DEPLOYMENT documentation files.

**Tasks**:
1. Write `FRONTEND.md` - Alpine.js structure, SSE connection, UI states, CSS design tokens
2. Write `CONFIGURATION.md` - project.yaml schema, project-config.json format, model selection
3. Write `DEPLOYMENT.md` - Prerequisites, running server, troubleshooting

**Success Criteria**:
- [ ] FRONTEND.md exists and explains conductorApp() structure with all sections (data, computed, methods)
- [ ] FRONTEND.md documents SSE connection pattern and api.js client design
- [ ] FRONTEND.md includes code example of Alpine.js state binding
- [ ] CONFIGURATION.md exists and documents all project.yaml fields with types and defaults
- [ ] CONFIGURATION.md explains model selection (haiku/sonnet/opus) for different task types
- [ ] DEPLOYMENT.md exists with step-by-step server startup instructions
- [ ] DEPLOYMENT.md includes troubleshooting section for common issues (port in use, Claude not found, etc.)
- [ ] All 3 files validate as proper Markdown

**Estimated Outputs**: 3 files created

---

## Phase 5: Quality Check and Cross-References

**Objective**: Validate documentation accuracy, add cross-references, ensure completeness.

**Tasks**:
1. Verify all code examples are accurate to actual implementation
2. Add cross-references between docs (e.g., ARCHITECTURE references STATE_MACHINE)
3. Ensure no references to archived/old code
4. Check that all diagrams render correctly
5. Validate that all 8 files exist and are complete
6. Update progress.md with completion summary

**Success Criteria**:
- [ ] All 8 documentation files exist in docs/SimpleClaudeConductorDocumentation/
- [ ] README.md file count matches actual implementation (verified by checking docs/ folder)
- [ ] No references to archive/, Bootstrap/, or other excluded directories
- [ ] All Mermaid diagrams have valid syntax (verified by checking for proper ```mermaid blocks)
- [ ] Cross-references use relative links and point to correct files
- [ ] progress.md contains list of all 8 files with brief description of each
- [ ] All code examples match actual source code (spot-checked against app.py and app.js)

**Estimated Outputs**: 8 files validated, 1 file updated (progress.md)

---

## Success Metrics

**Deliverables**:
- 8 documentation files in docs/SimpleClaudeConductorDocumentation/
- Complete API reference covering 30+ endpoints
- State machine diagrams with all transitions
- Architecture diagrams showing component interactions
- Code examples for common operations
- No references to archived code

**Quality Gates** (from project.yaml):
- All files are valid Markdown
- All diagrams render correctly
- All code examples are accurate to implementation

**Files Created**:
- docs/SimpleClaudeConductorDocumentation/README.md
- docs/SimpleClaudeConductorDocumentation/ARCHITECTURE.md
- docs/SimpleClaudeConductorDocumentation/STATE_MACHINE.md
- docs/SimpleClaudeConductorDocumentation/PROCESS_MANAGEMENT.md
- docs/SimpleClaudeConductorDocumentation/API_REFERENCE.md
- docs/SimpleClaudeConductorDocumentation/FRONTEND.md
- docs/SimpleClaudeConductorDocumentation/CONFIGURATION.md
- docs/SimpleClaudeConductorDocumentation/DEPLOYMENT.md

---

## Risk Assessment

**Low Risk**: This is a documentation task with clear requirements and all source files available.

**Potential Issues**:
- Missing some endpoints during cataloging → Mitigation: Read app.py line-by-line to catch all @app.route decorators
- Inaccurate code examples → Mitigation: Copy actual code from source files, don't write from memory
- Mermaid syntax errors → Mitigation: Use simple, tested Mermaid patterns

---

## Notes

- All documentation must reflect the current v2.0 implementation in server/ directory only
- Ignore archive/, .claude/, Bootstrap/, python-portable/, scripts/ directories
- Use Mermaid for diagrams (works in GitHub and most Markdown viewers)
- Include curl examples for API endpoints
- Keep language technical but clear (audience is developers)
