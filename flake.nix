{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    persist-retro.url = "github:straffern/persist-retro";

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: Intentionally NOT following nixpkgs - indexes are version-specific
    nix-index-database.url = "github:nix-community/nix-index-database";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Terminal

    zjstatus.url = "github:dj95/zjstatus";

    # Homelab

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI Agent Gateway
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Styling

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-colors.url = "github:IogaMaster/nix-colors";
    # prism.url = "github:IogaMaster/prism";

    # hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    lobster.url = "github:justchokingaround/lobster";

    devenv.url = "github:cachix/devenv";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    lumen.url = "github:jnsahaj/lumen/v2.22.0";
    ww.url = "github:omihirofumi/ww";

    hyprland.url = "github:hyprwm/hyprland";
    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankLinux
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  outputs = inputs: let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;

      snowfall = {
        metadata = "asgaard";
        namespace = "asgaard";
        meta = {
          name = "dotfiles";
          title = "dotfiles";
        };
      };
    };
  in
    lib.mkFlake {
      # inherit inputs;
      # src = ./.;
      channels-config = {
        allowUnfree = true;
      };

      overlays = with inputs; [
        nixgl.overlay
        nur.overlays.default
        devenv.overlays.default
        # Packages from nixos-unstable for cache hits (not yet in 25.11 stable)
        (
          final: prev: let
            unstablePkgs = import unstable {
              localSystem = final.stdenv.hostPlatform;
              inherit (prev) config;
            };
          in {
            hyprpaper = hyprpaper.packages.${final.stdenv.hostPlatform.system}.hyprpaper;
            inherit
              (unstablePkgs)
              bun
              jujutsu
              jjui
              hyprlock
              hypridle
              hyprpicker
              uwsm
              dgop
              ;
          }
        )
        nix-cachyos-kernel.overlays.pinned
      ];

      systems.modules.nixos = with inputs; [
        hyprland.nixosModules.default
        determinate.nixosModules.default
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        impermanence.nixosModules.impermanence
        persist-retro.nixosModules.persist-retro
        lanzaboote.nixosModules.lanzaboote
        hermes-agent.nixosModules.default
        dms.nixosModules.default
        dms.nixosModules.greeter
      ];
      homes.modules = with inputs; [
        hyprland.homeManagerModules.default
        persist-retro.nixosModules.home-manager.persist-retro
        stylix.homeModules.stylix
        catppuccin.homeModules.catppuccin
        niri.homeModules.niri
        dms.homeModules.dank-material-shell
        dms.homeModules.niri
        danksearch.homeModules.dsearch
        noctalia.homeModules.default
      ];

      deploy = lib.mkDeploy {inherit (inputs) self;};

      checks =
        builtins.mapAttrs (
          _system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy
        )
        inputs.deploy-rs.lib;
    };
}
