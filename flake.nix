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
          name = "flake-outputs";
          script = ''
            let system = $"($nu.os-info.arch)-($nu.os-info.name | str replace macos darwin)"
            let systemInput = $"github:nix-systems/($system)"

            def flake-outputs [flake: string] {
              # TODO: Error out on 
              # warning: the flag '--override-input systems github:nix-systems/aarch64-darwin' does not match any input
              let metadata = (
                    nix flake show 
                      --json 
                      --allow-import-from-derivation
                      --no-update-lock-file
                      --override-input systems $systemInput $flake | from json
                  )
              let packages = ($metadata | get packages | get $system | columns)
              let checks = (
                    $metadata | get checks | get $system | columns |
                      each { |pkg| $"checks.($system).($pkg)" } 
                  )
              let devShells = (
                    $metadata | get devShells | get $system | columns |
                      each { |pkg| $"devShells.($system).($pkg)" } 
                  )
              $packages ++ $checks ++ $devShells
            }


            # Return all flake outputs that are buildable derivations
            #
            # Filter out only current systems (assumes use of github:nix-systems)
            def main [
              flake: string = "."  # The flake to build
              --json # Whether to return json
              ] {
              if $json {
                flake-outputs $flake | to json
              } else {
                flake-outputs $flake | str join "\n"
              }
            }
          '';
        };
      };
    };
}

