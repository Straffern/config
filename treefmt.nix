{
  projectRootFile = "flake.nix";

  programs.alejandra.enable = true;
  programs.deadnix = {
    enable = true;
    no-lambda-pattern-names = true;
    no-underscore = true;
  };
  programs.statix.enable = true;
}
