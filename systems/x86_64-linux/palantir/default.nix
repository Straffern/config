{
  config,
  lib,
  namespace,
  pkgs,
  ...
}: let
  inherit (lib.${namespace}) enabled;
in {
  imports = [./disko.nix ./hardware-configuration.nix];

  ${namespace} = {
    system.boot.bios = enabled;
    system.boot.enable = lib.mkForce false;

    suites = {server.enable = true;};
    # suites.kubernetes = enabled;

    cli.programs.nix-ld = enabled;

    user."1" = {
      name = "alex";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
      extraGroups = ["wheel"];
      shell = pkgs.zsh;
    };
  };

  sops.secrets."palantir_ssh_private_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "600";
    path = "/home/" + config.${namespace}.user."1".name + "/.ssh/id_ed25519";
    sopsFile = ../../../secrets.yaml;
  };

  sops.secrets."palantir_ssh_public_key" = {
    owner = config.${namespace}.user."1".name;
    group = "users";
    mode = "644";
    path =
      "/home/"
      + config.${namespace}.user."1".name
      + "/.ssh/id_ed25519.pub";
    sopsFile = ../../../secrets.yaml;
  };

  # ── Hermes Agent (AI agent service) ──────────────────────────────────

  sops.secrets."openclaw_ai_api_key" = {
    sopsFile = ../../../secrets.yaml;
  };
  sops.secrets."openclaw_telegram_bot_alex" = {
    sopsFile = ../../../secrets.yaml;
  };

  # Hermes env file — reuses existing openclaw secrets from secrets.yaml
  sops.templates."hermes-env" = {
    content = ''
      OPENAI_API_KEY=${config.sops.placeholder."openclaw_ai_api_key"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."openclaw_telegram_bot_alex"}
      TELEGRAM_ALLOWED_USERS=6045704025
    '';
    owner = "hermes";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [config.sops.templates."hermes-env".path];
    settings = {
      model = {
        default = "minimax-m2.7";
        base_url = "https://opencode.ai/zen/go/v1";
      };
      toolsets = ["all"];
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };
  };

  # Ensure hermes-agent restarts when sops re-renders the env file
  systemd.services.hermes-agent = {
    after = ["sops-nix.service"];
    wants = ["sops-nix.service"];
    restartTriggers = [config.sops.templates."hermes-env".content];
  };

  environment.systemPackages = [pkgs.home-manager];

  programs.zsh.enable = true;

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
