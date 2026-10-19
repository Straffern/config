{
  lib,
  rustPlatform,
  fetchFromGitHub,
  git,
  jujutsu,
}:
rustPlatform.buildRustPackage rec {
  pname = "ji";
  version = "0.1.6";

  src = fetchFromGitHub {
    owner = "daeh";
    repo = "jujutsu-gi";
    rev = "88a852b603474094448688b53f020a7a3922dcbd";
    hash = "sha256-ZpB0JjVfk1/nWC7SeLVE1kgccp+3mscwKV5J/lvwIDE=";
  };

  patches = [./ji-linux.patch];

  cargoHash = "sha256-Ek75SHdySDpUu3nWrZUhA3SZE5KagqB9sRqQy/Dw3FE=";

  # jj >= 0.46 creates Git worktrees for workspaces in colocated repos.
  nativeCheckInputs = [git jujutsu];

  preCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';

  # Finder xattrs are macOS-only; exercise the remaining Linux test suite.
  checkFlags = [
    "--skip"
    "finder_xattrs::tests::"
    "--skip"
    "alias_changed_in_default_survives_transfer_to_workspace"
    "--skip"
    "alias_finder_info_survives_workspace_create"
    "--skip"
    "alias_without_disk_oracle_warns_on_create"
    "--skip"
    "fixup_disabled_by_config_still_warns"
    "--skip"
    "new_alias_created_in_workspace_reaches_target_on_close"
    "--skip"
    "plain_file_replacing_alias_does_not_gain_alias_flag"
    "--skip"
    "retargeted_alias_survives_merge_close"
  ];

  meta = with lib; {
    description = "TUI and CLI for managing Jujutsu workspaces";
    homepage = "https://github.com/daeh/jujutsu-gi";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
