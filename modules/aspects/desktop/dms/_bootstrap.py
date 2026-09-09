"""Install writable DMS defaults and transfer the former Home Manager settings once."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
        tmp.write(data)
        temporary = Path(tmp.name)
    temporary.chmod(0o644)
    temporary.replace(path)


def bootstrap(path, source, replace_store_link=False):
    backup = Path(str(path) + ".pre-home-manager")
    if not path.exists() and not path.is_symlink() and backup.is_file():
        backup.replace(path)
    if path.is_symlink() and str(path.resolve()).startswith("/nix/store/"):
        write(path, (source if replace_store_link else path).read_bytes())
    elif not path.exists() and not path.is_symlink():
        write(path, source.read_bytes())


def key_parts(key):
    return frozenset(part.lower().replace("super", "mod") for part in key.split("+"))


def run(manifest, files_only=False):
    marker = Path(manifest["marker"])
    if marker.exists():
        return

    for target, source in manifest["files"].items():
        bootstrap(Path(target), Path(source), target in manifest["replaceStoreLinks"])

    if files_only:
        return

    settings = Path(manifest["settings"])
    defaults = json.loads(Path(manifest["files"][str(settings)]).read_text())
    current = json.loads(settings.read_text())
    write(settings, (json.dumps(defaults | current, indent=2) + "\n").encode())

    if manifest["niri"]:
        env = os.environ | {"XDG_CONFIG_HOME": manifest["configHome"]}
        dms = manifest["dms"]
        result = subprocess.run(
            [dms, "keybinds", "show", "niri"], env=env, check=True, capture_output=True, text=True
        )
        bindings = [bind for group in json.loads(result.stdout)["binds"].values() for bind in group]
        owned = {key_parts(bind["key"]) for bind in bindings if bind["source"] in ("dms", "dms-default")}
        for key, bind in manifest["keybinds"].items():
            if key_parts(key) not in owned:
                subprocess.run(
                    [dms, "keybinds", "set", "niri", key, bind["action"], "--desc", bind["description"]],
                    env=env, check=True, capture_output=True,
                )

        rules = Path(manifest["configHome"]) / "niri/dms/windowrules.kdl"
        content = rules.read_text()
        if "@id=dotfiles-cast-indicator" not in content:
            content = Path(manifest["castRule"]).read_text() + "\n" + content
        if "@id=dotfiles-shell-blur" not in content:
            content += "\n" + Path(manifest["shellRule"]).read_text()
        write(rules, content.encode())

    write(marker, b"")


if __name__ == "__main__":
    run(json.loads(Path(sys.argv[1]).read_text()), "--files-only" in sys.argv[2:])
