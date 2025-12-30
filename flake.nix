{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = { url = "github:nix-community/NUR"; };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = { url = "github:nixos/nixos-hardware"; };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    persist-retro.url = "github:straffern/persist-retro";
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";

    nixgl.url = "github:nix-community/nixGL";
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

    # hyprland.url = "github:hyprwm/Hyprland";
    # waybar = {
    #   url = "github:Alexays/Waybar";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Terminal

    # zjstatus = { url = "github:dj95/zjstatus"; };

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

    stylix.url = "github:danth/stylix";
    catppuccin.url = "github:catppuccin/nix";

    # nix-colors.url = "github:IogaMaster/nix-colors";
    # prism.url = "github:IogaMaster/prism";

    # hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
    lobster = {
      url = "github:justchokingaround/lobster";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv";

    beads.url = "github:steveyegge/beads";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    jjui.url = "github:idursun/jjui";

  };

  outputs = inputs:
    let
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
    in lib.mkFlake {
      # inherit inputs;
      # src = ./.;
      channels-config = { allowUnfree = true; };

      overlays = with inputs; [
        nixgl.overlay
        nur.overlays.default
        # devenv.overlays.default
        # hyprland.overlays.default
        # waybar.overlays.default
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
        impermanence.nixosModules.home-manager.impermanence
        persist-retro.nixosModules.home-manager.persist-retro
        stylix.homeModules.stylix
        catppuccin.homeModules.catppuccin
      ];

      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks = builtins.mapAttrs
        (system: deploy-lib: deploy-lib.deployChecks inputs.self.deploy)
        inputs.deploy-rs.lib;

    };
}
