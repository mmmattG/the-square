# The Square

This project is a mod for the game Factorio.

control.lua is reloaded on world creation
settings.lua and data.lua on game startup

Only run end-to-end (e2e) tests when explicitly asked.

changelog.txt is a user-facing changelog. Include changes that are visible to players.
Significant internal refactors may be mentioned in broad, non-technical terms when useful for
setting player expectations, but do not describe their implementation details. Do not include
routine cleanup, tests, tooling, or other internal changes.
Follow Factorio's changelog format: https://lua-api.factorio.com/latest/auxiliary/changelog-format.html

## Version and release flow

A version bump starts development for that version; it does not mark a release. Bump info.json
early when needed for migrations and testing, and allow any number of subsequent commits to
implement and validate that version.

A version is released only when an explicit release marker commit and matching annotated Git
tag exist. After all changes for a version are merged, its user-facing changelog is finalized,
and validation passes:

1. Start from a clean, up-to-date main branch.
2. Create an empty commit named exactly `Release vX.Y.Z`.
3. Create an annotated tag named `vX.Y.Z` on that commit with the message `Release vX.Y.Z`.

Do not create the release marker commit or tag merely because info.json was bumped. The tag is
the authoritative release boundary when auditing changes since a previous release.

See CONTEXT.md for a glossary of terms
