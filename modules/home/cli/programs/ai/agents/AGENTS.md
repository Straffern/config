# Agent Orchestration System

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
   - If you think "this is too small for bd" - CREATE IT ANYWAY
2. **Tests MUST pass** - Before closing ANY issue
3. **Review agents MANDATORY** - Run before EVERY bd close
4. **jj commit** - Standard pattern (not jj describe + jj new)
5. **One issue per commit** - Exception: trivial typo batches only

## The bd-First Mindset

**RULE: If you're doing work, there's a bd issue for it.**

Every single task, no matter how trivial, must be tracked:
- Fixing a typo? Create bd issue.
- Updating a comment? Create bd issue.
- Refactoring 2 lines? Create bd issue.
- User asks a question requiring code changes? Create bd issue.

**The only time you DON'T create a bd issue:**
- Answering questions without making changes
- Running exploratory commands to understand the codebase
- Consulting agents for guidance

**When in doubt:** Create the issue. It takes 5 seconds and ensures nothing is forgotten.

## Workflow Entry Point

```
User request → analyze → SEARCH for existing issues → claim OR create bd issue → implement → review → close → commit
```

---

## The Standard Workflow

**FOLLOW THIS WORKFLOW FOR ALL WORK**

### Phase 1: Start

```bash
# 1. SEARCH for existing work FIRST (MANDATORY - check ALL statuses)
bd list --status open --json              # All open issues
bd list --status in_progress --json       # Currently active work
bd list --status blocked --json           # Blocked issues
bd list --title "keyword" --json          # Search by title/content similarity
bd duplicates --json                      # Check for duplicate content

# 2. DECISION based on search results:
#    A) Found exact match → Claim existing issue
bd update bd-XXXX --status in_progress

#    B) Found similar issue → Assess relationship
#       - If SAME work → Use existing issue
#       - If RELATED work → Create new with link:
bd create "Title" -t TYPE -p PRIORITY --deps related:bd-EXISTING

#    C) No match found → Create new issue
bd create "Title" -t TYPE -p PRIORITY
bd update bd-XXXX --status in_progress
```

### Phase 2: Execute

```bash
# 3. Consult agents BEFORE implementation (MANDATORY):
#    - Unknown tech/APIs/libraries: research-agent
#    - Code placement/structure: architecture-agent
#    - Elixir/Phoenix/Ecto/Ash: elixir skill
#    - Other domains: relevant skill (auto-loaded by file context)

# 4. Implement using agent guidance

# 5. Run tests:
#    - If FAIL: See "Test Failure Protocol" below
#    - If PASS: Continue to Phase 3
```

### Phase 3: Validate

```bash
# 6. Run ALL review agents in parallel (MANDATORY):
#    Launch: qa-reviewer, security-reviewer, consistency-reviewer,
#            factual-reviewer, redundancy-reviewer, senior-engineer-reviewer
#    Plus: elixir-reviewer (if Elixir code changed)

# 7. Handle review findings:
#    - Minor issues: Fix immediately
#    - Major issues: Create new bd issue, mark current blocked
```

### Phase 4: Complete

```bash
# 8. Close issue
bd close bd-XXXX --reason "Descriptive reason"

# 9. Commit with jj (auto-stages all changes including .beads/issues.jsonl)
jj commit -m "type: description"

# 10. Return to Phase 1
```

---

## Special Protocols

### Discovered Work Protocol

**When you find new work during execution:**

```bash
# Create linked issue
bd create "New work description" -t TYPE -p PRIORITY --deps discovered-from:bd-PARENT

# DECISION: Does new work BLOCK parent completion?

# If NOT BLOCKING:
#   Continue parent work, handle new issue later

# If BLOCKING:
bd update bd-PARENT --status blocked
bd update bd-NEW --status in_progress
# [work on new issue]
bd close bd-NEW --reason "Done"
jj commit -m "type: description"
bd update bd-PARENT --status in_progress
# [continue parent work]
```

### Test Failure Protocol

**Tests fail → IMMEDIATE action (ZERO tolerance):**

