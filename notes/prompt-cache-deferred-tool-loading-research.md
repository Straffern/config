# Prompt cache misses from deferred tool loading

**Research date:** 2026-09-21
**Scope:** OpenAI Responses API `tool_search` / `defer_loading`, prompt caching, Codex source, and public Autolith evidence.

## Conclusions

- OpenAI documents `defer_loading: true` as a way to omit function tools from the initial request and expose them through a later `tool_search` call. The documented example sends a namespace plus `{ type: "tool_search" }`.
- OpenAI prompt caching uses an exact prompt-prefix match. Any change in the cached prefix prevents reuse after that point. Therefore, a client that changes or replays an earlier `tool_search_output` item can cause the large re-read reported by Autolith. This is expected cache behavior, not evidence of a model defect.
- OpenAI's public documentation does not state that deferred tools are cache-safe. It also does not document a special cache-preserving replay rule for `tool_search_output`.
- The public Codex source implements deferred-tool discovery locally. It builds a `ToolSearchHandler` from entries whose exposure is deferred and returns a `ToolSearchOutput`. This confirms that dynamic tool discovery and tool-search output are active protocol state, but it does not prove that the OpenAI server cache is preserved across replay.
- I found no public, indexed Autolith issue or discussion that documents this exact warning or a maintained mitigation. The warning is therefore best treated as an Autolith/provider interaction, not as a publicly documented Autolith feature or guarantee.

## Primary sources

### OpenAI: deferred tools and `tool_search`

- [Tools guide, “Deferred tool loading”](https://developers.openai.com/api/docs/guides/tools). The page states that `tool_search` is supported on `gpt-5.4` and later, shows function definitions with `defer_loading: true`, and sends `tools: [crm_namespace, { type: "tool_search" }]`. In the rendered source, the relevant example contains the exact fields `defer_loading: true` and `{ type: "tool_search" }`.
- [Responses API reference](https://developers.openai.com/api/reference/resources/responses). This is the API reference for Responses input and output items, including tool-search items. Use it as the schema authority when comparing a client replay with the server's accepted item shape.

### OpenAI: prompt caching

- [Prompt caching guide](https://developers.openai.com/api/docs/guides/prompt-caching). It documents that caching applies to the beginning of the prompt, that cache hits require an identical prefix, and that `cached_tokens` in usage reports the reused prefix. The guide also describes `prompt_cache_key` as a way to improve cache hit rates when requests share a prefix.
- [Prompt caching FAQ](https://help.openai.com/en/articles/8683710-how-can-i-use-the-reported-usage-for-the-api). OpenAI's usage guidance explains that cached input is reported separately from uncached input. The relevant operational fact is that a cache miss charges the uncached portion again.

### OpenAI Codex source

- [Codex `tool_search.rs`](https://github.com/openai/codex/blob/main/codex-rs/core/src/tools/handlers/tool_search.rs), current main branch. `ToolSearchHandlerCache::get_or_build` filters the registry with `tool.exposure.is_deferred()`, then builds or reuses a handler based on the source listing and tool sources. The handler imports and returns `ToolSearchOutput`.
- [Codex tool-search handler, raw source](https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/tools/handlers/tool_search.rs). Exact source locations in the current file include the imports near the top (`ToolSearchOutput`) and `ToolSearchHandlerCache::get_or_build`, where deferred entries are selected and the handler cache is keyed by the source listing and sources.

## Interpretation for the Autolith warning

The warning says that the provider could not reuse the previous prompt prefix. A report such as `34.6K of 41.9K ... re-read` means that only the prefix before the changed point was reusable. If Autolith loads tools dynamically, then serializes, normalizes, or replays a `tool_search_output` item differently on the next request, the prefix differs. The provider must reprocess the suffix at uncached input price.

This is especially expensive in long sessions because the changed item can be before a large transcript suffix. Deferred loading can reduce the first request size, but it adds mutable protocol state. It does not guarantee lower total input cost.

## Recommended mitigation

1. **Confirm causality.** Compare two otherwise identical turns: one with deferred loading enabled and one with all tools declared up front. Record `usage.input_tokens_details.cached_tokens` and the uncached input tokens. Do not infer cost from the warning alone.
2. **Prefer a stable prefix.** Keep tool declarations, tool order, serialized schemas, and replayed Responses items byte-for-byte stable. Do not regenerate JSON with unstable key order or IDs.
3. **Use a stable `prompt_cache_key` where applicable.** Follow the Prompt caching guide. Use the same key only for requests that share the same prefix and compatible workload; do not use it to mask different tool sets.
4. **Disable deferred loading for cost-sensitive sessions as an A/B test.** Sending all tools up front increases the initial prompt, but may avoid repeated prefix invalidation. Select the cheaper behavior from usage data.
5. **Avoid replaying provider-generated tool-search output unless required by the API contract.** If replay is required, preserve the exact accepted item representation. A client-side normalization step can itself cause a prefix change.

## Limits of the evidence

The public sources establish exact-prefix cache behavior and the deferred-tool protocol. They do not establish that every `tool_search_output` replay causes a miss, nor do they expose the provider's cache key. The causal explanation is strong when misses begin after dynamic tool loading or replay, but an Autolith prompt mutation, model/developer message change, tool ordering change, or other prefix change can produce the same warning.
