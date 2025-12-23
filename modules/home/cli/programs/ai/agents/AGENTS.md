# Agent Orchestration System

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

## Agent Directory

### Core Consultation Agents

**research-agent** - Technical research and documentation gathering  
**architecture-agent** - Project structure and integration guidance  
**memory-agent** - Persistent knowledge storage and retrieval

### Planning Agents

**feature-planner** - Complex feature planning and breakdown  
**fix-planner** - Bug investigation and resolution planning  
**task-planner** - Lightweight task planning and organization

### Review Agents (Run Before Completion)

**qa-reviewer** - Testing coverage and functional validation  
**security-reviewer** - Security vulnerability assessment  
**consistency-reviewer** - Pattern and style consistency  
**factual-reviewer** - Implementation verification  
**redundancy-reviewer** - Code duplication analysis  
**senior-engineer-reviewer** - Strategic technical review

### Specialized Agents

**elixir-reviewer** - Elixir/Phoenix/Ash code review  
**documentation-reviewer** - Documentation quality assessment  
**jj-expert** - Jujutsu (jj) version control operations  
**lua-expert** - Lua programming and Neovim guidance  
**neovim-expert** - Neovim configuration and customization  
**test-expert** - Testing methodologies and best practices

See individual agent definition files in `agent-definitions/` for detailed guidance.

---

## Memory Management

### Using the Memory Agent

The **memory-agent** provides persistent knowledge storage using bd issues with special labels.

**When to use:**

1. **BEFORE starting work** - Check for relevant context:
   - Working with unfamiliar codebase areas
   - Implementing features similar to past work
   - Debugging recurring issues

2. **IMMEDIATELY AFTER solving difficult problems** - Capture hard-won knowledge:
   - Complex debugging sessions
   - Non-obvious solutions
   - Architecture decisions
   - Gotchas and pitfalls discovered

**How to use:**

**RETRIEVE mode** - Search for relevant memories:

```
Task agent: memory-agent
Prompt: "RETRIEVE: Search for memories about [topic/component/pattern]"
```

**STORE mode** - Save new knowledge:

```
Task agent: memory-agent
Prompt: "STORE: [Category] - [Title]
Context: [What was the problem/situation]
Solution: [What worked and why]
Lessons: [Key takeaways]"
```

**Examples:**

```
# Before working on authentication
"RETRIEVE: Search for memories about authentication implementation"

# After solving a tricky bug
"STORE: Debugging - NixOS module initialization order
Context: Modules failed to load due to dependency ordering
Solution: Use mkAfter for dependent service configurations
Lessons: Always check systemd service ordering with 'systemctl list-dependencies'"

# After making an architecture decision
"STORE: Architecture - Hyprland configuration structure
Context: Needed to organize Hyprland configs for multiple machines
Solution: Split into per-monitor, keybinds, and autostart modules
Lessons: Modular approach makes machine-specific overrides easier"
```

**Best practices:**

- ✅ Retrieve before starting unfamiliar work
- ✅ Store immediately after solving hard problems (don't wait!)
- ✅ Include enough context for future understanding
- ✅ Tag with clear categories (Debugging, Architecture, Performance, etc.)
- ❌ Don't store trivial information
- ❌ Don't defer storage - capture while fresh in memory

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
- ✅ **Use memory-agent** to capture hard-won knowledge
- ✅ **Run review agents** before completing significant work
- ✅ **Follow documentation policy** - no proactive planning docs
- ❌ **Do NOT create duplicate tracking** systems
- ❌ **Do NOT skip agent consultation** when needed

---

## When in Doubt

1. **Ask a clarifying question** - Don't assume, just ask (one at a time)
2. **Check memory-agent** - Search for relevant past learnings
3. **Consult relevant agents** - research-agent, architecture-agent, skills
4. **Look at existing patterns** - Tests, similar features, documentation

---
