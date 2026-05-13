# Specrew Versioning

Specrew currently ships as an alpha and uses feature-counted versions.

## Canonical Source

- `.specrew\config.yml` is the authoritative source for the active version.
- `README.md`, `CHANGELOG.md`, and release tags should mirror that value.

## Feature Releases

- New shipped features advance the baseline as `0.NN.0`.
- `NN` is the zero-padded shipped feature ordinal.
- Example: Feature 015 corresponds to version `0.15.0`.

## Hotfix Releases

- Hotfixes against an already shipped feature baseline use `0.NN.M`.
- `M` starts at `1` and increments for each additive fix on that same feature
  baseline.
- Hotfixes do not claim a new feature ordinal.

## Release Bookkeeping

For each shipped release baseline:

1. Update `.specrew\config.yml`.
2. Add or update the matching `CHANGELOG.md` entry.
3. Create an annotated `v0.NN.0` or `v0.NN.M` tag at the correct ship point.
4. Keep `README.md` concise and point readers here for the durable policy.

## Historical Tags

Retroactive tags are documentary bookkeeping only. They should anchor the
historical ship point, never rewrite an existing tag, and never imply that
later work belonged to the earlier release.
