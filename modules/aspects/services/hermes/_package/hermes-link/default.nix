{
  lib,
  buildNpmPackage,
  fetchurl,
}:
buildNpmPackage rec {
  pname = "hermes-link";
  version = "1.0.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@hermespilot/link/-/link-${version}.tgz";
    hash = "sha256-iJNI5IeCRgy6/3pmzKLZTY7sP0KM9K78CroMl+gHNd8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev"];

  npmDepsHash = "sha256-CyP0XC0doICQBcxeh+75v8s0M1j8JU0C8uYYAiewTWA=";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node_modules/@hermespilot
    cp -r . $out/lib/node_modules/@hermespilot/link
    mkdir -p $out/bin
    ln -s $out/lib/node_modules/@hermespilot/link/dist/cli/index.js $out/bin/hermeslink
    runHook postInstall
  '';

  meta = {
    description = "HermesPilot companion service for Hermes Agent";
    homepage = "https://www.npmjs.com/package/@hermespilot/link";
    license = lib.licenses.mit;
    mainProgram = "hermeslink";
    platforms = lib.platforms.linux;
  };
}
