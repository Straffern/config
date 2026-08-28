# Jujutsu v0.44 native flow research

## Scope, method, and version

This report asks whether Jujutsu can natively run the repository's “flow”
workflow: maintain several arm changes below one integration merge, keep an empty
working-copy child above it, update and publish the arms, and eventually remove
the integration state safely. It deliberately separates **command capability**
(what `jj` can express) from **workflow ergonomics** (what it remembers,
validates, and makes safe by default).

The baseline is **Jujutsu 0.44.0, released 2026-08-05**. The evidence was checked
against the `v0.44.0` changelog, command sources, and official documentation; the
local audit was made against the paths and line ranges linked below. The command
inventory follows the v0.44 command enum and excludes feature-gated `bench` and
the hidden `debug` family; `metaedit` is included because it is visible.
([version](https://github.com/jj-vcs/jj/blob/v0.44.0/Cargo.toml#L7-L8),
[changelog](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L21-L156),
[command enum](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/mod.rs#L99-L157))

Recommendations and classifications are analysis. Commands and semantics are
cited to v0.44 primary sources. The two megamerge recipes discussed in Jujutsu
Discussions are identified as community provenance, not shipped product.

## What changed in v0.44

The headline is stabilized Git tag fetch, tracking, and push. Fetch now imports
remote tags as `name@remote` and automatically tracks same-named local tags; an
existing repository's first post-upgrade fetch re-fetches tags to initialize
that state. Git's `tagOpt` is ignored, clone's
`--fetch-tags=all|none|included` is replaced by repeatable `--tag=PATTERN`, and
`git push --all` now includes every tag as well as every bookmark.
([changelog](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L21-L58))

The other breaking changes are template type changes
(`WorkspaceRef.root()` to `Option<FsPath>`, `RepoPath.absolute()` to `FsPath`,
and config-list `path` to `Option<FsPath>`), `file search` printing matched
lines unless `--name-only` is requested, and duplicate non-repeatable CLI
arguments becoming last-wins while repeatable arguments still accumulate.
There are no deprecations in this release.
([changelog](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L42-L62))

New features are:

- `merge_point(x)`, the root common descendant(s) of its arguments—not a named
  integration object; `workspace list` roots; template `try()`; and
  `diff.stat.max-bar-width`.
- `run` oldest-first ordering plus `--passthrough`, `--ignore-changes`, and
  `--ignore-errors`; `file search --line-number`.
- `git push --allow-conflicts`; `tag track`/`tag untrack`; reusable
  `builtin_log()`; and interactive `absorb -i`/`--tool`.

([new-feature ledger](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L60-L112),
[`merge_point`](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/revsets.md#L352-L357),
[`absorb` flags](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/absorb.rs#L35-L83))

The fixes cover recursive alias fallback, Git temporary-file cleanup, Git HEAD
after an immutable working copy, prompt creation of a new working-copy revision
when the current one becomes immutable, invalid-UTF-8 path handling, copied
repositories with an empty repo config directory, merge rename/copy reporting,
`run` on conflicted commits, oversized short-ID requests, and colocated
`git import`/`export` becoming no-ops by default. The last behavior can still be
forced with `--ignore-working-copy`.
([fixed bugs](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L114-L156),
[`git import`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/import.rs#L24-L50),
[`git export`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/export.rs#L23-L45))

For flow specifically, v0.44 adds useful primitives—interactive absorb,
`merge_point()`, conflict-permitting push, and visible workspace roots—but no
first-class megamerge, arm registry, safe-close operation, or flow-aware push.
The release contains no flow-relevant change to `new`, `rebase`, `parallelize`,
`arrange`, `simplify-parents`, or bookmark advance.
([changelog](https://github.com/jj-vcs/jj/blob/v0.44.0/CHANGELOG.md#L21-L156))

## Exhaustive visible top-level command inventory

This is the shipped top-level surface, grouped by purpose. Parenthesized names
are visible aliases, not additional commands. Membership comes from the v0.44
command enum; the descriptions summarize the corresponding command modules.
([command enum](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/mod.rs#L99-L157))

### Create, navigate, and inspect revisions

- `new` — create an empty change; multiple parents create a merge.
- `commit`, `describe`, `metaedit` — finish the working-copy change and start a
  child, edit descriptions, or rewrite metadata. `metaedit` may update change
  IDs, authors, timestamps, and messages.
- `edit`, `next`, `prev` — select or navigate the working-copy revision.
- `status`, `log`, `show`, `diff`, `interdiff`, `evolog`
  (`evolution-log`) — inspect work, graph, content, differences, and rewrite
  history.
- `root`, `version`, `help` — print the workspace root, version, or help.

([`new`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/new.rs#L40-L51),
[`metaedit`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/metaedit.rs),
[command sources](https://github.com/jj-vcs/jj/tree/v0.44.0/cli/src/commands))

### Rewrite the graph or content

- `abandon`, `duplicate`, `rebase`, `restore`, `revert` — discard identity,
  copy revisions, move revisions, restore content, or create inverse changes.
- `absorb`, `diffedit`, `resolve`, `split`, `squash` — redistribute or edit
  hunks and resolve recorded conflicts.
- `arrange`, `parallelize`, `simplify-parents` — interactively rearrange a
  connected set, make selected revisions siblings, or remove redundant parent
  edges.
- `fix`, `run` — run configured tools or a command over revisions, rewriting
  results unless the selected mode says otherwise.

([`rebase`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/rebase.rs#L48-L73),
[`simplify-parents`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/simplify_parents.rs#L13-L21),
[`parallelize`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/parallelize.rs#L32-L56),
[`arrange`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/arrange.rs#L73-L79))

### References, remotes, and publication

- `bookmark` (`b`) — advance, create, delete, forget, list, move, rename, set,
  track, or untrack bookmarks.
- `tag` — delete, list, set, track, or untrack lightweight tags.
- `git` — clone, configure colocation, import/export, fetch, initialize, push,
  manage remotes, and print the backing Git root.
- `gerrit` — upload revision stacks to Gerrit.
- `sign`, `unsign` — add or remove commit signatures.

Bookmarks are named pointers that follow rewritten revisions; remote positions
are last-seen records, not editable flow metadata.
([bookmark model](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/bookmarks.md#L1-L29),
[bookmark update behavior](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/bookmarks.md#L154-L177),
[`git push`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L86-L227))

### Repository, working-copy, and support operations

- `workspace` — add, forget, list, rename, locate, or repair extra working
  copies.
- `sparse` — edit, list, reset, or set materialized paths.
- `file` — annotate, chmod, list, search, show, track, or untrack files.
- `operation` (`op`) — abandon, diff, integrate, log, restore, revert, or show
  operation-log state.
- `undo`, `redo` — reverse or reapply repository operations.
- `config` — edit, garbage-collect, get, list, locate, set, or unset layered
  configuration.
- `bisect` — run a binary search over a revision range.
- `util` — backend-name, completion, config-schema, exec, garbage collection,
  man-page installation, Markdown help, and snapshot utilities.

([workspace model](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/workspace/mod.rs#L41-L59),
[operation log](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/operation-log.md#L5-L21),
[command sources](https://github.com/jj-vcs/jj/tree/v0.44.0/cli/src/commands))

## Flow requirements

A complete flow has twelve lifecycle requirements:

1. create an integration merge from named arms;
2. identify that merge unambiguously later;
3. keep a persistent, editable WIP child rather than edit the merge itself;
4. distribute selected WIP hunks into existing arms;
5. stage a new arm between trunk and the integration merge;
6. replace one advanced parent without recreating the merge;
7. fetch and retrunk mutable work;
8. remove redundant parent edges without losing intended membership;
9. inspect topology, conflicts, refs, and workspace state;
10. publish exactly the intended bookmarks/tags;
11. close only when WIP is empty and control state is unpublished; and
12. coexist across workspaces and, ideally, multiple independent flows.

Jujutsu directly supplies most graph transformations. It does **not** persist
“these bookmark names are the arms of this integration,” a canonical flow ID,
an empty-WIP invariant, or a safe publish/close policy. Its operation view stores
heads, bookmarks, tags, remotes, Git refs, Git HEAD, and workspace-to-commit
pointers—there is no bundle or flow field.
([operation view](https://github.com/jj-vcs/jj/blob/v0.44.0/lib/src/op_store.rs#L249-L263),
[operation-log contents](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/operation-log.md#L5-L21))

## Raw native-only recipe

Assume arm bookmarks `feat`, `docs`, and `fix`; integration merge `M`; and an
empty WIP child at `@`. Replace symbolic `M` below with the merge's change ID or
an exact description selector.

### Open and identify

```console
jj new feat docs fix
jj describe -m "[integration merge]"
jj new
jj log -r 'description(exact:"[integration merge]")'
```

`jj new` with multiple revisions creates a merge. The description is merely a
convention; `heads(merges() & ::@)` is another recipe and can be ambiguous with
multiple or nested merges. `merge_point(feat|docs|fix)` finds graph join roots,
not semantic identity. Keep work in the empty child; do not `jj edit M`.
([`new`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/new.rs#L40-L51),
[`merge_point`](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/revsets.md#L352-L357))

### Absorb and add arms

```console
# Scope flow absorption to every mutable ancestor of the arm refs. This excludes
# the control merge M while allowing absorption below the arm tips.
jj absorb -t 'ancestors(feat | docs | fix) & mutable()'
jj absorb -i -t 'ancestors(feat | docs | fix) & mutable()'
# For one explicit destination when blame is ambiguous:
jj squash --from @ --into feat -i --keep-emptied

# Turn a finished WIP revision W into another arm of M:
jj rebase -r W --insert-after trunk() --insert-before M
jj bookmark create newarm -r W
```

`absorb` only considers destinations that are ancestors of its source. For this
flow, target `ancestors(<arm refs>) & mutable()`: naming only the arm tips is too
narrow, while `parents(@)` selects the control merge `M` when `@` is its WIP
child. The default `mutable()` is also broader than the registered arms.
Ambiguous hunks remain in the source, and a fully absorbed undescribed source
can be abandoned. The stable staging primitive is `rebase -A/-B`; `squash
-A/-B` is explicitly experimental.
([`absorb`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/absorb.rs#L35-L69),
[`rebase` insertion](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/rebase.rs#L48-L73),
[`squash` experimental insertion](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/squash.rs#L79-L144))

### Replace a parent and retrunk

```console
# Capture the exact old edge while feat still names it.
OLD=$(jj log --no-graph -r 'exactly(M- & feat, 1)' -T 'commit_id ++ "\n"')
jj git fetch
jj rebase -s M -o "M- ~ $OLD" -o feat@origin
jj simplify-parents -r M

jj rebase -s 'roots(trunk()..) & mutable()' -o trunk() --simplify-parents
```

Rebase the existing merge change; recreating it loses its change identity and
requires conflict resolution again. Record the old direct parent before
fetching: fetch updates the last-seen `feat@origin`, and changes to a tracked
remote bookmark propagate to local `feat`. A rewritten or non-fast-forward
remote target can therefore replace `feat` or conflict it rather than preserving
the old edge. The saved full commit ID keeps that identity stable across fetch;
`M- ~ $OLD` retains every other direct parent, and the second `-o` adds the new
remote target. If `feat@origin` no longer resolves to one revision, stop instead
of guessing a replacement.
([remote and tracked bookmark semantics](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/bookmarks.md#L24-L49),
[`rebase` destinations](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/rebase.rs#L306-L365))

`--simplify-parents` drops any parent already reachable through another, so it
may remove an explicitly desired trunk edge when an arm contains trunk.
Immutable foreign arms do not move with the mutable retrunk recipe.
([`simplify-parents`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/simplify_parents.rs#L13-L21))

### Inspect and publish exactly

```console
jj log -r '::@ | bookmarks()'
jj status
jj op show -p
jj git push -b feat -b docs -b fix
```

Use explicit bookmark names. Default push selects tracking bookmarks **and
tracked tags** whose targets are in `remote_bookmarks(remote=<remote>)..@`, not
“the arms of M.” `git push -r 'feat|docs|fix'` is valid only when the target
commits already carry the intended bookmarks/tags; it creates no refs.
`--named feat=<tip>` is not a retargeting mechanism: `--named` and `--change`
require new bookmark names. Move an existing bookmark first, then push it with
`-b`. Descendants beyond a selected ref are not pushed.
([push selection](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L86-L227),
[`--named` rejects existing names](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L405-L520),
[error and prescribed fix](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L1110-L1117))

Never run unnamed `jj bookmark advance` while `@` is the WIP/megamerge path: its
default source is `heads(::@ & bookmarks())`, so all closest arm bookmarks may
advance to `@`. Supplying explicit names changes the selection, but still only
allows forward moves.
([bookmark advance defaults](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/bookmark/advance.rs#L38-L54))

### Close and use workspaces

```console
# Manually verify @ has no content and M is not published, then:
jj git push -b feat -b docs -b fix
jj abandon @
jj abandon M
jj new trunk()

jj workspace add ../other -r M
jj workspace list
jj workspace update-stale
```

There is no native close validator. Abandon reparents descendants; abandoning M
under nonempty WIP can leave that work on an accidental multi-parent commit.
A workspace has its own working-copy commit and sparse patterns but shares the
repository view and bookmarks. `workspace add -r M` creates a new working-copy
child of M, not a second editor attached directly to the same commit. Rewrites
from one workspace can stale another; operation restore also restores all
workspace commit pointers in the selected view.
([`abandon`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/abandon.rs),
[workspace model](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/workspace/mod.rs#L41-L59),
[`workspace add`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/workspace/add.rs#L48-L86),
[`op restore`](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/operation/restore.rs#L26-L45))

### Behavioral experiment

An isolated, non-colocated v0.44.0 repository with a clean `JJ_CONFIG` verified
the graph recipe end to end: scoped absorb rewrote only arm ancestors,
`rebase -r -A/-B` inserted a third arm, parent replacement preserved the
integration change ID, `simplify-parents` preserved the intended tips, and
abandoning WIP then the integration merge closed the graph. Git push and
cross-workspace effects remain source-verified rather than runtime-tested.

## Minimal-alias recipe

These aliases shorten graph mechanics but intentionally do not pretend to store
membership. They are user configuration, not v0.44 commands:

```toml
[revset-aliases]
"closest_merge(to)" = "heads(::to & merges())"
closest_merge = "exactly(closest_merge(@), 1)"

[aliases]
stage = ["rebase", "--after", "trunk()", "--before", "closest_merge", "--revision"]
restack = ["rebase", "--onto", "trunk()", "--source", "roots(trunk()..) & mutable()", "--simplify-parents"]
remerge = ["rebase", "--source", "closest_merge", "--onto"]
```

Use them as follows:

```console
jj new feat docs fix && jj describe -m "[integration merge]" && jj new
jj absorb -i -t 'ancestors(feat | docs | fix) & mutable()'
jj stage W
OLD=$(jj log --no-graph -r 'exactly(closest_merge- & feat, 1)' -T 'commit_id ++ "\n"')
jj git fetch
jj remerge "closest_merge- ~ $OLD | feat@origin"
jj simplify-parents -r closest_merge
jj restack
jj git push -b feat -b docs -b fix
```

The `exactly(..., 1)` guard rejects ambiguous nearest merges, but the user still
supplies arm names and replacement parents. An automatically computed
`mm_updates` set based on all local/remote bookmarks is not equivalent to stored
membership and can add unrelated remote heads.

**Community provenance:** the labeled octopus merge plus WIP-child pattern is
associated with Chris Krycho; `closest_merge`/`stack`/`stage`/`restack` recipes
with Benjamin Corbrey; Jujutsu maintainers and users discuss preserving the
merge change by rebasing it onto a replacement parent set. These are community
workflows, not shipped commands or supported flow metadata.
([Jujutsu Discussion #7588](https://github.com/jj-vcs/jj/discussions/7588),
[Jujutsu Discussion #9550](https://github.com/jj-vcs/jj/discussions/9550))

## Capability and lifecycle matrix

| Requirement | Class | Native mechanism | Manual or missing fact |
|---|---|---|---|
| Create merge | native-direct | `jj new A B C` | No named flow object |
| Identify | native-recipe | exact description, guarded nearest merge, or `merge_point(arms)` | Canonical ID and arm membership |
| Persistent WIP | native-direct | empty `jj new` child; extra workspace | Empty-child invariant |
| Absorb into arms | native-direct | `absorb -t 'ancestors(<arm refs>) & mutable()'`; `squash --into` | Exact arm refs; ambiguous hunks |
| Add new arm | native-recipe | `rebase -r W -A trunk() -B M` | Membership/bookmark naming |
| Replace advanced parent | native-direct | record the old parent, fetch, then `rebase -s M` with repeated `-o` | Exact pre-fetch parent identity and complete new parent set |
| Retrunk | native-direct graph / native-recipe lifecycle | fetch, then rebase mutable roots | Which foreign parents/arms belong |
| Simplify | native-direct | `simplify-parents` | Whether redundant trunk must remain explicit |
| Inspect | native-direct | log/status/show/diff/op/workspace list | No consolidated flow status |
| Publish exact refs | native-direct with known names; otherwise native-recipe | `git push -b/-t` | Exact arm bookmark/tag names |
| Close safely | missing | abandon, bookmark delete, op restore are primitives | Empty WIP, unpublished M, arms-at-tip checks |
| Coexist workspaces | native-direct | workspace add/list/forget/update-stale | No per-workspace flow registry; shared rewrites |
| Multiple named flows/bundles | missing | descriptions/bookmarks/config conventions | Durable membership and independent identity |
| `arrange`/`parallelize` | native-direct graph editing | TUI edit of a connected topology / remove in-set ancestor edges to make selected revisions siblings | Neither command records membership or supplies lifecycle policy |

## Current implementation: duplication, custom value, and defects

The local wrapper calls the synthetic `flow` bookmark “control state” and treats
its parents as work items
([`aliases.nix:289-302`](../modules/aspects/cli/jj/_config/aliases.nix#L289-L302)).
That provides the only genuinely custom concept: a stable, named entry point and
one-command add/remove/move/rebase/push UX. It does **not** preserve the names of
bookmarks that led to those parents, and most mechanics duplicate native
commands:

| Local surface | Local evidence | Native equivalent | Assessment |
|---|---|---|---|
| `flow tip` | [`aliases.nix:572-575`](../modules/aspects/cli/jj/_config/aliases.nix#L572-L575) | `jj new flow` | native-direct |
| `flow list` | [`aliases.nix:577-580`](../modules/aspects/cli/jj/_config/aliases.nix#L577-L580) | `jj log -r 'parents(flow)'` | native-direct |
| first add | [`aliases.nix:588-603`](../modules/aspects/cli/jj/_config/aliases.nix#L588-L603) | `new --no-edit`; create bookmark | native-recipe |
| later add/remove/move | [`aliases.nix:591-643`](../modules/aspects/cli/jj/_config/aliases.nix#L591-L643) | rebase M onto a parent set | native-direct graph operation |
| retrunk | [`aliases.nix:645-650`](../modules/aspects/cli/jj/_config/aliases.nix#L645-L650) | `rebase` | native-direct, but wrong scope |
| publish | [`aliases.nix:652-655`](../modules/aspects/cli/jj/_config/aliases.nix#L652-L655) | explicit `git push -b/-t` | native-direct once names are known |
| private policy | [`revsets.nix:85-87`](../modules/aspects/cli/jj/_config/revsets.nix#L85-L87), [`default.nix:241-244`](../modules/aspects/cli/jj/default.nix#L241-L244) | `git.private-commits` | native mechanism, local policy |
| `megamerge()` | [`revsets.nix:93-98`](../modules/aspects/cli/jj/_config/revsets.nix#L93-L98), [`revsets.nix:115-117`](../modules/aspects/cli/jj/_config/revsets.nix#L115-L117) | revset composition | custom selector policy |
| `sandwich` | [`aliases.nix:113-114`](../modules/aspects/cli/jj/_config/aliases.nix#L113-L114) | `rebase -r REV -A trunk() -B megamerge()` | native-direct duplication coupled to a non-singleton selector |

The audit found six defects:

1. **Final cleanup is unreachable.** The predicate intersects the flow bookmark
   with `none()` and a blank description even though creation writes
   `xxx:flow`; the wrapper deletes the bookmark but leaves the control commit
   orphaned. If the predicate were merely fixed, `abandon` would delete its
   pointing bookmark and the following explicit delete would be redundant.
   ([creation](../modules/aspects/cli/jj/_config/aliases.nix#L597-L603),
   [cleanup](../modules/aspects/cli/jj/_config/aliases.nix#L621-L629))
2. **Rebase escapes the flow.** `-s roots(DEST..flow)` includes each root and all
   descendants, potentially unrelated branches and other workspace WCs, despite
   help promising only flow-managed changes.
   ([promise](../modules/aspects/cli/jj/_config/aliases.nix#L330-L334),
   [implementation](../modules/aspects/cli/jj/_config/aliases.nix#L645-L650),
   [`-s` semantics](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/rebase.rs#L48-L73))
3. **Push help is false.** The wrapper passes a revision range; v0.44 then
   selects any existing bookmarks and tags whose targets intersect it. That can
   include unrelated refs and omits unbookmarked parents, rather than publishing
   exactly parent-tip bookmarks.
   ([promise](../modules/aspects/cli/jj/_config/aliases.nix#L336-L345),
   [implementation](../modules/aspects/cli/jj/_config/aliases.nix#L511-L529),
   [push implementation](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L1281-L1328))
4. **Control identity is unchecked.** Any ordinary local bookmark named `flow`
   enters the existing-flow path and may be rewritten with all descendants.
   ([dispatch](../modules/aspects/cli/jj/_config/aliases.nix#L591-L596))
5. **Move can become add.** The destination expression always adds `NEW`, but
   only removes `OLD` if it was a direct parent; no membership check enforces the
   promised one-for-one replacement.
   ([promise](../modules/aspects/cli/jj/_config/aliases.nix#L468-L485),
   [implementation](../modules/aspects/cli/jj/_config/aliases.nix#L636-L643))
6. **`megamerge()` is neither latest nor singleton.** It lacks `heads`,
   `latest`, or `exactly(..., 1)`, so consumers may receive several mutable
   merges.
   ([selector](../modules/aspects/cli/jj/_config/revsets.nix#L115-L117))

Conflict handling does not rescue these semantics. Jujutsu records conflicts in
commits and lets graph rewrites succeed; users later edit the conflicted commit
and resolve it. `git push --allow-conflicts` bypasses the push rejection but does
not prove the integration is resolved or safe to publish.
([conflict model](https://github.com/jj-vcs/jj/blob/v0.44.0/docs/conflicts.md#L11-L29),
[push flag](https://github.com/jj-vcs/jj/blob/v0.44.0/cli/src/commands/git/push.rs#L86-L194))

## Deletion test

Delete the wrapper mentally and ask what becomes impossible rather than merely
longer:

- Opening, listing, absorbing, staging, replacing a parent, retrunking,
  simplifying, inspecting, and explicit named publication all remain possible
  with the raw recipe.
- Multiple working copies, operation history, rollback primitives, private
  commit policy, and conflict recording remain native.
- What disappears is the **single `flow` handle**, the parent-set convention,
  concise lifecycle commands, rollback-instruction UX, and an obvious place to
  enforce policy.
- Exact arm names, semantic identity, membership validation, empty-WIP checks,
  unpublished-control checks, bounded workspace-aware rewrites, and safe close
  are not supplied by native Jujutsu—but the current wrapper does not reliably
  supply them either.

Therefore the existing implementation fails the keep test: most of its code is
native-command duplication, while its unique abstraction is not made durable or
safe.

## Recommendation

**Verdict: retire the current wrapper.** For occasional megamerges, use the raw
native recipe plus, at most, the three small graph aliases above. For frequent
use, and only when durable exact membership and guarded closure are firm
requirements, replace it with a small persisted-membership module. Do not retain
the current `tip`/`list`/`add`/`remove`/`move`/`rebase`/`push` surface.

Delete the thin `sandwich` alias
([`aliases.nix:113-114`](../modules/aspects/cli/jj/_config/aliases.nix#L113-L114))
and either delete `megamerge()` with it
([`revsets.nix:115-117`](../modules/aspects/cli/jj/_config/revsets.nix#L115-L117))
or redefine that selector as explicitly singleton.

The frequent-use module should have exactly three verbs:

1. **`flow reconcile [REF...]`** creates or updates the persisted flow identity
   and exact bookmark/tag membership, resolves those names, compares them with
   the control merge's parent set, and reports discrepancies. It must preserve
   the existing control change ID; graph repair remains an explicit native
   `jj rebase` operation.
2. **`flow status`** validates singleton control identity, resolved member refs,
   parent agreement, conflicts, empty-WIP state, publication/private state, and
   affected or stale workspaces. It may print the exact `-b`/`-t` names for
   publication.
3. **`flow close`** refuses closure unless WIP is empty, the control state is
   unpublished/private, member refs are at their intended tips, no arm is lost,
   and workspace effects are safe. It closes only the persisted membership
   record; graph teardown and recovery remain explicit native commands.

That module owns only durable identity, exact membership, reconciliation, and
closure policy. It must not wrap WIP creation; `absorb` or `squash`; staging,
parent replacement, retrunking, simplification, `arrange`, or `parallelize`;
workspace management; operation-log recovery; or Git transport. In particular,
publication remains an explicit native command such as
`jj git push -b feat -b docs -b fix`: the module may report those exact names
and block an invalid state, but must not execute or proxy push.

This is the dividing line: v0.44 supplies the graph algebra, content movement,
refs, workspaces, recovery, and transport. Occasional use needs no custom
lifecycle abstraction. Frequent use may justify only the three-verb
persisted-membership module above, not a second spelling of native commands.
