---
name: bd
description: bd (beads) issue tracking and dependency management
---

# bd (beads) Expertise

Comprehensive guidance on bd (beads) issue tracker, dependency management, workflow integration, and git-friendly issue tracking for development teams.

## Overview

bd is a lightweight issue tracker with first-class dependency support. Issues are "chained together like beads" with sophisticated relationship tracking.

### Core Philosophy

- **Dependency-first**: Issues track blocking relationships explicitly
- **Git-friendly**: SQLite database + JSONL export for version control
- **CLI-native**: Designed for programmatic use with `--json` flag
- **Agent-optimized**: Ready work detection, discovered-from links, status tracking

## Essential Commands

### Issue Creation

```bash
# Basic issue creation
bd create "Issue title" -t bug|feature|task|epic|chore -p 0-4 --json

# With description
bd create "Issue title" -t feature -p 1 \
  --desc "Detailed description" \
  --json

# With dependencies
bd create "Subtask" -t task \
  --deps blocks:bd-42 \
  --json

# With labels
bd create "Issue" -t bug \
  --label security \
  --label critical \
  --json

# Discovered work
bd create "Found bug" -t bug -p 1 \
  --deps discovered-from:bd-42 \
  --desc "Found while working on bd-42" \
  --json
```

### Querying Issues

```bash
# Show ready work (unblocked, open or in-progress)
bd ready --json
bd ready --priority 1 --json
bd ready --assignee $(whoami) --json

# List issues
bd list --json
bd list --status open --json
bd list --type feature --json
bd list --label security --json

# Show specific issue
bd show bd-42 --json

# Find blocked issues
bd blocked --json

# Find stale issues
bd stale --json
```

### Updating Issues

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

# Update multiple fields
bd update bd-42 \
  --status in_progress \
  --priority 1 \
  --assignee $(whoami) \
  --json
```

### Dependency Management

```bash
# Add dependencies (bd-41 blocks bd-42, bd-42 depends on bd-41)
bd dep add bd-42 bd-41 --type blocks --json
bd dep add bd-42 bd-40 --type discovered-from --json
bd dep add bd-42 bd-39 --type related --json
bd dep add bd-42 bd-38 --type parent-child --json

# Remove dependencies
bd dep rm bd-42 bd-41 --json

# Show dependencies (in show output)
bd show bd-42 --json

# Visualize dependency tree
bd dep tree bd-42

# Detect circular dependencies
bd dep cycles --json
```

### Label Management

```bash
# Add labels
bd label add bd-42 security urgent --json

# Remove labels
bd label rm bd-42 urgent --json

# List issues by label
bd list --json | jq -r '.[] | select(.labels | contains(["security"]))'
```

### Completing Work

```bash
# Close issue
bd close bd-42 --reason "Completed successfully" --json

# Close multiple issues
bd close bd-42 bd-43 bd-44 --reason "Batch completion" --json

# Reopen if needed
bd reopen bd-42 --reason "Found additional work" --json
```

### Comments

```bash
# Add comment
bd comments add bd-42 "This is a comment" --json

# List comments
bd comments list bd-42 --json
```

## Issue Types

| Type      | Purpose                                      | Examples                              |
| --------- | -------------------------------------------- | ------------------------------------- |
| `bug`     | Something broken that needs fixing           | Login fails, validation error         |
| `feature` | New functionality (can be epic for complex)  | User authentication, API endpoint     |
| `task`    | Work item (tests, docs, refactoring)         | Add tests, update docs, extract util  |
| `epic`    | Large feature with multiple subtasks         | Complete auth system, payment flow    |
| `chore`   | Maintenance (dependencies, tooling, infra)   | Update deps, CI config, database tuning |

## Priority Levels

| Priority | Meaning    | Use Cases                                    |
| -------- | ---------- | -------------------------------------------- |
| `0`      | Critical   | Security vulnerabilities, data loss, broken builds |
| `1`      | High       | Major features, important bugs, blocking work |
| `2`      | Medium     | Default, nice-to-have features, minor bugs   |
| `3`      | Low        | Polish, optimization, minor improvements     |
| `4`      | Backlog    | Future ideas, wishlist items                 |

## Dependency Types

### blocks

**Meaning**: This issue blocks the referenced issue from completion.

**Usage**: `bd-43 blocks bd-42` means bd-42 is blocked by bd-43

```bash
# Task that must complete before epic
bd create "Implement core feature" \
  --type task \
  --deps blocks:bd-42 \
  --json
