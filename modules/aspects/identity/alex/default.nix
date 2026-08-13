{den, ...}: {
  den.aspects.alex = {
    includes = [
      den.batteries.primary-user
      den.batteries.host-aspects
      (den.batteries.user-shell "zsh")
    ];

    user = {
      extraGroups = [
        "audio"
        "sound"
        "video"
        "input"
        "tty"
        "podman"
        "kvm"
        "libvirtd"
        "ydotool"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
    };

    homeManager = {
      unfree.packages = [
        "aseprite"
        "brave"
        "davinci-resolve-studio"
        "goofcord"
        "keymapp"
      ];
      xdg.dataFile."face.icon".source = ./_assets/pfp.jpg;
      xdg.dataFile."sounds/bell.oga".source = ./_assets/fuck.oga;
    };
  };
}
