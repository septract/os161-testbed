#!/bin/sh
#
# Boot the installed kernel non-interactively and check that the base
# system is healthy: thread test (tt1), kmalloc test (km1), semaphore
# test (sy1), then clean shutdown. These all pass on the unmodified
# base system; sy2/sy3/sy4 (locks/CVs) will NOT pass until ASST1 is done.

set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PATH="$ROOT/tools/bin:$PATH"; export PATH
LOG="${TMPDIR:-/tmp}/os161-smoke-$$.log"

cd "$ROOT/root"
sys161 -X kernel "tt1;km1;sy1;q" > "$LOG" 2>&1 || true

ok=1
for want in "Thread test done" "kmalloc test done" "Semaphore test done" \
            "The system is halted"; do
    if ! grep -q "$want" "$LOG"; then
        echo "MISSING: $want"
        ok=0
    fi
done

if [ "$ok" = 1 ]; then
    echo "smoke test PASSED (tt1, km1, sy1, clean shutdown)"
    rm -f "$LOG"
else
    echo "smoke test FAILED; transcript: $LOG"
    exit 1
fi
