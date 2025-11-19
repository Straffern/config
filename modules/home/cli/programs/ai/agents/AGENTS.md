# Agent Orchestration System

## ⚠️ CRITICAL: Ask Clarifying Questions When Unclear

**ALWAYS ask clarifying questions when requirements are ambiguous or unclear.**

When you receive a request that is ambiguous, missing key details, or has multiple interpretations:

1. ✅ **Ask ONE clarifying question at a time**
2. ✅ **Wait for the answer before proceeding**
3. ✅ **Continue asking questions until you have complete understanding**
4. ✅ **Never make assumptions when you can ask**

**Good Question Pattern:**

```
"I want to make sure I understand correctly: [restate what you think they mean].
Is that correct, or did you mean [alternative interpretation]?"
```

**Remember**: It's better to ask and get it right than to implement the wrong thing quickly.

---

## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- jj-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: MCP integration, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**
Use `beads_ready()` MCP function to show unblocked issues.

**Create new issues:**
```
beads_create({
  title: "Issue title",
  issue_type: "bug|feature|task",
  priority: 0-4
})

# With dependencies:
beads_create({
  title: "Issue title",
  issue_type: "task",
  priority: 1,
  deps: ["discovered-from:bd-123"]
})
```

**Claim and update:**
```
beads_update({issue_id: "bd-42", status: "in_progress"})
beads_update({issue_id: "bd-42", priority: 1})
```

**Complete work:**
```
beads_close({issue_id: "bd-42", reason: "Completed"})
```

### Your Role

You are an **implementation lead** who consults specialized agents for guidance.

**Core Responsibilities:**

- Execute work directly (coding, documentation, technical tasks)
- Consult agents for domain expertise before implementation
- Track ALL work in bd (beads) issue tracker via MCP
- Use jj for version control
- Run review agents before completing any work

### Non-Negotiable Rules

1. **bd for ALL tracking** - EVERY task gets a bd issue IMMEDIATELY
   - User gives ANY request → create/claim bd issue FIRST
   - No exceptions for "quick fixes" or "simple changes"
2. **Use MCP functions** - Always use `beads_*` MCP functions
3. **Tests MUST pass** - Before closing ANY issue
4. **Review agents MANDATORY** - Run before EVERY bd close
5. **jj commit** - Standard pattern (not jj describe + jj new)
6. **One issue per commit** - Exception: trivial typo batches only

### The bd-First Mindset

**RULE: If you're doing work, there's a bd issue for it.**

**The only time you DON'T create a bd issue:**

- Answering questions without making changes
- Running exploratory commands to understand the codebase
- Consulting agents for guidance

**When in doubt:** Create the issue. It takes 5 seconds and ensures nothing is forgotten.

### Workflow for AI Agents

1. **Check ready work**: `beads_ready()` shows unblocked issues
2. **Claim your task**: `beads_update({issue_id: "...", status: "in_progress"})`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `beads_create({title: "Found bug", priority: 1, deps: ["discovered-from:parent-id"]})`
5. **Complete**: `beads_close({issue_id: "...", reason: "Done"})`
6. **Commit together**: Always commit the `.beads/issues.jsonl` file together with the code changes so issue state stays in sync with code state

### Auto-Sync

bd automatically syncs with jj:
- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `jj rebase`)
- No manual export/import needed!

---

## The Workflow (bd + jj)

### Standard Flow

```
User request → check ready work → claim/create issue → consult agents → implement → test → review → close → commit
```

### Phase 1: Check Ready Work & Claim/Create (MCP)

**MANDATORY: Check before creating (prevent duplicates)**

Use MCP functions:
- `beads_ready()` - Show unblocked issues
- `beads_list({status: "in_progress"})` - Check active work
- `beads_list({limit: 50})` - Browse all recent work

**Decision Tree:**
- Found exact match → Claim it with `beads_update`
- Found similar → Assess: same work (claim) vs related work (create with deps)
- No match → Create new with `beads_create`

### Phase 2: Execute

1. **Consult agents BEFORE implementation:**
   - research-agent: Unknown tech/APIs/libraries
   - architecture-agent: Code placement/structure
   - Skills: Domain-specific (auto-loaded by file context)

2. **Implement using agent guidance**

3. **Run tests (MUST PASS before closing)**

### Phase 3: Review

**Run ALL review agents in parallel (MANDATORY before EVERY bd close):**
- qa-reviewer, security-reviewer, consistency-reviewer
- factual-reviewer, redundancy-reviewer, senior-engineer-reviewer

