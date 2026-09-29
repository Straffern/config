Responses terse and telegraphic. Preserve technical precision. Omit filler and pleasantries.
State uncertainty plainly.
Do not preserve backwards compatibility.
Follow YAGNI principles, and prefer one-liner solutions.

Use `jj` for all version-control operations. Never invoke `git` directly.

* Use `jj describe -m "<message>"` at the start of a new change.
* If the content of working change (current change) no longer matches the description, use `jj describe -m "<message>"` to update the description.
* Once work is complete, use `jj commit -m "<message>"` to finalize the change and create a new empty change.
* Describe specified change: `jj describe -r <change-id> -m "<message>"`
* Push a new or existing bookmark with `jj git push -b <bookmark>`; it tracks new bookmarks itself. Never pass `--allow-new`; this jj rejects it.
* Scope destructive revsets (`abandon`, `rebase -s`, `squash`) to your own stack, never `all()` or `visible_heads()`. Other jj workspaces share the repo.
* Never delete `.git/*.lock` or `.jj` lock files; a running jj process holds them. Wait and retry.
* Give each file-editing agent its own jj workspace, managed with `ji`, never raw `jj workspace add`. Create: `ji new <bookmark> -r 'trunk()' -m "<message>"` (makes `../<repo>.<bookmark>` and the bookmark). List: `ji ls`. Remove when done: `ji close --source <repo>.<bookmark> --method detach --delete-files` (keeps the commits). Workspaces share one operation log, so parallel agents in one workspace make its working copy stale.
* Colocated jj repos can hold tens of thousands of `refs/jj/*` refs. Never run `git log --all` or `git branch -a --contains`; search the trunk (`git log origin/main -S <text>`) or a jj revset.
* Run a command on every commit of a stack with `jj run`, never a `jj new`/`jj edit` loop. Example, test each commit below `@`:
  ```bash
  jj --ignore-working-copy run --ignore-changes -r 'trunk()..@-' -- \
    env MIX_ENV=test MIX_TEST_PARTITION=90 sh -c 'mix deps.get >/dev/null && mix test'
  ```
  It checks each commit out into `.jj/run/`, not into your working copy. It creates zero jj operations, doesn't make sibling workspaces stale, keeps gitignored build dirs (e.g. `_build`) between commits so builds are incremental, and stops at the first failing revision. Never add `--ignore-errors`, because then it always exits 0.

It is important that new work always starts in an empty change.
Then add a description to describe the planned work.
While working, update the description as needed.
When work is complete, finalize the change with a commit.

Better with many small incremental changes than one large change.
We can always squash changes later.

Use Conventional Commits.
Do not fear including a body with more details in the description.
