- In all interaction and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## Code Quality Standards

- Make minimal, surgical changes
- **Abstractions**: Consciously constrained, pragmatically parameterised, doggedly documented

### **ENTROPY REMINDER**

This codebase will outlive you. Every shortcut you take becomes
someone else's burden. Every hack compounds into technical debt
that slows the whole team down.

You are not just writing code. You are shaping the future of this
project. The patterns you establish will be copied. The corners
you cut will be cut again.

**Fight entropy. Leave the codebase better than you found it.**

## Testing

- Write tests that verify semantically correct behavior
- **Failing tests are acceptable** when they expose genuine bugs and test correct behavior

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.

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

Only use jj, NEVER USE git!
