{
  lib,
  python3,
  source,
}:
python3.pkgs.buildPythonPackage {
  pname = "omp-rpc";
  version = "0.1.0";
  pyproject = true;

  src = source;
  sourceRoot = "${source.name}/python/omp-rpc";

  build-system = [python3.pkgs.setuptools];

  pythonImportsCheck = ["omp_rpc"];

  meta = {
    description = "Typed Python client for the Oh My Pi RPC protocol";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = lib.licenses.mit;
  };
}
