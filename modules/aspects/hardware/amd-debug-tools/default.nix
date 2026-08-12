{den, ...}: let
  amd-debug-tools = pkgs: pkgs.callPackage ./_package {};
in {
  den.aspects.hardware.amd-debug-tools = {
    packages = {pkgs, ...}: {amd-debug-tools = amd-debug-tools pkgs;};
    nixos = {pkgs, ...}: {
      environment.systemPackages = [(amd-debug-tools pkgs)];
    };
  };
}
