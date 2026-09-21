# OpenCode V2 web-search provider comparison

**Research date:** 2026-09-21  
**Scope:** Octen, TinyFish, OpenCode-native Exa, Firecrawl, Parallel, and Tavily, plus OpenCode hosted Websearch. Sources are official documentation, source code, policies, and first-party benchmark reports.

## Recommendation

For a personal coding agent, use this order:

1. **Best default: OpenCode hosted Websearch.** It has the least setup, uses the native `websearch` tool, costs $0.01 per successful search, returns up to eight results, and has documented zero data retention. It needs an OpenCode Console workspace and balance.
2. **Best value fallback: TinyFish MCP.** Search and rendered-page Fetch are free within generous personal-use limits. Its remote MCP server uses OAuth and adds both tools. Use it when hosted search misses a source, when a page needs JavaScript rendering, or when the hosted balance is unavailable.
3. **Best quality escalation: Parallel.** Use native Parallel or its OpenCode plugin for hard, multi-hop research. Parallel publishes the strongest detailed agent benchmark among these vendors, but Parallel ran the evaluation itself.

If cost matters more than privacy and simplicity, reverse the first two: use TinyFish first and hosted Websearch as the fallback. If raw search latency matters most, add Octen MCP: Octen states a 62 ms P50, but this is a vendor measurement and MCP adds another integration path.

Do not configure several overlapping MCP search servers by default. They add tool-selection ambiguity and operational surface. OpenCode's native `"random"` provider mode is a useful availability fallback among Exa, Firecrawl, Parallel, and Tavily: it keeps one provider for the session and retries another only after HTTP 429. It is not a quality router.

## What OpenCode V2 actually integrates

