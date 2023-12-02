# nix-beam-utils

A flake providing utils for BEAM.

## Why?

The nixpkgs contains BEAM related utils with a broad set of features, but I am looking for implementations with more singular functionality. Given the wide user base of nixpkgs, to avoid affecting them, I decide to maintain my own utils. In the future, I'll try to merge them back to nixpkgs.

## Overlay

This flake primarily provides an overlay, which puts utils into a top-level namespace - `beamUtils`.

After setting up the overlay, you can access it via:

```nix
pkgs.beamUtils
```

## Tests

Test `buildMixRelease`:

```console
$ nix build '.#test-buildMixRelease'
```

## License

MIT
