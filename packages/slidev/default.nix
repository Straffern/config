{ lib
, stdenv
, fetchFromGitHub
, bun
}:

stdenv.mkDerivation rec {
  pname = "slidev";
  version = "0.49.29";
  
  src = fetchFromGitHub {
    owner = "slidevjs";
    repo = "slidev";
    rev = "v${version}";
    # TODO: Run `nix-prefetch-github slidevjs slidev --rev v0.49.29` to get the sha256
    sha256 = "sha256-sDu2GTTLGD6XdBmfuBuCw99ePu9rnFxZChFGmyyTl0A=";
  };
  
  nativeBuildInputs = [ bun ];
  
  buildPhase = ''
    # Create a bun project and install dependencies
    export HOME=$(mktemp -d)
    bun init -y
    bun install @slidev/cli@${version}
  '';
  
  installPhase = ''
    mkdir -p $out/bin $out/lib/slidev
    
    # Copy the node_modules to the output
    cp -r node_modules $out/lib/slidev/
    cp -r package.json $out/lib/slidev/
    
    # Create a wrapper script
    cat > $out/bin/slidev << EOF
    #!/bin/sh
    exec ${bun}/bin/bun $out/lib/slidev/node_modules/.bin/slidev "\$@"
    EOF
    
    chmod +x $out/bin/slidev
  '';
  
  meta = with lib; {
    description = "Slidev package for presentation slides";
    homepage = "https://sli.dev";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "slidev";
  };
}