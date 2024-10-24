{ pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # Enable Bootloader
  system.boot.efi.enable = true;

  system.battery.enable =
    true; # Only for laptops, they will still work without it, just improves battery life
  system.shell.shell = "zsh";

  environment.systemPackages = with pkgs; [
    # Any particular packages only for this host
    micromamba
    tealdeer
    nodejs
  ];

  system.shell.initExtra = ''eval "$(micromamba shell hook --shell zsh)"'';

  suites.desktop.enable = true;
  suites.development.enable = true;

  impermanence.enable = true;

  # ======================== DO NOT CHANGE THIS ========================
  system.stateVersion = "23.11";
  # ======================== DO NOT CHANGE THIS ========================
}
