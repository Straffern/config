{ pkgs, config, lib, namespace, ... }:
let
  inherit (lib)
    mkIf mkEnableOption mkOption types concatStringsSep attrNames mapAttrsToList
    splitString hasInfix elem;
  inherit (lib.${namespace}) mkOpt;
  cfg = config.${namespace}.cli.programs.ai;

  # === Helper Functions - Core Utilities ===
  # Find index of first matching element in list
  findIndexOf = pred: list:
    let
      indices = lib.range 0 ((lib.length list) - 1);
      matchingIndices = lib.filter (i: pred (lib.elemAt list i)) indices;
    in if matchingIndices == [ ] then null else lib.head matchingIndices;

  # Extract frontmatter and body from markdown content with error handling
  extractFrontmatterAndBody = content:
    let
      lines = lib.splitString "\n" content;
      hasStartMarker = (lib.length lines) > 0 && lib.elemAt lines 0 == "---";
    in if !hasStartMarker then {
      frontmatter = [ ];
      body = lines;
    } else
      let
        remainingLines = lib.tail lines;
        endIndex = findIndexOf (line: line == "---") remainingLines;
      in if endIndex == null then
        lib.warn
        "No frontmatter end marker found, treating as body-only content" {
          frontmatter = [ ];
          body = lines;
        }
      else {
        frontmatter = lib.sublist 0 endIndex remainingLines;
        body = lib.sublist (endIndex + 1)
          ((lib.length remainingLines) - endIndex - 1) remainingLines;
      };

  # === Configuration Constants ===
  # Tool mapping from Claude to OpenCode
  toolMapping = {
    "Read" = "read";
    "Write" = "write";
    "Edit" = "edit";
    "MultiEdit" = "edit";
    "NotebookEdit" = "edit";
    "Bash" = "bash";
    "Grep" = "grep";
    "Glob" = "glob";
    "LS" = "list";
    "TodoWrite" = "todowrite";
    "TodoRead" = "todoread";
    "WebSearch" = "webfetch";
    "WebFetch" = "webfetch";
    "Patch" = "patch";
    # Tools that imply read access
    "Task" = "read";
    "NotebookRead" = "read";
  };

  # Dynamic model mapping from Claude to OpenCode based on configuration
  modelMapping = {
    "opus" = cfg.defaultReasoningModel;
    "sonnet" = cfg.defaultNonReasoningModel;
  };

  # All available OpenCode tools
  allOpenCodeTools = [
    "read"
    "write"
    "edit"
    "bash"
    "grep"
    "glob"
    "list"
    "patch"
    "todowrite"
    "todoread"
    "webfetch"
  ];

  # === Helper Functions - Tool Processing ===
  # Parse Claude tools string and create OpenCode tools config
  parseClaudeTools = toolsString:
    let
      # Clean newlines but preserve spaces within tool names
      cleanToolsString = lib.replaceStrings [ "\n" "\r" ] [ "" "" ] toolsString;
      # Split on comma-space without removing internal spaces
      claudeTools = if cleanToolsString == "" then
        [ ]
      else
        lib.splitString ", " cleanToolsString;

      # Check if any Claude tool enables an OpenCode tool
      isToolEnabled = openCodeTool:
        let
          enabledBy = lib.filter
            (claudeTool: (toolMapping.${claudeTool} or null) == openCodeTool)
            claudeTools;
        in (lib.length enabledBy) > 0;

      # Generate tools configuration
      toolsConfig = lib.listToAttrs (map (tool: {
        name = tool;
        value = isToolEnabled tool;
      }) allOpenCodeTools);
    in toolsConfig;

  # Generate permissions based on enabled tools
  generatePermissions = toolsConfig:
    let
      editPerm = if toolsConfig.write || toolsConfig.edit then
        cfg.permissionDefaults.edit
      else
        "deny";
      bashPerm =
        if toolsConfig.bash then cfg.permissionDefaults.bash else "deny";
      webfetchPerm = if toolsConfig.webfetch then
        cfg.permissionDefaults.webfetch
      else
        "deny";
    in {
      edit = editPerm;
      bash = bashPerm;
      webfetch = webfetchPerm;
    };

  # === Main Conversion Functions ===
  # Convert Claude agent YAML frontmatter to OpenCode format with error handling
  convertClaudeAgentToOpenCode = agentFile: agentName: modelOverride:
    let
      # Safe file reading with error handling
      contentResult = builtins.tryEval (builtins.readFile agentFile);
      content = if contentResult.success then
        contentResult.value
      else
        lib.warn "Failed to read agent file ${agentFile}, using empty content"
        "";
      # Extract YAML frontmatter using helper function
      parsed = extractFrontmatterAndBody content;
      yamlLines = parsed.frontmatter;
      bodyLines = parsed.body;

      # Parse key YAML fields - handle multi-line descriptions with error handling
      parseYamlField = prefix: defaultValue:
        let
          matchingLines =
            lib.filter (line: lib.hasPrefix prefix line) yamlLines;
          directMatch = if matchingLines != [ ] then
            lib.removePrefix prefix (lib.head matchingLines)
          else
            null;

          # Handle multi-line descriptions starting with ">"
          multiLineMatch = if directMatch != null
          && lib.hasPrefix ">" (lib.removePrefix " " directMatch) then
            let
              startIdx =
                findIndexOf (line: lib.hasPrefix prefix line) yamlLines;
              relevantLines = if startIdx != null && startIdx
              < (lib.length yamlLines - 1) then
                lib.sublist (startIdx + 1)
                ((lib.length yamlLines) - startIdx - 1) yamlLines
              else
                [ ];
              indentedLines = let
                collectIndented = lib.foldl' (acc: line:
                  if acc.done then
                    acc
                  else if lib.hasPrefix "  " line || line == "" then
                    acc // { lines = acc.lines ++ [ line ]; }
                  else
                    acc // { done = true; }) {
                      lines = [ ];
                      done = false;
                    } relevantLines;
              in collectIndented.lines;
              cleanedLines =
                map (line: lib.removePrefix "  " line) indentedLines;
            in lib.concatStringsSep " "
            (lib.filter (line: line != "") cleanedLines)
          else
            directMatch;
        in if multiLineMatch != null then
          multiLineMatch
        else
          (lib.warn
            "YAML field '${prefix}' not found in ${agentFile}, using default: ${defaultValue}"
            defaultValue);

      # Extract values from YAML
      description = parseYamlField "description: " "AI Agent";
      originalModel = parseYamlField "model: " "sonnet";
      claudeTools = parseYamlField "tools: " "Read";

      # Apply model mapping and overrides
      mappedModel = modelMapping.${originalModel} or originalModel;

      # Parse tools and generate OpenCode configuration
      toolsConfig = parseClaudeTools claudeTools;
      permissions = generatePermissions toolsConfig;

      # Determine temperature based on agent name and overrides with validation
      rawTemperature =
        cfg.temperatureOverrides.${agentName} or (if lib.hasInfix "reviewer"
        agentName then
          0.1
        else if lib.hasInfix "planner" agentName then
          0.3
        else
          cfg.defaultTemperature);

      # Validate temperature range (0.0 <= temp <= 1.0)
      temperature = if rawTemperature >= 0.0 && rawTemperature <= 1.0 then
        rawTemperature
      else
        (lib.warn "Invalid temperature ${
            toString rawTemperature
          } for agent ${agentName}, using 0.2" 0.2);

      # Generate tools YAML
      toolsYaml = concatStringsSep "\n" (map
        (tool: "  ${tool}: ${if toolsConfig.${tool} then "true" else "false"}")
        allOpenCodeTools);

      # Generate model line conditionally
      # Always include model if there's an explicit agentProviders override
      # Otherwise respect includeModelInAgents setting
      modelLine = if modelOverride != null then
        "model: ${modelOverride}\n        "
      else if cfg.includeModelInAgents then
        "model: ${mappedModel}\n        "
      else
        "";

      # Generate OpenCode frontmatter
      openCodeFrontmatter = ''
        ---
        description: ${description}
        mode: subagent
        ${modelLine}temperature: ${toString temperature}
        tools:
        ${toolsYaml}
        permission:
          edit: ${permissions.edit}
          bash: ${permissions.bash}
          webfetch: ${permissions.webfetch}
        ---
      '';

      body = concatStringsSep "\n" bodyLines;
    in openCodeFrontmatter + "\n" + body;

  # Convert Claude command to OpenCode format with error handling
  convertClaudeCommandToOpenCode = commandFile: commandName: defaultAgent:
    let
      # Safe file reading with error handling
      contentResult = builtins.tryEval (builtins.readFile commandFile);
      content = if contentResult.success then
        contentResult.value
      else
        lib.warn
        "Failed to read command file ${commandFile}, using empty content" "";
      # Remove any existing frontmatter and use content as template
      lines = lib.splitString "\n" content;

      # Extract body using helper function
      parsed = extractFrontmatterAndBody content;
      bodyLines = parsed.body;

      # Check if command has a specific agent mapping
      hasAgentMapping = cfg.commandAgentMappings ? ${commandName};
      mappedAgent = if hasAgentMapping then
        cfg.commandAgentMappings.${commandName}
      else
        null;

      # Generate OpenCode command frontmatter with conditional agent field
      agentLine = if hasAgentMapping then "agent: ${mappedAgent}" else "";
      openCodeFrontmatter = ''
        ---
        description: ${commandName} command
        ${agentLine}
        ---
      '';

      body = concatStringsSep "\n" bodyLines + ''

        $ARGUMENTS'';
    in openCodeFrontmatter + "\n" + body;

  # === File Processing ===
  # Safely scan directory for markdown files
  scanMarkdownFiles = dir:
    let filesResult = builtins.tryEval (builtins.readDir dir);
    in if filesResult.success then
      attrNames (lib.filterAttrs
        (name: type: type == "regular" && lib.hasSuffix ".md" name)
        filesResult.value)
    else
      (lib.warn
        "Failed to read directory ${toString dir}, no files will be processed"
        [ ]);

  # Get all agent files with error handling
  agentNames = scanMarkdownFiles ./agents/agent-definitions;

  # Get all command files with error handling
  commandNames = scanMarkdownFiles ./agents/commands;

  # === Helper Functions - File Generation ===
  # Generic function to symlink files directly (default) or convert them
  generateConvertedFiles = { files, sourceDir, outputPrefix, converter, }:
    lib.listToAttrs (map (fileName:
      let
        baseName = lib.removeSuffix ".md" fileName;
        fullPath = sourceDir + "/${fileName}";
      in {
        name = "${outputPrefix}/${baseName}.md";
        value = { text = converter fullPath baseName; };
      }) files);

  # === Generate Configurations ===
  # Generate OpenCode agent files (always convert - different format needed)
  openCodeAgents = generateConvertedFiles {
    files = agentNames;
    sourceDir = ./agents/agent-definitions;
    outputPrefix = ".config/opencode/agent";
    converter = agentFile: agentName:
      let modelOverride = cfg.agentProviders.${agentName} or null;
      in convertClaudeAgentToOpenCode agentFile agentName modelOverride;
  };

  # Generate OpenCode command files (always convert - different format needed)
  openCodeCommands = generateConvertedFiles {
    files = commandNames;
    sourceDir = ./agents/commands;
    outputPrefix = ".config/opencode/command";
    converter = commandFile: commandName:
      convertClaudeCommandToOpenCode commandFile commandName "build";
  };

