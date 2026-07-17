#!/bin/sh
#
# Configure the OS/161 tree for this machine and set up the runnable
# system root (./root): generates os161/defs.mk, writes root/sys161.conf,
# and creates the two disk images. Re-runnable.
#
# Run ./setup/build-toolchain.sh first.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS="$ROOT/tools"
PATH="$TOOLS/bin:$PATH"; export PATH

if [ ! -x "$TOOLS/bin/mips-unknown-elf-gcc" ]; then
    echo "Toolchain not found -- run ./setup/build-toolchain.sh first." >&2
    exit 1
fi

#
# Generate defs.mk (machine-specific; not committed).
#
cd "$ROOT/os161"
./configure --ostree="$ROOT/root"

if [ "$(uname -s)" = Darwin ]; then
    cat >> defs.mk <<'EOF'

# --- appended by setup/configure-os161.sh (macOS host) ---
# Use CommandLineTools clang directly: the /usr/bin xcrun shims fail
# intermittently in sandboxed environments (cache in /var/folders).
# Invoked directly (not via xcrun) it needs the SDK spelled out.
HOST_CC=/Library/Developer/CommandLineTools/usr/bin/clang -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
# The committed WERROR demotion list uses gcc warning names; clang (the
# host compiler) rejects the ones it doesn't know and has a couple of
# its own warnings that fire on baseline host-tool code.
HOST_WERROR=-Werror -Wno-error=gnu-folding-constant -Wno-error=uninitialized-const-pointer
EOF
fi

#
# Set up the system root that sys161 boots from.
#
mkdir -p "$ROOT/root"
cd "$ROOT/root"

if [ ! -f sys161.conf ]; then
    cat > sys161.conf <<'EOF'
0	serial
1	emufs
2	disk	rpm=7200	file=LHD0.img	nodoom
3	disk	rpm=7200	file=LHD1.img
28	random	autoseed
29	timer
30	trace
31	mainboard	ramsize=2M	cpus=1
EOF
fi

[ -f LHD0.img ] || disk161 create LHD0.img 5M
[ -f LHD1.img ] || disk161 create LHD1.img 5M

echo
echo "Configured. Next: ./setup/build-os161.sh"
