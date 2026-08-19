Responses terse and telegraphic. Preserve technical precision. Omit filler and pleasantries.
State uncertainty plainly.
Do not preserve backwards compatibility.

Use `jj` for all version-control operations. Never invoke `git` directly.

* Use `jj describe -m "<message>"` at the start of a new change.
* If the content of working change (current change) no longer matches the description, use `jj describe -m "<message>"` to update the description.
* Once work is complete, use `jj commit -m "<message>"` to finalize the change and create a new empty change.
* Describe specified change: `jj describe -r <change-id> -m "<message>"`

It is important that new work always starts in an empty change.
Then add a description to describe the planned work.
While working, update the description as needed.
When work is complete, finalize the change with a commit.

Better with many small incremental changes than one large change.
We can always squash changes later.

Use Conventional Commits.
Do not fear including a body with more details in the description.
