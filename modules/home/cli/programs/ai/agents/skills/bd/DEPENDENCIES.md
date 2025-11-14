# bd Dependency Management

Complete guide to dependency types, usage patterns, and best practices.

## Overview

bd tracks sophisticated relationships between issues through four dependency types. Understanding when to use each type is critical for effective project management.

---

## Dependency Types

### blocks

**Meaning:** This issue blocks the referenced issue from completion.

**Direction:** `bd-43 blocks bd-42` means bd-42 is blocked by bd-43

**Usage:**

```bash
# During creation
bd create "Prerequisite task" -t task \
  --deps blocks:bd-42 \
  --json

# After creation (bd-41 blocks bd-42)
bd dep add bd-42 bd-41 --type blocks --json
```

**When to use:**
- ✅ Subtasks that block parent epic
- ✅ Prerequisites that must finish first
- ✅ Hard dependencies between work items
- ✅ Sequential tasks where order matters

**Example:**

```bash
# Epic: User Authentication
bd create "Auth System" -t epic -p 1 --json
# Returns: bd-auth

# Subtasks that block the epic
bd create "Create User resource" -t task --deps blocks:bd-auth --json
bd create "Add auth routes" -t task --deps blocks:bd-auth --json
bd create "Add session management" -t task --deps blocks:bd-auth --json

# Epic cannot close until all blocking subtasks are done
```

**Benefits:**
- Clear completion dependencies
- `bd ready` automatically filters blocked work
- Epic completes only when all blockers resolved

---

### discovered-from

**Meaning:** This work was discovered while working on another issue.

**Purpose:** Traceability - track where work originated for context

**Usage:**

```bash
# Bug found during feature implementation
bd create "Fix validation edge case" \
  -t bug \
  --deps discovered-from:bd-42 \
  --json
```

**When to use:**
- ✅ Bugs found during implementation
- ✅ Additional work discovered mid-task
- ✅ Scope expansion that needs tracking
- ✅ Technical debt identified during work
- ✅ Missing test coverage discovered
- ✅ Documentation gaps found

**Example:**

```bash
# Working on bd-42: "Implement user registration"
# Discovered several issues:

bd create "OrderedMap doesn't handle duplicate keys" \
  -t bug -p 1 \
  --deps discovered-from:bd-42 \
  --json

bd create "Add tests for JSON nested objects" \
  -t task -p 2 \
  --deps discovered-from:bd-42 \
  --json

bd create "Optimize ASCII operations for UTF-8 strings" \
  -t task -p 3 \
  --deps discovered-from:bd-42 \
  --json
```

**Benefits:**
- ✅ Maintains context for future reference
- ✅ Shows work discovery patterns
- ✅ Helps understand scope creep
- ✅ Links related issues without blocking
- ✅ Critical for AI agent traceability

**CRITICAL for AI Agents:** Always use `discovered-from` when finding new work during implementation. This prevents lost work items and maintains context.

---

### related

**Meaning:** Loosely related work without hard dependency (soft connection).

**Purpose:** Link contextually connected issues

**Usage:**

```bash
# During creation
bd create "Update API docs" \
  -t task \
  --deps related:bd-42 \
  --json

# After creation
bd dep add bd-43 bd-42 --type related --json
```

**When to use:**
- ✅ Related documentation
- ✅ Similar work in different areas
- ✅ Contextually connected issues
- ✅ Cross-references for future reference
- ✅ Loosely coupled work items

**Example:**

```bash
# Feature: bd-42 "Implement OAuth integration"

# Related but not blocking
bd create "Document OAuth setup" \
  -t task -p 2 \
  --deps related:bd-42 \
  --json

bd create "Add OAuth troubleshooting guide" \
  -t task -p 2 \
  --deps related:bd-42 \
  --json
```

**Benefits:**
- Maintains context without blocking
- Groups related work for review
- Doesn't affect `bd ready` filtering

**Difference from `blocks`:**
- `related`: Can be done before, after, or in parallel
- `blocks`: Must be done before dependent issue closes

**Difference from `discovered-from`:**
- `related`: Known related work
- `discovered-from`: Found during implementation

---

### parent-child

**Meaning:** Hierarchical epic/subtask relationship.

**Purpose:** Organize work into epics with subtasks

**Usage:**

