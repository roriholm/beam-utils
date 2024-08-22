{
  description = "Utils for BEAM";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: { beamUtils = prev.callPackage ./src { }; };
    in
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          test-buildMixRelease = pkgs.callPackage ./test/build-mix-release { };
        };
      }
    ))
    // {
      overlays.default = overlay;
    };
}
