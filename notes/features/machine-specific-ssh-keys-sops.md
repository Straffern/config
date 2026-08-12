# Machine-specific SSH keys with SOPS

This note describes the safe contract for host-specific SSH credentials. It is
an operational guide, not a place to record recipients, public keys, private
keys, decrypted output, or secret values.

## Model

- SOPS encrypts values for the intended user and host age recipients.
- Host recipients are derived from SSH host keys with `ssh-to-age`.
- Private keys remain encrypted at rest and are materialized only at their
  declared target path with restrictive permissions.
- Deployment metadata names an explicit host and user; it does not infer keys
  from a directory name.

The current hosts are `frostmourne`, `palantir`, and `sonic`. Keep recipient
identifiers in `.sops.yaml` and encrypted files, never in this note.

## Safe workflow

1. On the target machine, obtain its SSH host key through a trusted channel and
   convert it locally:

   ```bash
   ssh-keyscan -t ed25519 <hostname> 2>/dev/null | ssh-to-age
   ```

2. Add the resulting recipient to `.sops.yaml`, then use the repository's
   normal SOPS update workflow. Review recipient changes without printing
   decrypted data.
3. Generate a machine-specific ed25519 key in a protected temporary location.
   Record only the key's purpose and target host in change metadata; do not put
   key material in documentation.
4. Add the encrypted private/public values through the SOPS editor. Configure
   the owning host entity to materialize the private key as mode `0600` and the
   public key as mode `0644`, owned by the intended user.
5. Add explicit deployment SSH options only in the deployment aspect. Confirm
   the path and user match the host entity before deployment.
6. Rotate by adding the new recipient/key, re-encrypting with SOPS, deploying,
   and removing the old recipient/key after access is confirmed.

Do not use shell history, command output, issue comments, or this note for
secrets. Never run a command that decrypts a file into logs or pipes it to
`grep`, `cat`, or an untrusted process.

## Verification without disclosure

Use status and permission checks that do not print values:

```bash
sops --config .sops.yaml updatekeys <encrypted-file>
ssh -o BatchMode=yes <user>@<hostname> true
ssh <user>@<hostname> 'stat -c "%a %U %G" ~/.ssh/id_ed25519'
```

Perform deployment checks through the explicit deploy node and keep activation
user-owned. Do not activate a host, alter SOPS data, or copy private keys as a
side effect of documentation work.

## Den integration

Host SSH/SOPS behavior belongs to the owning Den host/security aspect and uses
native NixOS/SOPS options. Alex's Home Manager configuration is integrated in
the Palantir and Sonic host entities; there are no separate user outputs.
