# /implement

Orchestrate the implementation of planned work by delegating specific tasks to
the implementation-agent.

## Orchestration Process

As the orchestrator, you will:

1. **Identify current work context**:

   - Use `jj worklog` to determine work type and current context
   - Locate planning document in:
     - notes/features/<feature_name>.md
     - notes/fixes/<fix_name>.md
     - notes/tasks/<task_name>.md

2. **Read and analyze the plan**:

   - Understand the implementation steps
   - Identify what needs to be built
   - Determine the order of operations

3. **Delegate to implementation-agent**:

   - Give specific implementation tasks
   - Provide clear technical specifications
   - Specify patterns to follow
   - Define success criteria

4. **Coordinate the implementation**:
   - The implementation-agent will execute your instructions
   - It will proactively consult experts for patterns/guidance
   - It will return summaries of completed work
   - You decide next steps based on progress

**CRITICAL**: Implementation is NOT complete without working tests:

- Every feature/fix must have comprehensive test coverage
- Tests must pass before claiming any step complete
- Use test-developer for systematic test creation
- Never report implementation as "done" without working tests

## Example Orchestration

```markdown
# As orchestrator, you would:

1. Read notes/features/user-authentication.md
2. See it needs: User model, auth endpoints, JWT tokens, tests

3. Delegate to implementation-agent: "Create the User model in
   lib/app/users/user.ex following the existing Ash resource pattern. Include
   email, password_hash, and confirmed_at fields. Tests required."

4. Implementation-agent returns: "✅ Complete - Created User resource with 3
   fields, added 8 tests, all passing"

5. You continue with next task: "Now implement the authentication endpoints..."
```

## Usage Examples

```bash
# On feature work
jj edit feature/user-authentication  # or jj worklog to see current
/implement  # Orchestrator reads plan and delegates to implementation-agent

# On fix work
jj edit fix/memory-leak  # or jj worklog to see current
/implement  # Orchestrator analyzes fix and guides implementation

# On task work
jj edit task/update-dependencies  # or jj worklog to see current
/implement  # Orchestrator breaks down task and coordinates execution
```

## Key Benefits

- **Clear separation**: Orchestrator plans, implementation-agent executes
- **Expert consultation**: Implementation-agent proactively uses experts
- **Quality control**: You verify each step before proceeding
- **Flexible coordination**: You adapt based on implementation results

You maintain control of the workflow while the implementation-agent handles the
technical execution with expert support.
