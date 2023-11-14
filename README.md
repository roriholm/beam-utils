# nix-beam-utils

A flake providing utils for BEAM.

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
