{ pkgs }: {
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = true;
      bezier = [ "overshot,0.13,0.99,0.29,1.1" "linear,0.0,0.0,1.0,1.0" ];
      animation = [
        "windows,1,4,overshot,slide"
        "fade,1,10,default"
        "workspaces,1,6,overshot,slide"
        "borderangle,1,100,linear,loop"
      ];
    };

  };
}
