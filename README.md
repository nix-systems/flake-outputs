# nix-ci
WIP: Useful Nix CI workflows for projects that use [nix-systems](https://github.com/nix-systems/nix-systems).

## Usage

```sh
# Get all buildable flake outputs
OUTS=$(nix run github:srid/nix-ci flake drv-outputs github:srid/haskell-template)

# Build them
for OUT in $OUTS; do
  nix build $OUT 
done
```
