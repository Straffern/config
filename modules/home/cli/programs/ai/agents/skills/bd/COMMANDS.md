# bd Command Reference

Complete reference for all bd commands and options.

## Core Commands

### bd create

Create new issues.

```bash
# Basic syntax
bd create "Issue title" -t TYPE -p PRIORITY --json

# With description
bd create "Issue title" -t feature -p 1 \
  -d "Detailed description" \
  --json

# With dependencies (during creation)
bd create "Subtask" -t task --deps blocks:bd-42 --json
bd create "Work" --deps discovered-from:bd-42 --json
bd create "Docs" --deps related:bd-42 --json
bd create "Child" --deps parent-child:bd-42 --json

# With labels
bd create "Issue" -t bug \
  --label security \
  --label critical \
  --json

# Hierarchical children (epic breakdown)
bd create "Parent Epic" -t epic -p 1 --no-daemon --json
bd create "Child task" -t task --parent bd-EPIC --no-daemon --json

# Nested epic (up to 3 levels)
bd create "Child epic" -t epic --parent bd-PARENT --no-daemon --json
bd create "Grandchild" -t task --parent bd-PARENT.CHILD --no-daemon --json
```

**Options:**
- `-t, --type`: Issue type (bug, feature, task, epic, chore)
- `-p, --priority`: Priority level (0-4)
- `-d, --description`: Detailed description
- `--deps TYPE:ID`: Add dependency during creation
- `--label LABEL`: Add label (can repeat)
- `--parent ID`: Create hierarchical child (requires `--no-daemon`)
- `--assignee NAME`: Assign to user
- `--json`: Output JSON format

**Returns:** Issue ID and details

### bd update

Update existing issues.

```bash
# Update status
bd update bd-42 --status in_progress --json
bd update bd-42 --status blocked --json
bd update bd-42 --status open --json

# Update priority
bd update bd-42 --priority 0 --json

# Update assignee
bd update bd-42 --assignee alex --json

# Update description
bd update bd-42 --desc "Updated description" --json

# Add notes
bd update bd-42 --notes "Progress update" --json

# Multiple fields at once
bd update bd-42 \
  --status in_progress \
  --priority 1 \
  --assignee $(whoami) \
  --json
```

**Options:**
- `--status`: Change status (open, in_progress, blocked, closed)
- `--priority`: Change priority (0-4)
- `--assignee`: Assign to user
- `--desc`: Update description
- `--notes`: Add progress notes
- `--json`: Output JSON format

### bd close

Close completed issues.

```bash
# Close single issue
bd close bd-42 --reason "Completed successfully" --json

# Close multiple issues
bd close bd-42 bd-43 bd-44 --reason "Batch completion" --json

# Reopen if needed
bd reopen bd-42 --reason "Found additional work" --json
```

**Options:**
- `--reason`: Reason for closing (required)
- `--json`: Output JSON format

### bd ready

Show unblocked work ready to start.

```bash
# All ready work
bd ready --json

# Filter by priority
bd ready --priority 1 --json

# Filter by assignee
bd ready --assignee $(whoami) --json
```

**Shows:** Issues with status "open" or "in_progress" that have no unresolved blocking dependencies.

### bd list

List issues with filtering.

```bash
# List all issues
bd list --json

# Filter by status
bd list --status open --json
bd list --status in_progress --json
bd list --status closed --json

# Filter by type
bd list --type bug --json
bd list --type feature --json

# Filter by priority
bd list --priority 0 --json

# Filter by label
bd list --label security --json

# Filter by assignee
bd list --assignee alex --json

# Combine filters
bd list --status open --type bug --priority 0 --json
```

**Options:**
- `--status`: Filter by status
- `--type`: Filter by type
- `--priority`: Filter by priority
- `--label`: Filter by label
- `--assignee`: Filter by assignee
- `--json`: Output JSON format

### bd show

Show detailed information about specific issue.

```bash
bd show bd-42 --json
```

**Output includes:**
- Issue metadata (title, description, status, priority)
- Dependencies (blocks, blocked by, discovered from, related)
- Labels
- Timestamps (created, updated, closed)
- Notes history

### bd blocked

Find issues that are blocked by unresolved dependencies.

```bash
bd blocked --json
```

### bd stale

Find issues that haven't been updated recently.

```bash
bd stale --json
```

---

## Dependency Management

### bd dep add

Add dependencies after issue creation.

```bash
# bd-41 blocks bd-42 (bd-42 depends on bd-41)
bd dep add bd-42 bd-41 --type blocks --json

# Other dependency types
bd dep add bd-42 bd-40 --type discovered-from --json
bd dep add bd-42 bd-39 --type related --json
bd dep add bd-42 bd-38 --type parent-child --json
```

**Syntax:** `bd dep add ISSUE DEPENDENCY --type TYPE`

Where:
- `ISSUE`: The issue receiving the dependency
- `DEPENDENCY`: The issue it depends on
- `TYPE`: Dependency type (blocks, discovered-from, related, parent-child)

### bd dep rm

Remove dependencies.

```bash
bd dep rm bd-42 bd-41 --json
```

### bd dep tree

Visualize dependency tree.

```bash
bd dep tree bd-42
```

Shows hierarchical view of dependencies.

### bd dep cycles

Detect circular dependencies.

```bash
bd dep cycles --json
```

