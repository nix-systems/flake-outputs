# nix-ci
WIP: Useful Nix workflows for CI

## Usage

Examples,

```sh
nix run . -- flake check github:srid/haskell-template
```

## Development

```sh
nix run nixpkgs#watchexec -- -e nix nix run
```
