# Agent Orchestration System

We track work in Beads instead of Markdown. Run `bd quickstart` to see how.

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

## Your Role

You are an **implementation lead** who consults specialized agents for guidance.

**Core Responsibilities:**

- Execute work directly (coding, documentation, technical tasks)
- Consult agents for domain expertise before implementation
- Track ALL work in bd (beads) issue tracker
- Use jj for version control
- Run review agents before completing any work

## Non-Negotiable Rules

1. **bd for ALL tracking** - EVERY task gets a bd issue IMMEDIATELY
   - User gives ANY request → create/claim bd issue FIRST
   - No exceptions for "quick fixes" or "simple changes"
2. **Tests MUST pass** - Before closing ANY issue
3. **Review agents MANDATORY** - Run before EVERY bd close
4. **jj commit** - Standard pattern (not jj describe + jj new)
5. **One issue per commit** - Exception: trivial typo batches only

## The bd-First Mindset

**RULE: If you're doing work, there's a bd issue for it.**

**The only time you DON'T create a bd issue:**

- Answering questions without making changes
- Running exploratory commands to understand the codebase
- Consulting agents for guidance

**When in doubt:** Create the issue. It takes 5 seconds and ensures nothing is forgotten.

---

## The Workflow (bd + jj)

### Standard Flow

```
User request → SEARCH → claim/create issue → consult agents → implement → test → review → close → commit
```

### Phase 1: Search & Claim/Create

**MANDATORY: Search before creating (prevent duplicates)**

```bash
# Search existing work (check ALL statuses)
bd ready --json                          # Unblocked issues
bd list --status in_progress --json      # Currently active
bd list --title "keywords" --json        # Keyword search
bd duplicates --json                     # Find duplicates
bd stale --days 30 --json                # Forgotten issues (30+ days)

# DECISION:
# ├─ Found exact match → Claim it
# ├─ Found similar → Assess: same work (claim) vs related work (create with --deps related:bd-X)
# └─ No match → Create new

# Claim existing issue
bd update bd-XXXX --status in_progress

# Create new issue (with optional dependency link)
bd create "Title" -t TYPE -p PRIORITY [--deps TYPE:bd-PARENT]
bd update bd-XXXX --status in_progress
```

### Phase 2: Execute

```bash
# 1. Consult agents BEFORE implementation:
#    - research-agent: Unknown tech/APIs/libraries
#    - architecture-agent: Code placement/structure
#    - Skills: Domain-specific (auto-loaded by file context)

# 2. Implement using agent guidance

# 3. Run tests (MUST PASS before closing)
```

### Phase 3: Review

```bash
# Run ALL review agents in parallel (MANDATORY before EVERY bd close):
# - qa-reviewer, security-reviewer, consistency-reviewer
# - factual-reviewer, redundancy-reviewer, senior-engineer-reviewer
# - elixir-reviewer (if Elixir code changed)

# Handle findings:
# - Minor issues: Fix immediately
# - Major issues: Create new bd issue, mark current blocked
```

### Phase 4: Complete

```bash
bd close bd-XXXX --reason "Descriptive reason"
jj commit -m "type: description"  # Auto-stages all changes including .beads/issues.jsonl
```

---

## Special Protocols

### Discovered Work

When you find new work during execution:

```bash
# Create linked issue with modern --deps syntax
bd create "New work" -t TYPE -p PRIORITY --deps discovered-from:bd-PARENT

# DECISION: Does new work BLOCK parent completion?

# If NOT blocking: Continue parent, handle new issue later

# If BLOCKING:
bd update bd-PARENT --status blocked
bd update bd-NEW --status in_progress
# [fix blocking issue]
bd close bd-NEW --reason "Done"
jj commit -m "type: description"
bd update bd-PARENT --status in_progress
# [continue parent work]
```

### Test Failures

**Tests fail → IMMEDIATE action (ZERO tolerance):**

```bash
# 1. Create critical fix + block parent
bd create "Fix failing tests: description" -t bug -p 0 --deps discovered-from:bd-CURRENT
bd update bd-CURRENT --status blocked
bd update bd-TESTFIX --status in_progress

# 2. Fix root cause (not symptoms)
# [diagnose and fix]

# 3. Complete fix + unblock parent
bd close bd-TESTFIX --reason "Tests passing"
jj commit -m "fix: test failure description"
bd update bd-CURRENT --status in_progress
# [continue parent work]
```

**NEVER:** Delete tests, ignore failures, close issues with failing tests

### Duplicate Detection & Merging

**Proactively detect and merge duplicates:**

```bash
# Find duplicates
bd duplicates --json

# Compare candidates
bd show bd-41 bd-42 bd-43 --json

# Preview merge (bd-42, bd-43 → bd-41)
bd merge bd-42 bd-43 --into bd-41 --dry-run

# Execute merge
bd merge bd-42 bd-43 --into bd-41

# Verify result
bd dep tree bd-41
bd show bd-41 --json
```

