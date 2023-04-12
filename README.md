# flake-outputs
Get buildable outputs of a flake, for projects that use [nix-systems](https://github.com/nix-systems/nix-systems).

## Usage

```sh
# Get all buildable flake outputs
OUTS=$(nix run github:nix-systems/flake-outputs github:srid/haskell-template)

for OUT in $OUTS
do
  # Build them
  nix build --no-link .#"$OUT"
  # Push to cachix
  nix build --no-link --print-out-paths .#"$OUT" | cachix push mycache
done
```

## Rationale

This is useful in CI[^eg] to automate building of all outputs, regardless of IFD or use of multi-systems.

[^eg]: Jenkins, for example: https://github.com/juspay/jenkins-nix-ci/issues/12