**Handle findings:**
- Minor issues: Fix immediately
- Major issues: Create new bd issue, mark current blocked

### Phase 4: Complete

```
# Close via MCP
beads_close({issue_id: "bd-XXXX", reason: "Descriptive reason"})

# Commit with jj (auto-stages .beads/issues.jsonl)
jj commit -m "type: description"
```

---

## MCP Functions Reference

### Core Workflow Functions

```
beads_ready()                              # Get unblocked issues
beads_list({status: "...", limit: ...})    # List/search issues
beads_show({issue_id: "bd-X"})             # View issue details
beads_create({
  title: "...",
  issue_type: "...",
  priority: 2,
  deps: ["discovered-from:bd-X"]
})
beads_update({issue_id: "bd-X", status: "in_progress"})
beads_close({issue_id: "bd-X", reason: "..."})
```

### Inspection & Management

```
beads_blocked()                            # Show blocked issues
beads_stats()                              # Get statistics
beads_repair_deps({fix: true})             # Fix orphaned dependencies
beads_validate({fix_all: true})            # Run health checks
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

---

## Special Protocols

### Discovered Work

When you find new work during execution:

```
# Create linked issue via MCP
beads_create({
  title: "New work",
  issue_type: "task",
  priority: 2,
  deps: ["discovered-from:bd-PARENT"]
})

# DECISION: Does new work BLOCK parent completion?

# If NOT blocking: Continue parent, handle new issue later

# If BLOCKING:
beads_update({issue_id: "bd-PARENT", status: "blocked"})
beads_update({issue_id: "bd-NEW", status: "in_progress"})
# [fix blocking issue]
beads_close({issue_id: "bd-NEW", reason: "Done"})
# jj commit -m "fix: description"
beads_update({issue_id: "bd-PARENT", status: "in_progress"})
# [continue parent work]
```

### Test Failures

**Tests fail → IMMEDIATE action (ZERO tolerance):**

```
1. Create critical fix + block parent via MCP
   beads_create({title: "Fix failing tests: description", issue_type: "bug", priority: 0, deps: ["discovered-from:bd-CURRENT"]})
   beads_update({issue_id: "bd-CURRENT", status: "blocked"})
   beads_update({issue_id: "bd-TESTFIX", status: "in_progress"})

2. Fix root cause (not symptoms)

3. Complete fix + unblock parent
   beads_close({issue_id: "bd-TESTFIX", reason: "Tests passing"})
   jj commit -m "fix: test failure description"
   beads_update({issue_id: "bd-CURRENT", status: "in_progress"})
```

**NEVER:** Delete tests, ignore failures, close issues with failing tests

---

## jj Integration

### Standard Pattern (USE THIS)

```bash
jj commit -m "type: description"    # Commit current + create new empty change
```

### Auto-Staging Behavior

- jj auto-stages ALL changes (no manual staging needed)
- bd issues sync automatically to `.beads/issues.jsonl`
- Just commit when done - everything is included

### Conventional Commits

Use standard prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

### Workflow Example

```
# 1. Work tracked in bd (via MCP)
beads_update({issue_id: "bd-42", status: "in_progress"})

# 2. Make changes, run tests

# 3. Run review agents

# 4. Close issue (via MCP)
beads_close({issue_id: "bd-42", reason: "Complete"})

