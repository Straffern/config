# Hierarchical Child IDs

Complete guide to bd's hierarchical ID system for epic breakdown and multi-level work organization.

## Overview

bd supports hierarchical issue organization using dot notation (e.g., `bd-epic.1`, `bd-epic.2.1`) for natural work breakdown structures. This provides auto-numbered, collision-free, human-readable issue hierarchies.

**Hierarchical IDs use parent hash + child number:**

```
bd-a3f8e9          [epic]  Auth System
├── bd-a3f8e9.1    [task]  Design login UI
├── bd-a3f8e9.2    [task]  Backend validation
└── bd-a3f8e9.3    [epic]  Password Reset
    ├── bd-a3f8e9.3.1  [task]  Email templates
    └── bd-a3f8e9.3.2  [task]  Reset flow tests
```

---

## Creating Hierarchical Children

### Basic Pattern

```bash
# 1. Create parent epic (generates hash ID)
bd create "Auth System" -t epic -p 1 --no-daemon --json
# Returns: {"id": "bd-a3f8e9", ...}

# 2. Create child tasks (auto-numbered .1, .2, .3, etc.)
bd create "Design login UI" -t task -p 1 \
  --parent bd-a3f8e9 \
  --no-daemon --json
# Returns: {"id": "bd-a3f8e9.1", ...}

bd create "Backend validation" -t task -p 1 \
  --parent bd-a3f8e9 \
  --no-daemon --json
# Returns: {"id": "bd-a3f8e9.2", ...}
```

### Nested Hierarchy (2-3 Levels)

```bash
# Level 1: Top epic
bd create "E-commerce Platform" -t epic -p 1 --no-daemon --json
# Returns: bd-7x9p

# Level 2: Child epics
bd create "Shopping Cart" -t epic -p 1 \
  --parent bd-7x9p --no-daemon --json
# Returns: bd-7x9p.1

bd create "Checkout System" -t epic -p 1 \
  --parent bd-7x9p --no-daemon --json
# Returns: bd-7x9p.2

# Level 3: Grandchild tasks
bd create "Add item to cart" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.1

bd create "Remove item from cart" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.2

bd create "Update quantity" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.3
```

**Final structure:**
```
bd-7x9p                  E-commerce Platform (epic)
├── bd-7x9p.1            Shopping Cart (epic)
│   ├── bd-7x9p.1.1      Add item (task)
│   ├── bd-7x9p.1.2      Remove item (task)
│   └── bd-7x9p.1.3      Update quantity (task)
└── bd-7x9p.2            Checkout System (epic)
```

---

## Key Features

### Auto-Numbering

Children are numbered sequentially (.1, .2, .3, ...) without manual coordination.

```bash
# Parent manages child counter automatically
bd create "Child 1" --parent bd-epic --no-daemon --json  # bd-epic.1
bd create "Child 2" --parent bd-epic --no-daemon --json  # bd-epic.2
bd create "Child 3" --parent bd-epic --no-daemon --json  # bd-epic.3
```

### Collision-Free

Parent hash ensures unique namespace - no conflicts between different epics.

```bash
# Epic A
bd create "Feature A" -t epic --no-daemon --json  # bd-abc123
bd create "Task 1" --parent bd-abc123 --no-daemon --json  # bd-abc123.1

# Epic B (different namespace)
bd create "Feature B" -t epic --no-daemon --json  # bd-def456
bd create "Task 1" --parent bd-def456 --no-daemon --json  # bd-def456.1
```

No conflicts - each epic owns its child ID space.

### Flexible Depth

Up to 3 levels of nesting supported:

**Level 1: Epic → Tasks** (most projects)
```
bd-epic
├── bd-epic.1 (task)
├── bd-epic.2 (task)
└── bd-epic.3 (task)
```

**Level 2: Epic → Features → Tasks** (large projects)
```
bd-epic
├── bd-epic.1 (epic/feature)
│   ├── bd-epic.1.1 (task)
│   └── bd-epic.1.2 (task)
└── bd-epic.2 (epic/feature)
```

