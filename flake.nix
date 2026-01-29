{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    nixos-hardware = {url = "github:nixos/nixos-hardware";};

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

    # NOTE: hyprnix disabled - binary cache is incomplete, causing:
    # - ABI mismatches (GCC 14/15) when packages are built locally
    # - FetchContent failures (git not available in sandbox)
    # Using nixpkgs hyprland ecosystem packages instead.
    # hyprnix.url = "github:hyprwm/hyprnix";

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

    # Styling

    stylix = {
      url = "github:danth/stylix";
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

    jjui = {
      url = "github:idursun/jjui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lumen.url = "github:Straffern/lumen/fix-working-tree-path-resolution";
    ww.url = "github:Straffern/ww/add-nix-flake";
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
      channels-config = {allowUnfree = true;};

      overlays = with inputs; [
        nixgl.overlay
        nur.overlays.default
        devenv.overlays.default
        #
        # NOTE: hyprnix removed - binary cache incomplete, causes build failures
        # (ABI mismatches, FetchContent requiring git in sandbox)
        # Using nixpkgs hyprland ecosystem packages instead.
      ];

      systems.modules.nixos = with inputs; [
        determinate.nixosModules.default
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        impermanence.nixosModules.impermanence
        persist-retro.nixosModules.persist-retro
        lanzaboote.nixosModules.lanzaboote
      ];
      homes.modules = with inputs; [
        persist-retro.nixosModules.home-manager.persist-retro
        stylix.homeModules.stylix
        catppuccin.homeModules.catppuccin
      ];

      deploy = lib.mkDeploy {inherit (inputs) self;};

      checks =
        builtins.mapAttrs
        (_system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy)
        inputs.deploy-rs.lib;
    };
}
