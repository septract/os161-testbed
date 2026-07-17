# Vendored patches

## gcc-14.4.0-darwin.diff

Apple Silicon (aarch64-darwin) host support for GCC, from Iain Sandoe's
darwin development branch (https://github.com/iains/gcc-14-branch), as
distributed by the Homebrew project in homebrew-core
(`Patches/gcc/gcc-14.4.0.diff`, BSD-2-Clause). Vendored here because the
file in homebrew-core's `master` moves/disappears as their gcc formula
advances versions, and this repo pins gcc 14.4.0.

Only applied when building the cross-gcc on macOS; Linux hosts build
vanilla gcc unpatched.