**Level 3: Epic → Features → Stories → Tasks** (complex projects)
```
bd-epic
├── bd-epic.1 (epic/feature)
│   ├── bd-epic.1.1 (story)
│   │   ├── bd-epic.1.1.1 (task)
│   │   └── bd-epic.1.1.2 (task)
│   └── bd-epic.1.2 (story)
└── bd-epic.2 (epic/feature)
```

### Human-Readable

Clear parent-child relationships at a glance:

- `bd-auth.1` - First task in auth epic
- `bd-auth.3.2` - Second task in third sub-epic of auth
- `bd-payment.1.1.3` - Third grandchild task in first child of payment

---

## When to Use Hierarchical IDs vs Dependencies

### Decision Guide

**Use `--parent` (Hierarchical Child IDs) When:**

✅ **Clear epic breakdown structure**
- Large feature breaks into clear subtasks
- Example: "Payment System" → "Stripe", "PayPal", "Refunds"

✅ **Want readable, self-documenting IDs**
- `bd-a3f8e9.1` is more readable than two unrelated hashes
- Easy to see parent-child relationship at a glance

✅ **Multiple levels of organization needed**
- Epic → Sub-epics → Tasks (up to 3 levels)
- Example: "E-commerce" → "Cart" → "Add item", "Remove item"

✅ **All children must complete for parent to complete**
- Epic truly depends on ALL subtasks being done
- Natural work breakdown structure

**Example:**
```bash
bd create "User Authentication" -t epic -p 1 --no-daemon --json
bd create "Login UI" -t task --parent bd-auth --no-daemon --json
bd create "Password reset" -t task --parent bd-auth --no-daemon --json
bd create "2FA support" -t task --parent bd-auth --no-daemon --json
```

---

**Use `--deps` (Dependency Links) When:**

✅ **Loose or flexible relationships**
- Work is related but not strictly hierarchical
- Example: Documentation related to a feature

✅ **Discovered work during implementation**
- Always use `--deps discovered-from:ID` for traceability
- Found bugs, technical debt, missing tests

✅ **Cross-cutting concerns**
- Work that spans multiple epics
- Shared infrastructure or utilities

✅ **Retroactive linking**
- Linking existing issues that weren't created hierarchically
- Adding relationships after the fact

**Example:**
```bash
bd create "Bug in validation" -t bug -p 1 \
  --deps discovered-from:bd-feature --json

bd create "Add API docs" -t task -p 2 \
  --deps related:bd-feature --json

bd create "Prerequisite task" -t task -p 1 \
  --deps blocks:bd-feature --json
```

---

### Quick Comparison

| Scenario | Approach | Syntax |
|----------|----------|--------|
| Epic with clear subtasks | Hierarchical | `--parent bd-EPIC --no-daemon` |
| Found bug during work | Discovered link | `--deps discovered-from:bd-ID` |
| Task blocks another | Blocking dependency | `--deps blocks:bd-ID` |
| Related documentation | Related link | `--deps related:bd-ID` |
| Nested epic structure | Hierarchical (3 levels) | `--parent bd-EPIC.SUB --no-daemon` |

---

## Common Patterns

### Pattern 1: Simple Epic (1 level)

**Best for:** Most features, single epic with tasks

```bash
# Create epic
bd create "Feature X" -t epic -p 1 --no-daemon --json
# Returns: bd-x

# Create child tasks
bd create "Task 1" -t task --parent bd-x --no-daemon --json  # bd-x.1
bd create "Task 2" -t task --parent bd-x --no-daemon --json  # bd-x.2
bd create "Task 3" -t task --parent bd-x --no-daemon --json  # bd-x.3
```

**Structure:**
```
bd-x           Feature X (epic)
├── bd-x.1     Task 1
├── bd-x.2     Task 2
└── bd-x.3     Task 3
```

---

### Pattern 2: Complex Epic (2 levels)

**Best for:** Large features with sub-components

