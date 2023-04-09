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

            let system = $"($nu.os-info.arch)-($nu.os-info.name | str replace macos darwin)"
            let systemInput = $"github:nix-systems/($system)"

            def "main flake check" [...args] {
              # NOTE: "args" cannot accept flags (like -L), unfortunately
              # See https://github.com/nushell/nushell/issues/7758
              nix flake check --allow-import-from-derivation --override-input systems $systemInput $args
            }

            def "main build-all" [
              flake: string = "."  # The flake to build
              --no-checks  # Don't build checks
              --no-devShells  # Don't build devShells
              ] {

              let metadata = (nix flake show --json --allow-import-from-derivation --override-input systems $systemInput $flake | from json)

              # Handle nix build failures in one place, for reporting latter.
              # TODO: This is more of a hack; can it be done better?
              let failedPackages = [ ]

              def nixBuild [pkg: string] {
                  echo $"+ nix build ($flake)#($pkg)"
                  try {
                    nix build $"($flake)#($pkg)" 
                    []
                  } catch {
                    [pkg]
                  }
              }

              let packages = ($metadata | get $"packages" | get $system | columns)
              echo $"Flake outputs these packages: ($packages)"
              let failedPackages = ($failedPackages ++ $packages | each { |pkg| nixBuild $"($pkg)" } | flatten)

              let failedPackages = ($failedPackages ++ (if (not $no_checks) {
                let checks = ($metadata | get $"checks" | get $system | columns)
                echo $"Flake outputs these checks: ($checks)"
                $checks | each { |pkg| nixBuild $"checks.($system).($pkg)" } | flatten
              } else { [] }))

              let failedPackages = ($failedPackages ++ (if (not $no_devShells) {
                let devShells = ($metadata | get $"devShells" | get $system | columns)
                echo $"Flake outputs these devShells: ($devShells)"
                $devShells | each { |pkg| nixBuild $"devShells.($system).($pkg)" } | flatten
              } else { [] }))

              if (($failedPackages | length) == 0) {
                echo "No failures"
              } else {
                echo $"Failed to build: ($failedPackages)"
                exit 2
              }
            }
          '';
        };
      };
    };
}

