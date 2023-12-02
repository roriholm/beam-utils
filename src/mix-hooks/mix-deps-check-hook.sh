# shellcheck shell=bash
#
# This hook is derived from nixpkgs/pkgs/build-support/node/build-npm-package/hooks/npm-config-hook.sh
#

# use a special name for avoiding naming conflicts
_mixDepsCheckHook_log() {
    echo "[mix-deps-check] $1"
}

mixDepsCheckHook() {
    if [ -z "${mixDeps-}" ]; then
        _mixDepsCheckHook_log "no mixDeps is specified, skip"
        return 0
    fi

    local -r srcMixLock="$PWD/mix.lock"
    local -r cacheMixLock="$mixDeps/mix.lock"

    if [ -e "$srcMixLock" ] && [ -e "$srcMixLock" ]; then
        _mixDepsCheckHook_log "validating consistency between $srcMixLock and $cacheMixLock"
    elif ! [ -e "$srcMixLock" ]; then
        _mixDepsCheckHook_log "missing lock file from src: $srcMixLock, skip"
        return 0
    elif ! [ -e "$cacheMixLock" ]; then
        _mixDepsCheckHook_log "missing lock file from cache: $cacheMixLock, skip"
        return 0
    fi

    if ! @diff@ "$srcMixLock" "$cacheMixLock"; then
      echo
      echo "ERROR: the hash of mixDeps is out of date"
      echo
      echo "The mix.lock in src is not the same as the one in $mixDeps. To fix the issue:"
      echo
      echo "1. Use \`lib.fakeHash\` as the value of \`hash\` field of \`mixDeps\`"
      echo "2. Build the derivation and wait for it to fail with a hash mismatch"
      echo "3. Copy the 'got: sha256-' value back into the value of \`hash\` field of \`mixDeps\`"
      echo

      exit 1
    fi
}

postPatchHooks+=(mixDepsCheckHook)
