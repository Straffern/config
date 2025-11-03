# Machine-Specific SSH Keys with SOPS

## Overview

This document describes the implementation of machine-specific SSH keys using SOPS for NixOS systems, enabling secure, automated SSH key management and distribution.

## Architecture

### Components
- **SOPS**: Secrets management with age encryption
- **Age**: Modern encryption tool for SOPS
- **SSH Host Keys**: Used as age recipients for host-based decryption
- **Deploy-RS**: Integration for automated deployments

### Security Model
- Each machine has unique SSH keys for authentication
- Secrets are encrypted for specific recipients (users + hosts)
- Host-based decryption enables automatic secret access
- No manual key distribution required

## Implementation Guide

### Phase 1: SOPS Configuration Setup

#### Step 1: Generate Host Age Key

Extract the target machine's SSH host key and convert to age format:

```bash
# Install required tools
nix-shell -p ssh-to-age

# Extract SSH host key and convert to age format
ssh-keyscan -t ed25519 <hostname> 2>/dev/null | ssh-to-age
```

**Example Output:**
```
age1ajyn9l0v2fv5kyhdzvkr4dxw6rm602w06sk3qnxz5d7aj67ygy0qv4drf9
```

**Technical Explanation:**
- `ssh-keyscan`: Retrieves SSH host keys from remote server
- `-t ed25519`: Specifies modern, secure key type
- `ssh-to-age`: Converts SSH public keys to age format for SOPS
- Result: Age-compatible recipient identifier for the host

#### Step 2: Update SOPS Configuration

Add the host as a recipient in `.sops.yaml`:

```yaml
keys:
  - &users:
    - &alex age1ff98yfdlxax5ymnlu9rdzermuyvg8jwq98z6h86tpj8ajlxw7upsq4k8a0
  - &host: 
    - &grug age1uzfwpjz2d29gfd93xm0qenke89s7ynl5sy635wgrchcm96et9pfq99a9ja
    - &frostmourne age1kjqhsyucjhuw6gazjrjqcuavay6pfgpr8fasltft99vzfdkjdsdsvfx4xv
    - &palantir age1ajyn9l0v2fv5kyhdzvkr4dxw6rm602w06sk3qnxz5d7aj67ygy0qv4drf9

creation_rules:
  - path_regex: secrets\.ya?ml$
    key_groups:
      - age:
          - *frostmourne
          - *palantir
          - *alex
```

Update secrets file with new recipients:
```bash
nix-shell -p sops --run "sops updatekeys secrets.yaml"
```

### Phase 2: SSH Key Generation and Storage

#### Step 3: Generate Machine-Specific SSH Keys

Create unique SSH key pair for the target machine:

```bash
# Generate passwordless ed25519 key pair
ssh-keygen -t ed25519 -f /tmp/<hostname>_ssh_key -N "" -C "<hostname>@machine-specific"

# Display public key for reference
cat /tmp/<hostname>_ssh_key.pub
```

**Example Output:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5lRDX7EEywyLxJVcvA7gVQ1PxViFUlb0CT63b0VcaV palantir@machine-specific
```

#### Step 4: Add SSH Keys to SOPS Secrets

Edit secrets.yaml to include the new SSH keys:

```bash
nix-shell -p sops --run "sops secrets.yaml"
```

Add entries before the `sops:` section:
```yaml
<hostname>_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  [Full private key content here]
  -----END OPENSSH PRIVATE KEY-----

