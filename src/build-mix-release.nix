{ stdenv
, lib
, glibcLocalesUtf8
, elixir
, hex
, rebar3
, git
, findutils
, makeWrapper
, coreutils
, gnused
, gnugrep
, gawk
}@inputs:

{ pname
, version
, src
, nativeBuildInputs ? [ ]
, mixFodDeps ? null
, compileFlags ? [ ]
, removeCookie ? true
, env ? "prod"
, debug ? false
, elixir ? inputs.elixir
, hex ? inputs.hex.override { inherit elixir; }
, ...
}@attrs:
let
  # Remove non standard attributes
  overridable = builtins.removeAttrs attrs [ "compileFlags" ];
in
stdenv.mkDerivation (overridable // (if stdenv.isLinux then {
  LOCALE_ARCHIVE = "${glibcLocalesUtf8}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";
} else {
  LC_ALL = "en_US.UTF-8";
}) // {
  nativeBuildInputs = [
    elixir
    hex
    git
  ] ++ [
    findutils
    makeWrapper
  ] ++ nativeBuildInputs;

  # Mix and Hex environment variables
  MIX_ENV = env;
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
  MIX_DEBUG = if debug then 1 else 0;
  HEX_OFFLINE = 1;

  # Rebar3 environment variables
  DEBUG = if debug then 1 else 0; # for Rebar3 compilation

  configurePhase = attrs.configurePhase or ''
    runHook preConfigure

    # Mix and Hex
    export MIX_HOME="$TEMPDIR/.mix"
    export HEX_HOME="$TEMPDIR/.hex"

    # Rebar
    export REBAR_GLOBAL_CONFIG_DIR="$TEMPDIR/.rebar3"
    export REBAR_CACHE_DIR="$TEMPDIR/.rebar3.cache"

    ${lib.optionalString (mixFodDeps != null) ''
      # Compilation of the dependencies requires that the dependency is
      # writable, thus a copy to deps/.
      cp -r --no-preserve=mode "${mixFodDeps}" deps
    ''}

    mix deps.compile --skip-umbrella-children

    runHook postConfigure
  '';

  buildPhase = attrs.buildPhase or ''
    runHook preBuild

    mix compile ${lib.concatStringsSep " " compileFlags}

    runHook postBuild
  '';

  installPhase = attrs.installPhase or ''
    runHook preInstall

    mix release --path "$out"

    runHook postInstall
  '';

  postFixup = ''
        # Remove files for Microsoft Windows
        rm -f "$out"/bin/*.bat

        # Wrap programs in $out/bin with their runtime deps
        for f in $(find $out/bin/ -type f -executable); do
          wrapProgram "$f" \
            --prefix PATH : ${lib.makeBinPath [
    coreutils
    gnused
    gnugrep
    gawk
    ]}
        done
  '' + lib.optionalString removeCookie ''
    if [ -e $out/releases/COOKIE ]; then
      rm $out/releases/COOKIE
    fi
  '';

  # TODO: remove erlang references in resulting derivation
  #
  # # Step 1 - investigate why the resulting derivation still has references to erlang.
  #
  # The reason is that the generated binaries contains erlang reference. Here's a repo to
  # demonstrate the problem - <https://github.com/plastic-gun/nix-mix-release-unwanted-references>.
  #
  #
  # # Step 2 - remove erlang references from the binaries
  #
  # As said in above repo, it's hard to remove erlang references from `.beam` binaries.
  #
  # We need more experienced developers to resolve this issue.
  #
  #
  # # Tips
  #
  # When resolving this issue, it is convenient to fail the build when erlang is referenced,
  # which can be achieved by using:
  #
  #   disallowedReferences = [ erlang ];
  #
})
