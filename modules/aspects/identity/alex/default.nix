{den, ...}: {
  den.aspects.alex = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
    ];

    nixos = {
      users.users.alex = {
        group = "users";
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
      };
    };

    homeManager = {
      xdg.dataFile."face.icon".source = ./_assets/pfp.jpg;
      xdg.dataFile."sounds/bell.oga".source = ./_assets/fuck.oga;
    };
  };
}