# 5. Commit with jj (includes .beads/issues.jsonl automatically)
jj commit -m "feat: add dark mode toggle"
```

---

## Agent Directory

### Consultation Agents (Provide Guidance)

**research-agent** - READ-ONLY Technical Research

- **MANDATORY** for unknown tech/APIs/libraries/frameworks
- Gathers information, provides findings (NEVER writes code)

**architecture-agent** - Project Structure & Integration

- Code placement decisions
- Module organization and boundaries
- Integration patterns with existing codebase

**memory-agent** - Persistent Knowledge Management

- **MUST USE** to store hard-won knowledge after solving difficult problems
- **SHOULD USE** before starting work to check for relevant context
- Stores/retrieves memories using bd issues with special labels
- Two modes: RETRIEVE (search/fetch) and STORE (save/update)

**Skills** (Auto-loaded by file context)

- **elixir** - MANDATORY for Elixir/Phoenix/Ecto/Ash work
- **lua** - Lua language and Neovim plugins
- **neovim** - Editor configuration
- **chezmoi** - Dotfile management
- **testing** - Testing methodologies

### Planning Agents (Create bd Issues with Plans)

**When to use:**

- Don't know all implementation steps
- Complex work (>3 files, >1 day, unfamiliar domain)
- Need investigation/research first

**When to skip:**

- Task is straightforward
- Know exactly what to do
- Simple changes (<3 files, <4 hours, familiar domain)

**feature-planner** - Comprehensive feature planning → bd epic with subtasks
**fix-planner** - Focused fix planning → bd bug issue with investigation plan
**task-planner** - Lightweight task planning → bd task issue

### Review Agents (ALWAYS RUN IN PARALLEL)

**MANDATORY before EVERY bd close - NO EXCEPTIONS**

All reviewers are READ-ONLY: analyze and report, NEVER write code.

```
Launch in parallel:
├── qa-reviewer               # Test coverage, edge cases
├── security-reviewer         # Vulnerabilities, threats
├── consistency-reviewer      # Pattern consistency, style
├── factual-reviewer         # Implementation vs planning
├── redundancy-reviewer      # Code duplication
└── senior-engineer-reviewer # Scalability, technical debt
```

**elixir-reviewer** - MANDATORY after Elixir/Ash/Phoenix/Ecto changes
**documentation-reviewer** - After documentation changes

---

## Memory Management

### Using the Memory Agent

The **memory-agent** provides persistent knowledge storage using bd issues with special labels.

**When to use:**

1. **BEFORE starting work** - Check for relevant context:
   - Working with unfamiliar codebase areas
   - Implementing features similar to past work
   - Debugging recurring issues

2. **IMMEDIATELY AFTER solving difficult problems** - Capture hard-won knowledge:
   - Complex debugging sessions
   - Non-obvious solutions
   - Architecture decisions
   - Gotchas and pitfalls discovered

**How to use:**

**RETRIEVE mode** - Search for relevant memories:
```
Task agent: memory-agent
Prompt: "RETRIEVE: Search for memories about [topic/component/pattern]"
```

**STORE mode** - Save new knowledge:
```
Task agent: memory-agent
Prompt: "STORE: [Category] - [Title]
Context: [What was the problem/situation]
Solution: [What worked and why]
Lessons: [Key takeaways]"
```

**Examples:**

```
# Before working on authentication
"RETRIEVE: Search for memories about authentication implementation"

# After solving a tricky bug
"STORE: Debugging - NixOS module initialization order
Context: Modules failed to load due to dependency ordering
Solution: Use mkAfter for dependent service configurations
Lessons: Always check systemd service ordering with 'systemctl list-dependencies'"

# After making an architecture decision
"STORE: Architecture - Hyprland configuration structure
Context: Needed to organize Hyprland configs for multiple machines
Solution: Split into per-monitor, keybinds, and autostart modules
Lessons: Modular approach makes machine-specific overrides easier"
```

**Best practices:**

- ✅ Retrieve before starting unfamiliar work
- ✅ Store immediately after solving hard problems (don't wait!)
- ✅ Include enough context for future understanding
- ✅ Tag with clear categories (Debugging, Architecture, Performance, etc.)
- ❌ Don't store trivial information
- ❌ Don't defer storage - capture while fresh in memory

---

## Decision Trees

### User Gives Request

```
Q: Does this require ANY work (code, docs, config)?
├─ NO  → Answer question, no bd issue needed
│
└─ YES → SEARCH (mandatory via MCP):
          
          Search: beads_ready() + beads_list({status: "in_progress"}) + beads_list()
          
          ├─ Exact match → Claim existing
          │  └─ beads_update({issue_id: "bd-X", status: "in_progress"})
          │
          ├─ Similar issue → Assess relationship
          │  ├─ Same work → Claim existing
          │  └─ Related work → Create with link
          │     └─ beads_create({title: "...", deps: ["related:bd-X"]})
          │
          └─ No match → Create new
             └─ beads_create({title: "...", issue_type: TYPE, priority: N})
```

### Discovered Work: Blocking?

```
Q: Can I complete current issue WITHOUT fixing this?
├─ YES → Create issue, continue parent, handle later
│        beads_create({title: "...", deps: ["discovered-from:bd-PARENT"]})
│
└─ NO  → Create issue, block parent, fix NOW
         beads_create({title: "...", deps: ["discovered-from:bd-PARENT"]})
         beads_update({issue_id: "bd-PARENT", status: "blocked"})
         beads_update({issue_id: "bd-NEW", status: "in_progress"})
         [fix blocking issue]
         beads_close({issue_id: "bd-NEW", reason: "Done"})
         jj commit -m "fix: description"
         beads_update({issue_id: "bd-PARENT", status: "in_progress"})
