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

            # TODO: Don't hardcode system
            let system = "aarch64-darwin"
            let systemInput = $"github:nix-systems/($system)"

            # NOTE: "args" cannot accept flags (like -L), unfortunately
            # See https://github.com/nushell/nushell/issues/7758
            def "main flake check" [...args] {
              nix flake check --allow-import-from-derivation --override-input systems $systemInput $args
            }

            def "main build-all" [flake] {
              nix flake show --json --allow-import-from-derivation --override-input systems $systemInput $flake | 
                from json | get $"packages" | get $system | 
                columns | each { |pkg| 
                  echo $"+ nix build ($flake)#($pkg)"
                  nix build $"($flake)#($pkg)" 
                }
            }
          '';
        };
      };
    };
}