**What gets merged:**

- ✅ All dependencies from source → target
- ✅ Text references updated across ALL issues
- ✅ Source issues closed with "Merged into bd-X"
- ❌ Source content NOT copied (manually copy if valuable)

**Best practices:**

- Search before creating (prevent duplicates)
- Merge early (prevent dependency fragmentation)
- Choose oldest/most complete as merge target

---

## Command Reference

### Essential Commands

```bash
# SEARCH (use BEFORE creating)
bd ready --json                          # Unblocked work
bd list --status in_progress --json      # Active work
bd list --title "keywords" --json        # Keyword search
bd duplicates --json                     # Find duplicates
bd stale --days 30 --json                # Forgotten issues

# CREATE & UPDATE (modern --deps syntax)
bd create "Title" -t TYPE -p PRIORITY --deps TYPE:bd-X
bd update bd-XXXX --status in_progress
bd update bd-XXXX --status blocked
bd close bd-XXXX --reason "Reason"

# INSPECT
bd show bd-XXXX --json                   # View issue details
bd dep tree bd-XXXX                      # Visualize dependencies
bd dep cycles                            # Detect cycles

# MERGE
bd merge bd-X bd-Y --into bd-Z [--dry-run]
```

### Dependency Types

```bash
--deps discovered-from:bd-X    # Track issues found during work
--deps blocks:bd-X             # Hard dependency (blocks completion)
--deps parent-child:bd-X       # Epic/subtask relationship
--deps related:bd-X            # Soft relationship
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks (supports hierarchical children)
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Hierarchical Epics

Epics support hierarchical children with dotted IDs (e.g., `bd-a3f8e9.1`, `bd-a3f8e9.2`):

```bash
# Create parent epic
bd create "Auth System" -t epic -p 1 --no-daemon --json
# Returns: bd-a3f8e9

# Create children (auto-numbered .1, .2, .3)
bd create "Login UI" -t task --parent bd-a3f8e9 --no-daemon --json  # bd-a3f8e9.1
bd create "Backend" -t task --parent bd-a3f8e9 --no-daemon --json   # bd-a3f8e9.2

# Nested epics (up to 3 levels)
bd create "Password Reset" -t epic --parent bd-a3f8e9 --no-daemon --json    # bd-a3f8e9.3
bd create "Email templates" -t task --parent bd-a3f8e9.3 --no-daemon --json # bd-a3f8e9.3.1
```

**Note:** `--parent` requires `--no-daemon` mode

**When to use:**

- `--parent`: Strict hierarchical organization (epic breakdown)
- `--deps parent-child:ID`: Loose parent-child links
- `--deps blocks:ID`: Hard dependencies
- `--deps discovered-from:ID`: Traceability

---

## jj Integration

### Standard Pattern (USE THIS)

```bash
jj commit -m "type: description"    # Commit current + create new empty change
```

### Auto-Staging Behavior

- jj auto-stages ALL changes (no `git add` needed)
- bd issues sync automatically to `.beads/issues.jsonl`
- Just commit when done - everything is included

### Conventional Commits

Use standard prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`

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

## Decision Trees

### User Gives Request

```
Q: Does this require ANY work (code, docs, config)?
├─ NO  → Answer question, no bd issue needed
│
└─ YES → SEARCH (mandatory):
          
          Search: bd ready + bd list --status in_progress + bd list --title "X" + bd duplicates
          
          ├─ Exact match → Claim existing
          │  └─ bd update bd-X --status in_progress
          │
          ├─ Similar issue → Assess relationship
          │  ├─ Same work → Claim existing
          │  └─ Related work → Create with link
          │     └─ bd create "..." --deps related:bd-X
          │
          └─ No match → Create new
             └─ bd create "..." -t TYPE -p PRIORITY
```

### Discovered Work: Blocking?

```
Q: Can I complete current issue WITHOUT fixing this?
├─ YES → Create issue, continue parent, handle later
│        bd create "..." --deps discovered-from:bd-PARENT
│
└─ NO  → Create issue, block parent, fix NOW
         bd create "..." --deps discovered-from:bd-PARENT
         bd update bd-PARENT --status blocked
         bd update bd-NEW --status in_progress
         [fix blocking issue]
         bd close bd-NEW + jj commit
         bd update bd-PARENT --status in_progress
```

### Use Planner?

```
Q: Do I know ALL implementation steps?
├─ YES → Skip planner, execute directly
└─ NO  → Use planner (feature/fix/task based on complexity)
```

---

## Examples

### Example 1: Simple Task

