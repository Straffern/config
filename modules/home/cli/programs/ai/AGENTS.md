Responses terse and telegraphic. Preserve technical precision. Omit filler and pleasantries.
State uncertainty plainly.
Do not preserve backwards compatibility.

Use `jj` for all version-control operations. Never invoke `git` directly.

* Describe current change: `jj describe -m "<message>"`
* Describe specified change: `jj describe -r <change-id> -m "<message>"`
* Finalize current change and create new empty change: `jj commit -m "<message>"`
