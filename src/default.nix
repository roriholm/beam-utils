{ pkgs, lib, ... }:
let
  # Emulate https://github.com/NixOS/nixpkgs/blob/04ba0883815d54efa12dba5b9fea7834b9962cf3/pkgs/development/beam-modules/default.nix#L16
  callPackage = lib.callPackageWith (pkgs // pkgs.beamPackages);
in
{
  fetchMixDeps = callPackage ./fetch-mix-deps.nix { };
  buildMixRelease = callPackage ./build-mix-release.nix { };
}