```bash
# Top-level epic
bd create "System Y" -t epic -p 1 --no-daemon --json
# Returns: bd-y

# Child epics for major components
bd create "Component A" -t epic --parent bd-y --no-daemon --json
# Returns: bd-y.1

bd create "Component B" -t epic --parent bd-y --no-daemon --json
# Returns: bd-y.2

# Grandchild tasks for component A
bd create "Task A1" -t task --parent bd-y.1 --no-daemon --json  # bd-y.1.1
bd create "Task A2" -t task --parent bd-y.1 --no-daemon --json  # bd-y.1.2

# Grandchild tasks for component B
bd create "Task B1" -t task --parent bd-y.2 --no-daemon --json  # bd-y.2.1
bd create "Task B2" -t task --parent bd-y.2 --no-daemon --json  # bd-y.2.2
```

**Structure:**
```
bd-y              System Y (epic)
├── bd-y.1        Component A (epic)
│   ├── bd-y.1.1  Task A1
│   └── bd-y.1.2  Task A2
└── bd-y.2        Component B (epic)
    ├── bd-y.2.1  Task B1
    └── bd-y.2.2  Task B2
```

---

### Pattern 3: Mixed Approach

**Best for:** Hierarchical core with discovered/related work

```bash
# Hierarchical epic
bd create "Feature Z" -t epic -p 1 --no-daemon --json
# Returns: bd-z

bd create "Core work" -t task --parent bd-z --no-daemon --json
# Returns: bd-z.1

# Discovered work linked separately (not hierarchical)
bd create "Found bug" -t bug \
  --deps discovered-from:bd-z.1 --json
# Returns: bd-abc (separate ID, not bd-z.2)

bd create "Add tests" -t task \
  --deps related:bd-z --json
# Returns: bd-def (separate ID)
```

**When to use:** 
- Core planned work in hierarchy
- Unexpected discoveries as separate issues with links

---

## Complete Example: Payment System

```bash
# Create top-level epic
bd create "Payment System" -t epic -p 1 --no-daemon --json
# Returns: bd-7x9p

# Create child epics for integrations
bd create "Stripe Integration" -t epic -p 1 \
  --parent bd-7x9p --no-daemon --json
# Returns: bd-7x9p.1

bd create "PayPal Integration" -t epic -p 1 \
  --parent bd-7x9p --no-daemon --json
# Returns: bd-7x9p.2

bd create "Refund Processing" -t epic -p 1 \
  --parent bd-7x9p --no-daemon --json
# Returns: bd-7x9p.3

# Break down Stripe integration
bd create "Setup Stripe SDK" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.1

bd create "Implement payment flow" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.2

bd create "Add webhook handlers" -t task -p 1 \
  --parent bd-7x9p.1 --no-daemon --json
# Returns: bd-7x9p.1.3

# Break down PayPal integration
bd create "Setup PayPal SDK" -t task -p 1 \
  --parent bd-7x9p.2 --no-daemon --json
# Returns: bd-7x9p.2.1

bd create "Implement payment flow" -t task -p 1 \
  --parent bd-7x9p.2 --no-daemon --json
# Returns: bd-7x9p.2.2

# Work through hierarchy
bd ready --json  # Shows leaf tasks: bd-7x9p.1.1, bd-7x9p.1.2, etc.

bd update bd-7x9p.1.1 --status in_progress --no-daemon --json
# ... implement
bd close bd-7x9p.1.1 --reason "Done" --no-daemon --json
jj commit -m "feat: setup Stripe SDK"

# Continue with remaining tasks...
```

**Final structure:**
```
bd-7x9p                  Payment System (epic)
├── bd-7x9p.1            Stripe Integration (epic)
│   ├── bd-7x9p.1.1      Setup Stripe SDK (task)
│   ├── bd-7x9p.1.2      Implement payment flow (task)
│   └── bd-7x9p.1.3      Add webhook handlers (task)
├── bd-7x9p.2            PayPal Integration (epic)
│   ├── bd-7x9p.2.1      Setup PayPal SDK (task)
│   └── bd-7x9p.2.2      Implement payment flow (task)
└── bd-7x9p.3            Refund Processing (epic)
```