OpenCode V2 natively supports provider IDs `exa`, `firecrawl`, `parallel`, and `tavily`. Configure `websearch.provider`, connect the provider through `/connect`, or supply its documented environment variable. `"random"` handles only rate-limit failover. Hosted Websearch arrives through an OpenCode Console workspace and needs neither a provider key nor `websearch.provider`.[OpenCode Websearch](https://opencode.ai/v2/docs/websearch/) [Hosted Websearch](https://opencode.ai/v2/docs/console/websearch/)

Octen and TinyFish are **not native V2 websearch providers**. Connect them as remote MCP servers. OpenCode V2 stores servers under `mcp.servers`, uses OAuth by default, and can source headers from environment variables.[OpenCode MCP servers](https://opencode.ai/v2/docs/mcp-servers/) TinyFish documents the direct OpenCode command `opencode mcp add tinyfish --url https://agent.tinyfish.ai/mcp`.[TinyFish MCP](https://docs.tinyfish.ai/mcp-integration/index.md) Octen exposes `https://mcp.octen.ai/mcp` and requires an `x-api-key` header, so its key should come from an environment variable rather than the config file.[Octen MCP](https://docs.octen.ai/integrations/octen-mcp-server.md)

The native tool gives the model one consistent search interface. A provider's broader API features do not become native OpenCode tools merely because that provider supports them. Provider plugins or MCP can expose fetch, crawl, deep research, and other tools. For example, Parallel's official OpenCode plugin adds separate search and fetch tools, while Tavily's plugin drives its CLI and adds search, extract, map, crawl, and research.[Parallel OpenCode plugin](https://docs.parallel.ai/integrations/opencode-plugin.md) [Tavily OpenCode plugin](https://docs.tavily.com/documentation/integrations/opencode.md)

The tracked `opencode.jsonc` in this repository currently configures only Nix formatting. It does not select web search or declare an MCP server. The Home Manager aspect enables OpenCode and persists `.config/opencode`, but it does not configure a provider. No secret values were inspected.

## Comparison

Prices are self-serve list prices on the research date. “Vendor claim” means that the vendor measured or asserted the result. Public benchmark datasets do not make a vendor-run evaluation independent.

| Option | OpenCode V2 path | Search and reading capability | Published latency | Free use and paid price | Limits | Privacy and retention | Operations |
|---|---|---|---|---|---|---|---|
| **Hosted Websearch** | Native, workspace-managed | Public-web search, up to eight results with source links | Not published | No free tier stated; **$0.01 per successful search**; failed or rate-limited calls are free | Not published | **Zero data retention** for query and result contents | Lowest: enable once in Console and `/connect` |
| **Exa** | Native (`exa`, `EXA_API_KEY`) | Ranked semantic search; Exa API also supports highlights, full text, filters, synthesis, and deep modes | Standard example reports 1.324 s; deep modes are about 4–40 s. These are vendor examples or estimates, not a service-level benchmark | $20 introductory credit, then **$10 monthly**; Search **$7/1k** calls; Deep **$12–15/1k** | 10 QPS Search; 5 QPS deep | SOC 2 Type II; ZDR only on Enterprise for Search, Contents, and Agent; standard retention period is not stated in the cited docs | Low natively; separate API/MCP needed for full Exa surface |
| **Firecrawl** | Native (`firecrawl`, `FIRECRAWL_API_KEY`) | Search with highlights; full-page scrape, news, images, PDF, research, and a coding-specific Developer Index exist in the API | No general search figure. Vendor scrape benchmark reports 3.387 s P95 | **1,000 credits/month** = 500 ten-result searches; Hobby $19 monthly or $16/month annual for 2,500 searches; Search uses 2 credits/10 results | Free Search 10 RPM and 2 concurrent browsers; Hobby 100 RPM and 5 browsers | Policy permits caching/indexing and says PII is retained until written deletion; end-to-end search ZDR is Enterprise-only | Low natively; richer search/scrape needs plugin, MCP, or API |
| **Parallel** | Native (`parallel`, `PARALLEL_API_KEY`); official plugin adds fetch | Search modes return ranked URLs and compressed excerpts; separate Extract, Responses, Task, FindAll, and Monitor APIs | **~200 ms Turbo, ~700 ms Fast, ~1 s Basic, ~3 s Advanced**; vendor-stated | Up to $80 at signup plus **$5 monthly**; Search **$1–5/1k** ten-result calls | 600 Search RPM | No model training on customer data; encrypted in US data centers; ZDR is Enterprise-only | Low natively; low-medium with official plugin |
| **Tavily** | Native (`tavily`, `TAVILY_API_KEY`); official plugin adds full suite | Search plus separate Extract, Map, Crawl, and Research APIs | No current first-party search latency commitment found | **1,000 credits/month**; basic search 1 credit, advanced 2; PAYG **$0.008/credit** | Development 100 RPM; Production 1,000 RPM; production needs PAYG or paid plan | May use query data to improve responses and may send it to third-party search indexes; retention lasts while needed, while the account exists, or until valid deletion | Low natively; medium with CLI-backed plugin |
| **Octen** | Remote MCP or custom integration | Search, broad concurrent subqueries, extract, images, and video through MCP; strong date, domain, language, and content controls | **62 ms P50** search, vendor-stated | **$5 signup credit**; currently **$1/1k** Search calls; Extract $1/1k URLs | Free 10 QPS; Base 20 QPS after adding credits; Extract 100 RPM | Says customer data is not used for training and deletion is available on request; ZDR is Enterprise-only; standard retention period is not stated | Medium: MCP plus API-key header and another tool namespace |
| **TinyFish** | Remote MCP with OAuth | Structured live search, rendered-page Fetch, browser sessions, and web automation | Vendor eval: **556 ms P50 search** and 1.47 s average Search+Fetch; Browser cold start under 250 ms is another vendor claim | **Search and Fetch free**; new accounts get $8 wallet credit; Agent $0.016/step; Browser $0.002/min | Search 30 RPM and 500/hour; Fetch 150 URLs/min and 1,000/day | General policy retains data as long as necessary and allows service improvement; no self-serve ZDR commitment found | Medium: one OAuth MCP, but it exposes a large tool set including browser automation |

Pricing, limits, and capability sources: [Exa pricing and limits](https://exa.ai/docs/admin/pricing) [Exa billing](https://exa.ai/docs/admin/billing) [Firecrawl pricing](https://www.firecrawl.dev/pricing) [Firecrawl limits](https://docs.firecrawl.dev/rate-limits) [Parallel pricing](https://www.parallel.ai/pricing) [Parallel limits](https://docs.parallel.ai/getting-started/rate-limits) [Tavily credits](https://docs.tavily.com/documentation/api-credits) [Tavily limits](https://docs.tavily.com/documentation/rate-limits) [Octen pricing](https://octen.ai/pricing) [Octen limits](https://docs.octen.ai/resources/rate-limits.md) [TinyFish pricing](https://www.tinyfish.ai/pricing).

Privacy sources: [Exa ZDR](https://exa.ai/docs/admin/security/zero-data-retention.md) [Firecrawl privacy](https://www.firecrawl.dev/privacy-policy) [Firecrawl search ZDR](https://docs.firecrawl.dev/features/search.md#zero-data-retention-zdr) [Parallel FAQ](https://docs.parallel.ai/resources/faqs.md) [Tavily privacy](https://www.tavily.com/privacy) [Octen security](https://docs.octen.ai/resources/security-&-compliance.md) [TinyFish privacy](https://www.tinyfish.ai/privacy-policy).

## Quality evidence

There is no neutral, current, apples-to-apples evaluation covering all seven options through their actual OpenCode V2 integrations. The available evidence is useful for forming hypotheses, not declaring a universal winner:

- **Octen vendor claim:** 95.2% on SimpleQA and 55.8% on FreshQA Strict, ahead of Exa Instant, Parallel Turbo, and Tavily Ultra-fast. The public page gives scores but not enough harness detail to reproduce the comparison.[Octen product page](https://octen.ai/)
- **Parallel vendor evaluation:** on vendor-run September 2026 agent evaluations, Parallel modes score 91–97% on a 100-question SimpleQA Verified sample and 32–74% on a 50-question BrowseComp sample. The page states models, samples, dates, cost treatment, and that an LLM graded answers, which makes it the best-documented first-party comparison found here.[Parallel benchmarks](https://parallel.ai/benchmarks)
- **TinyFish vendor evaluation:** reports 49.2% for first-result evidence on SimpleQA and 86.8% for end-to-end Search+Fetch, tied with Parallel. It also reports the cross-provider P50 latency figures used above. TinyFish ran these tests.[TinyFish benchmarks](https://www.tinyfish.ai/benchmarks)
- **Firecrawl vendor evaluation:** its coding-specific Developer Retrieval Benchmark covers 1,179 tasks and reports 63.1% Recall@10 for Firecrawl, 57.7% for Parallel, and 53.7% for Exa. This is relevant to coding agents, but it evaluates Firecrawl's Developer Index, not necessarily OpenCode's native default Firecrawl request.[Firecrawl benchmarks](https://www.firecrawl.dev/benchmarks)
- **Exa and Tavily:** no current first-party cross-provider report with enough methodology was found. Their scores above come from competitors' runs and should not be treated as proof against them.
- **Hosted Websearch:** OpenCode does not disclose its underlying provider or publish a quality benchmark. Its advantages are integration, billing, and privacy, not demonstrated leaderboard superiority.

## Decision by priority

- **Fastest published search:** Octen MCP. The 62 ms P50 is a vendor claim, and end-to-end OpenCode latency will be higher. Parallel Turbo is the fastest native-provider figure at about 200 ms.
- **Best demonstrated quality:** unresolved. Parallel has the clearest vendor methodology for multi-step agent work. Firecrawl has the most coding-specific evaluation. Octen reports the highest single-search scores but gives less methodology.
- **Best value:** TinyFish, because Search and Fetch remain free at a zero wallet balance. Among native providers, Parallel's $1/1k low-latency mode is cheapest at list price, but OpenCode does not document which paid mode its native adapter selects.
- **Best privacy:** hosted Websearch, because zero data retention is documented at the self-serve price. The other explicit ZDR offerings are Enterprise features.
- **Lowest operational complexity:** hosted Websearch, followed by one native bring-your-own-key provider. TinyFish and Octen require MCP, and provider plugins create separate tools rather than replacing the native path cleanly.

## Suggested fallback policy

1. Run the normal query through hosted Websearch.
2. If results are weak or page text is missing, use TinyFish `search`, then `fetch_content` only for the selected URLs.
3. For a hard multi-hop question, use Parallel's fetch-enabled plugin or research APIs deliberately. Do not pay deep-research latency for routine lookups.
4. For coding questions, test Firecrawl's Developer Index when ordinary search misses a repository, pull request, issue, or documentation page.
5. Never place API keys in `opencode.jsonc`. Use OAuth where available or OpenCode V2 environment substitution for MCP headers.

This policy uses different providers for distinct failure modes. It avoids sending every query to multiple vendors, which would increase latency, cost, data exposure, and duplicate context.

## Evidence limits

All latency numbers in this report are vendor-stated or vendor-measured. Network location, cache state, result count, live fetching, and search mode materially affect them. Pricing and product surfaces changed during 2026 and can change again. Recheck the linked pricing, limits, and OpenCode V2 Websearch pages before applying configuration.
