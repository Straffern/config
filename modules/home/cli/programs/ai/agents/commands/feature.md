# Feature Development Command

**PURPOSE**: Complex features requiring comprehensive planning and research integration.

## When to Use This Command

Use when:
- Feature spans multiple files (>3)
- Unfamiliar technologies or APIs involved
- Requires architectural decisions
- Estimated >1 day of work

**For simple features**: Skip this command, use the Standard Workflow directly.

## Command Flow

### Step 1: Create Feature Epic with feature-planner

Invoke **feature-planner** agent with your feature description. The planner will:
- Consult **research-agent** for unfamiliar technologies
- Leverage elixir skill for Elixir/Phoenix/Ash patterns
- Consult **senior-engineer-reviewer** for architecture
- Create bd epic with subtasks
- Leave issues in `open` status for you to claim

**Output**: bd epic (bd-XXXX) with linked subtasks

### Step 2: Execute Using Standard Workflow

**Reference**: See AGENTS.md "Standard Workflow" (Phase 1-4)

```bash
# Check what feature-planner created
bd ready --json

# Claim the epic or first subtask
bd update bd-XXXX --status in_progress --json

# Work on it (consult agents as needed)
[implement]

# Run tests (MUST PASS)
[test]

# Run ALL review agents in parallel (MANDATORY)
[review]

# Complete and commit
bd close bd-XXXX --reason "Feature complete, tests passing" --json
jj commit -m "feat: feature description"
```

### Step 3: Continue with Subtasks

Repeat Standard Workflow for each subtask until epic is complete.

## Version Control

- Use `jj commit -m "..."` for all commits
- jj auto-stages all changes including .beads/issues.jsonl
- Use conventional commit format: `feat:`, `fix:`, `docs:`, etc.
- Do not reference claude in commit messages

## Test Requirements

**CRITICAL**: Features are NOT complete without working tests.

- Every feature must have comprehensive test coverage
- Tests must pass before closing ANY issue
- Follow Test Failure Protocol if tests fail (see AGENTS.md)
- Never claim feature completion without passing tests

## What feature-planner Creates

The **feature-planner** agent creates:

### bd Epic Structure
- Parent epic issue with comprehensive description
- Child subtasks with dependency relationships
- All issues left in `open` status for you to claim

### Issue Description Format
1. **Problem Statement** - Clear description and impact
2. **Solution Overview** - High-level approach
3. **Agent Consultations** - Documents research performed
4. **Technical Details** - File locations, dependencies
5. **Success Criteria** - Measurable outcomes
6. **Implementation Plan** - Logical steps

## Integration with Standard Workflow

This command is a **wrapper** around AGENTS.md Standard Workflow:

1. **feature-planner** creates the bd epic (replaces Phase 1 "create issue")
2. **You follow Standard Workflow** for execution (Phase 1-4)
3. **Repeat** for each subtask

**Reference**: See AGENTS.md for complete workflow details.
