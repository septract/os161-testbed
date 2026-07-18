# OS/161 environment setup notes (2026-07-17)

Goal: build/run OS/161 2.0.3 on macOS arm64 (Apple Silicon) for working through
the classic student assignments (sync → syscalls → VM → FS) without looking at
solution code.

## Layout (everything project-local, nothing installed globally)

- `downloads/` — tarballs from os161.org + gnu.org
- `build/` — scratch build trees (safe to delete when done)
- `tools/` — install prefix: sys161, bmake, mips-unknown-elf binutils/gcc
- `os161-base-2.0.3/` — the OS/161 source tree (the thing we hack on)
- `root/` — $(OSTREE): installed kernel + userland image that sys161 boots

## Key decisions / deviations from os161.org instructions

- **Skipped the official toolchain** (binutils 2.24 / gcc 4.8.3 from 2014):
  gcc 4.8 cannot be built for an arm64-Darwin host at all. Per advice
  (friend's setup notes), use a modern vanilla cross toolchain instead and set
  `GNUTARGET=mips-unknown-elf` in `defs.mk`.
- **binutils 2.44** vanilla, `--target=mips-unknown-elf --disable-werror
  --disable-nls --with-system-zlib`. Bundled zlib doesn't compile against the
  macOS 26 SDK (K&R prototypes); system zlib fixes it.
- **gcc 14.4.0** vanilla + Homebrew's Apple Silicon host patch
  (`Patches/gcc/gcc-14.4.0.diff` from homebrew-core; the Iain Sandoe darwin
  branch diff). C only, `--without-headers --with-newlib`, libssp/quadmath/
  atomic/gomp/lto disabled, gmp/mpfr/mpc from existing Homebrew kegs.
  Chose 14.x over 15/16 because it defaults to gnu17, friendlier to 2015-era
  kernel C than gnu23 (bool/true/false keywords etc.).
- **bmake-20101215** from os161.org needed two fixes on macOS 26 / clang 19:
  `#include <err.h>` in util.c and manually adding `HAVE_VERR/VERRX/VWARN/
  VWARNX` to config.h (configure misdetects them; clang 19 treats implicit
  decls as errors).
- **sys161 2.0.8** built natively, no changes needed (`./configure
  --prefix=... mipseb`). QEMU is not an option: OS/161's drivers target
  System/161's custom LAMEbus devices, which QEMU doesn't emulate.
- macOS quirk: `/usr/bin/{gcc,g++,ar,ranlib}` are xcrun shims that want a
  cache db in `/var/folders` (blocked in the CC sandbox). Worse than a hard
  failure: they fail *intermittently*, so gcc's configure silently misdetected
  headers (e.g. `dlfcn.h`) and the build broke deep in `plugin.cc`. Fix: run
  configure with `CC/CXX/AR/RANLIB` pointing directly at
  `/Library/Developer/CommandLineTools/usr/bin/*`, plus `--disable-plugin`.

## Build sequence for the OS itself (friend's notes, corrected)

```
cd os161-base-2.0.3
./configure --ostree=.../root     # done; defs.mk edited: GNUTARGET=mips-unknown-elf
bmake && bmake install            # userland
cd kern/conf && ./config DUMBVM   # note: script is "config", not "configure"
cd ../compile/DUMBVM && bmake depend && bmake && bmake install
cd .../root && sys161 kernel      # boots; sys161.conf + LHD{0,1}.img created
```

(`GENERIC` config not usable until a real VM system is written — that's ASST3.)

## Porting fixes needed for modern toolchain (all working 2026-07-17)

1. **defs.mk**: `GNUTARGET=mips-unknown-elf`; `WERROR=-Werror -Wno-error=<new
   gcc-14 warning families>` (format-truncation/overflow, stringop-*,
   array-bounds, maybe-uninitialized, infinite-recursion, dangling-pointer,
   use-after-free); `HOST_WERROR=-Werror -Wno-error=gnu-folding-constant
   -Wno-error=uninitialized-const-pointer` (clang names differ from gcc);
   `HOST_CC=` direct CLT clang; `LDFLAGS=-Wl,-e,__start` (crt0 uses MIPS
   `__start`, vanilla ld defaults to `_start`).
2. **mk/os161.config-mips.mk**: added `-G0` to CFLAGS and KCFLAGS. Vanilla
   mips-elf gcc defaults to -G8 small-data; nothing sets $gp for kernel
   threads → tt1 panicked with kernel-mode TLB miss at ~0xffff8xxx (gp-relative
   load off a garbage gp). The os161-patched toolchain forced -G0.
3. **kern/arch/mips/conf/ldscript**: `/DISCARD/ : { *(.MIPS.abiflags) }` —
   modern binutils emits PT_MIPS_ABIFLAGS (0x70000003), sys161's boot loader
   rejects unknown segment types ("unknown segment type 1879048195").
4. **kern/include/elf.h + kern/syscall/loadelf.c**: define PT_MIPS_ABIFLAGS,
   skip it in both loadelf switches (userland binaries carry it too).

## Verified working

- Boot to menu, clean shutdown (`q`)
- `tt1` thread test: 8 threads interleave, passes
- `km1` kmalloc test, `sy1` semaphore test: pass
- `p /testbin/palin`: loads, enters user mode, spams "Unknown syscall 55"
  (write() unimplemented — that IS ASST2), dies on user stack fault dumbvm
  can't handle (that IS ASST3). Exactly the expected base-system behavior.
- Note: the menu's `p` doesn't wait for the program (no waitpid yet) — give
  the simulator time before `q`, or output never appears.
- sys161 "bind: Operation not permitted" warnings = CC sandbox blocking the
  optional gdb/meter sockets; harmless for normal runs.

## gdb (added later on 2026-07-17)

- **gdb 17.2** vanilla, `--target=mips-unknown-elf`, same recipe as
  binutils/gcc (direct CLT clang, SDKROOT, system zlib, brew gmp/mpfr),
  `--disable-sim --without-python --disable-nls --disable-werror`,
  `MAKEINFO=true` to skip docs. Built clean first try; installed as
  `tools/bin/mips-unknown-elf-gdb`. Symbol loading + source listing from the
  kernel ELF verified.
- **Remote debugging works** (verified 2026-07-17): `sys161 -w kernel`
  creates `.sockets/gdb` in the working directory; attach with
  `mips-unknown-elf-gdb kernel` + `target remote .sockets/gdb`
  (symbols, registers, disassembly, per-CPU threads via
  `info threads` all confirmed). Sandboxed build environments that
  block `bind(2)` need the run done outside the sandbox (or with a
  network-policy exception); this is a sandbox policy matter, not a
  toolchain limitation.
- build/ was deleted after the toolchain was done (2.3G reclaimed);
  re-creatable from downloads/ in ~20 min.

## Console input needs a tty: use setup/interact161.py (2026-07-17)

sys161 enables console *input* only when its stdin is a terminal.
Piping input (`echo 31337 | sys161 ...`) silently never reaches the
simulated console, which made interactive tests (sbrktest 18/21,
malloctest 7, an interactive /bin/sh session) look unrunnable during
ASST2 — that was misdiagnosed at the time as an environment
limitation. The actual fix: `setup/interact161.py` runs sys161 on a
pseudo-terminal and answers prompts from an expect/send list:

    ../setup/interact161.py 300 'Enter random seed: ' '31337\n' -- \
        ../tools/bin/sys161 -X kernel "p /testbin/sbrktest 18;q"

(Sandboxed build environments may need to permit pty allocation —
/dev/ptmx — for this to work.)

## SOLVED: cpus=2/3 boot stall was a sys161 heap overflow (2026-07-17)

The former "known environment quirk" (cpus=2 stalling at secondary-CPU
bringup) is root-caused and fixed. It is a latent heap buffer overflow
in System/161 2.0.8 itself: each CPU's CRAM scratch area is decoded as
a 256-byte register window, and a starting secondary's boot stack
points at the window's end, but the backing buffer is malloc'd at only
LAMEBUS_CRAM_SIZE = 128 bytes — so the secondary's first stack pushes
write ~24 bytes past the end of a 128-byte heap block. What that
corrupts depends on the host allocator's layout, which is why the
symptom was configuration-dependent (on macOS/arm64: cpus=2/3 zeroed
the boot CPU's simulated $sp and wedged the machine in an exception
storm; cpus=1/4 landed harmlessly — and on the x86/Linux hosts the
course runs on, apparently harmlessly for years).

Diagnosed with the project's own tooling, no guest-kernel changes:
gdb attach over the debug socket (garbage $sp inside the LAMEbus CRAM
window), `trace161 -tx` (first bad exception: boot CPU faulting with
sp=0 right after the CPUE write), then instrumented sys161 builds that
caught the corruption between two cycle boundaries and identified the
overflowing store path.

Fix: `setup/patches/sys161-2.0.8-cram-overflow.diff` (one line:
CRAM_SIZE 128 -> 256), applied by setup/build-toolchain.sh. With it,
cpus=2 and cpus=3 boot and run the full ASST1 battery cleanly; 1 and 4
unchanged. Worth reporting upstream to os161.org.

## Disk footprint (project-local only)

build/ 2.3G (deletable scratch), downloads/ 279M, tools/ 68M,
os161-base-2.0.3/ 11M, root/ 14M.

## Assignment plan (avoid solution poisoning)

- Exercises: ops-class.org ASST0–3 + Harvard CS161 versions; canonical
  sequence per os161.org: locks/CV → syscalls → VM → FS → extra.
- Do NOT fetch other people's os161 GitHub repos or ops-class solution
  branches; instructor solutions are password-protected on os161.org.
