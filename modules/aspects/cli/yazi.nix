{den, ...}: {
  den.aspects.cli.yazi.homeManager = {pkgs, ...}: {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
    };
    home.packages = with pkgs; [imagemagick ffmpegthumbnailer fontpreview unar poppler unar];
  };
}
