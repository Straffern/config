add this to kanshi module for the systemd:

  Service.RestartSec = 3;
  Unit.StartLimitIntervalSec = 60;
  Unit.StartLimitBurst = 10;

Do the same for Pypr daemon if possible.

reason:
when hyprland crashes unexpectedly, certain services/daemons wont get restarted or will restart too quick and fail.

We want to make the recovery more smooth and robust.
