{den, ...}: {
  den.aspects.gaming.core.nixos = {pkgs, ...}: {
    hardware = {
      # xpadneo.enable = true;
      # xone.enable = true;
      graphics.enable = true;
    };

    services.ratbagd.enable = true;

    programs = {
      gamemode.enable = true;
      gamescope = {
        enable = true;
        capSysNice = true;
        package = pkgs.gamescope.overrideAttrs (old: {
          patches =
            (old.patches or [])
            ++ [./_/gamescope-drop-child-capabilities.patch];
        });
      };
      steam = {
        enable = true;
        package =
          pkgs.steam.override {extraPkgs = p: with p; [mangohud gamemode];};
        dedicatedServer.openFirewall = true;
        remotePlay.openFirewall = true;

        extraCompatPackages = with pkgs; [proton-ge-bin];
      };
    };

    environment.systemPackages = with pkgs; [
      winetricks
      wineWow64Packages.waylandFull
      adwsteamgtk
    ];
  };
}
