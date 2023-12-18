{ stdenvNoCC
, lib
, glibcLocalesUtf8
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

stdenvNoCC.mkDerivation (attrs // (if stdenvNoCC.isLinux then {
  LOCALE_ARCHIVE = "${glibcLocalesUtf8}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";
} else {
  LC_ALL = "en_US.UTF-8";
}) // {
  nativeBuildInputs = [ cacert elixir hex git ];

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

    mkdir -p $out

    mix deps.get --only $MIX_ENV

    # 1. To make Elixir deps checking work as expected, .git should be a
    #    valid git repository. So, you can't just remove .git or the necessary
    #    files in it. More details can be found in follow links:
    #
    #    * https://github.com/elixir-lang/elixir/blob/92d46d0069906f8ed0ccc709e40e21e2acac68c1/lib/mix/lib/mix/scm/git.ex#L259
    #
    # 2. To make this derivation reproducible, remove all git files except the
    #    necessary files:
    #
    #    * config
    #    * HEAD
    #    * objects/
    #    * refs/
    #    * */refs/*
    #
    find . -path '*/.git/*' \
      -a ! -name config \
      -a ! -name HEAD \
      -a ! \( -type d -name objects \) \
      -a ! \( -type d -name refs \) \
      -a ! \( -path '*/refs/*' \) \
      -exec rm -rf {} +

    cp --no-preserve=mode,ownership,timestamps mix.exs $out
    cp --no-preserve=mode,ownership,timestamps mix.lock $out
    cp --no-preserve=mode,ownership,timestamps -r deps $out

    runHook postInstall
  '';

  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  outputHashAlgo = null;
  outputHashMode = "recursive";
  outputHash = if hash != "" then hash else lib.fakeHash;
})
