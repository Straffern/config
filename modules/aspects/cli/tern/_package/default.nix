{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  glib,
  makeDesktopItem,
  copyDesktopItems,
  libGL,
  libxkbcommon,
  linux-pam,
  vulkan-loader,
  wayland,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "tern";
  version = "0.3.1";

  # Closed beta, not publicly downloadable. Add to the store once:
  #   nix-store --add-fixed sha256 ~/Downloads/Tern-0.3.1-linux-x86_64.tar.gz
  src = requireFile {
    name = "Tern-${finalAttrs.version}-linux-x86_64.tar.gz";
    url = "https://stencil.so/tern";
    sha256 = "1q7fcpnqanzdjqmzaln43w8z6ic3i61lbly1kv0y0df08lblqhq5";
  };

  nativeBuildInputs = [autoPatchelfHook makeWrapper copyDesktopItems];
  buildInputs = [stdenv.cc.cc.lib];
  # dlopen'd at runtime, not in DT_NEEDED.
  runtimeDependencies = [libGL libxkbcommon linux-pam vulkan-loader wayland];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/tern $out/bin
    cp -r tern assets $out/lib/tern/
    makeWrapper $out/lib/tern/tern $out/bin/tern --prefix PATH : ${lib.makeBinPath [glib]}
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "tern";
      desktopName = "Tern";
      exec = "tern";
      icon = "utilities-terminal";
      categories = ["System" "TerminalEmulator"];
    })
  ];

  meta = {
    description = "Tern terminal by Stencil (closed beta)";
    homepage = "https://stencil.so/tern";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "tern";
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