```bash
# During creation
bd create "Implement auth component" \
  -t task \
  --deps parent-child:bd-42 \
  --json

# After creation (bd-42 is parent, bd-43 is child)
bd dep add bd-43 bd-42 --type parent-child --json
```

**When to use:**
- ✅ Breaking epics into subtasks
- ✅ Hierarchical work organization
- ✅ Multi-step features with clear parent-child structure
- ✅ When NOT using `--parent` flag for hierarchical IDs

**Example:**

```bash
# Epic: Payment System
bd create "Payment System" -t epic -p 1 --json
# Returns: bd-payment

# Child tasks using parent-child dependencies
bd create "Stripe integration" \
  -t task \
  --deps parent-child:bd-payment \
  --json

bd create "PayPal integration" \
  -t task \
  --deps parent-child:bd-payment \
  --json

bd create "Refund processing" \
  -t task \
  --deps parent-child:bd-payment \
  --json
```

**Note:** This is the dependency-based approach to parent-child relationships. For hierarchical IDs with auto-numbering, see [HIERARCHICAL_IDS.md](HIERARCHICAL_IDS.md).

---

## Decision Tree: Which Dependency Type?

```
Does work BLOCK another issue from completion?
├─ YES → Use `blocks`
│  Example: "Fix database migration" blocks "Deploy to production"
│
└─ NO  → Was work DISCOVERED during another issue?
    ├─ YES → Use `discovered-from`
    │  Example: Found bug while implementing feature
    │
    └─ NO  → Is work RELATED but independent?
        ├─ YES → Use `related`
        │  Example: Documentation for implemented feature
        │
        └─ NO  → Is this a PARENT-CHILD hierarchy?
            └─ YES → Use `parent-child` or `--parent` flag
               Example: Epic with subtasks
```

---

## Dependency Management Commands

### Add Dependency

```bash
# Syntax: bd dep add ISSUE DEPENDENCY --type TYPE

# bd-41 blocks bd-42
bd dep add bd-42 bd-41 --type blocks --json

# bd-40 was discovered from bd-42
bd dep add bd-40 bd-42 --type discovered-from --json

# bd-39 is related to bd-42
bd dep add bd-39 bd-42 --type related --json

# bd-43 is child of bd-42
bd dep add bd-43 bd-42 --type parent-child --json
```

**Remember:** When using `blocks`, the syntax is:
```bash
bd dep add BLOCKED_ISSUE BLOCKING_ISSUE --type blocks
```

So if bd-41 blocks bd-42:
```bash
bd dep add bd-42 bd-41 --type blocks --json
```

### Remove Dependency

```bash
bd dep rm bd-42 bd-41 --json
```

### Visualize Dependencies

```bash
# Show dependency tree
bd dep tree bd-42

# Example output:
# bd-42 Feature: User Authentication
# ├─ blocks: bd-41 Create User resource
# ├─ blocks: bd-40 Add auth routes
# ├─ discovered-from: bd-50 Fix validation bug
# └─ related: bd-51 Document auth flow
```

### Detect Circular Dependencies

```bash
bd dep cycles --json

# Returns any circular dependency chains
# Example: bd-42 → bd-43 → bd-44 → bd-42 (circular!)
```

---

## Best Practices

### Use `blocks` for Hard Dependencies

**Good:**
```bash
# Epic cannot close until subtasks done
bd create "Create User resource" -t task --deps blocks:bd-epic --json
bd create "Add auth routes" -t task --deps blocks:bd-epic --json
```

**Bad:**
```bash
# Using related when should use blocks
bd create "Create User resource" -t task --deps related:bd-epic --json
# Epic could close before subtask is done!
```

### Always Use `discovered-from` for Traceability

**Good:**
```bash
# Found bug while working on bd-42
bd create "Fix null pointer in validation" \
  -t bug -p 1 \
  --deps discovered-from:bd-42 \
  --json
```

**Bad:**
```bash
# No context about where bug was found
bd create "Fix null pointer in validation" \
  -t bug -p 1 \
  --json
```

### Avoid Circular Dependencies

**Bad:**
```bash
bd dep add bd-42 bd-43 --type blocks --json
bd dep add bd-43 bd-42 --type blocks --json
# Circular! Neither can complete.
```

**Detect with:**
```bash
bd dep cycles --json
```

### Break Down Large Epics

