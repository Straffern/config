---
name: bd
description: Issue tracking and dependency management with bd (beads). Use when managing tasks, creating issues, tracking work progress, checking what to work on next, or linking discovered work. Supports hierarchical epic breakdown, dependency tracking, and VCS-friendly JSONL export.
---

# bd (beads) Issue Tracking

**CRITICAL**: This project uses bd for ALL task tracking. Never use markdown TODOs, task lists in comments, or external trackers.

## Quick Start

```bash
# Check what to work on
bd ready --json

# Create issue
bd create "Issue title" -t bug|feature|task|epic|chore -p 0-4 --json

# Claim work
bd update bd-42 --status in_progress --json

# Complete work
bd close bd-42 --reason "Completed" --json
```

## Core Workflow for AI Agents

### Step 1: Check Ready Work

**Before starting any work:**

```bash
bd ready --json
```

Shows unblocked issues ready to work on. If empty, check all issues with `bd list --json`.

### Step 2: Claim Your Task

```bash
bd update bd-42 --status in_progress --json
```

Signals you're working on it and prevents duplicate work.

### Step 3: Work on It

Standard development workflow - implement, test, document, format code, update CHANGELOG if needed.

### Step 4: Discover New Work? Create Linked Issue

**Critical for traceability:**

```bash
bd create "Found edge case: empty list behavior" -t bug -p 1 \
  --deps discovered-from:bd-42 --json
```

**Why use `discovered-from`:**
- ✅ Traces where the issue was found
- ✅ Links related work together
- ✅ Helps understand issue context
- ✅ Prevents lost work items

### Step 5: Complete

```bash
bd close bd-42 --reason "Implemented with full test coverage" --json
```

**Verify before closing:**
- ✅ Code implemented and tested
- ✅ Tests pass
- ✅ Code formatted
- ✅ CHANGELOG.md updated (if user-facing)
- ✅ Changes committed

---

## Essential Commands

### Creating Issues

```bash
# Basic creation
bd create "Issue title" -t TYPE -p PRIORITY --json

# With description
bd create "Issue title" -t feature -p 1 -d "Detailed description" --json

# With dependencies
bd create "Subtask" -t task --deps blocks:bd-42 --json

# Discovered work (ALWAYS link)
bd create "Found bug" -t bug -p 1 --deps discovered-from:bd-42 --json

# Hierarchical epic breakdown (see HIERARCHICAL_IDS.md)
bd create "Parent Epic" -t epic -p 1 --no-daemon --json
bd create "Child task" -t task --parent bd-EPIC --no-daemon --json
```

### Querying Issues

```bash
bd ready --json              # Show ready work
bd list --json               # List all issues
bd list --status open --json # Filter by status
bd show bd-42 --json         # Show specific issue
bd blocked --json            # Find blocked issues
```

### Updating Issues

```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
bd update bd-42 --notes "Progress notes" --json
```

### Completing Work

```bash
bd close bd-42 --reason "Completed successfully" --json
```

---

## Issue Types

| Type | Purpose | Examples |
|------|---------|----------|
| `bug` | Something broken | Login fails, validation error, memory leak |
| `feature` | New functionality | User auth, API endpoint, new primitive |
| `task` | Work item | Tests, docs, refactoring, optimization |
| `epic` | Large feature with subtasks | Complete auth system, payment flow |
| `chore` | Maintenance | Dependencies, tooling, CI/CD |

## Priorities

| Priority | Level | When to Use |
|----------|-------|-------------|
| `0` | Critical | Security vulnerabilities, data loss, broken builds, spec violations |
| `1` | High | Major features, important bugs, blocking other work |
| `2` | Medium | Default priority, nice-to-have features, minor bugs |
| `3` | Low | Polish, optimization, code cleanup |
| `4` | Backlog | Future ideas, "would be nice" features |

---

## Dependency Types

**blocks**: Hard dependency - `bd-43 blocks bd-42` means bd-42 cannot complete until bd-43 is done

```bash
bd create "Prerequisite task" -t task --deps blocks:bd-42 --json
```

**discovered-from**: Work found during implementation - CRITICAL for traceability

```bash
bd create "Found bug" -t bug --deps discovered-from:bd-42 --json
```

**related**: Soft connection without hard dependency

```bash
bd create "Update docs" -t task --deps related:bd-42 --json
```

**parent-child**: Hierarchical epic/subtask relationship

```bash
bd create "Subtask" -t task --deps parent-child:bd-42 --json
```

**See [DEPENDENCIES.md](DEPENDENCIES.md) for complete guide.**

---

## Hierarchical Epic Breakdown

For large features, use hierarchical child IDs with `--parent` flag:

```bash
# Create epic
bd create "Auth System" -t epic -p 1 --no-daemon --json
# Returns: bd-a3f8e9

# Create children (auto-numbered)
bd create "Login UI" -t task --parent bd-a3f8e9 --no-daemon --json
# Returns: bd-a3f8e9.1

bd create "Backend validation" -t task --parent bd-a3f8e9 --no-daemon --json
# Returns: bd-a3f8e9.2
```

**Benefits:**
- Clear parent-child relationships (bd-epic.1, bd-epic.2)
- Auto-numbered (no coordination needed)
- Up to 3 levels of nesting
- Human-readable structure

**⚠️ Current Limitation:** `--parent` flag requires `--no-daemon` mode

**See [HIERARCHICAL_IDS.md](HIERARCHICAL_IDS.md) for complete guide and decision tree.**

---

## Version Control Integration

**CRITICAL**: Always commit `.beads/issues.jsonl` with code changes

