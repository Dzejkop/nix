---
name: update
description: Update this flake's packages to their latest upstream releases and refresh pinned hashes. Use when asked to update, bump, or refresh packages here, or when an upstream release needs pinning.
---

# Updating packages

Every package lives in `packages/<name>.nix` and is wired into `flake.nix`. Versions and hashes are pinned: read them from upstream artifacts, never guess. The version table in `README.md` mirrors the package files.

Read `packages/<pkg>.nix` and take one branch:

- `src = fetchurl` on a `github.com/.../releases/download/...` URL — **release binary** (default; e.g. `maki`, `opencode`, `pi-coding-agent`). Follow [Release binaries](#release-binaries).
- `src = fetchurl` on a `registry.npmjs.org/...` tarball — **npm package** (only `deepseek-harness`, identified by its vendored `deepseek-harness-package-lock.json`). Follow [deepseek-harness](#deepseek-harness).
- Anything else (`fetchFromGitHub`, source builds) — delegate to `nix-update` (only `prime-agent`). Follow [Source builds](#source-builds).

## Release binaries

1. Read the file: `version`, the `sources` attr (`asset`/`target` and `hash` per system), and the URL in `src`.
2. Find the newest release: `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, then strip a leading `v`.
3. For every system in `sources`, put the new version into the URL (asset names often embed it too) and hash the result:
   ```console
   nix store prefetch-file --json --hash-type sha256 <url>
   ```
   The `hash` field is the SRI string. Local Nix refuses to build a fixed-output derivation for a foreign system, so serve every system this way instead of building it cross-system.
4. Edit the file: the `version = "...";` line and each system's `hash = "...";`. Change nothing else.
5. [Verify](#verify).

`opencode-desktop` wraps its Linux `src` with `appimageTools`, which hides it from `nix eval`; the `sources` attr in the file is still the source of truth.

## deepseek-harness

The published `@deepseek-ai/dsh` package lists unpublished workspace packages (such as `@deepseek-ai/dsh-experimental-code-runtime-python`) as `devDependencies`, so npm cannot resolve a lockfile until they are stripped. The stripped lockfile is vendored as `packages/deepseek-harness-package-lock.json` and must be regenerated on every update.

1. Newest version from GitHub releases — they are all prereleases, so `releases/latest` misses them. The npm `latest` dist-tag also lags behind `next`:
   ```console
   gh api 'repos/deepseek-ai/deepseek-harness/releases?per_page=1' --jq '.[0].tag_name'
   ```
   Strip the `dsh-v` prefix.
2. Hash the tarball and edit `packages/deepseek-harness.nix` (`version`, `src.hash`):
   ```console
   nix store prefetch-file --json --hash-type sha256 \
     "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-<version>.tgz"
   ```
3. Regenerate the lockfile (needs `npm` and `jq`), then copy it into `packages/`:
   ```console
   workdir=$(mktemp -d)
   curl -fsSL "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-<version>.tgz" |
     tar -xz -C "$workdir" package/package.json
   jq 'del(.devDependencies)' "$workdir/package/package.json" > "$workdir/package.json"
   (cd "$workdir" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)
   cp "$workdir/package-lock.json" packages/deepseek-harness-package-lock.json
   ```
4. Refresh `npmDepsHash` after the lockfile is in place:
   ```console
   nix run nixpkgs#nix-update -- --flake --no-src --version=skip deepseek-harness
   ```
5. [Verify](#verify).

## Source builds

`prime-agent` builds from a `fetchFromGitHub` tag with a patch and an `npmDepsHash`. `nix-update` bumps the version and both hashes:

```console
nix run nixpkgs#nix-update -- --flake prime-agent
```

If `prime-agent-remove-uv-python-install.patch` stops applying, upstream moved the code in `packages/coding-agent/src/core/kernel/bootstrap.ts`; refresh the patch against the new source.

## Verify

For every changed package:

- Build it on the host system: `nix build .#<pkg> --no-link --print-build-logs`. The build runs each package's install check (version strings, the desktop app's plist); a stale hash or version fails here.
- Run `nix fmt flake.nix packages/*.nix` after nix edits.
- Run `nix flake check --no-build --all-systems` to catch evaluation errors on systems this host cannot build.
- `git add` new or regenerated files: flakes ignore untracked files.
- Update the package's row in the `README.md` version table.

Set `GITHUB_TOKEN` if GitHub API rate limits bite. The `x86_64-darwin` outputs use the older `nixpkgs-26.05-darwin` input, and `prime-agent` is intentionally absent there; still refresh the hashes for its supported systems.
