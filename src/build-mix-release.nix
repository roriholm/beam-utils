{ stdenv
, lib
, glibcLocalesUtf8
, elixir
, erlang
, hex
, rebar3
, git
, mixHooks
, findutils
, ripgrep
, bbe
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
, mixEnv ? "prod"
, mixDeps ? null
  # Options to be passed to the `mix compile`.
  # Checkout `mix help compile` for more details.
, mixCompilerOptions ? [ ]
  # Options to be passed to the Erlang compiler.
  # Checkout <https://www.erlang.org/doc/man/compile> for more details.
, erlCompilerOptions ? [ ]
, removeCookie ? true
, debug ? false
, elixir ? inputs.elixir
, erlang ? inputs.erlang
, hex ? inputs.hex.override { inherit elixir; }
, ...
}@attrs:
let
  overridable = builtins.removeAttrs attrs [
    "env"
    "nativeBuildInputs"
    "mixEnv"
    "mixDeps"
    "mixCompilerOptions"
    "erlCompilerOptions"
    "removeCookie"
    "debug"
    "elixir"
    "erlang"
    "hex"
  ];
in
stdenv.mkDerivation (overridable // (if stdenv.isLinux then {
  LOCALE_ARCHIVE = "${glibcLocalesUtf8}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";
} else {
  LC_ALL = "en_US.UTF-8";
}) // {
  nativeBuildInputs = [
    mixHooks.mixDepsCheckHook
  ] ++ [
    elixir
    hex
    git
  ] ++ [
    findutils
    ripgrep
    bbe
    makeWrapper
  ] ++ nativeBuildInputs;

  # Erlang environment variables
  ERL_COMPILER_OPTIONS =
    let
      compilerOptions = lib.unique (
        [
          # Remove options and source tuples from Line chunk of BEAM files.
          # This option will make it easier to achieve reproducible builds,
          #
          # In the Nix world, it helps to remove erlang references from BEAM files.
          "deterministic"
        ]
        ++ lib.optional debug "debug_info"
      );
    in
    "[${lib.concatStringsSep "," compilerOptions}]";

  # Hex environment variables
  HEX_OFFLINE = 1;

  # Mix environment variables
  MIX_ENV = mixEnv;
  MIX_REBAR3 = "${rebar3}/bin/rebar3";
  MIX_DEBUG = if debug then 1 else 0;

  # Rebar environment variables
  DEBUG = if debug then 1 else 0; # for Rebar3 compilation

  configurePhase = attrs.configurePhase or ''
    runHook preConfigure

    # Hex
    export HEX_HOME="$TEMPDIR/.hex"

    # Mix
    export MIX_HOME="$TEMPDIR/.mix"

    # Rebar
    export REBAR_GLOBAL_CONFIG_DIR="$TEMPDIR/.rebar3"
    export REBAR_CACHE_DIR="$TEMPDIR/.rebar3.cache"

    ${lib.optionalString (mixDeps != null) ''
      # Compilation of the dependencies requires that the dependency is
      # writable, thus a copy to deps/.
      cp -r --no-preserve=mode "${mixDeps}/deps" deps
    ''}

    mix deps.compile --skip-umbrella-children

    runHook postConfigure
  '';

  buildPhase = attrs.buildPhase or (
    let
      compilerOptions = lib.unique mixCompilerOptions;
    in
    ''
      runHook preBuild

      mix compile ${lib.concatStringsSep " " compilerOptions}

      runHook postBuild
    ''
  );

  installPhase = attrs.installPhase or ''
    runHook preInstall

    mix release --path "$out"

    runHook postInstall
  '';

  postFixup = ''
    echo "removing files for Microsoft Windows"
    rm -f "$out"/bin/*.bat

    echo "wrapping programs in $out/bin with their runtime deps"
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
      echo "removing $out/releases/COOKIE"
      rm $out/releases/COOKIE
    fi
  '' + ''
    if ! [ -e $out/erts-* ]; then
      echo "ERROR: missing ERTS in $out"
      echo ""
      echo "References to erlang will be removed in the subsequent processing flow, because of that, ERTS must be included in the release."
      echo "To fix this issue, please make sure:"
      echo ""
      echo "+ \`:include_erts\` option of mix release is \`true\`."
      echo ""
      exit 1
    fi

    # ERTS is included in the release, then erlang is not required as a runtime dependency.
    # But, erlang is still referenced in some places. Because of that, following steps are required.

    # 1. remove references to erlang from plain text files
    for file in $(rg "${erlang}/lib/erlang" "$out" --files-with-matches); do
      echo "removing references to erlang in $file"
      substituteInPlace "$file" --replace "${erlang}/lib/erlang" "$out"
    done

    # 2. remove references to erlang from .beam files
    #
    # No need to do anything, because it has been handled by "deterministic" option specified
    # by ERL_COMPILER_OPTIONS.

    # 3. remove references to erlang from normal binary files
    for file in $(rg "${erlang}/lib/erlang" "$out" --files-with-matches --binary --iglob '!*.beam'); do
      echo "removing references to erlang in $file"
      # use bbe to substitute strings in binary files, because using substituteInPlace
      # on binaries will raise errors
      bbe -e "s|${erlang}/lib/erlang|$out|" -o "$file".tmp "$file"
      rm -f "$file"
      mv "$file".tmp "$file"
    done
  '';

  # References to erlang should be removed from output after above processing.
  #
  # Here, disallowedReferences attribute is used to guard that erlang is not referenced. If erlang
  # is referenced, which is not expected, an error will be raised.
  disallowedReferences = [ erlang ];
})
