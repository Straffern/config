# bd Advanced Features

Advanced patterns, integrations, and workflows for power users and AI agents.

## Searching with jq

bd's `--json` output works perfectly with jq for complex queries.

### Find High-Priority Bugs

```bash
bd list --json | jq -r '
  .[] | 
  select(.type == "bug" and .priority <= 1)
'
```

### Find Memory Issues by Category

```bash
bd list --json | jq -r '
  .[] | 
  select(.labels | contains(["memory:hard-won-knowledge"]))
'
```

### Find Issues Discovered from Specific Issue

```bash
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(.target) | contains(["bd-42"]))
'
```

### Find Recently Updated Issues

```bash
bd list --json | jq -r '
  .[] | 
  select(.updated_at > "2025-11-01")
'
```

### Count Issues by Type

```bash
bd list --json | jq -r '
  group_by(.type) | 
  map({type: .[0].type, count: length})
'
```

### Find All Blocked Issues with Details

```bash
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(select(.type == "blocks")) | length > 0)
'
```

---

## Bulk Operations

### Close Multiple Issues

```bash
bd close bd-42 bd-43 bd-44 --reason "Completed in batch" --json
```

### Update Priority for Multiple Issues

```bash
for id in bd-42 bd-43 bd-44; do
  bd update $id --priority 1 --json
done
```

### Add Label to All Bugs

```bash
for id in $(bd list --type bug --json | jq -r '.[].id'); do
  bd label add $id needs-review --json
done
```

### Capturing Issue ID for Scripting

```bash
# Create and capture ID for dependent work
PARENT_ID=$(bd create "Parent task" -t task --json | jq -r '.id')

bd create "Subtask 1" -t task --deps blocks:$PARENT_ID --json
bd create "Subtask 2" -t task --deps blocks:$PARENT_ID --json
```

---

## Version Control Integration

### Auto-Sync System

bd automatically syncs between SQLite and JSONL:
- Changes export to `.beads/issues.jsonl` after modifications (5s debounce)
- Imports from JSONL when it's newer than DB (e.g., after update)
- No manual export/import needed in normal workflow

### Commit Workflow with jj

**CRITICAL**: Always commit `.beads/issues.jsonl` with code changes

```bash
# jj auto-stages all changes including .beads/issues.jsonl
jj commit -m "feat: implement feature (closes bd-42)"

# Verify what's included
jj diff  # Shows all changes before committing

# Set message for current change
jj describe -m "feat: implement feature (closes bd-42)"
jj new  # Commit and create new change
```

### Commit Message Integration

Reference bd issues in commit messages:

```bash
# Close issue via commit message
jj commit -m "feat: add authentication (closes bd-42)"

# Reference issue
jj commit -m "refactor: extract validation (refs bd-42)"

# Multiple issues
jj commit -m "fix: handle edge cases (closes bd-42, closes bd-43)"
```

### Handling Conflicts

When `.beads/issues.jsonl` has conflicts after update:

```bash
# jj marks conflicts in the file
# Manually resolve, or:

# Accept both versions and re-import
cat .beads/issues.jsonl | grep -v "^<<<<<<" | grep -v "^======" | grep -v "^>>>>>>" | sort -u > .beads/issues.jsonl.merged
mv .beads/issues.jsonl.merged .beads/issues.jsonl

# Re-import to SQLite
bd import --json

# Commit resolved conflict
jj commit -m "merge: resolve bd issues conflict"
```

---

## Memory Management Patterns

Use bd to track hard-won knowledge and technical patterns.

### Store Memory as Issue

```bash
bd create "Memory: Testing patterns" \
  --type task \
  --priority 3 \
  --label memory \
  --label memory:technical-patterns \
  --desc "$(cat <<'DESC'
# Testing Patterns

## Summary
Established testing patterns for the project

## Details
- Prefer integration tests over unit tests
- Use property-based testing for complex logic
- Keep tests co-located with source

## Update History
- 2025-11-03: Initial capture
DESC
)" \
  --json
```

