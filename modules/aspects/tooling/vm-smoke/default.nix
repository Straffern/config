{
  config,
  den,
  lib,
  self,
  ...
}: let
  testPasswordHash = "$y$j9T$3.a6H29WOGTHDjo2jbcpa/$./XxI/xi4EoxYOO4KkACmF0/utSiCAcxWK94.T.p6s7";

  phaseOrder = {
    boot = 0;
    greeter = 10;
    login = 20;
    session = 30;
    health = 40;
  };

  sortDescriptors = builtins.sort (a: b: let
    aPhase = phaseOrder.${a.phase};
    bPhase = phaseOrder.${b.phase};
  in
    if aPhase == bPhase
    then a.name < b.name
    else aPhase < bPhase);

  indent = text:
    lib.concatMapStringsSep "\n" (line: "    ${line}") (
      lib.splitString "\n" (lib.trim text)
    );

  pythonLiteral = value:
    if value == null
    then "None"
    else builtins.toJSON value;

  renderDescriptor = descriptor: ''
    with subtest(${builtins.toJSON descriptor.description}):
    ${indent descriptor.script}
  '';

  mkLoginModule = host: {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (host.vmSmoke) loginUser sessionCommand;
  in {
    environment.etc."vm-smoke/greetd.toml".text = ''
      [terminal]
      vt = 2
      switch = true

      [default_session]
      command = "${pkgs.greetd}/bin/agreety --cmd ${sessionCommand}"
      user = "greeter"
    '';

    users.mutableUsers = lib.mkForce false;
    users.users.${loginUser} = {
      hashedPassword = lib.mkForce testPasswordHash;
      initialHashedPassword = lib.mkForce null;
    };

    systemd.services.vm-smoke-login = {
      description = "Authenticate the VM smoke-test user on a separate greetd seat";
      conflicts = ["getty@tty2.service"];
      after = ["systemd-user-sessions.service"];
      serviceConfig = {
        ExecStart = "${pkgs.greetd}/bin/greetd --config /etc/vm-smoke/greetd.toml";
        Restart = "no";
        Type = "simple";
      };
    };
  };

  mkCheck = pkgs: name: host: configuration: let
    vm = host.vmSmoke;
    loginEnabled = vm.loginUser != null;
    hostOverrides = map (override: override.module) vm.overrides;
    descriptorModules = map (descriptor: descriptor.module) configuration.config.dotfiles.vmSmoke.descriptors;
    extraArgs = configuration.extraArgs // {inherit (host) vmSmoke;};
  in
    pkgs.testers.runNixOSTest {
      name = "vm-smoke-${name}";
      globalTimeout = vm.timeout;
      node = {
        pkgsReadOnly = false;
        # host.mainModule omits Den host-instantiation effects such as the integrated Home Manager bridge.
        specialArgs = extraArgs;
      };

      nodes.machine = {lib, ...}: {
        imports =
          configuration._module.args.modules
          ++ descriptorModules
          ++ hostOverrides
          ++ lib.optional loginEnabled (mkLoginModule host);

        virtualisation = {
          inherit (vm) cores diskSize graphics memorySize writableStoreUseTmpfs;
        };
      };

      testScript = {nodes, ...}: let
        machineConfig = nodes.machine;
        descriptors =
          builtins.filter (descriptor: lib.trim descriptor.script != "")
          (sortDescriptors machineConfig.dotfiles.vmSmoke.descriptors);
        inherit (vm) loginUser;
        loginUid =
          if loginEnabled
          then machineConfig.users.users.${loginUser}.uid
          else null;
        loginHome =
          if loginEnabled
          then machineConfig.users.users.${loginUser}.home
          else null;
        allowedKernelErrors =
          [
            "acpi PNP0A03:00: _OSC: platform retains control of PCIe features (AE_ERROR)"
            "cros_ec_lpcs: unsupported system."
          ]
          ++ vm.allowedKernelErrors;
      in ''
        start_all()
        machine.wait_for_unit(${builtins.toJSON vm.waitForUnit})

        login_user = ${pythonLiteral loginUser}
        login_uid = ${pythonLiteral loginUid}
        login_home = ${pythonLiteral loginHome}
        ${lib.optionalString loginEnabled ''
          user_prefix = (
              f"runuser -u {login_user} -- env "
              f"HOME={login_home} "
              f"USER={login_user} "
              f"LOGNAME={login_user} "
              f"PATH={login_home}/.local/state/nix/profile/bin:/run/current-system/sw/bin "
              f"XDG_CONFIG_HOME={login_home}/.config "
              f"XDG_CACHE_HOME={login_home}/.cache "
              f"XDG_DATA_HOME={login_home}/.local/share "
              f"XDG_STATE_HOME={login_home}/.local/state "
              f"XDG_RUNTIME_DIR=/run/user/{login_uid}"
          )
          def user_command(command):
              return f"{user_prefix} {command}"
        ''}

        ${lib.concatMapStringsSep "\n\n" renderDescriptor descriptors}

        with subtest("system manager has no failed units"):
            machine.succeed('test -z "$(systemctl --failed --no-legend --plain)"')

        ${lib.optionalString loginEnabled ''
          with subtest("test user manager has no failed units"):
              machine.succeed(user_command("systemctl --user is-system-running --wait | grep -Ex 'running|degraded'"))
              machine.succeed(f'test -z "$( {user_prefix} systemctl --user --failed --no-legend --plain )"')
        ''}

        with subtest("kernel emitted no unexpected errors"):
            errors = machine.succeed("journalctl --quiet -b -k -p err..alert --no-pager --output=cat").splitlines()
            allowed = ${builtins.toJSON allowedKernelErrors}
            unexpected = [line for line in errors if line not in allowed]
            assert not unexpected, f"unexpected kernel errors: {unexpected}"

        with subtest("no process dumped core"):
            machine.succeed('test -z "$(coredumpctl --no-pager --no-legend 2>/dev/null)"')

        ${lib.optionalString loginEnabled ''
          with subtest("graphical test session shuts down cleanly"):
              machine.succeed(f"loginctl terminate-user {login_user}")
              machine.wait_until_succeeds(f"test -z \"$(loginctl list-sessions --no-legend | awk '$3 == \\\"{login_user}\\\" {{ print $1 }}')\"")
              machine.wait_until_succeeds(f"! systemctl is-active --quiet user@{login_uid}.service")
              machine.succeed("systemctl stop vm-smoke-login.service")
              machine.succeed('test -z "$(systemctl --failed --no-legend --plain)"')
        ''}

        machine.shutdown()
      '';
    };
in {
  den.quirks.vmSmoke.description = "NixOS VM smoke-test descriptors";

  den.schema.host = {
    includes = [den.aspects.tooling.vm-smoke];
    imports = [
      ({
        config,
        lib,
        ...
      }: let
        overrideType = lib.types.submodule {
          options = {
            reason = lib.mkOption {
              type = lib.types.nonEmptyStr;
              description = "Why the real host configuration needs this VM-only adapter";
            };
            module = lib.mkOption {
              type = lib.types.deferredModule;
              description = "NixOS module applied only to this host's smoke-test VM";
            };
          };
        };
      in {
        options.vmSmoke = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to emit this host's baseline and aspect smoke test";
          };
          skipReason = lib.mkOption {
            type = lib.types.nullOr lib.types.nonEmptyStr;
            default = null;
            description = "Why this host cannot run its VM smoke test";
          };
          waitForUnit = lib.mkOption {
            type = lib.types.str;
            default = "multi-user.target";
          };
          loginUser = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "User authenticated with the public test password 'test'";
          };
          sessionCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Session launched after authenticating loginUser";
          };
          timeout = lib.mkOption {
            type = lib.types.ints.positive;
            default = 900;
          };
          memorySize = lib.mkOption {
            type = lib.types.ints.positive;
            default = 2048;
          };
          cores = lib.mkOption {
            type = lib.types.ints.positive;
            default = 2;
          };
          diskSize = lib.mkOption {
            type = lib.types.ints.positive;
            default = 8192;
          };
          graphics = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          writableStoreUseTmpfs = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          allowedKernelErrors = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
          overrides = lib.mkOption {
            type = lib.types.listOf overrideType;
            default = [];
          };
        };
      })
    ];
  };

  den.aspects.tooling.vm-smoke = {
    nixos = {
      config,
      lib,
      vmSmoke,
      ...
    }: let
      descriptorType = lib.types.submodule {
        options = {
          name = lib.mkOption {type = lib.types.nonEmptyStr;};
          description = lib.mkOption {type = lib.types.nonEmptyStr;};
          phase = lib.mkOption {
            type = lib.types.enum (builtins.attrNames phaseOrder);
            default = "session";
          };
          script = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
            default = {};
            description = "VM-only NixOS fixture owned by this probe's aspect";
          };
        };
      };
      names = map (descriptor: descriptor.name) config.dotfiles.vmSmoke.descriptors;
    in {
      options.dotfiles.vmSmoke.descriptors = lib.mkOption {
        type = lib.types.listOf descriptorType;
        default = [];
        internal = true;
      };

      config = {
        dotfiles.vmSmoke.descriptors = vmSmoke;
        assertions = [
          {
            assertion = builtins.length names == builtins.length (lib.unique names);
            message = "VM smoke-test descriptor names must be unique: ${lib.concatStringsSep ", " names}";
          }
          {
            assertion = lib.all (name: builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name != null) names;
            message = "VM smoke-test descriptor names must use kebab-case";
          }
        ];
      };
    };

    flake-parts = {
      pkgs,
      system,
      ...
    }: let
      hosts = config.den.hosts.${system} or {};
      enabledHosts = lib.filterAttrs (name: host:
        assert lib.assertMsg (host.vmSmoke.enable || host.vmSmoke.skipReason != null)
        "${name}: vmSmoke.skipReason is required when vmSmoke.enable is false";
        assert lib.assertMsg ((host.vmSmoke.loginUser == null) == (host.vmSmoke.sessionCommand == null))
        "${name}: vmSmoke.loginUser and vmSmoke.sessionCommand must be configured together";
          host.class == "nixos" && host.vmSmoke.enable)
      hosts;
    in {
      checks = lib.mapAttrs' (name: host:
        lib.nameValuePair "vm-smoke-${name}" (mkCheck pkgs name host self.nixosConfigurations.${name}))
      enabledHosts;
    };
  };
}
