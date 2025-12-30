<div align="center">
<h1>
<img width="96" src="./.github/assets/flake.webp"></img> <br>
  Asgaard Dotfiles
</h1>
</h2><img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="500" />
<br>
<h4>
  :warning: This config repo is constantly changing,
  Let me know if you see something that can be improved or done better :smile: .</h4>
</div>

## 💽 Usage

<details>
  <summary>Install</summary>

To install NixOS on any of my devices I use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).
You will need to be able to SSH to the target machine from where this command will be run. Load nix installer ISO if
no OS on the device. You need to copy ssh keys onto the target machine:
`mkdir -p ~/.ssh && curl https://github.com/straffern.keys > ~/.ssh/authorized_keys` in my case I can copy them from GitHub.

```bash
git clone git@github.com:straffern/.dotfiles.git ~/.dotfiles/
cd ~/.dotfiles

nix develop

nixos-anywhere --flake '.#hostname' nixos@192.168.1.8 # Replace with your IP
```

</details>

### Building

To build my config for a specific host you can do something like:

```bash
git clone git@github.com:straffern/.dotfiles.git ~/.dotfiles/
cd ~/.dotfiles

# To build system configuration
nh os switch

# To build user configuration
nh home switch
```

> [!IMPORTANT]
> **Determinate Nix Migration**: If you are switching to this configuration for the first time on a standard NixOS install, use the following flags to enable the Determinate binary cache and avoid building Nix from source:
> ```bash
> sudo nixos-rebuild switch --flake .#HOSTNAME \
>   --option extra-substituters https://install.determinate.systems \
>   --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
> ```

### Updating
```bash
# Update all flake inputs
nix flake update

# Garbage collect and optimize store
nh clean

# Deploy to remote server (Home Lab) using deploy-rs
sys deploy HOSTNAME # legacy wrapper for deploy-rs

# Build custom ISO
nix build .#nixosConfigurations.graphical.config.system.build.isoImage
```

## 🚀 Features

Some features of my config:

- **Snowfall Lib**: Structured to allow multiple **NixOS configurations**, including **desktop**, **laptop** and **homelab**
- **Suites Pattern**: Composable bundles of functionality for easy machine setup
- **Custom namespace**: All custom options live under the `asgaard` namespace
- **Stylix**: Consistent theming with **Stylix** (Catppuccin Macchiato)
- **Persistence**: Opt-in persistence through **Impermanence**
- **Disk Management**: Declarative partitioning with **Disko**
- **Secret Management**: Encrypted secrets with **sops-nix** and age
- **Environments**: Choice of **Hyprland** or **GNOME**
- **Development**: AI-integrated workflows with custom **OpenCode** shell tools and agents
- **Homelab**: Managed Kubernetes clusters with **k3s** and remote deployment via **deploy-rs**

## 🖼️ Showcase

### Desktop (Hyprland)

![terminal](./.github/assets/terminal.png)
*(Coming soon: updated screenshots)*

## Appendix

### Inspired By

- nixicle: https://github.com/hmajid2301/nixicle
- Snowfall config: https://github.com/jakehamilton/config
- My original structure: https://github.com/anotherhadi/nixy
- Neovim UI: https://github.com/NvChad/nvchad
