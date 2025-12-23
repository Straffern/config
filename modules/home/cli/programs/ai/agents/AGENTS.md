# 🧑‍💻 Agents

## ⚠️ CRITICAL: Ask Clarifying Questions When Unclear

**ALWAYS ask clarifying questions when requirements are ambiguous or unclear.**

When you receive a request that is ambiguous, missing key details, or has multiple interpretations:

1. ✅ **Ask ONE clarifying question at a time**
2. ✅ **Wait for the answer before proceeding**
3. ✅ **Continue asking questions until you have complete understanding**
4. ✅ **Never make assumptions when you can ask**

**Good Question Pattern:**

```
"I want to make sure I understand correctly: [restate what you think they mean].
Is that correct, or did you mean [alternative interpretation]?"
```

**Remember**: It's better to ask and get it right than to implement the wrong thing quickly.

---

## Documentation Policy

**DO NOT** proactively create planning or documentation files (PLAN.md, IMPLEMENTATION.md, ARCHITECTURE.md, DESIGN.md, etc.) unless explicitly instructed by the user.

- ❌ Do NOT create planning documents without explicit request
- ❌ Do NOT create markdown documentation files autonomously
- ✅ Only create documentation when user explicitly asks for it

---

## Essential Rules Summary

- ✅ **Ask clarifying questions** when requirements are unclear
- ✅ **Consult agents** before implementation for domain expertise
- ✅ **Run review agents** before completing significant work
- ✅ **Follow documentation policy** - no proactive planning docs
- ❌ **Do NOT create duplicate tracking** systems
- ❌ **Do NOT skip agent consultation** when needed

---

## When in Doubt

1. **Ask a clarifying question** - Don't assume, just ask (one at a time)
2. **Consult relevant skills** -  Seek advice from relevant skills
3. **Look at existing patterns** - Tests, similar features, documentation

---

## Skills - Knowledge Injection

Skills are reusable knowledge packages. Load them on-demand for specialized tasks.

### When to Use

- Before unfamiliar work - check if a skill exists
- When you need domain-specific patterns
- For complex workflows that benefit from guidance

### Usage

```bash
skills_list()                              # See available skills
skills_use(name="swarm-coordination")      # Load a skill
skills_use(name="cli-builder", context="building a new CLI") # With context
```

**Bundled Skills:** cli-builder, learning-systems, skill-creator, swarm-coordination, system-design, testing-patterns

## CASS - Cross-Agent Session Search

Search across ALL your AI coding agent histories before solving problems from scratch.

### When to Use

- **BEFORE implementing anything**: check if any agent solved it before
- **Debugging**: "what did I try last time this error happened?"
- **Learning patterns**: "how did Cursor handle this API?"

### Usage

```bash
# Search all agents
cass_search(query="authentication token refresh", limit=5)

# Filter by agent/time
cass_search(query="useEffect cleanup", agent="claude", days=7)

# View specific result
cass_view(path="/path/from/search", line=42)

# Expand context around match
cass_expand(path="/path", line=42, context=10)
```

**Pro tip:** Query CASS at the START of complex tasks. Past solutions save time.

## Semantic Memory - Persistent Learning

Store and retrieve learnings across sessions. Memories persist and are searchable.

### When to Use

- After solving a tricky problem - store the solution
- After making architectural decisions - store the reasoning
- Before starting work - search for relevant past learnings
- When you discover project-specific patterns

### Usage

```bash
# Store a learning
semantic-memory_store(information="OAuth refresh tokens need 5min buffer before expiry", metadata="auth, tokens")

# Search for relevant memories
semantic-memory_find(query="token refresh", limit=5)

# Validate a memory is still accurate (resets decay timer)
semantic-memory_validate(id="mem_123")
```

**Pro tip:** Store the WHY, not just the WHAT. Future you needs context.

## Swarm Coordinator Checklist (MANDATORY)

When coordinating a swarm, you MUST monitor workers and review their output.

### Monitor Loop

```
┌─────────────────────────────────────────────────────────────┐
│                 COORDINATOR MONITOR LOOP                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CHECK INBOX                                             │
│     swarmmail_inbox()                                       │
│     swarmmail_read_message(message_id=N)                    │
│                                                             │
│  2. CHECK STATUS                                            │
│     swarm_status(epic_id, project_key)                      │
│                                                             │
│  3. REVIEW COMPLETED WORK                                   │
│     swarm_review(project_key, epic_id, task_id, files)      │
│     → Generates review prompt with epic context + diff      │
│                                                             │
│  4. SEND FEEDBACK                                           │
│     swarm_review_feedback(                                  │
│       project_key, task_id, worker_id,                      │
│       status="approved|needs_changes",                      │
│       issues="[{file, line, issue, suggestion}]"            │
│     )                                                       │
│                                                             │
│  5. INTERVENE IF NEEDED                                     │
│     - Blocked >5min → unblock or reassign                   │
│     - File conflicts → mediate                              │
│     - Scope creep → approve or reject                       │
│     - 3 review failures → escalate to human                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Review Tools

| Tool | Purpose |
|------|---------|
| `swarm_review` | Generate review prompt with epic context, dependencies, and git diff |
| `swarm_review_feedback` | Send approval/rejection to worker (tracks 3-strike rule) |

### Review Criteria

- Does work fulfill subtask requirements?
- Does it serve the overall epic goal?
- Does it enable downstream tasks?
- Type safety, no obvious bugs?

### 3-Strike Rule

After 3 review rejections, task is marked **blocked**. This signals an architectural problem, not "try harder."

**NEVER skip the review step.** Workers complete faster when they get feedback.
