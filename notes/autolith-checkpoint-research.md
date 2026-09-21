# Autolith checkpoint and rollback research

**Research date:** 2026-09-21  
**Version inspected:** Autolith 0.50.2 installed source and release notes.  
**Sources:** Official Autolith repository and its first-party release notes only.

## Conclusion

Autolith documents and implements `/checkpoint`, `/generations`, and `/rollback`.
The documented workflow is short, not a wizard:

1. Run `/checkpoint`.
2. Autolith saves an exact live-heap image and restarts. The launcher probes the saved image before it selects it and reopens the session.
3. Run `/generations` to list generations available for recovery.
4. Run `/rollback [ID]` to select a retained generation for the next recovery start. Without an ID, the command opens a picker. If the list is empty, the picker reports `No retained generations exist.`

The official sources do not describe a separate guided, step-by-step checkpoint workflow. `/rollback` has a guided picker only when no ID is supplied. The commands do not manage private image commits.

## Primary sources

### Release notes

- [Autolith 0.50.1](https://github.com/lambda-symbolics/autolith/blob/v0.50.1/docs/releases/v0.50.1.md#fullscreen-terminal) says that Autolith saves exact live-heap checkpoints through a supervised save and restart. It says checkpointing restarts the active process, then the launcher probes the saved image before selecting it and reopening the session.
- [Autolith 0.25.1](https://github.com/lambda-symbolics/autolith/blob/v0.25.1/docs/releases/v0.25.1.md) says retained images are stored and probed through `sbcl-generations`, with exact provenance, credential clearing, and inherited-worker detachment.
- [Autolith 0.16.2](https://github.com/lambda-symbolics/autolith/blob/v0.16.2/docs/releases/v0.16.2.md#revision-safe-recovery) says automatic crash recovery uses retained generations from the current Git revision. It also says deliberate cross-revision recovery is available through `/rollback`, manual recovery, and explicit `--generation` selection.
- [Autolith 0.50.0](https://github.com/lambda-symbolics/autolith/blob/v0.50.0/docs/releases/v0.50.0.md) documents `autolith resume --pristine` as a rescue session that skips private mutation replay and executable user initialization. This is separate from generation rollback.

### First-party command source

The [v0.50.2 command implementation](https://github.com/lambda-symbolics/autolith/blob/v0.50.2/src/application/commands.lisp) is the direct behavior specification:

- [`application-checkpoint`](https://github.com/lambda-symbolics/autolith/blob/v0.50.2/src/application/commands.lisp#L1897-L1921) creates a generation. On restartable platforms it schedules a restart and reports that the exact heap checkpoint is scheduled. Otherwise it reports that publication is in progress.
- [`/checkpoint` and `/generations`](https://github.com/lambda-symbolics/autolith/blob/v0.50.2/src/application/commands.lisp#L2556-L2580) define `/checkpoint` as “save a retained live generation” and `/generations` as “list retained generations.” The tips say that `/checkpoint` saves the current live state and `/generations` shows live generations available for recovery.
- [`/rollback`](https://github.com/lambda-symbolics/autolith/blob/v0.50.2/src/application/commands.lisp#L2582-L2603) accepts an optional ID. Without an ID, interactive mode calls the generation picker with the title `select a generation for recovery`, usage `Usage: /rollback ID`, and empty notice `No retained generations exist.` With an ID, it requests rollback for that generation.

## What these terms mean in the source

```text
/checkpoint
    -> create and publish a retained live-heap generation

/generations
    -> list retained generations that can be used for recovery

/rollback [ID]
    -> select one retained generation for the next recovery start

private image commit
    -> separate durable Autolith code/settings state
    -> not selected or managed by these three commands
```

The source uses “retained generation” and “exact heap checkpoint.” It does not define “private image commit” in the checkpoint command itself. The private-image terminology belongs to the separate self-modification and durable-mutation system.

## Operational guidance supported by the sources

```text
Before risky runtime work:
    /checkpoint
    wait for restart to complete
    /generations
    confirm that the new generation is listed

To recover:
    /rollback
    choose a listed generation
    allow the next recovery start to load it

For a base-code rescue session, not a generation rollback:
    autolith resume --pristine
```

This guidance combines the command contracts and release-note behavior. The sources do not promise generation names, a checkpoint confirmation wizard, or a confirmation prompt before rollback.
