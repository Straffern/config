# Bug Fix Command

**PURPOSE**: Complex bugs requiring investigation, root cause analysis, and systematic resolution.

## When to Use This Command

Use when:
- Bug requires investigation (root cause unknown)
- Affects multiple components
- Needs regression tests
- Security or data integrity implications

**For simple bugs**: Skip this command, use the Standard Workflow directly.

## Command Flow

### Step 1: Investigation with fix-planner

Invoke **fix-planner** agent with bug description. The planner will:
- Analyze symptoms and error messages
- Consult **research-agent** for unfamiliar error patterns
- Leverage elixir skill for Elixir/Phoenix/Ash debugging
- Consult **security-reviewer** if security-related
- Create bd bug issue with investigation findings
- Leave issue in `open` status for you to claim

**Output**: bd bug issue (bd-XXXX) with root cause analysis and fix plan

### Step 2: Execute Using Standard Workflow

**Reference**: See AGENTS.md "Standard Workflow" (Phase 1-4)

```bash
# Check what fix-planner created
bd ready --json

# Claim the bug issue
bd update bd-XXXX --status in_progress --json

# Implement fix (consult agents as needed)
[fix bug]

# Add regression tests (MANDATORY)
[add tests that fail before fix, pass after fix]

# Run ALL tests (MUST PASS)
[test]

# Run ALL review agents in parallel (MANDATORY)
[review]

# Complete and commit
bd close bd-XXXX --reason "Bug fixed, regression tests added, all tests passing" --json
jj commit -m "fix: bug description"
```

## Version Control

- Use `jj commit -m "..."` for all commits
- jj auto-stages all changes including .beads/issues.jsonl
- Use conventional commit format: `fix:` for bugs
- Do not reference claude in commit messages

## Test Requirements

**CRITICAL**: Fixes are NOT complete without regression tests.

- Every bug fix must include tests that verify the fix
- Regression tests must fail BEFORE the fix and pass AFTER
- ALL existing tests must continue to pass
- Follow Test Failure Protocol if tests fail (see AGENTS.md)
- Never claim fix completion without passing tests

## What fix-planner Creates

The **fix-planner** agent creates:

### bd Bug Issue Structure
- Bug issue with investigation findings
- Root cause analysis
- Proposed fix approach
- Testing strategy
- Issue left in `open` status for you to claim

### Issue Description Format
1. **Problem Description** - Symptoms, errors, impact
2. **Investigation** - Debugging steps performed
3. **Root Cause** - Why the bug occurs
4. **Agent Consultations** - Research performed
5. **Fix Approach** - Proposed solution
6. **Testing Strategy** - Regression test plan

## Test Failure Protocol

If you encounter test failures during the fix:

**IMMEDIATE ACTION** (see AGENTS.md for details):
1. Create critical test fix issue: `bd create "Fix failing tests" -t bug -p 0 --deps discovered-from:bd-CURRENT`
2. Block current work: `bd update bd-CURRENT --status blocked`
3. Fix tests NOW (priority 0)
4. Unblock original fix once tests pass
5. Continue with original fix

## Integration with Standard Workflow

This command is a **wrapper** around AGENTS.md Standard Workflow:

1. **fix-planner** creates the bd bug issue (replaces Phase 1 "create issue")
2. **You follow Standard Workflow** for execution (Phase 1-4)
3. **Add regression tests** (mandatory for all fixes)

**Reference**: See AGENTS.md for complete workflow details.