in {
  options.${namespace}.cli.programs.ai = {
    enable = mkEnableOption "AI tools (Claude Code and OpenCode)";

    claude = { enable = mkEnableOption "Claude Code configuration"; };

    opencode = {
      enable = mkEnableOption "OpenCode configuration";
      convertAgents = mkOption {
        type = types.bool;
        default = true;
        description = "Convert Claude agents to OpenCode format";
      };
      convertCommands = mkOption {
        type = types.bool;
        default = true;
        description = "Convert Claude commands to OpenCode format";
      };
    };

    agentProviders = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "elixir-expert" = "cerebras/qwen3-coder";
        "architecture-agent" = "anthropic/claude-3-5-sonnet";
      };
      description = "Model provider overrides for specific agents";
    };

    defaultTemperature = mkOption {
      type = types.float;
      default = 0.2;
      description = "Default temperature for all agents";
    };

    temperatureOverrides = mkOption {
      type = types.attrsOf types.float;
      default = { };
      example = {
        "creative-agent" = 0.7;
        "code-reviewer" = 0.1;
      };
      description = "Temperature overrides for specific agents";
    };

    permissionDefaults = mkOption {
      type = types.submodule {
        options = {
          edit = mkOption {
            type = types.enum [ "allow" "ask" "deny" ];
            default = "allow";
            description = "Default permission for edit operations";
          };
          bash = mkOption {
            type = types.enum [ "allow" "ask" "deny" ];
            default = "allow";
            description = "Default permission for bash operations";
          };
          webfetch = mkOption {
            type = types.enum [ "allow" "ask" "deny" ];
            default = "allow";
            description = "Default permission for webfetch operations";
          };
        };
      };
      default = { };
      description = "Default permission strategy for tools";
    };

    defaultReasoningModel = mkOption {
      type = types.str;
      default = "anthropic/claude-opus-4-1-20250805";
      description =
        "Default model to use when Claude agent specifies 'opus' (reasoning model)";
    };

    defaultNonReasoningModel = mkOption {
      type = types.str;
      default = "anthropic/claude-sonnet-4-20250514";
      description =
        "Default model to use when Claude agent specifies 'sonnet' (non-reasoning model)";
    };

    includeModelInAgents = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether to include model field in converted OpenCode agents. When false, OpenCode uses its configured default model";
    };

    commandAgentMappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "feature" = "plan";
        "implement" = "build";
        "review" = "plan";
      };
      description =
        "Mapping of command names to agent names for OpenCode commands. Commands not specified will not include an agent field in the generated markdown";
    };
  };

  config = mkIf cfg.enable {
    # Claude configuration
    home.file = lib.mkMerge [
      # Link Claude agents and commands directly
      (lib.mkIf cfg.claude.enable {
        ".claude/agents" = {
          source = ./agents/agent-definitions;
          recursive = true;
        };
        ".claude/commands" = {
          source = ./agents/commands;
          recursive = true;
        };
        ".claude/CLAUDE.md" = { source = ./agents/AGENTS.md; };
      })

      # OpenCode converted files
      (lib.mkIf (cfg.opencode.enable && cfg.opencode.convertAgents)
        openCodeAgents)
      (lib.mkIf (cfg.opencode.enable && cfg.opencode.convertCommands)
        openCodeCommands)

      # OpenCode orchestration documentation
      (lib.mkIf cfg.opencode.enable {
        ".config/opencode/AGENTS.md" = { source = ./agents/AGENTS.md; };
        ".config/opencode/skills" = {
          source = ./agents/skills;
          recursive = true;
        };
        # ".config/opencode/opencode.json" = { source = ./agents/opencode.json; };
      })
    ];
  };
}