Returns any circular dependency chains found.

---

## Label Management

### bd label add

Add labels to issues.

```bash
# Single label
bd label add bd-42 security --json

# Multiple labels
bd label add bd-42 security urgent critical --json
```

### bd label rm

Remove labels from issues.

```bash
bd label rm bd-42 urgent --json
```

### List by label

```bash
# Using list command
bd list --label security --json

# Using jq
bd list --json | jq -r '.[] | select(.labels | contains(["security"]))'
```

---

## Comments

### bd comments add

Add comment to issue.

```bash
bd comments add bd-42 "This is a comment" --json
```

### bd comments list

List comments on issue.

```bash
bd comments list bd-42 --json
```

---

## Status and Information

### bd status

Show database overview.

```bash
bd status --json
```

### bd stats

Show statistics.

```bash
bd stats --json
```

### bd info

Show daemon and configuration info.

```bash
bd info --json
```

---

## Import/Export

### bd export

Export issues to JSONL (happens automatically after 5s debounce).

```bash
bd export --json
```

### bd import

Import issues from JSONL (happens automatically when file is newer).

```bash
bd import --json
```

---

## Validation

### bd validate

Validate issue database for consistency.

```bash
bd validate --json
```

Checks for:
- Circular dependencies
- Invalid references
- Data consistency

---

## Advanced Queries with jq

### Find high-priority bugs

```bash
bd list --json | jq -r '
  .[] | 
  select(.type == "bug" and .priority <= 1)
'
```

### Find issues discovered from specific issue

```bash
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(.target) | contains(["bd-42"]))
'
```

### Find recently updated issues

```bash
bd list --json | jq -r '
  .[] | 
  select(.updated_at > "2025-11-01")
'
```

### Count issues by type

```bash
bd list --json | jq -r '
  group_by(.type) | 
  map({type: .[0].type, count: length})
'
```

### Find all blocked issues with details

```bash
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(select(.type == "blocks")) | length > 0)
'
```

---

## Bulk Operations

### Close multiple issues

```bash
bd close bd-42 bd-43 bd-44 --reason "Completed in batch" --json
```

### Update priority for multiple issues

```bash
for id in bd-42 bd-43 bd-44; do
  bd update $id --priority 1 --json
done
```

### Add label to all bugs

```bash
for id in $(bd list --type bug --json | jq -r '.[].id'); do
  bd label add $id needs-review --json
done
```

---

## ID Format

**Standard IDs**: Hash-based format (e.g., `bd-f14c`, `bd-a1b2`, `bd-3e7a`)

**Hierarchical Child IDs**: Dot notation for epic breakdown

```
bd-a3f8e9          [epic]  Auth System
bd-a3f8e9.1        [task]  Login UI
bd-a3f8e9.2        [task]  Backend validation
bd-a3f8e9.3        [epic]  Password Reset
bd-a3f8e9.3.1      [task]  Email templates
bd-a3f8e9.3.2      [task]  Reset flow tests
```

**Benefits:**
- Collision-free (parent hash ensures unique namespace)
- Human-readable (clear parent-child relationships)
- Flexible depth (up to 3 levels)
- No coordination needed

---

## Common Options

### --json flag

**CRITICAL:** Always use `--json` flag for programmatic operations.

Ensures consistent, parseable output for automation and AI agents.

### --no-daemon flag

**Required** when using `--parent` flag for hierarchical children.

```bash
bd create "Child" --parent bd-EPIC --no-daemon --json
```

---

## Exit Codes

- `0`: Success
- `1`: General error
- `2`: Invalid arguments
- `3`: Issue not found
- `4`: Dependency error

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

## Examples by Scenario

### Feature Development

```bash
# Create epic
EPIC=$(bd create "Feature: User Profile" -t feature -p 1 --json | jq -r '.id')

# Break into subtasks with hierarchical IDs
bd create "Create Profile resource" -t task --parent $EPIC --no-daemon --json
bd create "Add profile routes" -t task --parent $EPIC --no-daemon --json
bd create "Add profile UI" -t task --parent $EPIC --no-daemon --json
bd create "Add profile tests" -t task --parent $EPIC --no-daemon --json

# Work through ready tasks
bd ready --json
```

### Bug Investigation

```bash
# Create bug issue
BUG=$(bd create "Bug: Login fails with SSO" -t bug -p 1 \
  --desc "Investigation and fix for SSO login failure" \
  --json | jq -r '.id')

# Investigation reveals multiple issues
bd create "Fix SAML parsing" -t task --deps blocks:$BUG --json
bd create "Update session handling" -t task --deps blocks:$BUG --json
bd create "Add SSO tests" -t task --deps blocks:$BUG --json
```

### Technical Debt

```bash
# Track debt discovered during work
bd create "Refactor: Extract validation logic" \
  -t task -p 3 \
  --deps discovered-from:bd-42 \
  --label tech-debt \
  --desc "Validation logic duplicated across 3 files" \
  --json
```

---

## Tips

1. **Always use `--json`** for programmatic operations
2. **Link discovered work** with `discovered-from`
3. **Check `bd ready`** before asking what to work on
4. **Commit `.beads/issues.jsonl`** with code changes
5. **Use hierarchical IDs** for clear epic breakdown
6. **Filter with jq** for complex queries
7. **Validate regularly** to catch circular dependencies