### Recall Memory

```bash
bd list --json | jq -r '
  .[] | 
  select(.labels | contains(["memory"])) | 
  select(.title + .description | ascii_downcase | contains("testing"))
'
```

### Memory Labels

Organize memories with hierarchical labels:
- `memory` - All memories
- `memory:technical-patterns` - Code patterns
- `memory:hard-won-knowledge` - Lessons learned
- `memory:project-context` - Project-specific info
- `memory:api-usage` - API/library usage

---

## Research Tracking Pattern

Track research work with comprehensive context:

```bash
PROJECT=$(basename $(git rev-parse --show-toplevel))

bd create "Research: Stripe integration" \
  --type task \
  --priority 2 \
  --label research \
  --label "project:$PROJECT" \
  --desc "$(cat <<'DESC'
# Stripe Integration Research

## Dependencies Found
- stripity_stripe 2.17.2

## Integration Points
- Payment Intents API
- Webhook handling
- Customer management

## Documentation
- [Stripity Stripe Docs](https://hexdocs.pm/stripity_stripe/2.17.2)

## Next Steps
- Set up test account
- Implement basic payment flow
- Add webhook validation
DESC
)" \
  --json
```

---

## MCP Tool References

When using bd with MCP (Model Context Protocol) tools, always use fully qualified tool names.

### Format

`ServerName:tool_name`

### Example

```bash
# In skill or agent instructions
Use the beads:bd_create tool to create issues.
Use the beads:bd_ready tool to find ready work.
```

Where:
- `beads` is the MCP server name
- `bd_create`, `bd_ready` are tool names within that server

Without the server prefix, Claude may fail to locate the tool.

---

## Status and Overview Commands

### Database Overview

```bash
bd status --json
```

Shows:
- Total issues
- Issues by status
- Issues by priority
- Database location
- Sync status

### Statistics

```bash
bd stats --json
```

Provides:
- Issue counts by type
- Average completion time
- Dependency statistics
- Label frequency

### Check for Issues Needing Attention

```bash
# Stale issues (not updated recently)
bd stale --json

# Blocked issues
bd blocked --json

# In-progress issues
bd list --status in_progress --json
```

---

## Validation

### Validate Database

```bash
bd validate --json
```

Checks for:
- Circular dependencies
- Invalid references
- Data consistency
- Orphaned issues

### Detect Circular Dependencies

```bash
bd dep cycles --json
```

Returns any circular dependency chains found.

Example output:
```json
{
  "cycles": [
    ["bd-42", "bd-43", "bd-44", "bd-42"]
  ]
}
```

---

## Import/Export

### Manual Export

```bash
bd export --json
```

Exports SQLite database to `.beads/issues.jsonl`.

**When to use:**
- Before major changes
- When auto-sync seems stuck
- For backup purposes

### Manual Import

```bash
bd import --json
```

Imports from `.beads/issues.jsonl` to SQLite database.

**When to use:**
- After `git pull` if auto-import didn't trigger
- After manually editing JSONL file
- When recovering from conflicts

---

## Integration with AI Workflows

### For Planners

Feature/fix/task planners should:
1. Create parent issue (epic, bug, or task)
2. Break into subtasks with `blocks` dependencies or hierarchical IDs
3. Include comprehensive descriptions
4. Set appropriate priorities and labels
5. Return issue IDs for tracking

### For Implementers

During implementation:
1. Check `bd ready --json` for unblocked work
2. Claim with `bd update <id> --status in_progress --json`
3. Create discovered work with `discovered-from`
4. Close with `bd close <id> --reason "..." --json`
5. Commit code + `.beads/issues.jsonl` together

### For Reviewers

During code review:
1. Check bd status: `bd show <id> --json`
2. Verify tests included
3. Check for discovered work needing attention
4. Validate dependencies resolved

---

## Environment Variables

### BD_PROJECT_DIR

Override project directory detection.

```bash
BD_PROJECT_DIR=/path/to/project bd ready --json
```

### BD_DB_PATH

