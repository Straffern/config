_: final: prev: {
  # Temporary overlay for jj-fzf until nixpkgs PR #455933 lands in nixos-unstable
  # The 0.33.0 package was missing preflight.sh and lib/ directory
  # Remove this overlay once nixos-unstable has jj-fzf >= 0.34.0
  jj-fzf = prev.stdenv.mkDerivation rec {
    pname = "jj-fzf";
    version = "0.34.0";

    src = final.fetchFromGitHub {
      owner = "tim-janik";
      repo = "jj-fzf";
      tag = "v${version}";
      hash = "sha256-aJyKVMg/yI2CmAx5TxN0w670Rq26ESdLzESgh8Jr4nE=";
    };

    strictDeps = true;
    buildInputs = [final.bashInteractive];
    nativeBuildInputs = [final.bashInteractive final.makeWrapper final.pandoc final.jujutsu];

    dontConfigure = true;
    dontBuild = true;
    makeFlags = ["PREFIX=${placeholder "out"}"];
    patches = [./nix-preflight.patch];

    postPatch = ''
      substituteInPlace lib/gen-message.py \
        --replace-fail '/usr/bin/env -S python3 -B' '${final.python3}/bin/python -B'
      patchShebangs --build lib/*.sh
      patchShebangs --host jj-fzf *.sh contrib/*.sh
    '';

    postInstall = ''
      wrapProgram $out/bin/jj-fzf \
        --prefix PATH : ${
        final.lib.makeBinPath [
          final.bashInteractive
          final.coreutils
          final.fzf
          final.gawk
          final.gnused
          final.jujutsu
          final.python3
          final.unixtools.column
        ]
      }
    '';

    meta = with final.lib; {
      description = "Text UI for Jujutsu based on fzf";
      homepage = "https://github.com/tim-janik/jj-fzf";
      license = licenses.mpl20;
      maintainers = with maintainers; [bbigras];
      platforms = platforms.all;
    };
  };
}
