#!/bin/sh
#
# Build the full OS/161 toolchain into ./tools (project-local; nothing
# is installed globally):
#
#   sys161 2.0.8                  - the System/161 MIPS machine simulator
#   bmake 20101215                - BSD make, which OS/161's build uses
#   binutils 2.44                 - vanilla, --target=mips-unknown-elf
#   gcc 14.4.0                    - vanilla + (macOS only) Homebrew's
#                                   Apple Silicon host patch; C only,
#                                   soft-float, mips1, no multilibs
#   gdb 17.2                      - vanilla, --target=mips-unknown-elf
#
# We deliberately do NOT use the os161-patched toolchain from os161.org
# (binutils 2.24 / gcc 4.8.3, from 2014): it cannot be built on modern
# hosts (gcc 4.8 has no arm64-Darwin host support at all). The tree's
# build config is adjusted for the vanilla toolchain instead; see the
# "Port build to modern vanilla mips-unknown-elf toolchain" commit.
#
# Tested on: macOS 26 arm64 (Apple Silicon), CommandLineTools clang,
# Homebrew gmp/mpfr/libmpc/gmake. The Linux path is untested best-effort;
# you need: gcc/g++, GNU make, gmp/mpfr/mpc dev packages, zlib dev.
#
# Each component is skipped if its installed binary already exists, so
# the script is safe to re-run.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS="$ROOT/tools"
DL="$ROOT/downloads"
BUILD="$ROOT/build"
PATCHES="$ROOT/setup/patches"

SYS161_V=2.0.8
BMAKE_V=20101215
MK_V=20100612
BINUTILS_V=2.44
GCC_V=14.4.0
GDB_V=17.2

OS=$(uname -s)

if [ "$OS" = Darwin ]; then
    # Use the CommandLineTools compilers directly rather than the
    # /usr/bin xcrun shims: the shims want a cache in /var/folders and
    # fail (intermittently!) in sandboxed environments, silently
    # corrupting configure results.
    CLT=/Library/Developer/CommandLineTools/usr/bin
    export SDKROOT="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk}"
    export CC="$CLT/clang" CXX="$CLT/clang++" AR="$CLT/ar" RANLIB="$CLT/ranlib"
    GMAKE=gmake
    BREW_PREFIX=$(brew --prefix 2>/dev/null || echo /opt/homebrew)
    GMP="$BREW_PREFIX/opt/gmp"; MPFR="$BREW_PREFIX/opt/mpfr"; MPC="$BREW_PREFIX/opt/libmpc"
    for d in "$GMP" "$MPFR" "$MPC"; do
        if [ ! -d "$d" ]; then
            echo "Missing $d -- install with: brew install gmp mpfr libmpc" >&2
            exit 1
        fi
    done
    if ! command -v "$GMAKE" >/dev/null; then
        echo "GNU make not found -- install with: brew install make" >&2
        exit 1
    fi
else
    GMAKE=make
    GMP=/usr; MPFR=/usr; MPC=/usr
fi

NJOBS=$( (sysctl -n hw.ncpu || nproc || echo 4) 2>/dev/null | head -1 )

mkdir -p "$TOOLS/bin" "$DL" "$BUILD"
PATH="$TOOLS/bin:$PATH"; export PATH

fetch() {
    # fetch <url> [outname]
    out="$DL/${2:-$(basename "$1")}"
    if [ ! -f "$out" ]; then
        echo "==> downloading $(basename "$out")"
        curl -fL -o "$out" "$1"
    fi
}

#
# System/161
#
if [ ! -x "$TOOLS/bin/sys161" ]; then
    echo "==> sys161 $SYS161_V"
    fetch "http://os161.org/download/sys161-$SYS161_V.tar.gz"
    cd "$BUILD"
    rm -rf "sys161-$SYS161_V"
    tar -xzf "$DL/sys161-$SYS161_V.tar.gz"
    cd "sys161-$SYS161_V"
    ./configure --prefix="$TOOLS" mipseb
    make -j"$NJOBS"
    make install
fi

