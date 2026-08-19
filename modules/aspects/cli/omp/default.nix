{den, ...}: {
  den.aspects.cli.omp.homeManager = {pkgs, ...}: let
    ompPackage = pkgs.callPackage ./_package {};
  in {
    home.packages = [ompPackage];
    home.file.".omp/natives/${ompPackage.version}".source = "${ompPackage}/lib/omp/natives/${ompPackage.version}";
  };
}
