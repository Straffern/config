"""Run against a built HM generation: python3 _test_bootstrap.py /nix/store/...-home-manager-generation."""

import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from unittest.mock import patch


generation = Path(sys.argv[1])
activation = (generation / "activate").read_text()
bootstrap_path = re.search(r"/nix/store/[^\s]+-_bootstrap.py", activation)[0]
manifest_path = re.search(r"/nix/store/[^\s]+-dms-bootstrap.json", activation)[0]
original = json.loads(Path(manifest_path).read_text())

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("bootstrap", bootstrap_path)
bootstrap = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bootstrap)


def command(manifest, *args):
    return subprocess.run(
        args, check=True, capture_output=True, text=True,
        env=os.environ | {"XDG_CONFIG_HOME": manifest["configHome"]},
    ).stdout


def activate(manifest, **kwargs):
    # Home Manager activation does not inherit the interactive desktop PATH.
    with patch.dict(os.environ, {"PATH": "/no-programs"}):
        bootstrap.run(manifest, **kwargs)


with tempfile.TemporaryDirectory(prefix="dms-bootstrap-test-") as directory:
    for scenario in ("fresh", "existing"):
        root = Path(directory) / scenario
        config = root / ".config"
        state = root / ".local/state"
        manifest = json.loads(json.dumps(original).replace(original["configHome"], str(config)))
        original_state = str(Path(original["marker"]).parent.parent)
        manifest = json.loads(json.dumps(manifest).replace(original_state, str(state)))
        settings = Path(manifest["settings"])
        binds = config / "niri/dms/binds.kdl"
        rules = config / "niri/dms/windowrules.kdl"
        gtk = config / "gtk-3.0/settings.ini"
        autostart = config / "autostart/org.kde.kdeconnect.daemon.desktop"
        outputs = config / "niri/dms/outputs.kdl"

        if scenario == "existing":
            bootstrap.write(settings, b'{"keyboardLayouts":"dk","keyboardOptions":"","blurEnabled":false,"acProfileName":"","batteryProfileName":"1"}')
            bootstrap.write(binds, b'binds { Mod+Shift+S { spawn "true"; }; }\n')
            bootstrap.write(rules, b'// @id=user-rule @name=User rule\nwindow-rule { match app-id="^user$"; opacity 0.9; }\n')
            profile = config / "niri/dms/profiles/chosen.kdl"
            bootstrap.write(profile, b'output "eDP-1" { scale 1.25; }\n')
            outputs.symlink_to(profile)
            gtk.parent.mkdir(parents=True)
            gtk.symlink_to(manifest["files"][str(gtk)])
            autostart.parent.mkdir(parents=True)
            # A retired HM desktop stub must be replaced with a complete entry.
            autostart.symlink_to(manifest["files"][str(gtk)])
            backup = state / "DankMaterialShell/session.json.pre-home-manager"
            bootstrap.write(backup, b'{"wallpaperPath":"/chosen.png"}')

        activate(manifest, files_only=True)
        for name in ("config.kdl", "hm.kdl"):
            (config / "niri" / name).symlink_to(generation / "home-files/.config/niri" / name)
        activate(manifest)

        for target in manifest["files"]:
            path = Path(target)
            assert path.is_file(), target
            if path != outputs or scenario == "fresh":
                assert not path.is_symlink(), target
            assert os.access(path, os.W_OK), target
        prefs = json.loads(settings.read_text())
        assert prefs["keyboardLayouts"] == ("dk" if scenario == "existing" else "us,dk")
        assert prefs["keyboardOptions"] == ("" if scenario == "existing" else "grp:alts_toggle")
        assert prefs["blurEnabled"] is (scenario == "fresh")
        assert prefs["acProfileName"] == ("" if scenario == "existing" else "2")
        assert prefs["batteryProfileName"] == ("1" if scenario == "existing" else "0")
        if scenario == "existing":
            assert "user-rule" in rules.read_text()
            assert rules.read_text().index("dotfiles-cast-indicator") < rules.read_text().index("user-rule")
            assert rules.read_text().index("user-rule") < rules.read_text().index("dotfiles-shell-blur")
            assert "Exec=kdeconnectd" in autostart.read_text()
            assert outputs.is_symlink() and outputs.resolve() == profile
            assert json.loads((state / "DankMaterialShell/session.json").read_text())["wallpaperPath"] == "/chosen.png"

        dms = manifest["dms"]
        parsed = json.loads(command(manifest, dms, "keybinds", "show", "niri"))
        owned = {bootstrap.key_parts(b["key"]): b for group in parsed["binds"].values() for b in group}
        for key in manifest["keybinds"]:
            assert owned[bootstrap.key_parts(key)]["source"] in ("dms", "dms-default"), owned[bootstrap.key_parts(key)]
        if scenario == "existing":
            assert "true" in owned[bootstrap.key_parts("Mod+Shift+S")]["action"]
        command(manifest, "niri", "validate", "-c", str(config / "niri/config.kdl"))

        # Exercise the same DMS CLI used by Settings, then prove activation cannot restore the binding.
        command(manifest, dms, "keybinds", "remove", "niri", "Mod+Ctrl+Shift+F")
        command(manifest, dms, "keybinds", "set", "niri", "Mod+Ctrl+S", "spawn true")
        settings.write_text('{"keyboardLayouts":"","keyboardOptions":"","blurEnabled":false}\n')
        gtk.write_text("[Settings]\ngtk-icon-theme-name=Adwaita\n")
        rules.write_text("// User removed all rules\n")
        autostart.unlink()
        before = {p: p.read_bytes() for p in (settings, gtk, binds, rules)}
        activate(manifest, files_only=True)
        activate(manifest)
        assert all(path.read_bytes() == data for path, data in before.items())
        assert not autostart.exists(), "User-deleted autostart was restored"
        new_file = config / "hypr/dms/new-seed.lua"
        manifest["files"][str(new_file)] = manifest["files"][str(outputs)]
        activate(manifest)
        assert new_file.read_bytes() == Path(manifest["files"][str(outputs)]).read_bytes()
        assert all(path.read_bytes() == data for path, data in before.items())
        assert not autostart.exists()
        assert str(new_file) in json.loads(Path(manifest["seeded"]).read_text())
        parsed = json.loads(command(manifest, dms, "keybinds", "show", "niri"))
        assert not any(bootstrap.key_parts(b["key"]) == bootstrap.key_parts("Mod+Ctrl+Shift+F") for group in parsed["binds"].values() for b in group)
        command(manifest, "niri", "validate", "-c", str(config / "niri/config.kdl"))
        print(f"{scenario}: writable defaults, DMS edits, seed-once defaults, and repeat activation passed")
