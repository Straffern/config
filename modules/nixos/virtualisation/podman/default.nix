{ options, config, lib, pkgs, ...}: 

with lib;
with lib.custom;
let cfg = config.custom.virtualisation.podman;
in
{
  options.custom.virtualisation.podman = with types; {
    enable = mkBoolOpt false "Wether or not to enable podman";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [podman-compose];

    home.extraOptions = {
      home.shellAliases = { "docker-compose" = "podman-compose";};
    };

    virtualisation.containers = enabled;
    virtualisation = {
      podman = {
        enable = cfg.enable;
        dockerCompat = true;
        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