---

## Working with Hierarchical Issues

### List Children of Epic

```bash
# Find all children of bd-a3f8e9
bd list --json | jq '.[] | select(.id | startswith("bd-a3f8e9."))'
```

### Check Epic Status

```bash
bd show bd-a3f8e9 --json
```

### Work on Specific Child

```bash
bd update bd-a3f8e9.1 --status in_progress --no-daemon --json
```

### Close Epic When All Children Done

```bash
# Verify all children closed first
bd list --json | jq '.[] | select(.id | startswith("bd-epic.")) | select(.status != "closed")'

# If empty, safe to close epic
bd close bd-epic --reason "All subtasks complete" --no-daemon --json
```

---

## Current Limitations

### Daemon Mode Requirement

⚠️ **The `--parent` flag currently requires `--no-daemon` mode**

```bash
# This works
bd create "Child" -t task --parent bd-XXXX --no-daemon --json

# This fails in daemon mode
bd create "Child" -t task --parent bd-XXXX --json
# Error: --parent flag not yet supported in daemon mode
```

**Workaround:** Always include `--no-daemon` when using `--parent` flag.

**Why:** Daemon mode optimization doesn't yet support parent-child counter synchronization.

---

## Benefits of Hierarchical IDs

### vs Standard Dependencies

**Hierarchical IDs:**
- ✅ Clear parent-child relationship at a glance (bd-epic.1)
- ✅ Auto-numbered (no manual coordination)
- ✅ Human-readable structure
- ✅ Natural work breakdown
- ✅ Easy to navigate and understand

**Standard Dependencies:**
- ✅ More flexible (can link after creation)
- ✅ Works across unrelated epics
- ✅ Supports multiple relationship types
- ✅ Works in daemon mode (no --no-daemon needed)

### When Each Shines

**Use Hierarchical IDs for:**
- Planned epic breakdown
- Clear multi-level organization
- When all children known upfront
- Natural work breakdown structures

**Use Dependencies for:**
- Discovered work (always use `discovered-from`)
- Cross-cutting concerns
- Retroactive linking
- Complex dependency graphs

---

## Best Practices

### ✅ DO

- Use hierarchical IDs for planned epic breakdown
- Use up to 3 levels for complex features
- Include `--no-daemon` flag with `--parent`
- Close children before closing parent
- Use meaningful epic titles (they become ID prefixes conceptually)

### ❌ DON'T

- Mix hierarchical IDs with `--deps parent-child` for same epic
- Create more than 3 levels of nesting (gets unwieldy)
- Forget `--no-daemon` flag (will error)
- Close parent before all children closed
- Create hundreds of children under one parent (split into sub-epics)

---

## Troubleshooting

### Error: --parent flag not supported in daemon mode

**Solution:** Add `--no-daemon` flag

```bash
bd create "Child" -t task --parent bd-epic --no-daemon --json
```

### Children show as "orphaned" after parent deleted

**Prevention:** Never delete parent epic while children exist

**Fix:** 
```bash
# Recreate parent or reassign children
bd update bd-epic.1 --deps parent-child:bd-new-parent --json
```

### Can't find all children of epic

**Solution:** Use jq to filter by ID prefix

```bash
bd list --json | jq '.[] | select(.id | startswith("bd-epic."))'
```

---

## Summary

**Hierarchical IDs provide:**
- Auto-numbered children (bd-epic.1, bd-epic.2, ...)
- Collision-free namespaces (parent hash)
- Human-readable structure
- Up to 3 levels of nesting
- Clear work breakdown

**Use when:**
- Planning epic breakdown
- Need clear multi-level organization
- All children known upfront
- Want readable issue structure

**Remember:**
- Always use `--no-daemon` flag
- Close children before parent
- Prefer for planned work
- Use dependencies for discovered work

**For dependency-based relationships, see [DEPENDENCIES.md](DEPENDENCIES.md).**
