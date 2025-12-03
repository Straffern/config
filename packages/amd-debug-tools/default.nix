{ lib, python312, fetchurl, makeWrapper, acpica-tools, ethtool, edid-decode
, callPackage, autoPatchelfHook, systemd, }:

let
  # Build cysystemd locally since it's not in nixpkgs
  cysystemd = python312.pkgs.buildPythonPackage {
    pname = "cysystemd";
    version = "2.0.1";
    format = "wheel";

    src = fetchurl {
      url =
        "https://files.pythonhosted.org/packages/21/22/afd2153b4100c7a8849a0810932c0636143b226d9ee0d8a761e233f0f8ce/cysystemd-2.0.1-cp312-cp312-manylinux_2_34_x86_64.whl";
      hash = "sha256-ObA9z87XaVft5fPyGVa1aHoFEb3R0NQfLT3/yd8yMg0=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ systemd ];
    propagatedBuildInputs = [ ];
    doCheck = false;
    pythonImportsCheck = [ "cysystemd" ];

    meta = with lib; {
      description = "systemd wrapper in Cython";
      homepage = "https://github.com/mosquito/cysystemd";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };
in python312.pkgs.buildPythonApplication rec {
  pname = "amd-debug-tools";
  version = "0.2.11";
  format = "wheel";

  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/ea/59/ebda469d74a1e18f68e0a231dd26127585d75d5a06c58dd5be1befd831fd/amd_debug_tools-0.2.11-py3-none-any.whl";
    hash = "sha256-pnALYN9tS9VJ8d0c8w0EELrYzArgN8fexHI+4A/u/Hk=";
  };

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with python312.pkgs; [
    dbus-fast
    pyudev
    packaging
    pandas
    jinja2
    tabulate
    seaborn
    matplotlib
    cysystemd
  ];

  # Disable tests (not available in wheel)
  doCheck = false;

  # Wrap executables to include runtime tools in PATH
  postFixup = ''
    for bin in $out/bin/amd-*; do
      wrapProgram "$bin" \
        --prefix PATH : ${lib.makeBinPath [ acpica-tools ethtool edid-decode ]}
    done
  '';

  pythonImportsCheck = [ "amd_debug" ];

  meta = with lib; {
    description =
      "Debug tools for AMD systems (amd-s2idle, amd-bios, amd-pstate, amd-ttm)";
    homepage = "https://github.com/superm1/amd-debug-tools";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "amd-s2idle";
    maintainers = [ ];
  };
}
