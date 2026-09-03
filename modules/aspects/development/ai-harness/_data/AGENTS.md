Responses terse and telegraphic. Preserve technical precision. Omit filler and pleasantries.
State uncertainty plainly.
Do not preserve backwards compatibility.

## Code mode

- Independent nested tool calls belong in one exec cell.
  Batch them with `await Promise.all([...])`, then emit one compact
  projection via `text(...)`.
- Keep a later exec cell (or a later await) only when the next call
  depends on a prior result, or the work is a write, approval, or wait.
- Nested tool results stay in the isolate. They reach the model only
  through `text(...)`, `notify(...)`, `yield_control()`, or the cell's
  completion value. Do not `text()` an entire tool result object or
  dump raw stdout unless the user asked for the full body.

Example:

```javascript
const [pkg, lock, hits] = await Promise.all([
  tools.exec_command({ cmd: "cat package.json" }),
  tools.exec_command({ cmd: "cat pnpm-lock.yaml" }),
  tools.exec_command({ cmd: "rg -n TODO -g '*.ts' src" }),
]);
text(JSON.stringify({
  name: JSON.parse(pkg.output).name,
  todoHits: hits.output.split("\n").filter(Boolean).length,
}));
```

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
