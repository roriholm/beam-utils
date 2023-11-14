{ lib, beamUtils, ... }:
let
  pname = "demo";
  version = "0.1.0";
  src = ./demo;
in
beamUtils.buildMixRelease {
  inherit pname version src;

  mixFodDeps = beamUtils.fetchMixDeps {
    pname = "${pname}-mix-deps";
    inherit version src;
    hash = "sha256-xYV4+C5UTpNmVs7AHz7cz83+ddhrHC4+wcpvkGyypi4=";
  };

  removeCookie = false;
  enableDebug = false;
}
