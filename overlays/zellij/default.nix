_: final: prev: let
  inherit (final.lib) optionalString;
  version = "0.42.1";
  system = final.stdenv.hostPlatform.system;

  releaseSrc =
    if system == "x86_64-linux"
    then
      final.fetchurl {
        url = "https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-CscQNdarbGjHCc+9Y42+ALqSFd/eWe6X/jIr60e9EP8=";
      }
    else null;
in {
  # Pin zellij to 0.42.1 as a workaround for nvim rendering issues:
  # https://github.com/zellij-org/zellij/issues/4263
  zellij =
    if releaseSrc == null
    then prev.zellij
    else
      final.stdenvNoCC.mkDerivation {
        pname = "zellij";
        inherit version;
        src = releaseSrc;

        nativeBuildInputs = [
          final.installShellFiles
          final.versionCheckHook
        ];

        dontConfigure = true;
        dontBuild = true;
        sourceRoot = ".";

        installPhase =
          ''
            runHook preInstall

            install -Dm755 zellij $out/bin/zellij
          ''
          + optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
            installShellCompletion --cmd zellij \
              --bash <($out/bin/zellij setup --generate-completion bash) \
              --fish <($out/bin/zellij setup --generate-completion fish) \
              --zsh <($out/bin/zellij setup --generate-completion zsh)
          ''
          + ''
            runHook postInstall
          '';

        doInstallCheck = true;
        versionCheckProgramArg = "--version";

        meta =
          prev.zellij.meta
          // {
            changelog = "https://github.com/zellij-org/zellij/blob/v${version}/CHANGELOG.md";
          };
      };
}
