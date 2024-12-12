{
  description = "";

  inputs = {
    # Core
    # NixPkgs (nixos-23.11)
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    persist-retro.url = "github:Geometer1729/persist-retro";

    stylix.url = "github:danth/stylix";

    nix-colors.url = "github:IogaMaster/nix-colors";
    prism.url = "github:IogaMaster/prism";

    hyprpanel.url = "github:Jas-SinghFSU/HyprPanel";
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "dotfiles";
            title = "dotfiles";
          };

          namespace = "asgaard";
        };
      };
    in lib.mkFlake {
      inherit inputs;
      src = ./.;
      channels-config = { allowUnfree = true; };

      overlays = with inputs; [ hyprpanel.overlay ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        stylix.nixosModules.stylix
        impermanence.nixosModules.impermanence
        persist-retro.nixosModules.persist-retro
      ];
      homes.modules = with inputs; [ stylix.homeManagerModules.stylix ];

      templates = import ./templates { };
    };
}
