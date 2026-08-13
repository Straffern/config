{den, ...}: {
  den.aspects.hardware.amd-monitoring.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.nvtopPackages.amd];
  };
}
