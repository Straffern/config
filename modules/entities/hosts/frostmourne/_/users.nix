_: {
  den.aspects._frostmourne-users.nixos = {lib, ...}: {
    users.users.alex = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJhTYisdHd7YcoN8MbBduHSnJthNpEvFum2rmLuS4LwV alex@flensborg.dev"
      ];
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
    users.users.niko = {
      isNormalUser = true;
      group = "users";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGOjIECjXpxmLWZXOX6DK3RqyGKvK9DQultaoWeyBXP Gunniko@gmail.com"
      ];
      extraGroups = [
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
}
