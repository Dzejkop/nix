# Personal Nix packages

Packages missing from nixpkgs that I want to install with Nix.

| Package | Version | Upstream |
| --- | --- | --- |
| `maki` | 0.5.3 | [maki.sh](https://maki.sh/) |
| `iroh-doctor` | 0.101.0 | [n0-computer/iroh-doctor](https://github.com/n0-computer/iroh-doctor) |
| `opencode` | 1.18.30 | [anomalyco/opencode](https://github.com/anomalyco/opencode) |
| `opencode-desktop` | 1.18.30 | [opencode.ai](https://opencode.ai/) |
| `pi-coding-agent` | 0.85.1 | [earendil-works/pi](https://github.com/earendil-works/pi) |
| `deepseek-harness` | 0.1.5-rc.2 | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) |
| `prime-agent` | 0.9.4 | [PrimeIntellect-ai/prime-agent](https://github.com/PrimeIntellect-ai/prime-agent) |

There is deliberately no default package. Select the package you want:

```console
nix profile install github:Dzejkop/nix#maki
nix profile install github:Dzejkop/nix#iroh-doctor
nix profile install github:Dzejkop/nix#opencode
nix profile install github:Dzejkop/nix#opencode-desktop
nix profile install github:Dzejkop/nix#pi-coding-agent
nix profile install github:Dzejkop/nix#deepseek-harness
nix profile install github:Dzejkop/nix#prime-agent
```

You can also run a package without installing it:

```console
nix run github:Dzejkop/nix#maki
nix run github:Dzejkop/nix#opencode
nix run github:Dzejkop/nix#pi-coding-agent -- --version
nix run github:Dzejkop/nix#deepseek-harness -- --version
nix run github:Dzejkop/nix#prime-agent -- --version
nix run github:Dzejkop/nix#iroh-doctor -- --help
```

## Platform notes

- `opencode` and `opencode-desktop` use upstream's official release binaries
  for all four supported platforms. The desktop build is upstream's BETA app.
- `pi-coding-agent` uses upstream's official release binaries and installs the
  `pi` command.
- `deepseek-harness` installs the CLI from the published `@deepseek-ai/dsh` npm
  package; its dependency tree is pinned by a vendored lockfile.
- `prime-agent` is built from source and is not available on `x86_64-darwin`.
- `maki` and `iroh-doctor` use upstream's official Linux and macOS release
  binaries. Intel macOS flake outputs use `nixpkgs-26.05-darwin`, the final
  nixpkgs release supporting that platform.

All downloaded sources are pinned to their published SHA-256 digests.

## Updating packages

Updating is agent-driven. The procedure — version sources, hashing artifacts
without cross-compilation, the `deepseek-harness` npm lockfile, and
verification — lives in
[`.agents/skills/update/SKILL.md`](.agents/skills/update/SKILL.md). Ask the
agent to update the packages and it follows that skill, keeping the version
table above in sync.

## Use as a nixpkgs overlay

Add this flake as an input:

```nix
{
  inputs.extra-packages.url = "github:Dzejkop/nix";

  outputs = { nixpkgs, extra-packages, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ extra-packages.overlays.default ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.maki pkgs.iroh-doctor pkgs.opencode ];
      };
    };
}
```

The packages are then available as `pkgs.maki`, `pkgs.iroh-doctor`,
`pkgs.opencode`, `pkgs.opencode-desktop`, `pkgs.pi-coding-agent`,
`pkgs.deepseek-harness` and `pkgs.prime-agent`. Note that `pkgs.opencode`,
`pkgs.opencode-desktop` and `pkgs.pi-coding-agent` replace the nixpkgs
versions.
