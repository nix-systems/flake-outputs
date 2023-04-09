{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nuenv.url = "github:DeterminateSystems/nuenv";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = { pkgs, lib, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.nuenv.overlays.nuenv ];
        };
        packages.default = pkgs.nuenv.mkScript {
          name = "nix-ci";
          script = ''
            def main [] {
              echo WIP
            }

            # NOTE: "args" cannot accept flags (like -L), unfortunately
            # See https://github.com/nushell/nushell/issues/7758
            def "main flake check" [...args] {
              # TODO: Don't hardcode system
              nix flake check --allow-import-from-derivation --override-input systems github:nix-systems/aarch64-darwin $args
            }
          '';
        };
      };
    };
}

