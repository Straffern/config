# Voxtype Soniox feature warning at `69221e30`

## Finding

The “Soniox was built without `--features soniox`” report is stale at locked upstream revision [`69221e30e2ebbf3b70fa49ce74cfb45a74bc4325`](https://github.com/peteonrails/voxtype/commit/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325). Soniox is compiled into every binary at that revision. The warning is an independent preflight check; it does not prevent the runtime factory from constructing `SonioxTranscriber`.

## What changed from `167c99e4`

At prior revision [`167c99e4fc92a0c8a5520b1e360be1b82f71d2da`](https://github.com/peteonrails/voxtype/commit/167c99e4fc92a0c8a5520b1e360be1b82f71d2da):

- `tokio-tungstenite`, `futures-util`, and `reqwest` were optional dependencies, and Cargo feature `soniox` enabled them ([old `Cargo.toml`](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/Cargo.toml#L38-L45), [feature declaration](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/Cargo.toml#L287-L289)).
- Both `pub mod soniox` and the successful `create_transcriber` arm were guarded by `#[cfg(feature = "soniox")]`; the inverse arm returned `Soniox engine requested but voxtype was not compiled with --features soniox` ([old `src/transcribe/mod.rs`](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/src/transcribe/mod.rs#L16-L20), [old factory branches](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/src/transcribe/mod.rs#L285-L300)).
- Upstream `flake.nix` did not put `soniox` in `onnxCpuFeatures`, `onnxCudaFeatures`, `onnxMigraphxFeatures`, or the default package’s empty feature list ([old feature lists](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/flake.nix#L42-L75), [old package construction](https://github.com/peteonrails/voxtype/blob/167c99e4fc92a0c8a5520b1e360be1b82f71d2da/flake.nix#L118-L137)). A downstream `features = [ "soniox" ]` override therefore mattered for that revision.

At `69221e30`:

- The three dependencies are non-optional, and the `soniox` Cargo feature no longer exists; `Cargo.toml` explicitly says Soniox is unconditional ([locked `Cargo.toml` dependencies](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/Cargo.toml#L38-L45), [locked feature commentary](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/Cargo.toml#L286-L294)).
- `pub mod soniox` and `TranscriptionEngine::Soniox` in `create_transcriber` are unconditional. The factory requires a `[soniox]` section, then calls `soniox::SonioxTranscriber::new(cfg.clone())` ([locked module declaration](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/transcribe/mod.rs#L16-L21), [locked factory arm](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/transcribe/mod.rs#L281-L291)).
- The Nix feature lists remain free of `soniox`, now correctly: there is no feature to enable, and all packages inherit the unconditional dependencies ([locked `flake.nix` feature lists](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/flake.nix#L42-L75), [`buildFeatures = features`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/flake.nix#L118-L137)). Removing a downstream `soniox` feature override is therefore the correct repository change.

## Exact stale emitter and condition

The root defect is [`src/setup/variant_check.rs::required_feature`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/setup/variant_check.rs#L61-L70). It still returns `None` only for `Whisper` and `Some(engine.name())` for every other engine. For `TranscriptionEngine::Soniox`, it therefore returns `Some("soniox")` even though that Cargo feature was deleted.

[`detect_mismatch`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/setup/variant_check.rs#L72-L111) emits a mismatch when:

1. configured engine is Soniox;
2. `required_feature(Soniox)` yields `"soniox"`; and
3. `inventory.compiled_features` does not contain `"soniox"`.

Condition 3 is unavoidable in the locked source: [`src/setup/binary.rs::compiled_features`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/setup/binary.rs#L686-L747) intentionally enumerates optional Cargo features only, and has no Soniox entry.

The daemon call path is [`Daemon::warn_on_variant_mismatch`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/daemon.rs#L2482-L2527), invoked at the start of `Daemon::run` before transcriber creation. It logs `Variant mismatch at daemon startup: …` and sends a desktop notification. Package installs format the body as:

> `<active binary> was built without --features soniox. Run sudo voxtype setup onnx --enable …`

Source installs format it as:

> `This source build was compiled without --features soniox. Rebuild voxtype with that feature to enable the soniox engine.`

Those messages are stale for Soniox only. This path returns after warning; it does not mutate configuration or abort startup.

The same bad predicate feeds the persistent TUI banner: [`App::detect_variant_mismatch`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/tui/app.rs#L388-L399) calls `detect_mismatch`, while [`render_variant_mismatch_banner`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/tui/mod.rs#L500-L555) renders `engine = soniox but … was built without --features soniox`.

There are two further stale TUI-only availability checks in [`EngineState::refresh_binary_match`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/tui/engine.rs#L435-L457) and [`installed_engine_choices`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/tui/engine.rs#L895-L951): source builds treat only Whisper as unconditional, and the chooser’s installed/compiled engine tables omit Soniox. These can show `Source build: rebuild voxtype with the corresponding Cargo feature for this engine` or omit Soniox from cycling, despite the engine being present.

No relevant locked-revision source string literally says `Soniox is not included`. The closest compile-availability strings are the daemon/TUI messages above and generic [`ConfigSetError::FeatureNotCompiled`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/config_set.rs#L21-L40), which says an engine `is not compiled into this binary`. That CLI validator no longer rejects Soniox: [`engine_feature_compiled`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/config_set.rs#L55-L84) explicitly returns `true` for both Whisper and Soniox.

## Can Soniox initialize?

Yes. Compile availability and runtime initialization are separate here:

- `TranscriptionEngine` includes Soniox without a feature gate, so TOML/CLI parsing accepts `engine = "soniox"` ([`src/config/engines/mod.rs`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/config/engines/mod.rs#L19-L64)).
- `load_config` loads the normal config and may layer `SONIOX_API_KEY` into `config.soniox`; there is no feature validation ([`src/config/load.rs`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/config/load.rs#L1-L42), [Soniox environment handling](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/config/load.rs#L181-L188)).
- The unconditional factory arm initializes Soniox when `[soniox]` exists. `SonioxTranscriber::new` then requires an API key from config or `SONIOX_API_KEY`, loads optional terms, and returns the transcriber ([`src/transcribe/soniox.rs::new`](https://github.com/peteonrails/voxtype/blob/69221e30e2ebbf3b70fa49ce74cfb45a74bc4325/src/transcribe/soniox.rs#L139-L193)).

Real runtime failures remain possible for missing `[soniox]`, missing API key, invalid `terms_file`, network/TLS, or Soniox API errors. None means “not compiled.” The warning preflight does not prove which executable a service runs or whether a newly built system generation is active; those are deployment questions outside this upstream source trace.

## Local confirmation

The active Home Manager service uses `/nix/store/dvff1f02fzdnndw0ca72jl32rp6ys5i5-voxtype-onnx-migraphx-wrapped-0.7.5/bin/voxtype`, whose inner executable is built from locked revision `69221e30`. Its Cargo feature list correctly omits the deleted `soniox` feature.

The August 26 service startup log confirms the false-positive sequence:

1. `Variant mismatch ... compiled without --features soniox`
2. `Loading transcription model: stt-rt-v5`
3. `Soniox backend configured: mode=realtime, model=stt-rt-v5, streaming=true`
4. `Model loaded, ready for voice input`

The service remained active. This proves the notification came from preflight bookkeeping, while the same process successfully constructed the Soniox backend. No API key or other secret was included in this inspection.

## Minimal correction

No downstream Nix feature override should be restored at `69221e30`; `--features soniox` names a deleted feature.

The minimum upstream fix for the reported daemon notification is:

```rust
pub fn required_feature(engine: TranscriptionEngine) -> Option<&'static str> {
    match engine {
        TranscriptionEngine::Whisper | TranscriptionEngine::Soniox => None,
        other => Some(other.name()),
    }
}
```

Update the adjacent regression test so Soniox, like Whisper, must return `None`. To remove all stale CLI/TUI availability behavior, also make `EngineState::refresh_binary_match` treat `"soniox"` as unconditional and insert Soniox unconditionally in `installed_engine_choices`. `config_set::engine_feature_compiled` already has the correct rule. This is an upstream bookkeeping correction, not a packaging change and not a Soniox factory change.