```

**When to use**:
- Subtasks that block parent epic
- Prerequisites that must finish first
- Hard dependencies between work items

### discovered-from

**Meaning**: This work was discovered while working on another issue.

**Usage**: Track where work originated for context

```bash
# Bug found during feature implementation
bd create "Fix validation edge case" \
  --type bug \
  --deps discovered-from:bd-42 \
  --json
```

**When to use**:
- Bugs found during implementation
- Additional work discovered mid-task
- Scope expansion that needs tracking
- Technical debt identified during work

### related

**Meaning**: Loosely related work without hard dependency (soft connection).

**Usage**: Link related but independent work

```bash
# During creation
bd create "Update API docs" \
  --type task \
  --deps related:bd-42 \
  --json

# After creation
bd dep add bd-43 bd-42 --type related --json
```

**When to use**:
- Related documentation
- Similar work in different areas
- Contextually connected issues
- Cross-references for future reference

### parent-child

**Meaning**: Hierarchical epic/subtask relationship.

**Usage**: Organize work into epics with subtasks

```bash
# During creation
bd create "Implement auth component" \
  --type task \
  --deps parent-child:bd-42 \
  --json

# After creation
bd dep add bd-43 bd-42 --type parent-child --json
# bd-42 is parent epic, bd-43 is child task
```

**When to use**:
- Breaking epics into subtasks
- Hierarchical work organization
- Multi-step features with clear parent-child structure

## Common Workflow Patterns

### Standard Development Flow

```bash
# 1. Check ready work
bd ready --json

# 2. Claim issue
bd update bd-42 --status in_progress --json

# 3. Work on it (implement, test, document)

# 4. Discover additional work? Create linked issue
bd create "Fix edge case" -t bug \
  --deps discovered-from:bd-42 \
  --json

# 5. Complete
bd close bd-42 --reason "Implemented and tested" --json

# 6. Commit code + .beads/issues.jsonl together
git add .beads/issues.jsonl [other files]
git commit -m "feat: implement feature (closes bd-42)"
```

### Epic with Subtasks

```bash
# 1. Create epic
EPIC_ID=$(bd create "Feature: User Auth" -t feature -p 1 \
  --desc "Comprehensive authentication system" \
  --json | jq -r '.id')

# 2. Create subtasks that block the epic
bd create "Create User resource" -t task \
  --deps blocks:$EPIC_ID \
  --json

bd create "Add auth routes" -t task \
  --deps blocks:$EPIC_ID \
  --json

bd create "Integrate with LiveView" -t task \
  --deps blocks:$EPIC_ID \
  --json

# 3. Work through subtasks using bd ready
bd ready --json  # Shows unblocked subtasks

# 4. Epic completes when all subtasks are closed
```

### Memory Management Pattern

```bash
# Store memory as bd issue
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

# Recall memory
bd list --json | jq -r '
  .[] | 
  select(.labels | contains(["memory"])) | 
  select(.title + .description | ascii_downcase | contains("testing"))
'
```

### Research Tracking Pattern

```bash
# Track research work
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
DESC
)" \
  --json
```

## Advanced Features

### Searching with jq

```bash
# Find high-priority bugs
bd list --json | jq -r '
  .[] | 
  select(.type == "bug" and .priority <= 1)
'

# Find memory issues by category
bd list --json | jq -r '
  .[] | 
  select(.labels | contains(["memory:hard-won-knowledge"]))
'

# Find issues discovered from specific issue
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(.target) | contains(["bd-42"]))
'