**Good:**
```bash
# Create clear subtasks with blocking dependencies
EPIC=$(bd create "Complete Auth System" -t epic -p 1 --json | jq -r '.id')

bd create "User model" -t task --deps blocks:$EPIC --json
bd create "Auth routes" -t task --deps blocks:$EPIC --json
bd create "Session management" -t task --deps blocks:$EPIC --json
bd create "Tests" -t task --deps blocks:$EPIC --json
```

**Better (with hierarchical IDs):**
```bash
# Use --parent for clearer structure
bd create "Complete Auth System" -t epic -p 1 --no-daemon --json
# Returns: bd-auth

bd create "User model" -t task --parent bd-auth --no-daemon --json
bd create "Auth routes" -t task --parent bd-auth --no-daemon --json
bd create "Session management" -t task --parent bd-auth --no-daemon --json
bd create "Tests" -t task --parent bd-auth --no-daemon --json
```

See [HIERARCHICAL_IDS.md](HIERARCHICAL_IDS.md) for complete hierarchical ID guide.

---

## Common Patterns

### Feature Development with Blockers

```bash
# Create feature
FEATURE=$(bd create "Feature: Export Reports" -t feature -p 1 --json | jq -r '.id')

# Prerequisite tasks that block feature
bd create "Add export API endpoint" -t task --deps blocks:$FEATURE --json
bd create "Create CSV formatter" -t task --deps blocks:$FEATURE --json
bd create "Add UI export button" -t task --deps blocks:$FEATURE --json

# Feature can only close when all blockers resolved
```

### Discovered Work During Implementation

```bash
# Working on bd-42: "Implement search"

# Discovered during implementation
bd create "Optimize database query performance" \
  -t task -p 2 \
  --deps discovered-from:bd-42 \
  --json

bd create "Add search result caching" \
  -t task -p 3 \
  --deps discovered-from:bd-42 \
  --json

bd create "Fix pagination bug" \
  -t bug -p 1 \
  --deps discovered-from:bd-42 \
  --json
```

### Related Documentation

```bash
# Feature implemented: bd-42
# Add related documentation

bd create "Document new API endpoints" \
  -t task -p 2 \
  --deps related:bd-42 \
  --json

bd create "Update user guide" \
  -t task -p 2 \
  --deps related:bd-42 \
  --json
```

---

## Advanced: Multiple Dependency Types

Issues can have multiple dependencies of different types:

```bash
# Create issue with multiple dependencies
bd create "Complete OAuth integration" -t feature -p 1 --json
# Returns: bd-oauth

# Blocking dependencies (must finish first)
bd create "Setup OAuth provider" -t task --deps blocks:bd-oauth --json
bd create "Add callback route" -t task --deps blocks:bd-oauth --json

# Related work (can be parallel)
bd create "Document OAuth flow" -t task --deps related:bd-oauth --json

# Discovered during work
bd create "Fix session timeout" -t bug --deps discovered-from:bd-oauth --json
```

**View with:**
```bash
bd show bd-oauth --json
```

---

## Querying Dependencies

### Find all issues blocking specific issue

```bash
bd show bd-42 --json | jq '.dependencies | map(select(.type == "blocks"))'
```

### Find all issues discovered from specific issue

```bash
bd list --json | jq -r '
  .[] | 
  select(.dependencies | map(select(.type == "discovered-from" and .target == "bd-42")) | length > 0)
'
```

### Find all blocked issues

```bash
bd blocked --json
```

---

## Summary

**Dependency Types:**

| Type | Purpose | Affects `bd ready`? | Example |
|------|---------|---------------------|---------|
| `blocks` | Hard dependency | Yes | Subtask blocks epic |
| `discovered-from` | Traceability | No | Bug found during work |
| `related` | Soft connection | No | Documentation for feature |
| `parent-child` | Hierarchy | No (use with deps) | Epic/subtask organization |

**Key Rules:**
1. ✅ Use `blocks` for hard dependencies
2. ✅ Always use `discovered-from` for work found during implementation
3. ✅ Use `related` for loose connections
4. ✅ Avoid circular dependencies
5. ✅ Validate regularly with `bd dep cycles`
6. ✅ Visualize with `bd dep tree`

**For hierarchical epic breakdown with auto-numbering, see [HIERARCHICAL_IDS.md](HIERARCHICAL_IDS.md).**
