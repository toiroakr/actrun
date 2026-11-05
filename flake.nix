{
  description = "actrun – Run GitHub Actions locally";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    moon-registry = {
      url = "git+https://mooncakes.io/git/index";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      moonPlatformFor = pkgs:
        (pkgs.mkMoonPlatform.override {
          fetchurl = args: pkgs.fetchurl (args // {
            url = pkgs.lib.replaceStrings
              [ "https://moonbitlang-mooncakes.s3.us-west-2.amazonaws.com" ]
              [ "https://download.mooncakes.io" ]
              args.url;
          });
        }) { version = "latest"; };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = {
        overlays.default = _final: prev: {
          actrun = prev.callPackage ./package.nix {
            moonRegistryIndex = inputs.moon-registry;
            moonPlatform = moonPlatformFor prev;
          };
        };
      };

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.moonbit-overlay.overlays.default
              (_final: prev: {
                moonPlatform = moonPlatformFor prev;
              })
            ];
            config.allowBroken = true;
          };

          actrun = pkgs.callPackage ./package.nix {
            moonRegistryIndex = inputs.moon-registry;
          };

          moonHome = pkgs.moonPlatform.bundleWithRegistry {
            cachedRegistry = pkgs.moonPlatform.buildCachedRegistry {
              moonModJson = ./nix/moon.mod.json;
              registryIndexSrc = inputs.moon-registry;
            };
          };
        in
        {
          packages = {
            default = actrun;
            inherit actrun;
          };

          apps = {
            default = {
              type = "app";
              program = "${actrun}/bin/actrun";
            };
            actrun = {
              type = "app";
              program = "${actrun}/bin/actrun";
            };
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = [
              moonHome
              pkgs.git
              pkgs.just
              pkgs.pnpm
              pkgs.nodejs
            ];
            env.MOON_HOME = "${moonHome}";
          };
        };
    };
}
