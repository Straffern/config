{
  den,
  inputs,
  ...
}: {
  flake-file.inputs.helium-browser = {
    url = "github:oxcl/nix-flake-helium-browser";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.helium.homeManager = {
    lib,
    host,
    pkgs,
    ...
  }: {
    imports = [inputs.helium-browser.homeModules.default];
    config = let
      # wrapGAppsHook uses a C wrapper, so shell parameter expansion becomes a
      # literal browser target. Use the platform-neutral Chromium flag directly.
      helium =
        inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.helium.overrideAttrs
        (old: {
          preFixup =
            builtins.replaceStrings
            [
              ''--add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"''
            ]
            [
              ''--add-flags "--ozone-platform-hint=auto"''
            ]
            old.preFixup;
        });
    in
      lib.mkMerge [
        {
          programs.helium = {
            enable = true;
            package = helium;
          };
        }
        (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
          home.persistence."/persist".directories = [
            ".config/helium"
            ".cache/helium"
          ];
        })
      ];
  };
}