#
# bmake (+ its "mk" include files, which unpack *inside* the bmake dir)
#
if [ ! -x "$TOOLS/bin/bmake" ]; then
    echo "==> bmake $BMAKE_V"
    fetch "http://os161.org/download/bmake-$BMAKE_V.tar.gz"
    fetch "http://os161.org/download/mk-$MK_V.tar.gz"
    cd "$BUILD"
    rm -rf bmake
    tar -xzf "$DL/bmake-$BMAKE_V.tar.gz"
    cd bmake
    tar -xzf "$DL/mk-$MK_V.tar.gz"
    # Modern-libc fixes (needed at least on macOS 26 / clang 19):
    # util.c calls the err(3) family without including <err.h>, and
    # configure misses that libc provides verr/verrx/vwarn/vwarnx.
    awk '{print} /^#include <stdarg\.h>$/ && !done {
        print "#ifdef HAVE_ERR_H"; print "#include <err.h>"; print "#endif"; done=1
    }' util.c > util.c.new && mv util.c.new util.c
    ./configure --prefix="$TOOLS" \
        --with-default-sys-path="$TOOLS/share/mk"
    if [ "$OS" = Darwin ]; then
        printf '\n#define HAVE_VERR 1\n#define HAVE_VERRX 1\n#define HAVE_VWARN 1\n#define HAVE_VWARNX 1\n' >> config.h
    fi
    sh ./make-bootstrap.sh
    mkdir -p "$TOOLS/bin" "$TOOLS/share/man/man1" "$TOOLS/share/mk"
    cp bmake "$TOOLS/bin/"
    cp bmake.1 "$TOOLS/share/man/man1/"
    sh mk/install-mk "$TOOLS/share/mk"
fi

#
# binutils (assembler, linker, objdump, ... for mips-unknown-elf)
#
if [ ! -x "$TOOLS/bin/mips-unknown-elf-ld" ]; then
    echo "==> binutils $BINUTILS_V"
    fetch "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_V.tar.xz"
    cd "$BUILD"
    rm -rf "binutils-$BINUTILS_V" binutils-build
    tar -xf "$DL/binutils-$BINUTILS_V.tar.xz"
    mkdir binutils-build && cd binutils-build
    # --with-system-zlib: the bundled zlib is too old to compile
    # against current macOS SDK headers.
    "../binutils-$BINUTILS_V/configure" \
        --target=mips-unknown-elf --prefix="$TOOLS" \
        --disable-werror --disable-nls --with-system-zlib
    $GMAKE -j"$NJOBS"
    $GMAKE install
fi

#
# gcc (C-only cross-compiler)
#
if [ ! -x "$TOOLS/bin/mips-unknown-elf-gcc" ]; then
    echo "==> gcc $GCC_V"
    fetch "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_V/gcc-$GCC_V.tar.xz"
    cd "$BUILD"
    rm -rf "gcc-$GCC_V" gcc-build
    tar -xf "$DL/gcc-$GCC_V.tar.xz"
    if [ "$OS" = Darwin ]; then
        # Vanilla gcc has no arm64-Darwin *host* support; Homebrew
        # maintains Iain Sandoe's darwin branch as a patch. A copy is
        # vendored in setup/patches/ (see the README there).
        cd "gcc-$GCC_V"
        patch -p1 < "$PATCHES/gcc-$GCC_V-darwin.diff"
        cd ..
    fi
    mkdir gcc-build && cd gcc-build
    # soft-float/mips1: System/161 has no FPU and is an r3000 at heart;
    # this also sidesteps libgcc's hard-float multilib variants, which
    # fail to build for this target.
    "../gcc-$GCC_V/configure" \
        --target=mips-unknown-elf --prefix="$TOOLS" \
        --enable-languages=c --without-headers --with-newlib \
        --with-float=soft --with-arch=mips1 --disable-multilib \
        --disable-shared --disable-threads --disable-nls \
        --disable-libssp --disable-libquadmath --disable-libatomic \
        --disable-libgomp --disable-lto --disable-plugin \
        --with-gmp="$GMP" --with-mpfr="$MPFR" --with-mpc="$MPC" \
        --with-system-zlib
    $GMAKE -j"$NJOBS"
    $GMAKE install
fi

#
# gdb (for remote-debugging the kernel through sys161)
#
if [ ! -x "$TOOLS/bin/mips-unknown-elf-gdb" ]; then
    echo "==> gdb $GDB_V"
    fetch "https://ftp.gnu.org/gnu/gdb/gdb-$GDB_V.tar.xz"
    cd "$BUILD"
    rm -rf "gdb-$GDB_V" gdb-build
    tar -xf "$DL/gdb-$GDB_V.tar.xz"
    mkdir gdb-build && cd gdb-build
    "../gdb-$GDB_V/configure" \
        --target=mips-unknown-elf --prefix="$TOOLS" \
        --disable-nls --disable-werror --disable-sim --without-python \
        --with-system-zlib --with-gmp="$GMP" --with-mpfr="$MPFR"
    $GMAKE -j"$NJOBS" MAKEINFO=true
    $GMAKE install MAKEINFO=true
fi

echo
echo "Toolchain complete in $TOOLS/bin."
echo "You may delete $BUILD (scratch) to reclaim space."
echo "Next: ./setup/configure-os161.sh"
