# Split JJ Diff into Logical Changes

## Command Overview

This command analyzes the current JJ diff and splits it into logical, atomic changes. It uses JJ commands to examine the changes and creates separate commits for each logical unit of work.

## Getting Help with JJ

Before starting, use JJ's built-in help:
- `jj help` - Show all available commands and options
- `jj help <subcommand>` - Get detailed help for specific commands (e.g., `jj help diff`, `jj help new`)
- `jj help --list` - List all available subcommands

## Workflow

### 1. **Analyze Current State**

- Run `jj status` to see current working copy state
- Run `jj diff` to examine all changes  
- Run `jj log` to understand current change context
- Use `jj help status` or `jj help diff` if you need command options

### 2. **Identify Logical Changes**

Analyze the diff to identify distinct logical units:
- Separate file modifications that can be committed independently
- Related changes that belong together (same feature/fix)
- Configuration changes vs code changes
- Documentation updates vs implementation changes

### 3. **Create Atomic Changes**

**Method 1: Using jj split with filesets (Recommended)**
For each logical change:
1. Use `jj split <files>` to split specific files into a new commit
2. Provide appropriate commit message when prompted
3. Repeat for remaining files

**Method 2: Using jj new + jj squash workflow**
1. First commit all changes: `jj commit -m "temp: all changes"`
2. For each logical change:
   - Use `jj new -m "type(scope): description"` to create empty commit
   - Use `jj squash --from <parent> --into @ <files>` to move specific files
3. Abandon the temporary commit if needed

**Method 3: Using jj restore approach**
1. Use `jj commit -m "temp: all changes"` to capture current state
2. For each logical change:
   - Use `jj new -m "type(scope): description"`
   - Use `jj restore --from <temp_commit> <files>` to bring back specific files
3. Use `jj abandon <temp_commit>` to clean up

### 4. **Commit Message Guidelines**

- Use conventional commit format: `type(scope): description`
- **IMPORTANT**: Using `feature:` or `feat:` requires explicit permission
- Ask before using these prefixes: "May I use 'feature:' prefix for this change?"
- Preferred types: `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`
- Keep messages concise and descriptive

### 5. **Handle Empty Changes**

- Do NOT abandon empty changes unless they appear between two non-empty changes
- Empty changes at the beginning or end of a series can be kept
- Use `jj abandon <change-id>` only when necessary for clean history

## JJ Command Reference

### Essential Commands

```bash
# View current state
jj status          # Show working copy status
jj diff            # Show all changes
jj diff --stat     # Show summary of changes
jj log             # Show change history

# Change management
jj new             # Create new empty change
jj new <revision>  # Create new change based on specific revision
jj describe -m "message"  # Set commit message for current change
jj commit          # Finalize current change and start new one

# Splitting changes
jj split <files>   # Split specific files into new commit
jj split -m "message" <files>  # Split with message

# Selective changes
jj restore <file>  # Restore file to parent state
jj restore --from <revision> <file>  # Restore from specific revision
jj edit <revision> # Edit specific change

# Moving changes between commits
jj squash --from <src> --into <dest> <files>  # Move specific files

# Change cleanup
jj abandon <revision>  # Abandon a change
jj squash            # Squash multiple changes
jj rebase -d <dest>   # Rebase change onto destination
```

### Advanced Usage

```bash
# Compare changes
jj diff -r <revision>     # Compare with specific revision
jj interdiff <r1> <r2>    # Compare two revisions

# Change manipulation
jj move <src> --to <dest> # Move changes between revisions
```

## Implementation Strategy

### 1. **Initial Analysis**

```bash
# Get overview of changes
jj status
jj diff --stat
jj log -l 5
```

### 2. **Change Grouping**

Group changes by:
- **Functionality**: Related feature implementations
- **File type**: Code, tests, docs, config
- **Scope**: Single file vs multi-file changes
- **Dependency**: Changes that depend on each other

### 3. **Sequential Splitting**

**Recommended Approach: Using jj split with filesets**
For each logical group:
1. Split specific files: `jj split -m "type(scope): description" <file1> <file2>`
2. Repeat for remaining files
3. All changes will be automatically organized

**Alternative Approach: Commit + Restore workflow**
1. Commit all changes first: `jj commit -m "temp: all changes"`
2. For each logical group:
   - Create new change: `jj new -m "type(scope): description"`
   - Restore specific files: `jj restore --from <temp_commit> <file1> <file2>`
3. Clean up: `jj abandon <temp_commit>`

**Important**: Always specify files explicitly and avoid interactive options.

### 4. **Validation**

After splitting:
- Verify all changes are preserved: `jj diff` across all changes
- Check logical grouping makes sense: `jj log`
- Ensure build/tests still work
- Review commit messages for consistency
- Use `jj help diff` or `jj help log` if you need additional options

## Examples

### Example 1: Feature + Documentation

```bash
# Current diff has code changes + README update
# Method 1: Using jj split
jj split -m "feat(auth): add JWT authentication" src/auth.rs src/main.rs
jj split -m "docs: update README for JWT auth" README.md

# Method 2: Using commit + restore
jj commit -m "temp: auth feature + docs"
jj new -m "feat(auth): add JWT authentication"
jj restore --from @- src/auth.rs src/main.rs
jj new -m "docs: update README for JWT auth" 
jj restore --from @-2 README.md
jj abandon @-2
```

### Example 2: Bug Fix + Test

```bash
# Current diff has fix + new test
# Method 1: Using jj split
jj split -m "fix(api): handle null response in user endpoint" src/api.rs
jj split -m "test: add coverage for null response handling" tests/api_test.rs

# Method 2: Using commit + restore  
jj commit -m "temp: bug fix + test"
jj new -m "fix(api): handle null response in user endpoint"
jj restore --from @- src/api.rs
jj new -m "test: add coverage for null response handling"
jj restore --from @-2 tests/api_test.rs
jj abandon @-2
```

## Quality Checks

Before finishing:
- [ ] All logical changes are separated
- [ ] Commit messages follow conventions
- [ ] No unnecessary empty changes
- [ ] Build/tests pass across all changes
- [ ] Change history tells a clear story
- [ ] Asked permission for `feature:`/`feat:` prefixes

## Troubleshooting

### Common Issues

- **Too many small changes**: Combine related changes with `jj squash`
- **Change in wrong order**: Use `jj rebase` to reorder
- **Forgot a file**: Use `jj edit <change>` and add file
- **Wrong commit message**: Use `jj describe` to update
- **Need command options**: Use `jj help <command>` to see available flags

### Recovery

```bash
# If something goes wrong, check recent changes
jj log -l 10

# Abandon problematic change
jj abandon <problematic-change>

# Start over with fresh change
jj new

# Get help if needed
jj help abandon
jj help rebase
```

Remember: The goal is a clean, logical history where each change represents one coherent unit of work. Always use `jj help` and `jj help <subcommand>` when you need command options or syntax help.