<hostname>_ssh_public_key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5lRDX7EEywyLxJVcvA7gVQ1PxViFUlb0CT63b0VcaV <hostname>@machine-specific
```

### Phase 3: System Configuration

#### Step 5: Configure Target System SSH

Update the target system's configuration to use SOPS secrets:

```nix
# systems/x86_64-linux/<hostname>/default.nix
${namespace} = {
  user."1" = {
    name = "alex";
    # Remove old authorizedKeys, will be set via SOPS
    extraGroups = [ "wheel" ];
  };

  security.sops = enabled;
  
  # SOPS secrets for SSH keys
  sops.secrets."<hostname>_ssh_private_key" = {
    owner = "alex";
    group = "users";
    mode = "600";
    path = "/home/alex/.ssh/id_ed25519";
  };
  
  sops.secrets."<hostname>_ssh_public_key" = {
    owner = "alex";
    group = "users";
    mode = "644";
    path = "/home/alex/.ssh/id_ed25519.pub";
  };
};
```

### Phase 4: Deploy-RS Integration

#### Step 6: Update Deploy-RS Configuration

Modify deploy-rs to use the machine-specific key:

```nix
# flake.nix
deploy.nodes.<hostname> = {
  hostname = "<hostname>";
  sshUser = "alex";
  sshOpts = [ "-i" "/home/alex/.ssh/id_ed25519" ];
  profiles.system = {
    user = "root";
    path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.<hostname>;
  };
};
```

### Phase 5: Testing and Verification

#### Step 7: Testing Procedures

**Verify SOPS Decryption:**
```bash
# Test on target machine
ssh <hostname> "sops -d secrets.yaml | grep <hostname>_ssh"
```

**Test SSH Authentication:**
```bash
# Test SSH connection with new key
ssh -i ~/.ssh/<hostname>_ssh_key alex@<hostname> "echo 'SSH key works!'"
```

**Test Deploy-RS:**
```bash
# Test deployment
deploy --targets <hostname>
```

## Security Considerations

### Key Management
- Private keys are stored encrypted in SOPS secrets
- Host-based decryption using SSH host keys
- Proper file permissions enforced (600 for private, 644 for public)
- No passphrases for automated deployment compatibility

### Access Control
- Only specified recipients can decrypt secrets
- Host keys provide machine-specific access
- User keys provide administrative access
- Separation of concerns between user and host access

### Key Rotation
- Update `.sops.yaml` with new host keys
- Run `sops updatekeys secrets.yaml`
- Regenerate and re-encrypt SSH keys
- Update system configurations

## Troubleshooting

### Common Issues

**SOPS Permission Denied:**
```bash
# Check host key age conversion
ssh-keyscan -t ed25519 <hostname> | ssh-to-age

# Verify recipient in .sops.yaml
grep <hostname> .sops.yaml
```

**SSH Key Permission Issues:**
```bash
# Check file permissions on target
ssh <hostname> "ls -la ~/.ssh/"

# Verify SOPS secret paths
ssh <hostname> "ls -la /run/secrets/"
```

**Deploy-RS Connection Issues:**
```bash
# Test SSH connection manually
ssh -i /path/to/key user@hostname

# Check deploy-rs configuration
deploy --check
```

### Debug Commands

```bash
# Verify SOPS recipients
nix-shell -p sops --run "sops --decrypt secrets.yaml | head -5"

# Check SSH host key
ssh-keyscan -t ed25519 <hostname>

# Test age conversion
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5lRDX7EEywyLxJVcvA7gVQ1PxViFUlb0CT63b0VcaV" | ssh-to-age

# Verify secret deployment
ssh <hostname> "cat /home/alex/.ssh/id_ed25519.pub"
```

## Best Practices

1. **Use ed25519 keys**: Modern, secure, and performant
2. **Passwordless keys**: Required for automated deployment
3. **Proper permissions**: 600 for private keys, 644 for public keys
4. **Regular rotation**: Update keys periodically for security
5. **Documentation**: Keep records of key generation and rotation
6. **Testing**: Verify all components after changes
7. **Backup**: Maintain secure backups of SOPS configuration

## Integration with Existing Infrastructure

This approach integrates seamlessly with:
- **NixOS**: Declarative configuration management
- **Home Manager**: User-level configuration
- **Deploy-RS**: Automated deployment system
- **SOPS-Nix**: NixOS SOPS integration
- **Age**: Modern encryption system

## References

- [SOPS Documentation](https://github.com/mozilla/sops)
- [Age Encryption](https://github.com/FiloSottile/age)
- [SOPS-Nix](https://github.com/Mic92/sops-nix)
- [Deploy-RS](https://github.com/serokell/deploy-rs)
- [SSH-to-Age](https://github.com/Mic92/ssh-to-age)

---

## Implementation Status

### ✅ Completed Steps
1. **Generate Palantir Host Age Key** - `age1ajyn9l0v2fv5kyhdzvkr4dxw6rm602w06sk3qnxz5d7aj67ygy0qv4drf9`
2. **Update SOPS Configuration** - Added palantir recipient to `.sops.yaml`
3. **Generate Machine-Specific SSH Keys** - Created ed25519 key pair for palantir

### 🔄 Next Steps
4. **Add SSH Keys to SOPS Secrets** - Manual step required
5. **Configure Palantir System SSH** - Update system configuration
6. **Update Deploy-RS Configuration** - Modify deployment settings
7. **Testing and Verification** - Validate complete workflow

### 📁 Generated Files
- SSH private key: `/tmp/palantir_ssh_key`
- SSH public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5lRDX7EEywyLxJVcvA7gVQ1PxViFUlb0CT63b0VcaV palantir@machine-specific`

### 🔧 Tools Used
- `ssh-to-age` for host key conversion
- `sops` for secrets management
- `ssh-keygen` for key generation