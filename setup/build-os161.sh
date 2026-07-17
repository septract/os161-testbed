#!/bin/sh
#
# Build and install OS/161: userland, then the kernel. Pass a kernel
# config name as the first argument (default DUMBVM; GENERIC only works
# once you have written a real VM system -- that's the point of ASST3).
#
# Run ./setup/configure-os161.sh first. Re-runnable; does an incremental
# build.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PATH="$ROOT/tools/bin:$PATH"; export PATH
CONFIG=${1:-DUMBVM}
NJOBS=$( (sysctl -n hw.ncpu || nproc || echo 4) 2>/dev/null | head -1 )

if [ ! -f "$ROOT/os161/defs.mk" ]; then
    echo "Tree not configured -- run ./setup/configure-os161.sh first." >&2
    exit 1
fi

cd "$ROOT/os161"
bmake -j"$NJOBS"
bmake install

cd kern/conf
./config "$CONFIG"
cd "../compile/$CONFIG"
bmake depend
bmake -j"$NJOBS"
bmake install

echo
echo "Built and installed into $ROOT/root (kernel-$CONFIG)."
echo "Boot it:  cd root && ../tools/bin/sys161 kernel"
echo "Or run the smoke test:  ./setup/smoke-test.sh"
