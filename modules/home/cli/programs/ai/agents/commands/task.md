# Task Command

**PURPOSE**: Lightweight task planning for simple, focused work items.

## When to Use This Command

Use when:
- Simple, focused work (<3 files)
- You don't immediately know all the steps
- Want structured task breakdown
- Estimated <4 hours of work

**For straightforward tasks**: Skip this command, use the Standard Workflow directly.

## Command Flow

### Step 1: Create Task with task-planner

Invoke **task-planner** agent with task description. The planner will:
- Create lightweight task breakdown
- Identify key steps and considerations
- Consult agents if needed (research, architecture)
- Create bd task issue
- Leave issue in `open` status for you to claim

**Smart Escalation**: If task is too complex, task-planner will recommend using feature-planner or fix-planner instead.

**Output**: bd task issue (bd-XXXX) with step breakdown

### Step 2: Execute Using Standard Workflow

**Reference**: See AGENTS.md "Standard Workflow" (Phase 1-4)

```bash
# Check what task-planner created
bd ready --json

# Claim the task
bd update bd-XXXX --status in_progress --json

# Work on it (consult agents as needed)
[implement]

# Run tests if applicable
[test]

# Run ALL review agents in parallel (MANDATORY)
[review]

# Complete and commit
bd close bd-XXXX --reason "Task complete" --json
jj commit -m "type: task description"
```

## Version Control

- Use `jj commit -m "..."` for all commits
- jj auto-stages all changes including .beads/issues.jsonl
- Use conventional commit format: `feat:`, `docs:`, `refactor:`, `test:`, `chore:`, etc.
- Do not reference claude in commit messages

## Test Requirements

Run tests when applicable:
- Code changes: Tests must pass
- Documentation only: Tests optional
- Configuration changes: Verify system still works

Follow Test Failure Protocol if tests fail (see AGENTS.md).

## What task-planner Creates

The **task-planner** agent creates:

### bd Task Issue Structure
- Task issue with step breakdown
- Key considerations
- Testing notes
- Issue left in `open` status for you to claim

### Issue Description Format
1. **Task Description** - What needs to be done
2. **Steps** - Key implementation steps
3. **Considerations** - Edge cases, gotchas
4. **Testing** - How to verify completion

## Integration with Standard Workflow

This command is a **wrapper** around AGENTS.md Standard Workflow:

1. **task-planner** creates the bd task issue (replaces Phase 1 "create issue")
2. **You follow Standard Workflow** for execution (Phase 1-4)

**Reference**: See AGENTS.md for complete workflow details.

## When Task Is Too Complex

If task-planner determines the work is too complex for lightweight planning, it will:
- Recommend using **feature-planner** for large features
- Recommend using **fix-planner** for complex bugs
- Provide reasoning for the recommendation

In that case, use the recommended command instead.

## Example Task Types

**Good for task-planner:**
- Configuration changes
- Simple refactoring
- Documentation updates
- Tool setup or installation
- Small improvements (<3 files, <4 hours)

**Should use feature-planner:**
- New complex functionality
- Multi-component integrations
- Architectural changes

**Should use fix-planner:**
- Bug investigations
- Security issues
- System stability problems
