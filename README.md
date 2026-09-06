# Personal Nix packages

Packages missing from nixpkgs that I want to install with Nix.

| Package | Version | Upstream |
| --- | --- | --- |
| `maki` | 0.5.1 | [maki.sh](https://maki.sh/) |
| `iroh-doctor` | 0.101.0 | [n0-computer/iroh-doctor](https://github.com/n0-computer/iroh-doctor) |

There is deliberately no default package. Select the package you want:

```console
nix profile install github:Dzejkop/nix#maki
nix profile install github:Dzejkop/nix#iroh-doctor
```

You can also run a package without installing it:

```console
nix run github:Dzejkop/nix#maki
nix run github:Dzejkop/nix#iroh-doctor -- --help
```

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
        packages = [ pkgs.maki pkgs.iroh-doctor ];
      };
    };
}
```

The packages are then available as `pkgs.maki` and `pkgs.iroh-doctor`.

Both packages use upstream's official Linux and macOS release binaries for x86-64 and ARM64, pinned to their published SHA-256 digests. Intel macOS flake outputs use `nixpkgs-26.05-darwin`, the final nixpkgs release supporting that platform.
