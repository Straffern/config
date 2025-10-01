# OpenCode Command Agent Mapping

This document explains the new command-to-agent mapping feature for OpenCode commands.

## Overview

The AI module now supports customizing which agent executes specific OpenCode commands. By default, commands do not specify any agent, allowing OpenCode to use its default agent selection. You can optionally specify agents for specific commands.

## Default Behavior

**No agent specified by default** - All commands generate clean frontmatter without an `agent` field, allowing OpenCode to use its configured default agent.

## Configuration

The mappings can be customized in your NixOS configuration:

```nix
{
  asgaard.cli.programs.ai.commandAgentMappings = {
    "feature" = "plan";
    "implement" = "build";
    "research" = "plan";
    "review" = "plan";
    "custom-command" = "build";
  };
}
```

## How It Works

1. The `commandAgentMappings` option defines specific command-to-agent mappings
2. During OpenCode command generation, each command checks for a specific mapping
3. **If no mapping exists**, no `agent` field is included in the generated markdown
4. **If a mapping exists**, the `agent:` frontmatter is included with the specified agent
5. OpenCode uses the agent field when present, or falls back to its default behavior

## Example Generated Files

### Without mapping (default):
```yaml
---
description: feature command
---
```

### With mapping:
```yaml
---
description: feature command
agent: plan
---
```

## Benefits

- **Clean defaults**: No unnecessary agent specifications when not needed
- **Flexible control**: Specify agents only when required for specific workflows
- **OpenCode native behavior**: Leverages OpenCode's built-in agent management
- **Minimal configuration**: Only specify what you need to override

## Recommended Mappings

Common mappings you might want to use:

```nix
{
  asgaard.cli.programs.ai.commandAgentMappings = {
    # Planning and analysis commands
    "feature" = "plan";
    "research" = "plan";
    "breakdown" = "plan";
    "document" = "plan";
    
    # Implementation commands
    "implement" = "build";
    "execute" = "build";
    "fix" = "build";
    
    # Review and validation
    "review" = "plan";  # Use plan agent for read-only reviews
  };
}
```

## Example Usage

With the above configuration, when you run `/feature` in OpenCode, it will use the "plan" agent (which has restricted permissions for analysis and planning). When you run `/implement`, it will use the "build" agent with full implementation capabilities. Commands without mappings will use OpenCode's default agent.