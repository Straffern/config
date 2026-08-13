{
  den,
  inputs,
  ...
}: {
  flake-file.inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  den.aspects.platform = {
    nix.nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        nil
        nixfmt
        nix-index
        nix-prefetch-git
      ];
      nix = {
        settings = {
          trusted-users = [
            "@wheel"
            "root"
          ];
          auto-optimise-store = true;
          use-xdg-base-directories = true;
          experimental-features = ["pipe-operators"];
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
          max-substitution-jobs = 128;
          fallback = true;
          narinfo-cache-negative-ttl = 21600;
          substituters = [
            "https://cache.nixos.org"
            "https://devenv.cachix.org?priority=41"
            "https://nix-community.cachix.org?priority=42"
            "https://hyprland.cachix.org?priority=43"
            "https://niri.cachix.org?priority=44"
            "https://attic.xuyh0120.win/lantian?priority=45"
            "https://cache.numtide.com?priority=46"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
            "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
        };
      };
    };

    boot.nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        efibootmgr
        efitools
        efivar
        fwupd
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

    fonts.nixos = {pkgs, ...}: {
      environment.variables.LOG_ICONS = "true";
      environment.systemPackages = [pkgs.font-manager];
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
      ];
    };

    xkb.nixos = {
      console.useXkbConfig = true;
      services.xserver.xkb = {
        layout = "us";
        options = "caps:escape";
      };
    };
    nix.homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: {
      home.packages = with pkgs; [
        inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel
        nix-output-monitor
        nvd
      ];
      systemd.user.startServices = "sd-switch";
      programs.home-manager.enable = true;
      home.sessionVariables.NH_FLAKE = "/home/${config.home.username}/.dotfiles";
      nix.settings = {
        extra-trusted-substituters = ["https://numtide.cachix.org?priority=42"];
        extra-trusted-public-keys = ["numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        warn-dirty = false;
        use-xdg-base-directories = true;
      };
      news = {
        display = "silent";
        json = lib.mkForce {};
        entries = lib.mkForce [];
      };
    };
  };
}
