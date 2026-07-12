{inputs, ...}: final: prev: let
  system = final.stdenv.hostPlatform.system;
in {
  # Upstream dropped overlays.default; keep local pkgs.llm-agents namespace.
  llm-agents = (prev.llm-agents or {}) // inputs.llm-agents.packages.${system};
}
