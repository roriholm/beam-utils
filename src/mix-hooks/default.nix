{
  lib,
  makeSetupHook,
  diffutils,
  ...
}:
{
  mixDepsCheckHook = makeSetupHook {
    name = "mix-deps-check-hook";
    substitutions = {
      diff = "${diffutils}/bin/diff";
    };
  } ./mix-deps-check-hook.sh;
}