# Find recently updated issues
bd list --json | jq -r '
  .[] | 
  select(.updated_at > "2025-11-01")
'
```

### Capturing Issue ID

```bash
# Create and capture ID for dependent work
PARENT_ID=$(bd create "Parent task" -t task --json | jq -r '.id')

bd create "Subtask 1" -t task --deps blocks:$PARENT_ID --json
bd create "Subtask 2" -t task --deps blocks:$PARENT_ID --json
```

### Bulk Operations

```bash
# Close multiple issues
bd close bd-42 bd-43 bd-44 --reason "Completed in batch" --json

# Update priority for multiple issues
for id in bd-42 bd-43 bd-44; do
  bd update $id --priority 1 --json
done

# Add label to multiple issues
for id in $(bd list --type bug --json | jq -r '.[].id'); do
  bd label add $id needs-review --json
done
```

### Status Overview

```bash
# Database overview
bd status --json

# Statistics
bd stats --json

# Check for issues needing attention
bd stale --json
bd blocked --json
```

## Git Integration

### Auto-Sync System

bd automatically syncs between SQLite and JSONL:
- Changes export to `.beads/issues.jsonl` after modifications (5s debounce)
- Imports from JSONL when it's newer than DB (e.g., after `git pull`)
- No manual export/import needed in normal workflow

### Commit Workflow

**CRITICAL**: Always commit `.beads/issues.jsonl` with code changes

```bash
# Good: Issue state and code together
git add .beads/issues.jsonl src/feature.ex test/feature_test.exs
git commit -m "feat: implement feature (closes bd-42)"

# Bad: Code without issue state
git add src/feature.ex
git commit -m "feat: implement feature"
# .beads/issues.jsonl not committed!
```

### Commit Message Integration

Reference bd issues in commit messages:

```bash
# Close issue via commit message
git commit -m "feat: add authentication (closes bd-42)"

# Reference issue
git commit -m "refactor: extract validation (refs bd-42)"

# Multiple issues
git commit -m "fix: handle edge cases (closes bd-42, closes bd-43)"
```

## Best Practices

### Issue Creation

**Clear Titles**:
- ✅ "Add email validation to User resource"
- ✅ "Fix password reset token expiration"
- ❌ "Validation"
- ❌ "Fix bug"

**Detailed Descriptions**:
- Include context and background
- Specify acceptance criteria
- Link related documentation
- Add reproduction steps (for bugs)

**Appropriate Types**:
- Use `bug` for things that are broken
- Use `feature` for new functionality
- Use `task` for work items (tests, docs, refactoring)
- Use `epic` for large features with subtasks
- Use `chore` for maintenance work

**Sensible Priorities**:
- Reserve priority 0 for true emergencies
- Most work should be priority 1-2
- Use priority 3-4 for nice-to-haves

### Issue Management

**Check Ready Work First**:
```bash
# Always check what's unblocked before asking
bd ready --json
```

**Update Status**:
```bash
# Mark when starting
bd update bd-42 --status in_progress --json

# Mark when blocked
bd update bd-42 --status blocked --json

# Close when done
bd close bd-42 --reason "Completed" --json
```

**Link Discovered Work**:
```bash
# Use discovered-from for traceability
bd create "Found issue" \
  --deps discovered-from:bd-42 \
  --json
```

**Commit Together**:
```bash
# Always include .beads/issues.jsonl
git add .beads/issues.jsonl [files]
git commit -m "message"
```

### Dependency Design

**Use blocks for hard dependencies**:
- When work truly can't proceed without another issue
- Subtasks blocking parent epic
- Prerequisites for implementation

**Use discovered-from for traceability**:
- Track where work originated
- Maintain context for future reference
- Show work discovery patterns

**Avoid circular dependencies**:
- Ensure dependency graph is acyclic
- If A blocks B, B cannot block A
- Use `related` for non-blocking relationships

**Break down large epics**:
- Create subtasks with clear boundaries
- Use blocks dependencies appropriately
- Allow parallel work when possible

## Common Patterns

### Feature Development

```bash
# 1. Create epic
EPIC=$(bd create "Feature: User Profile" -t feature -p 1 --json | jq -r '.id')

