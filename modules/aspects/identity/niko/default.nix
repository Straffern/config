{den, ...}: {
  den.aspects.niko.user = {
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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHGOjIECjXpxmLWZXOX6DK3RqyGKvK9DQultaoWeyBXP Gunniko@gmail.com"
    ];
  };
}
