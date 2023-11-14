{ stdenvNoCC
, lib
, cacert
, elixir
, hex
, rebar3
, git
}@inputs:

{ pname
, version
, src
, hash ? ""
, env ? "prod"
, debug ? false
, elixir ? inputs.elixir
, hex ? inputs.hex.override { inherit elixir; }
, ...
}@attrs:

stdenvNoCC.mkDerivation (attrs // {
  nativeBuildInputs = [ cacert elixir hex git ];

  LC_ALL = "en_US.UTF-8";

  # Mix environment variables
  MIX_ENV = env;
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
  MIX_DEBUG = if debug then 1 else 0;

  # Rebar3 environment variables
  DEBUG = if debug then 1 else 0;

  configurePhase = ''
    runHook preConfigure

    # Mix and Hex
    export MIX_HOME="$TEMPDIR/.mix";
    export HEX_HOME="$TEMPDIR/.hex";

    # Rebar3
    export REBAR_GLOBAL_CONFIG_DIR="$TMPDIR/.rebar3"
    export REBAR_CACHE_DIR="$TMPDIR/.rebar3.cache"

    runHook postConfigure
  '';

  dontBuild = true;

  installPhase = attrs.installPhase or ''
    runHook preInstall

    mix deps.get --only $MIX_ENV

    # 1. To make Elixir deps checking work as expected, .git should be a
    #    valid git repository. So, you can't just remove .git or the necessary
    #    files in it. More details can be found in follow links:
    #
    #    * https://github.com/elixir-lang/elixir/blob/92d46d0069906f8ed0ccc709e40e21e2acac68c1/lib/mix/lib/mix/scm/git.ex#L259
    #
    # 2. To make this derivation reproducible, remove files which are not
    #    necessary and change all the time.
    find deps \( -path '*/.git/index' -o -path '*/.git/logs' \) -exec rm -rf {} +

    cp -r --no-preserve=mode,ownership,timestamps deps $out

    runHook postInstall
  '';

  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  outputHashMode = "recursive";
} // (
  if hash != "" then { outputHashAlgo = null; outputHash = hash; }
  else { outputHashAlgo = "sha256"; outputHash = lib.fakeSha256; }
))