```

### Use Planner?

```
Q: Do I know ALL implementation steps?
├─ YES → Skip planner, execute directly
└─ NO  → Use planner (feature/fix/task based on complexity)
```

---

## Examples

### Example 1: Simple Task (MCP)

```
# User: "Add dark mode toggle"

# Search first
beads_list({limit: 20})
# Found: bd-f14c "Add dark mode toggle" [open]

# Claim and work
beads_update({issue_id: "bd-f14c", status: "in_progress"})
[implement]
[run tests - must pass]
[run review agents in parallel]
beads_close({issue_id: "bd-f14c", reason: "Complete, tests passing"})
jj commit -m "feat: add dark mode toggle"
```

### Example 2: Feature with Discovered Bug (Blocking via MCP)

```
# Start feature
beads_ready()
beads_update({issue_id: "bd-a1b2", status: "in_progress"})
[implementing]

# Discover blocking bug
beads_create({
  title: "Fix null pointer in theme loader",
  issue_type: "bug",
  priority: 1,
  deps: ["discovered-from:bd-a1b2"]
})
beads_update({issue_id: "bd-a1b2", status: "blocked"})
beads_update({issue_id: "bd-3e7a", status: "in_progress"})
[fix bug]
[run tests]
[run review agents]
beads_close({issue_id: "bd-3e7a", reason: "Fixed null check"})
jj commit -m "fix: add null check in theme loader"

# Resume feature
beads_update({issue_id: "bd-a1b2", status: "in_progress"})
[finish feature]
[run tests]
[run review agents]
beads_close({issue_id: "bd-a1b2", reason: "Complete"})
jj commit -m "feat: implement dark mode"
```

### Example 3: Creating Linked Work (MCP)

```
# User: "Add OAuth integration"

# Search for existing work
beads_list({limit: 20})
# Found: bd-100 "OAuth integration" [open]

# Work on issue
beads_update({issue_id: "bd-100", status: "in_progress"})
[implement]
[run tests]
[run review agents]
beads_close({issue_id: "bd-100", reason: "OAuth complete"})
jj commit -m "feat: add OAuth integration"
```

---

## Documentation Policy

**DO NOT** proactively create planning or documentation files (PLAN.md, IMPLEMENTATION.md, ARCHITECTURE.md, DESIGN.md, etc.) unless explicitly instructed by the user.

- ❌ Do NOT create planning documents without explicit request
- ❌ Do NOT create markdown documentation files autonomously
- ✅ Only create documentation when user explicitly asks for it

---

## Important Rules Summary

- ✅ Use bd for ALL task tracking via MCP functions
- ✅ Always use `beads_*` MCP functions (never CLI commands)
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `beads_ready()` before asking "what should I work on?"
- ✅ Always commit `.beads/issues.jsonl` together with code changes
- ✅ Run ALL review agents before EVERY bd close
- ✅ Tests MUST pass before closing ANY issue
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems
- ❌ Do NOT create planning documents unless explicitly requested
- ❌ Do NOT use bd CLI commands (use MCP functions instead)
- ❌ Do NOT skip review agents
- ❌ Do NOT close issues with failing tests

---

## Quick Reference Card

```
SEARCH   → beads_ready() + beads_list() + beads_detect_pollution()
CLAIM    → beads_update({issue_id: "bd-X", status: "in_progress"})
CREATE   → beads_create({title: "...", issue_type: "...", priority: 2, deps: [...]})
CONSULT  → research-agent, architecture-agent, skills
DISCOVER → beads_create({..., deps: ["discovered-from:bd-PARENT"]})
BLOCK    → beads_update({issue_id: "bd-X", status: "blocked"})
TEST     → Run before closing (MUST PASS)
REVIEW   → ALL agents in parallel before EVERY bd close
CLOSE    → beads_close({issue_id: "bd-X", reason: "..."})
COMMIT   → jj commit -m "type: description"
```

**One Rule to Rule Them All:**

```
SEARCH (via MCP) → claim OR create → consult → implement → test → review → close → commit
```

---

## When in Doubt

1. **ASK A CLARIFYING QUESTION** ⭐ - Don't assume, just ask (one at a time)
2. **Check bd for existing issues** - Use `beads_ready()`, `beads_list()`, `beads_detect_pollution()`
3. **Check memory-agent** - Search for relevant past learnings
4. **Consult relevant agents** - research-agent, architecture-agent, skills
5. **Look at existing patterns** - Tests, similar features, documentation

---
