{den, ...}: {
  den.aspects.apps.brave.homeManager = {
    lib,
    host,
    ...
  }:
    lib.mkMerge [
      {
        home.sessionVariables.KDE_USE_SESSION_KEYRING = "0";

        programs.brave = {
          enable = true;
          commandLineArgs = [
            "--disable-gpu-driver-bug-workaround --skia-graphite-backend"
            "--disable-features=PasswordManager"
            "--password-store=basic"
            "--no-default-browser-check"
            "--restore-last-session"
            "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks,PlatformHEVCEncoderSupport"
            "--ozone-platform=wayland"
            "--ozone-platform-hint=wayland"
          ];
        };
      }
      (lib.optionalAttrs (host.hasAspect den.aspects.platform.impermanence) {
        home.persistence."/persist".directories = [
          ".brave"
          ".cache/brave"
        ];
      })
    ];
}
