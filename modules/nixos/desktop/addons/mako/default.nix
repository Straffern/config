{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.custom; let
  cfg = config.desktop.addons.mako;
  inherit (inputs.nix-colors.colorschemes.${builtins.toString config.desktop.colorscheme}) palette;
in {
  options.desktop.addons.mako = with types; {
    enable = mkBoolOpt false "Enable or disable mako";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mako
      libnotify
    ];

    home.configFile."mako/config" = {
      text = ''
        background-color=#${palette.base00}
        text-color=#${palette.base05}
        border-color=#${palette.base0D}
        progress-color=over #${palette.base02}

        [urgency=high]
        border-color=#${palette.base09}
      '';
      onChange = ''
        ${pkgs.busybox}/bin/pkill -SIGUSR2 mako
      '';
    };
  };
}
