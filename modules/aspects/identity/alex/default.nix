{den, ...}: {
  den.aspects.alex = {
    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
    ];

    nixos = {
      users.users.alex = {
        isNormalUser = true;
        home = "/home/alex";
        group = "users";
        extraGroups = [
          "wheel"
          "audio"
          "sound"
          "video"
          "networkmanager"
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
      home.username = "alex";
      home.homeDirectory = "/home/alex";
      xdg.dataFile."face.icon".source = ./_assets/pfp.jpg;
      xdg.dataFile."sounds/bell.oga".source = ./_assets/fuck.oga;
    };
  };
}