```bash
# 1. Create critical test fix issue
bd create "Fix failing tests: description" -t bug -p 0 --deps discovered-from:bd-CURRENT

# 2. Block current work
bd update bd-CURRENT --status blocked

# 3. Fix tests NOW
bd update bd-TESTFIX --status in_progress
# [diagnose and fix root cause]
# Run tests → MUST PASS

# 4. Complete test fix
bd close bd-TESTFIX --reason "Tests now passing"
jj commit -m "fix: test failure description"

# 5. Unblock and continue
bd update bd-CURRENT --status in_progress
# Run tests again → verify still passing
# [continue current work]
```

**NEVER:**
- Delete tests without user approval
- Ignore failing tests
- Close issues with failing tests
- Fix symptoms instead of root cause

---

## bd Command Reference

### `--json` Flag Usage

**The `--json` flag is optional on ALL bd commands.** Use it when you need programmatic access to structured data.

#### Common Patterns

**Query commands** (almost always want `--json`):
```bash
# Get list of available work
bd ready --json

# Find specific issues
bd list --status open --json
bd list --priority 0 --json
bd list --type bug --json

# Get detailed issue info
bd show bd-XXXX --json
bd info --json
```

**Action commands** (usually don't need `--json`, but useful for scripting):
```bash
# Standard usage (human-readable output):
bd create "Fix typo" -t task -p 2
bd update bd-XXXX --status in_progress
bd close bd-XXXX --reason "Done"

# With --json for scripting/automation:
ISSUE_ID=$(bd create "Fix typo" -t task -p 2 --json | jq -r '.id')
bd update $ISSUE_ID --status in_progress
```

#### Practical Examples with `jq`

```bash
# Get the ID of the highest priority ready issue
bd ready --json | jq -r '.[0].id'

# Count how many issues are in progress
bd list --status in_progress --json | jq 'length'

# List all blocked issue titles
bd list --status blocked --json | jq -r '.[].title'

# Get all critical priority issues
bd list --priority 0 --json | jq -r '.[] | "\(.id): \(.title)"'

# Find all issues with a specific label
bd list --json | jq '.[] | select(.labels[] == "security")'

# Check if any tests are failing (priority 0 bugs)
if [ $(bd list --type bug --priority 0 --json | jq 'length') -gt 0 ]; then
  echo "⚠️  Critical bugs exist!"
fi
```

#### Rule of Thumb

- **Viewing** issue info → Use `--json` with `jq` for filtering/parsing
- **Creating/updating** issues → Skip `--json` unless scripting
- **In documentation examples** → Skip `--json` for readability (it's implied as optional)

### Essential Commands

```bash
# SEARCH COMMANDS (use BEFORE creating issues)
bd list --status open --json                 # All open issues
bd list --status in_progress --json          # Currently active
bd list --status blocked --json              # Blocked issues  
bd list --title "keyword" --json             # Search by title/content
bd duplicates --json                         # Find duplicate content
bd ready --json                              # Show unblocked work

# CRUD COMMANDS
bd create "Title" -t TYPE -p PRIORITY        # Create issue (after search!)
bd update bd-XXXX --status in_progress       # Claim/start work
bd update bd-XXXX --status blocked           # Mark blocked
bd close bd-XXXX --reason "Reason"           # Complete work
```

### Dependency Commands

```bash
bd create "Title" --deps discovered-from:bd-XXXX   # Link discovered work
bd create "Task" --deps blocks:bd-XXXX             # Blocking dependency
bd create "Task" --deps parent-child:bd-XXXX       # Epic subtask
bd create "Task" --deps related:bd-XXXX            # Soft link

bd dep add bd-A bd-B --type blocks                 # Add dependency later
bd dep tree bd-XXXX                                # Visualize tree
bd dep cycles                                      # Detect cycles
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

### ID Format

**Always**: `bd-[hash]` format (e.g., `bd-f14c`, `bd-a1b2`, `bd-3e7a`)

---

## jj Command Reference

### Standard Pattern (USE THIS)

```bash
jj commit -m "type: description"    # Commit current + create new empty change
```

### Advanced Commands (Rarely Needed)

```bash
jj describe -m "message"            # Set message, keep working
jj new                              # Commit current, new change
jj worklog                          # Check current work context
jj diff                             # See changes
jj bookmark create type/name        # Create bookmark for feature/fix/task
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
- Returns: Documentation summaries, API patterns, integration approaches

**architecture-agent** - Project Structure & Integration
- Code placement decisions
- Module organization and boundaries
- Integration patterns with existing codebase

**Skills** (Auto-loaded by file context)
- **elixir** - MANDATORY for Elixir/Phoenix/Ecto/Ash work (.ex, .exs files)
- **lua** - Lua language and Neovim plugins (.lua files)
- **neovim** - Editor configuration (Neovim config files)
- **chezmoi** - Dotfile management (chezmoi dotfiles)
- **testing** - Testing methodologies (test files)

Location: `agents/skills/[skill]/SKILL.md`

### Planning Agents (Create bd Issues with Plans)

**When to use planners:**
- You don't immediately know all implementation steps
- Complex work (>3 files, >1 day, unfamiliar domain)
- Need investigation or research first

**When to skip planners:**
- Task is straightforward
- You know exactly what to do
- Simple changes (<3 files, <4 hours, familiar domain)

**feature-planner** - Comprehensive Feature Planning
- Use: Complex features requiring detailed planning
- Output: bd epic with subtasks
- Consults: research-agent, architecture-agent, relevant skills

**fix-planner** - Focused Fix Planning
- Use: Complex bugs needing investigation
- Output: bd bug issue with investigation and fix plan
- Consults: research-agent, relevant skills, security-reviewer

**task-planner** - Lightweight Task Planning
- Use: Simple tasks, quick work items
- Output: bd task issue
- Smart escalation: Recommends feature/fix-planner if too complex

### Review Agents (ALWAYS RUN IN PARALLEL)

**MANDATORY before EVERY bd close - NO EXCEPTIONS**

All reviewers are READ-ONLY: analyze and report, NEVER write code.

```
Launch in parallel:
├── qa-reviewer               # Test coverage, edge cases, validation
├── security-reviewer         # Vulnerabilities, OWASP Top 10, threats
├── consistency-reviewer      # Pattern consistency, naming, style
├── factual-reviewer         # Implementation vs planning verification
├── redundancy-reviewer      # Code duplication, refactoring opportunities
└── senior-engineer-reviewer # Scalability, technical debt, strategic decisions
```

**elixir-reviewer** - MANDATORY After Elixir Changes
- Run ALWAYS after Elixir/Ash/Phoenix/Ecto changes
- Tools: mix format, credo, dialyzer, sobelow, deps.audit, test coverage

**documentation-reviewer** - After Documentation Changes
- Use: After creating/updating documentation
- Focus: Accuracy, completeness, readability, standards compliance

---

## Decision Trees

### User Gives Request

```
Q: Does this request require ANY work (code, docs, config changes)?
├─ NO  → Answer question, no bd issue needed
│
└─ YES → SEARCH SEQUENCE (MANDATORY):
          
          Step 1: Search ALL existing issues
          ├─ bd list --status open --json
          ├─ bd list --status in_progress --json
          ├─ bd list --status blocked --json
          └─ bd list --title "keywords" --json
          
          Step 2: Check for duplicates
          └─ bd duplicates --json
          
          Step 3: DECISION based on search results
          ├─ Exact match found → Claim existing issue
          │  └─ bd update bd-XXXX --status in_progress
          │     Execute
          │
          ├─ Similar issue found → Assess relationship
          │  ├─ Same work → Use existing issue
          │  │  └─ bd update bd-XXXX --status in_progress
          │  │     Execute
          │  └─ Related work → Create with link
          │     └─ bd create "..." --deps related:bd-XXXX
          │        bd update bd-NEW --status in_progress
          │        Execute
          │
          └─ No match found → Create new issue
             └─ bd create "..." -t TYPE -p PRIORITY
                bd update bd-XXXX --status in_progress
                Execute
```

### Should I Use a Planner?

```
Q: Do I know ALL implementation steps right now?
├─ YES → Skip planner, go directly to execution
└─ NO  → Use planner

Q: Is this work complex?
   - Multiple files (>3)
   - Unfamiliar domain
   - Takes >4 hours
   - Needs research
├─ YES → Use feature-planner or fix-planner
└─ NO  → Use task-planner OR skip planner entirely
```

### Is Discovered Work Blocking?

```
Q: Can I complete current issue WITHOUT fixing this new issue?
├─ YES → bd create "..." --deps discovered-from:bd-PARENT
│        Continue parent work
│        Handle new issue later
│
└─ NO  → bd create "..." --deps discovered-from:bd-PARENT
         bd update bd-PARENT --status blocked
         bd update bd-NEW --status in_progress
         Fix new issue NOW
         bd close bd-NEW + jj commit
         bd update bd-PARENT --status in_progress
         Continue parent work
```

### Should I Batch Multiple Issues in One Commit?

```
Q: Are ALL issues trivial (<5 line changes each)?
├─ YES → MAYBE batch (e.g., fixing 3 typos together)
└─ NO  → NEVER batch - one issue per commit
```

### When to Consult User?

```
ALWAYS ASK USER:
- Delete tests
- Change project architecture significantly
- Introduce new major dependencies
- Clarify ambiguous requirements

DECIDE AUTONOMOUSLY:
- Which agent to consult
- Whether discovered work is blocking
- Code implementation details
- Minor refactoring decisions
```

---

## Workflow Examples

### Example 1: Search Before Create (Prevents Duplicates)

```
# User: "Add dark mode toggle to settings"

# MANDATORY SEARCH FIRST
bd list --title "dark mode" --json
# Found: bd-f14c "Add dark mode toggle" [open]

# Decision: Exact match found → Use existing issue
bd update bd-f14c --status in_progress
[implement feature]
[run tests - all must pass]
[run all review agents in parallel]
bd close bd-f14c --reason "Feature complete, tests passing"
jj commit -m "feat: add dark mode toggle"
```

### Example 2: Create When No Duplicates Found

```
# User: "Add OAuth integration"

# MANDATORY SEARCH FIRST
bd list --status open --json              # Check open
bd list --status in_progress --json       # Check in progress
bd list --title "oauth" --json            # Search by keyword
bd duplicates --json                      # Check duplicates

# Decision: No matches found → Safe to create
bd create "Add OAuth integration" -t feature -p 1
bd update bd-a1b2 --status in_progress
[implement feature]
[run tests]
[run review agents]
bd close bd-a1b2 --reason "OAuth integration complete"
jj commit -m "feat: add OAuth integration"
```

### Example 3: Feature with Discovered Bug

```
bd ready --json
bd update bd-a1b2 --status in_progress
[start implementing]
[discover bug in existing code]
bd create "Fix null pointer in theme loader" -t bug -p 1 --deps discovered-from:bd-a1b2

# Bug is BLOCKING
bd update bd-a1b2 --status blocked
bd update bd-3e7a --status in_progress
[fix bug]
[run tests]
[run review agents]
bd close bd-3e7a --reason "Fixed null check"
jj commit -m "fix: add null check in theme loader"

# Resume original work
bd update bd-a1b2 --status in_progress
[finish feature]
[run tests]
[run review agents]
bd close bd-a1b2 --reason "Complete"
jj commit -m "feat: implement dark mode"
```

### Example 4: Epic with Subtasks

```
# Create epic and subtasks
bd create "User authentication system" -t epic -p 1
bd create "Add login form" -t task -p 1 --deps parent-child:bd-9k2m
bd create "Add password hashing" -t task -p 1 --deps parent-child:bd-9k2m
bd create "Add session management" -t task -p 1 --deps blocks:bd-4h8n,blocks:bd-7j3p

# Work on first subtask
bd ready --json  # Shows bd-4h8n, bd-7j3p (not bd-2q5r - blocked)
bd update bd-4h8n --status in_progress
[implement login form]
[run tests]
[run review agents]
bd close bd-4h8n --reason "Login form complete"
jj commit -m "feat: add login form component"

# Work on second subtask
bd update bd-7j3p --status in_progress
[implement password hashing]
[run tests]
[run review agents]
bd close bd-7j3p --reason "Password hashing implemented"
jj commit -m "feat: add bcrypt password hashing"

# Third subtask now unblocked
bd ready --json  # NOW shows bd-2q5r
bd update bd-2q5r --status in_progress
[implement sessions]
[run tests]
[run review agents]
bd close bd-2q5r --reason "Sessions working"
jj commit -m "feat: add session management"

# Close epic
bd close bd-9k2m --reason "All subtasks complete"
jj commit -m "feat: complete authentication system

Closes bd-9k2m"
```

### Example 5: Test Failure During Work

```
bd ready --json
bd update bd-8v1w --status in_progress
[implement feature]
mix test  # TESTS FAIL

# IMMEDIATE ACTION
bd create "Fix failing auth tests" -t bug -p 0 --deps discovered-from:bd-8v1w
bd update bd-8v1w --status blocked
bd update bd-6d9x --status in_progress
[diagnose and fix test failures]
mix test  # TESTS PASS
[run review agents]
bd close bd-6d9x --reason "Tests now passing"
jj commit -m "fix: resolve auth test failures"

# Resume original work
bd update bd-8v1w --status in_progress
mix test  # Verify still passing
[finish feature]
[run tests]
[run review agents]
bd close bd-8v1w --reason "Feature complete, all tests pass"
jj commit -m "feat: add oauth integration"
```

### Example 6: Multiple Small Tasks

```
bd ready --json  # Shows bd-5m2k, bd-1n7p, bd-3r8q

# Task 1: Typo fix
bd update bd-5m2k --status in_progress
[fix typo]
[run review agents]
bd close bd-5m2k --reason "Typo fixed"
jj commit -m "docs: fix typo in authentication guide"

# Task 2: Update dependencies
bd update bd-1n7p --status in_progress
[update deps]
[run tests]
[run review agents]
bd close bd-1n7p --reason "Dependencies updated"
jj commit -m "chore: update dependencies"

# Task 3: Refactor
bd update bd-3r8q --status in_progress
[refactor code]
[run tests]
[run review agents]
bd close bd-3r8q --reason "Refactoring complete"
jj commit -m "refactor: simplify theme module structure"
```

### Example 7: Work-in-Progress Commits

```
bd ready --json
bd update bd-4t2y --status in_progress
[implement part 1]

# Optional: Set WIP message
jj describe -m "feat: add user profile page (WIP)"

[implement part 2]
[run tests]
[run review agents]
bd close bd-4t2y --reason "Complete"

# Update message and commit
jj describe -m "feat: add user profile page"
jj new  # Commit and create new change
```

---

## Anti-Patterns

**DO NOT DO THE FOLLOWING:**

❌ Using markdown TODO lists instead of bd
❌ **Creating issues without searching for duplicates first**
❌ **Skipping the search sequence (bd list + bd duplicates)**
❌ Skipping review agents ("just this once")
❌ Closing issues with failing tests
❌ Using `jj describe + jj new` instead of `jj commit` for standard workflow
❌ Committing without closing related bd issue
❌ Creating issues and never claiming them (use immediately or don't create)
❌ Consulting user for every minor decision (be autonomous)
❌ Implementing without consulting relevant agents first
❌ Batching unrelated issues in one commit
❌ Ignoring agent recommendations without explanation
❌ Marking work complete without running tests
❌ Deleting tests to make them pass
❌ Creating bd issues for trivial thoughts (use bd for WORK only)
❌ Updating issue status multiple times without actual progress
❌ Using priority 0 for non-critical issues

---

## Quick Reference Card

```
SEARCH   → bd list --status open/in_progress/blocked --json
           bd list --title "keywords" --json
           bd duplicates --json (MANDATORY before creating)
CLAIM    → bd update bd-XXXX --status in_progress
CREATE   → bd create "..." (ONLY after search confirms no duplicates)
CONSULT  → research-agent (unknown tech), architecture-agent (placement), skills (domain)
DISCOVER → bd create "..." --deps discovered-from:bd-PARENT
BLOCK    → bd update bd-XXXX --status blocked
TEST     → Run before closing (MUST PASS)
REVIEW   → ALL agents in parallel before EVERY bd close
CLOSE    → bd close bd-XXXX --reason "..."
COMMIT   → jj commit -m "type: description"
```

**One Rule to Rule Them All:**
```
SEARCH (all statuses + duplicates) → claim existing OR create new → consult → implement → test → review → close → commit
```
