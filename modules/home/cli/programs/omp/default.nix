# Wrappers for bun-managed Oh My Pi that inject LD_LIBRARY_PATH.
#
# nix-ld only intercepts unpatched executables using /lib64/ld-linux.
# Bun from nixpkgs uses nix-store's glibc, so its dlopen() for .node
# native addons cannot find libraries via NIX_LD_LIBRARY_PATH alone.
# Per the nix-ld FAQ, the fix is a per-process LD_LIBRARY_PATH export.
{
  config,
  lib,
  pkgs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.${namespace}.cli.programs.omp;

  bunBin = "${config.home.homeDirectory}/.local/cache/.bun/bin";

  # Wraps a bun-installed binary with LD_LIBRARY_PATH set from NIX_LD_LIBRARY_PATH.
  # This scopes the library injection to the process tree only.
  mkWrapper = name:
    pkgs.writeShellScriptBin name ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      exec ${bunBin}/${cfg.bunBinaryName} "$@"
    '';
in {
  options.${namespace}.cli.programs.omp = {
    enable = mkEnableOption "Oh My Pi LD_LIBRARY_PATH wrappers";

    bunBinaryName = mkOption {
      type = types.str;
      default = "omp";
      description = "Name of the bun-installed binary to wrap";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (mkWrapper "omp")
      (mkWrapper "pi")
    ];
  };
}
