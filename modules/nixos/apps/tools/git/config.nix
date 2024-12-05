{ sshKeyPath, name, email, safe-dirs }:
let
  safeDirectoriesConfig = builtins.concatStringsSep "\n"
    (map (dir: "  directory = ${dir}") safe-dirs);
in ''
  [user]
  	name = ${name}
  	email = ${email}
      signingkey = ${sshKeyPath}
  [pull]
  	rebase = true
  [init]
  	defaultBranch = main
  [rerere]
    enabled = true
  [filter "lfs"]
  	process = git-lfs filter-process
  	required = true
  	clean = git-lfs clean -- %f
  	smudge = git-lfs smudge -- %f
  [gpg]
    format = ssh
  [commit]
    gpgsign = true
  [alias]
    lg1 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all
    lg2 = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n'''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'
    lg = lg1
  [safe]
  ${safeDirectoriesConfig}
''