```bash
# jj auto-stages all changes including .beads/issues.jsonl
jj commit -m "feat: implement feature (refs bd-42)"

# Verify what's included before committing
jj diff

# Alternative: Set message then commit
jj describe -m "feat: implement feature (refs bd-42)"
jj new  # Commits and creates new change
```

**Note:** Reference bd issues in commit messages for traceability. bd does not auto-close issues from commit messages - you must explicitly close them with `bd close`.

**Auto-sync**: bd automatically syncs between SQLite and JSONL:
- Changes export to `.beads/issues.jsonl` after 5s debounce
- Imports from JSONL when newer than DB (e.g., after update)
- No manual export/import needed

---

## Common Workflow Patterns

### Standard Development Flow

```bash
# 1. Check ready work
bd ready --json

# 2. Claim issue
bd update bd-42 --status in_progress --json

# 3. Work on it (implement, test, document)

# 4. Discover additional work? Create linked issue
bd create "Fix edge case" -t bug --deps discovered-from:bd-42 --json

# 5. Complete
bd close bd-42 --reason "Implemented and tested" --json

# 6. Commit (jj auto-stages all changes)
jj commit -m "feat: implement feature (refs bd-42)"
```

### Epic with Subtasks (Hierarchical)

```bash
# Create epic
bd create "Feature: User Auth" -t epic -p 1 --no-daemon --json
# Returns: bd-auth

# Create children
bd create "Create User resource" -t task --parent bd-auth --no-daemon --json
bd create "Add auth routes" -t task --parent bd-auth --no-daemon --json
bd create "Add LiveView integration" -t task --parent bd-auth --no-daemon --json

# Work through ready tasks
bd ready --json  # Shows bd-auth.1, bd-auth.2, bd-auth.3

# When all children done, close epic
bd close bd-auth --reason "All subtasks complete" --json
```

### Discovered Bug During Work

```bash
# Working on bd-42 (feature)
# Found a bug in existing code

# Create linked bug issue
bd create "URL parser crashes on null input" -t bug -p 0 \
  --deps discovered-from:bd-42 --json

# Decide priority:
#   P0 (critical)? Fix immediately
#   P1 (high)? Fix after current feature
#   P2+ (medium/low)? Fix later
```

---

## Documentation Strategy

### Track in beads (for task management)
- ✅ Work items (bugs, features, tasks)
- ✅ Progress notes (`bd update --notes`)
- ✅ Discovered issues
- ✅ Dependencies and blockers

### Store in `docs/` (ignored working notes)
- ✅ Analysis documents
- ✅ Research notes
- ✅ Progress summaries
- ✅ Test results
- ✅ Planning documents
- ✅ Personal notes and scratch work

### Commit to repo root (essential public docs)
- ✅ `README.md` - User documentation
- ✅ `CHANGELOG.md` - Version history (user-facing changes only)
- ✅ `CONTRIBUTING.md` - Contributor guide
- ✅ `AGENTS.md` - Agent instructions
- ✅ `LICENSE` - License file

**Why?** Keeps repository clean, prevents commit noise from progress updates, maintains single source of truth (beads).

---

## Best Practices

**✅ DO:**
- Use bd for ALL task tracking
- Always use `--json` flag for programmatic operations
- Link discovered work with `discovered-from`
- Check `bd ready --json` before starting new work
- Commit `.beads/issues.jsonl` with code changes (jj auto-stages)
- Update issue status as work progresses
- Use hierarchical IDs for epic breakdown
- Store working notes in `docs/` directory

**❌ DON'T:**
- Create markdown TODO lists
- Use external issue trackers
- Duplicate tracking systems
- Forget `--json` flag
- Skip `discovered-from` links
- Delete tests to make them pass
- Clutter root with working notes

---

## Quick Command Reference

```bash
# Common commands
bd ready --json                           # Find work
bd create "Title" -t TYPE -p NUM --json  # Create issue
bd update ID --status STATUS --json      # Update status
bd close ID --reason "REASON" --json     # Close issue
bd show ID --json                         # Show details
bd list --json                            # List all issues

# With dependencies
bd create "Task" --deps blocks:ID --json
bd create "Work" --deps discovered-from:ID --json
bd create "Docs" --deps related:ID --json

# Hierarchical children
bd create "Epic" -t epic --no-daemon --json
bd create "Child" --parent bd-EPIC --no-daemon --json
```

---

## Advanced Features

For detailed information on:
- **Complete command reference**: See [COMMANDS.md](COMMANDS.md)
- **Dependency management**: See [DEPENDENCIES.md](DEPENDENCIES.md)
- **Hierarchical IDs**: See [HIERARCHICAL_IDS.md](HIERARCHICAL_IDS.md)
- **Advanced workflows**: See [ADVANCED.md](ADVANCED.md)
  - Version control integration (jj/git)
  - Bulk operations
  - MCP tool references
  - Searching with jq
  - Memory management patterns

---

## Troubleshooting

### Issue Not Showing in Ready

```bash
# Check if blocked
bd show bd-42 --json | jq '.dependencies'

# Check status (must be "open" or "in_progress")
bd show bd-42 --json | jq '.status'
```

### Changes Not Syncing

```bash
# Manual export
bd export --json

# Manual import
bd import --json
```

---

## Summary

**bd (beads) is the single source of truth for task tracking.**

**Key principles:**
1. ✅ Use bd for ALL task tracking
2. ✅ Always use `--json` flag
3. ✅ Link discovered work with `discovered-from`
4. ✅ Check `bd ready` before starting work
5. ✅ Commit `.beads/issues.jsonl` with code changes

**Workflow:** ready → claim → implement → discover & link → test → close → commit
