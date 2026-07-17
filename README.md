# os161-claude

[OS/161](http://www.os161.org/) — Harvard's instructional operating
system — set up to build and run with a **modern vanilla toolchain** on
current machines (developed on Apple Silicon macOS; the stock 2014
toolchain no longer builds there), plus self-contained write-ups of the
classic student exercises so the assignments can be attempted and
evaluated reproducibly.

## Layout

```
os161/          OS/161 2.0.3 source (the thing you hack on)
setup/          scripts that build the toolchain and the system
exercises/      the assignment specs + evaluation protocol
notes/          dated working notes from setting this up
tools/          (generated) installed toolchain: sys161, bmake,
                mips-unknown-elf-{gcc,ld,gdb,...}
root/           (generated) installed system image; sys161 boots here
downloads/      (generated) fetched tarballs
build/          (generated) toolchain build scratch; deletable
```

Only `os161/`, `setup/`, `exercises/`, and `notes/` are tracked; the
rest is recreated by the scripts. Git history starts from the pristine
upstream tarball (tag `vanilla-2.0.3`), so `git log os161/` shows every
change ever made to the OS — including the small portability patch set
this repo adds (see the "Port build to modern vanilla mips-unknown-elf
toolchain" commit).

## Platform support

Honest status: **this was built and is tested on Apple Silicon macOS
only** (macOS 26, arm64), because that's the machine it was developed
on — not because anything here wants to be Mac-specific.

The split is deliberate:

- The **OS/161 tree** (`os161/`) contains no host-specific changes at
  all. Every committed patch (toolchain target, `-G0`, entry symbol,
  `.MIPS.abiflags`) is about the *cross*-toolchain, identical on any
  host. Host-specific settings go into the generated, uncommitted
  `os161/defs.mk`.
- The **setup scripts** are where host knowledge lives. The macOS
  branches (CommandLineTools paths, SDKROOT, Homebrew library paths,
  the vendored gcc host patch, clang-vs-gcc warning-name differences)
  are marked as such. The Linux path is written but **untested**; it
  should be *simpler* than macOS (vanilla gcc needs no host patch, the
  host cc is gcc so no warning-name mismatch). Fixes welcome — the
  intent is that this runs anywhere POSIX-ish.

## Quickstart

Prerequisites on macOS: Xcode CommandLineTools and
`brew install gmp mpfr libmpc make`. On Linux: gcc/g++, GNU make,
gmp/mpfr/mpc dev packages, zlib dev.

```sh
./setup/build-toolchain.sh     # ~30 min first time; all project-local
./setup/configure-os161.sh     # per-machine config + root/ + disks
./setup/build-os161.sh         # userland + DUMBVM kernel
./setup/smoke-test.sh          # boots, runs tt1/km1/sy1, checks output
```

Interactive boot:

```sh
cd root && ../tools/bin/sys161 kernel
```

Type `?` for the menu, `?t` for tests, `q` to shut down. Kernel
debugging: `sys161 -w -p 16161 kernel`, then
`mips-unknown-elf-gdb kernel` and `target remote :16161`.

## The exercises

See [exercises/README.md](exercises/README.md) for the sequence
(sync → syscalls → VM), per-exercise specs with acceptance tests, and
[exercises/EVALUATION.md](exercises/EVALUATION.md) for the rules that
keep attempts honest (no consulting existing solutions).

## Credits

OS/161 and System/161 are by David A. Holland, Ada T. Lim, Margo I.
Seltzer, and others at Harvard University — see
[os161.org](http://www.os161.org/) and the copyright headers in the
source. The exercise sequence follows Harvard CS161 and
[ops-class.org](https://ops-class.org/). The gcc Apple Silicon host
patch is Iain Sandoe's, via Homebrew (see `setup/patches/`).
