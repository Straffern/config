{
  den,
  inputs,
  ...
}: {
  den.aspects.development.mutable-source = {
    vmSmoke = [
      {
        name = "mutable-source";
        description = "Mutable mode survives Home Manager reactivation and returns to store sources";
        phase = "session";
        module = {
          config,
          vmSmoke,
          ...
        }: {
          systemd.tmpfiles.rules = [
            "L+ ${config.users.users.${vmSmoke.loginUser}.home}/.dotfiles - - - - ${inputs.self}"
          ];
        };
        script = ''
          assert login_user is not None, "Mutable-source smoke test requires vmSmoke.loginUser"
          nvim = f"{login_home}/.config/nvim/lua/config/lazy.lua"
          agents = f"{login_home}/.agents/AGENTS.md"
          repo_nvim = f"{login_home}/.dotfiles/modules/aspects/cli/neovim/_config/config/lazy.lua"
          repo_agents = f"{login_home}/.dotfiles/modules/aspects/development/ai-harness/_data/AGENTS.md"
          machine.succeed(user_command("mutable status | grep -Fx immutable"))
          machine.succeed(f"readlink {nvim} | grep -E '^/nix/store/'")
          machine.succeed(f"readlink {agents} | grep -E '^/nix/store/'")
          machine.succeed(user_command("mutable on"))
          machine.succeed(f'test "$(readlink "$(readlink "$(readlink {nvim})")")" = {repo_nvim}')
          machine.succeed(f'test "$(readlink "$(readlink "$(readlink {agents})")")" = {repo_agents}')
          machine.succeed(user_command("mutable status | grep -Fx mutable"))
          machine.succeed(f"systemctl restart home-manager-{login_user}.service")
          machine.succeed(f'test "$(readlink "$(readlink "$(readlink {nvim})")")" = {repo_nvim}')
          machine.succeed(f'test "$(readlink "$(readlink "$(readlink {agents})")")" = {repo_agents}')
          machine.succeed(user_command("mutable status | grep -Fx mutable"))
          machine.succeed(user_command("mutable off"))
          machine.succeed(f"readlink {nvim} | grep -E '^/nix/store/'")
          machine.succeed(f"readlink {agents} | grep -E '^/nix/store/'")
          machine.succeed(user_command("mutable status | grep -Fx immutable"))
        '';
      }
    ];
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Home Manager updates current-home after activation hooks, so only a
      # service post-start can make the mutable child the final GC root.
      systemd.services = lib.mapAttrs' (user: home:
        lib.nameValuePair "home-manager-${user}" {
          serviceConfig.ExecStartPost = pkgs.writeShellScript "restore-mutable-${user}" ''
            if [ -e "${home.xdg.stateHome}/mutable-sources/active" ] &&
               [ -x "${home.home.activationPackage}/specialisation/mutable/activate" ]; then
              "${home.home.activationPackage}/specialisation/mutable/activate" --driver-version 1
            fi
          '';
        })
      config.home-manager.users;
    };
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: let
      root = toString inputs.self;
      repoPath = path: let
        source = toString path;
      in
        if source == root || lib.hasPrefix "${root}/" source
        then builtins.unsafeDiscardStringContext ("${config.home.homeDirectory}/.dotfiles" + lib.removePrefix root source)
        else throw "mutableSources: ${source} is outside ${root}";
      mutableCommand = pkgs.writeShellApplication {
        name = "mutable";
        runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.systemd];
        text = ''
          mode="''${1:-status}"
          if [[ $# -gt 1 ]]; then
            echo "usage: mutable [on|off|status]" >&2
            exit 2
          fi
          flag="${config.xdg.stateHome}/mutable-sources/active"
          generation="$(systemctl show -P ExecStart "home-manager-$USER.service" |
            grep -oE '/nix/store/[^[:space:]]+-home-manager-generation' | head -n 1)"
          [[ -n "$generation" ]] || { echo "Home Manager generation not found" >&2; exit 1; }
          case "$mode" in
            on)
              mkdir -p "''${flag%/*}"
              touch "$flag"
              "$generation/specialisation/mutable/activate" --driver-version 1
              ;;
            off)
              rm -f "$flag"
              "$generation/activate" --driver-version 1
              ;;
            status)
              if [[ -e "$flag" ]]; then
                mode=mutable
                expected="$generation/specialisation/mutable"
              else
                mode=immutable
                expected="$generation"
              fi
              current="''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/current-home"
              if [[ "$(readlink -f "$current")" == "$(readlink -f "$expected")" ]]; then
                echo "$mode"
              else
                echo "$mode stale"
              fi
              ;;
            *)
              echo "usage: mutable [on|off|status]" >&2
              exit 2
              ;;
          esac
        '';
      };
    in {
      options.mutableSources.active = lib.mkOption {
        type = lib.types.bool;
        default = false;
        internal = true;
      };
      config = {
        lib.mutableSources = {
          source = path:
            if config.mutableSources.active
            then config.lib.file.mkOutOfStoreSymlink (repoPath path)
            else path;
          link = path: config.lib.file.mkOutOfStoreSymlink (repoPath path);
        };
        specialisation.mutable.configuration.mutableSources.active = true;
        home.packages = [mutableCommand];
      };
    };
  };
}
