# Address PR Feedback

## Process

1. **Check PR feedback**: Use `gh` to check the PR for this branch for
   unresolved comments

2. **Identify work type and related bd issues**:

   - Find feature epic or tasks with labels: `feature`, `project:[project]`
   - Find bug issues with labels: `bug`, `project:[project]`
   - Find task issues with labels: `task`, `project:[project]`

3. **Update planning document with feedback**:

   - **For features**: Use **feature-planner** agent to incorporate feedback
     into comprehensive plan updates
   - **For fixes**: Use **fix-planner** agent to reassess approach based on
     feedback
   - **For tasks**: Use **task-planner** agent to adjust simple task planning

4. **Research guidance**: Use **research-agent** if feedback involves unfamiliar
   concepts or technologies

5. **Ensure consistency**: Use **consistency-reviewer** to verify updates align
   with existing patterns

6. **Update documentation** to align with the feedback

7. **Create new Implementation Plan** for the changes requested using the
   appropriate planning agent

8. **Continue with the new plan** following updated guidance