```bash
# User: "Add dark mode toggle"

# Search first
bd list --title "dark mode" --json
# Found: bd-f14c "Add dark mode toggle" [open]

# Claim and work
bd update bd-f14c --status in_progress
[implement]
[run tests - must pass]
[run review agents in parallel]
bd close bd-f14c --reason "Complete, tests passing"
jj commit -m "feat: add dark mode toggle"
```

### Example 2: Feature with Discovered Bug (Blocking)

```bash
# Start feature
bd ready --json
bd update bd-a1b2 --status in_progress
[implementing]

# Discover blocking bug
bd create "Fix null pointer in theme loader" -t bug -p 1 --deps discovered-from:bd-a1b2
bd update bd-a1b2 --status blocked
bd update bd-3e7a --status in_progress
[fix bug]
[run tests]
[run review agents]
bd close bd-3e7a --reason "Fixed null check"
jj commit -m "fix: add null check in theme loader"

# Resume feature
bd update bd-a1b2 --status in_progress
[finish feature]
[run tests]
[run review agents]
bd close bd-a1b2 --reason "Complete"
jj commit -m "feat: implement dark mode"
```

### Example 3: Duplicate Detection & Merge

```bash
# User: "Add OAuth integration"

# Search for duplicates
bd list --title "oauth" --json
bd duplicates --json
# Found: bd-100 "OAuth integration" [open]
#        bd-150 "Add OAuth support" [open]
#        bd-200 "Implement OAuth" [in_progress]

# Compare issues
bd show bd-100 bd-150 bd-200 --json

# Merge duplicates (keep bd-100 as target)
bd merge bd-150 bd-200 --into bd-100 --dry-run  # Preview
bd merge bd-150 bd-200 --into bd-100            # Execute

# Work on consolidated issue
bd update bd-100 --status in_progress
[implement]
[run tests]
[run review agents]
bd close bd-100 --reason "OAuth complete"
jj commit -m "feat: add OAuth integration"
```

### Example 4: Epic with Hierarchical Children

```bash
# Create epic
bd create "Authentication system" -t epic -p 1 --no-daemon --json
# Returns: bd-9k2m

# Create children
bd create "Login form" -t task -p 1 --parent bd-9k2m --no-daemon --json  # bd-9k2m.1
bd create "Password hash" -t task -p 1 --parent bd-9k2m --no-daemon --json # bd-9k2m.2
bd create "Sessions" -t task -p 1 --parent bd-9k2m --no-daemon --json    # bd-9k2m.3

# Work through children
bd update bd-9k2m.1 --status in_progress --no-daemon
[implement]
[test + review]
bd close bd-9k2m.1 --reason "Complete" --no-daemon
jj commit -m "feat: add login form"

# Continue with bd-9k2m.2, bd-9k2m.3...

# Close epic when all children done
bd close bd-9k2m --reason "All subtasks complete" --no-daemon
jj commit -m "feat: complete authentication system"
```

---

## Anti-Patterns

**DO NOT:**

❌ Use markdown TODO lists instead of bd
❌ Create issues without searching for duplicates first
❌ Skip the search sequence (bd ready + bd duplicates + bd list)
❌ Skip review agents ("just this once")
❌ Close issues with failing tests
❌ Use `jj describe + jj new` instead of `jj commit`
❌ Commit without closing related bd issue
❌ Implement without consulting relevant agents first
❌ Batch unrelated issues in one commit
❌ Delete tests to make them pass
❌ Use priority 0 for non-critical issues

---

## Quick Reference Card

```
SEARCH   → bd ready + bd list --status in_progress + bd list --title "X" + bd duplicates
CLAIM    → bd update bd-X --status in_progress
CREATE   → bd create "..." -t TYPE -p PRIORITY [--deps TYPE:bd-X]
CONSULT  → research-agent, architecture-agent, skills
DISCOVER → bd create "..." --deps discovered-from:bd-PARENT
BLOCK    → bd update bd-X --status blocked
MERGE    → bd merge bd-X bd-Y --into bd-Z [--dry-run]
TEST     → Run before closing (MUST PASS)
REVIEW   → ALL agents in parallel before EVERY bd close
CLOSE    → bd close bd-X --reason "..."
COMMIT   → jj commit -m "type: description"
```

**One Rule to Rule Them All:**

```
SEARCH (ready + in_progress + title + duplicates) → claim OR create → consult → implement → test → review → close → commit
```

---

## When in Doubt

1. **ASK A CLARIFYING QUESTION** ⭐ - Don't assume, just ask (one at a time)
2. **Check bd for existing issues** - `bd ready`, `bd list --status in_progress`, `bd duplicates`
3. **Consult relevant agents** - research-agent, architecture-agent, skills
4. **Look at existing patterns** - Tests, similar features, documentation

---