Override database path.

```bash
BD_DB_PATH=/custom/path/.beads/db.sqlite bd list --json
```

---

## Advanced Workflow Patterns

### Feature Development with Research

```bash
# 1. Create research task
RESEARCH=$(bd create "Research: OAuth providers" -t task -p 2 \
  --label research --json | jq -r '.id')

# 2. Work on research, discover options

# 3. Create epic based on research
EPIC=$(bd create "Feature: OAuth integration" -t epic -p 1 \
  --deps discovered-from:$RESEARCH --json | jq -r '.id')

# 4. Break into subtasks
bd create "Google OAuth" -t task --parent $EPIC --no-daemon --json
bd create "GitHub OAuth" -t task --parent $EPIC --no-daemon --json
bd create "OAuth tests" -t task --parent $EPIC --no-daemon --json

# 5. Close research
bd close $RESEARCH --reason "Research complete, epic created" --json
```

### Bug Investigation to Fix

```bash
# 1. Create investigation issue
BUG=$(bd create "Bug: Memory leak in worker" -t bug -p 0 \
  --desc "Investigation and fix" --json | jq -r '.id')

# 2. Investigate, discover root cause

# 3. Create fix tasks
bd create "Fix worker cleanup" -t task --deps blocks:$BUG --json
bd create "Add memory profiling" -t task --deps blocks:$BUG --json
bd create "Add leak detection tests" -t task --deps blocks:$BUG --json

# 4. Work through fixes

# 5. Close bug when all blockers done
bd close $BUG --reason "All fixes implemented and tested" --json
```

### Technical Debt Tracking

```bash
# During feature work, discover debt
bd create "Refactor: Extract validation logic" \
  -t task -p 3 \
  --deps discovered-from:bd-feature \
  --label tech-debt \
  --label area:validation \
  --desc "Validation logic duplicated across 3 files" \
  --json

# Later, query all tech debt
bd list --json | jq -r '.[] | select(.labels | contains(["tech-debt"]))'

# Prioritize and tackle
bd update bd-debt-1 --priority 2 --json
bd update bd-debt-1 --status in_progress --json
```

---

## Tips and Tricks

### Always Use --json

For programmatic operations (AI agents, scripts):
```bash
bd ready --json
bd create "..." --json
bd update bd-42 --json
```

### Link Discovered Work

CRITICAL for traceability:
```bash
bd create "Found issue" --deps discovered-from:bd-parent --json
```

### Check Ready Before Asking

```bash
# Instead of asking "what should I work on?"
bd ready --json
```

### Commit Issues with Code

```bash
# jj auto-stages everything
jj commit -m "message"
```

### Use Hierarchical IDs for Epics

```bash
bd create "Epic" -t epic --no-daemon --json
bd create "Task" --parent bd-epic --no-daemon --json
```

### Filter with jq

```bash
# Complex queries
bd list --json | jq '[.[] | select(.priority <= 1 and .status == "open")]'
```

### Validate Regularly

```bash
# Catch circular dependencies early
bd dep cycles --json
```

---

## Troubleshooting

### Daemon Issues

```bash
# Check daemon status
bd info --json

# Restart daemon
killall bd-daemon
bd daemon
```

### Sync Issues

```bash
# Force export
bd export --json

# Force import
bd import --json

# Check file timestamps
ls -la .beads/
```

### Missing Issues After Pull

```bash
# Re-import from JSONL
bd import --json
```

### Circular Dependencies

```bash
# Detect
bd dep cycles --json

# Fix
bd dep rm bd-A bd-B --json
```

---

## Summary

**Advanced features enable:**
- Complex queries with jq
- Bulk operations on multiple issues
- Version control integration (git/jj)
- Memory and research tracking
- MCP tool integration
- Status monitoring and validation

**Key practices:**
- Use `--json` for all programmatic operations
- Commit `.beads/issues.jsonl` with code
- Link discovered work with `discovered-from`
- Validate regularly with `bd dep cycles`
- Filter and search with jq for complex queries
