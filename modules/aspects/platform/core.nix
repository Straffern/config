{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  den.aspects.platform = {
    nix.nixos = {
      config,
      lib,
      ...
    }: {
      imports = [
        inputs.determinate.nixosModules.default
      ];
      determinate.enable = true;
      nix = {
        settings = {
          auto-optimise-store = true;
          use-xdg-base-directories = true;
          lazy-trees = true;
          experimental-features = [
            "nix-command"
            "flakes"
            "fetch-tree"
            "pipe-operators"
            "parallel-eval"
          ];
          warn-dirty = false;
          system-features = [
            "kvm"
            "big-parallel"
            "nixos-test"
          ];
          connect-timeout = 15;
          stalled-download-timeout = 30;
          download-attempts = 2;
          http-connections = 128;
          max-jobs = 4;
          cores = 4;
          max-substitution-jobs = 32;
          fallback = true;
          narinfo-cache-negative-ttl = 21600;
          substituters = [
            "https://cache.nixos.org"
            "https://install.determinate.systems"
            "https://devenv.cachix.org?priority=41"
            "https://nix-community.cachix.org?priority=42"
            "https://niri.cachix.org?priority=43"
            "https://cache.numtide.com?priority=46"
            "https://numtide.cachix.org?priority=42"
          ];
          # The daemon already trusts `substituters` exactly as written. Flake nixConfig names
          # caches without `?priority=`, so trust the bare URLs too: untrusted users can then opt
          # in to any configured cache, at that cache's advertised priority.
          trusted-substituters = map (url: lib.head (lib.splitString "?" url)) config.nix.settings.substituters;
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
          ];
        };
      };
      systemd.services.nix-daemon.serviceConfig = {
        CPUWeight = 50;
        IOWeight = 50;
        # journald stamps all daemon output priority 6, ERRORs included, so LogLevelMax cannot
        # separate noise from failures. Drop the per-connection lines and determinate-nixd's
        # warning for every download result its logger cannot parse.
        LogFilterPatterns = [
          "~^accepted connection from pid [0-9]+, user"
          "~^reaped child process [0-9]+, status = succeeded$"
          "~Unparsed Nix daemon log line"
          "~^ +(in determinate_nixd::api::logger::handle_connection|at src/api/logger[.]rs:[0-9]+)$"
        ];
      };
    };

    boot.nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        efibootmgr
        efitools
        efivar
      ];
      boot = {
        initrd.systemd.enable = true;
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            enable = true;
            configurationLimit = 20;
            editor = false;
          };
          timeout = 1;
        };
      };
    };

    environment.nixos = {
      environment.sessionVariables = {
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_BIN_HOME = "$HOME/.local/bin";
        XDG_DESKTOP_DIR = "$HOME";
      };
      environment.variables = {
        LESSHISTFILE = "$XDG_CACHE_HOME/less.history";
        WGETRC = "$XDG_CONFIG_HOME/wgetrc";
      };
    };

    nix.homeManager = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = with pkgs; [
        nil
        nix-output-monitor
        nix-prefetch-git
        nixfmt
        nvd
      ];
      systemd.user.startServices = "sd-switch";
      news = {
        display = "silent";
        json = lib.mkForce {};
        entries = lib.mkForce [];
      };
    };
  };
}
