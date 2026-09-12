---
name: update
description: Update this flake's packages to their latest upstream releases and refresh pinned hashes. Use when asked to update, bump, or refresh packages here, or when an upstream release needs pinning.
---

# Updating packages

Every package lives in `packages/<name>.nix` and is wired into `flake.nix`. Versions and hashes are pinned: read them from upstream artifacts, never guess. The version table in `README.md` mirrors the package files.

Read `packages/<pkg>.nix` and take one branch:

- `src = fetchurl` on a `github.com/.../releases/download/...` URL — **release binary** (every package here; e.g. `maki`, `opencode`, `pi-coding-agent`). Follow [Release binaries](#release-binaries).

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

## Verify

For every changed package:

- Build it on the host system: `nix build .#<pkg> --no-link --print-build-logs`. The build runs each package's install check (version strings, the desktop app's plist); a stale hash or version fails here.
- Run `nix fmt flake.nix packages/*.nix` after nix edits.
- Run `nix flake check --no-build --all-systems` to catch evaluation errors on systems this host cannot build.
- `git add` new or regenerated files: flakes ignore untracked files.
- Update the package's row in the `README.md` version table.

Set `GITHUB_TOKEN` if GitHub API rate limits bite. The `x86_64-darwin` outputs use the older `nixpkgs-26.05-darwin` input; still refresh the hashes for its supported systems.
