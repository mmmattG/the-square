# Documentation

## Current sources of truth

- [../CONTEXT.md](../CONTEXT.md): canonical glossary and ubiquitous language for design sessions
- [LORE.md](LORE.md): current narrative direction and writing rules

## Removed deprecated context

Deprecated PRDs, feature lists, old conversation transcripts, and the previous `docs/UBIQUITOUS_LANGUAGE.md` glossary were removed because they polluted agent context too often. Use root [`CONTEXT.md`](../CONTEXT.md) for glossary terms and current issues for active planning.

## Design-session workflow

Future grill/design sessions should use the `grill-with-docs` structure:

1. Start with root [`CONTEXT.md`](../CONTEXT.md) as the canonical glossary.
2. Challenge new plans against the existing terms before inventing new language.
3. Update `CONTEXT.md` inline when a term stabilizes; keep it glossary-only, not a spec or implementation notebook.
4. Create `docs/adr/` lazily only when there is a durable decision that is hard to reverse, surprising without context, and the result of a real tradeoff.
5. Keep ADRs short and consistently named as `docs/adr/NNNN-short-slug.md`.
