{ ... }:
final: prev: {
  efitools = prev.efitools.overrideAttrs (old: {
    # Fix for GCC 15 / C23 where 'bool' is a keyword.
    # efitools tries to typedef it, which causes a conflict.
    # Forcing an older C standard avoids this.
    env = (old.env or { }) // {
      NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "") + " -std=gnu17";
    };
  });
}
