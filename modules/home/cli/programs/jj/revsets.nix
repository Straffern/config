# JJ revset aliases - custom revset definitions for navigation and filtering
{
  config,
  lib,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.${namespace}.cli.programs.jj;
in {
  config = mkIf cfg.enable {
    programs.jujutsu.settings.revset-aliases = {
      # ══════════════════════════════════════════════════════════════════════════
      # Base references
      # ══════════════════════════════════════════════════════════════════════════

      "head" = "git_head()";
      "latest" = "latest(curbranch..@ ~ subject(exact:'') ~ empty())";
      "bases" = "dev";

      # trunk() by default resolves to the latest 'main'/'master' remote bookmark.
      # May require customization for repos like nixpkgs.
      "trunk()" = "latest((present(main) | present(master)) & remote_bookmarks())";

      # ══════════════════════════════════════════════════════════════════════════
      # Branch/bookmark utilities
      # ══════════════════════════════════════════════════════════════════════════

      "downstream(x,y)" = "(x::y) & y";
      "branches" = "downstream(trunk(), bookmarks())";
      "heads" = "heads(trunk()::)";
      "leafs" = "branches | heads";
      "curbranch" = "latest(branches::@- & branches)";
      "nextbranch" = "roots(@:: & branchesandheads)";

      # Bookmark utilities
      "closest_bookmark(to)" = "heads(::to & bookmarks())";
      "branch_start()" = "heads(::@ & trunk())+ & ::@";

      # Full branch from trunk to @ including descendants (ignores immutability)
      "br()" = "trunk()..@ | @::";

      # ══════════════════════════════════════════════════════════════════════════
      # Graph utilities
      # ══════════════════════════════════════════════════════════════════════════

      # Commits in either x or y, but not both
      "symdiff(x, y)" = "(x ~ y) | (y ~ x)";
      # lr(x, y) is what 'git log' calls x...y
      "lr(x, y)" = "fork_point(x | y)..(x | y)";
      "vee(x, y)" = "fork_point(x | y) | (fork_point(x | y)..(x | y))";

      # ══════════════════════════════════════════════════════════════════════════
      # Work utilities - tracking merged/unmerged work
      # ══════════════════════════════════════════════════════════════════════════

      "named()" = "bookmarks() | remote_bookmarks() | tags() | trunk()";
      "merged()" = "ancestors(named())";
      "unmerged()" = "~merged()";

      # ══════════════════════════════════════════════════════════════════════════
      # Commit authorship
      # ══════════════════════════════════════════════════════════════════════════

      "user(x)" = "author(x) | committer(x)";
      "mine()" = let
        names = [cfg.userName];
        emails = [cfg.email];
        toAuthor = x: "author(exact:${builtins.toJSON x})";
      in
        builtins.concatStringsSep " | "
        (map toAuthor (emails ++ names));

      # ══════════════════════════════════════════════════════════════════════════
      # Immutability and special branches
      # ══════════════════════════════════════════════════════════════════════════

      # By default, show the repo trunk, the remote bookmarks, and all remote tags.
      "immutable_heads()" = "present(trunk()) | remote_bookmarks() | tags()";

      # Useful to ignore in many repos. For repos like `jj` these are consistently
      # populated with auto-generated commits, so ignoring is often nice.
      "gh_pages()" = "ancestors(remote_bookmarks(exact:'gh-pages'))";

      # ══════════════════════════════════════════════════════════════════════════
      # WIP/Private commits - should never be pushed
      # ══════════════════════════════════════════════════════════════════════════

      "wip()" = "description(glob-i:'^wip:*')";
      "private()" = "description(regex:'^[xX]+:') | description(glob:'private:*')";
      "blacklist()" = "wip() | private()";

      # ══════════════════════════════════════════════════════════════════════════
      # Stack utilities
      # ══════════════════════════════════════════════════════════════════════════

      # stack(x, n) is the set of mutable commits reachable from 'x', with 'n' parents.
      # 'n' is often useful to customize the display and return set for certain operations.
      # 'x' can be used to target the set of 'roots' to traverse, e.g. @ is the current stack.
      "stack()" = "ancestors(reachable(@, mutable()), 2)";
      "stack(x)" = "ancestors(reachable(x, mutable()), 2)";
      "stack(x, n)" = "ancestors(reachable(x, mutable()), n)";

      # ══════════════════════════════════════════════════════════════════════════
      # Open work - current set of "open" works
      # ══════════════════════════════════════════════════════════════════════════

      # Given the set of commits not in trunk, that are written by me,
      # calculate the given stack() for each of those commits.
      # n = 1, meaning that nothing from `trunk()` is included,
      # so all resulting commits are mutable by definition.
      "open()" = "stack(trunk().. & mine(), 1)";

      # The set of 'ready()' commits - open commits but nothing blacklisted or their children.
      # Often used with gerrit: `jj gerrit send -r 'ready()' --dry-run`
      "ready()" = "open() ~ blacklist()::";

      # Find the latest megamerge. Mostly useful in combination with other aliases.
      # Assumes there's only one megamerge on your current path to the root.
      "megamerge()" = "reachable(stack(), merges())";

      # ══════════════════════════════════════════════════════════════════════════
      # Time-based revsets
      # ══════════════════════════════════════════════════════════════════════════

      "mine_today()" = "mine() & author_date(after:'today 00:00:00')";
      "recent()" = ''committer_date(after:"1 month ago")'';
      "stale(days)" = "mine() & ~::trunk() & ~last_modified(after: days ++ ' days ago')";

      # ══════════════════════════════════════════════════════════════════════════
      # Conflict & resolution
      # ══════════════════════════════════════════════════════════════════════════

      "fixable()" = "conflicts() & mine()";
      "orphans" = "mutable() ~ ::bookmarks()";

      # ══════════════════════════════════════════════════════════════════════════
      # Push-ready detection (complements ready())
      # ══════════════════════════════════════════════════════════════════════════

      "pushable()" = "mine() & ~empty() & ~description(exact:'') & remote_bookmarks()..";
      "unpushable()" = "mine() & remote_bookmarks() & ::@";

      # ══════════════════════════════════════════════════════════════════════════
      # File & impact analysis
      # ══════════════════════════════════════════════════════════════════════════

      "impacts(path)" = "files(path)";
      "find_todo()" = "diff_contains('TODO')";

      # ══════════════════════════════════════════════════════════════════════════
      # Worklog aliases - composable components for worklog revset
      # ══════════════════════════════════════════════════════════════════════════

      # Trunk head only
      "worklog_trunk()" = "heads(trunk())";
      # All mutable commits without descriptions (shows full un-described portion of stacks)
      "worklog_empty_stack()" = ''mutable() & (description(exact:"") | blacklist())'';
      # Mutable stack heads that have descriptions
      "worklog_heads()" = ''heads(mutable() ~ (description(exact:"") | blacklist()))'';
      # Where stacks meet trunk (connection points)
      "worklog_connections()" = "parents(roots(mutable())) & ::trunk()";
      # Recent immutable heads not on trunk
      "worklog_recent_immutable()" = "latest(heads(immutable_heads()) ~ ::trunk(), 10)";

      # Full worklog revset: trunk + empty stack commits + described heads + connections + recent immutable
      "worklog()" = "worklog_trunk() | worklog_empty_stack() | worklog_heads() | worklog_connections() | worklog_recent_immutable()";
    };
  };
}