# 2. Break into subtasks
bd create "Create Profile resource" -t task --deps blocks:$EPIC --json
bd create "Add profile routes" -t task --deps blocks:$EPIC --json
bd create "Add profile UI" -t task --deps blocks:$EPIC --json
bd create "Add profile tests" -t task --deps blocks:$EPIC --json

# 3. Work through ready tasks
bd ready --json
```

### Bug Investigation

```bash
# 1. Create bug issue
BUG=$(bd create "Bug: Login fails with SSO" -t bug -p 1 \
  --desc "Investigation and fix for SSO login failure" \
  --json | jq -r '.id')

# 2. Investigation reveals multiple issues
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

### Documentation Work

```bash
# Documentation related to feature
bd create "Document new API endpoints" \
  -t task -p 2 \
  --deps related:bd-42 \
  --label documentation \
  --json
```

## Troubleshooting

### Issue Not Showing in Ready

**Check if blocked:**
```bash
bd show bd-42 --json | jq '.dependencies'
```

**Check status:**
```bash
bd show bd-42 --json | jq '.status'
# Must be "open" or "in_progress"
```

### Changes Not Syncing

**Manual export:**
```bash
bd export --json
```

**Manual import:**
```bash
bd import --json
```

**Check daemon:**
```bash
bd info --json
```

### Circular Dependencies

**Detect:**
```bash
bd validate --json
# Will report circular dependency errors
```

**Fix:**
```bash
# Remove problematic dependency
bd dep rm bd-42 blocks:bd-41 --json
```

## Integration with AI Workflows

### For Planners

Feature/fix/task planners should:
1. Create parent issue (epic, bug, or task)
2. Break into subtasks with `blocks` dependencies
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

## Critical Rules

- ✅ Always use `--json` flag for programmatic operations
- ✅ Check `bd ready --json` before starting new work
- ✅ Link discovered work with `discovered-from`
- ✅ Commit `.beads/issues.jsonl` with code changes
- ✅ Use descriptive titles and detailed descriptions
- ✅ Update issue status as work progresses
- ❌ Do NOT create duplicate tracking systems
- ❌ Do NOT use markdown TODOs instead of bd
- ❌ Do NOT forget to close issues when complete
- ❌ Do NOT commit code without committing issue state

## Quick Reference

```bash
# Common commands
bd ready --json                           # Find work
bd create "Title" -t TYPE -p NUM --json  # Create issue
bd update ID --status STATUS --json      # Update status
bd close ID --reason "REASON" --json     # Close issue
bd show ID --json                         # Show details
bd list --json                            # List all issues

# With dependencies (during creation)
bd create "Task" --deps blocks:ID --json           # Blocks parent
bd create "Work" --deps discovered-from:ID --json  # Discovered
bd create "Docs" --deps related:ID --json          # Related
bd create "Subtask" --deps parent-child:ID --json  # Child of parent

# Add dependencies after creation
bd dep add ID OTHER_ID --type blocks --json        # OTHER_ID blocks ID
bd dep add ID OTHER_ID --type related --json
bd dep add ID OTHER_ID --type parent-child --json
bd dep tree ID                                      # Visualize tree
bd dep cycles --json                                # Check for cycles

# With labels
bd label add ID label1 label2 --json     # Add labels
bd list --json | jq 'select(.labels | contains(["label"]))'  # Filter

# Status workflow
bd ready --json                           # 1. Find work
bd update ID --status in_progress --json # 2. Claim
# ... do work ...
bd close ID --reason "Done" --json       # 3. Complete
git add .beads/issues.jsonl [files]      # 4. Commit together
```

## Further Reading

- bd repository: https://github.com/steveyegge/beads
- Run `bd help` for command reference
- Run `bd [command] --help` for command details
- Check `.beads/issues.jsonl` for raw issue data
