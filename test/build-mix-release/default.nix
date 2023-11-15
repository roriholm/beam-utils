{ beamUtils, ... }:
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
    hash = "sha256-5rVnKLy5tiDfsawtmwhnHdhgnM95jHpVcQCiD7GHkM8=";
  };

  removeCookie = false;
  enableDebug = false;
}
