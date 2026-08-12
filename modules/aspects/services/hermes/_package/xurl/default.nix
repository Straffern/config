{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "xurl";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "xdevplatform";
    repo = "xurl";
    tag = "v${version}";
    hash = "sha256-eGZtwKFUMmkDmZ4+KQz4rPgprsXpRhkB8UbRZrl+41U=";
  };

  vendorHash = "sha256-sYGm/Yrcu+i+EsjcJfZcCrp3tvWLxo8cte5YnC0fEbI=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/xdevplatform/xurl/version.Version=v${version}"
  ];

  # Upstream api/client_test.go hard-codes the development User-Agent while
  # release builds identify themselves as v${version}; skip only that stale test.
  checkFlags = [
    "-skip"
    "TestBuildRequest"
  ];

  postInstall = ''
    install -Dm0644 SKILL.md $out/share/xurl/SKILL.md
    cat >> $out/share/xurl/SKILL.md <<'EOF'

    ## Hermes safety requirements

    - Before any state-changing action (including posting, replying, liking, following, blocking, muting, messaging, or uploading media), ask the user for explicit confirmation immediately before running the command.
    - Never read, print, parse, summarize, upload, or send `~/.xurl` or any copy of it to the model context.
    - For public read operations with this service's app-only bearer, explicitly select app auth (`xurl read POST_ID --auth app`, `xurl search "QUERY" --auth app`, `xurl user USERNAME --auth app`, `xurl posts USERNAME --auth app`, or `xurl --auth app /2/...`); without it xurl prefers any stored OAuth2 token before falling back to the app-only bearer.
    - Never print tokens, credentials, or secret files; never use commands or flags that expose them.
    EOF
  '';

  meta = {
    description = "CLI tool for making authenticated requests to the X API";
    homepage = "https://github.com/xdevplatform/xurl";
    license = lib.licenses.mit;
    mainProgram = "xurl";
  };
}
