{den, ...}: {
  den.aspects.apps.obs-studio.homeManager = {
    programs.obs-studio.enable = true;
  };

  den.aspects.apps.audacity.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.audacity];
  };

  den.aspects.apps.kdenlive.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.kdePackages.kdenlive];
  };

  den.aspects.apps.davinci-resolve.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.davinci-resolve-studio];
  };

  den.aspects.apps.webcamoid.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.webcamoid];
  };

  den.aspects.apps.godot.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.godot_4];
  };

  den.aspects.apps.aseprite.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.aseprite];
  };
}
