# The OS/161 exercises

These are the classic OS/161 programming assignments, as taught at
Harvard (CS161) and Buffalo (ops-class.org), restated here so an attempt
can be made from this repo alone. The canonical sequence, per
[os161.org](http://www.os161.org/):

| # | Exercise | Implements | Spec |
|---|----------|------------|------|
| 0 | [Getting started](00-intro.md) | nothing — build, boot, explore | — |
| 1 | [Synchronization](01-synch.md) | locks, CVs, reader-writer locks; toy problems | ~ hundreds of lines |
| 2 | [System calls](02-syscalls.md) | file + process syscalls; run user programs | ~ 2,000+ lines |
| 3 | [Virtual memory](03-vm.md) | TLB handling, paging, swap, `sbrk` | largest |
| 4 | File system work (locking, journaling) — not yet written up | | |

External references (specs only — see [EVALUATION.md](EVALUATION.md)
for what must *not* be consulted):

- ops-class.org assignments: <https://ops-class.org/asst/0/> … `/asst/3/`
- Harvard CS161 2017: <https://www.eecs.harvard.edu/~cs161/>
- The in-tree man pages: `os161/man/` (syscall semantics live here —
  `man/syscall/*.html` is the authoritative contract for ASST2)

## Workflow

Each attempt happens on a branch, so attempts are independent and
reviewable:

```
main                    # patched baseline; the ASST1 starting point
  asst1/<attempt>       # branch from main
  asst2/<attempt>       # branch from an accepted asst1 result
  asst3/<attempt>       # branch from an accepted asst2 result
```

The assignments are cumulative by nature (syscalls use your locks; VM
runs under your syscalls), so later assignments start from an accepted
earlier result — tag accepted states (`asst1-done`, ...) to give later
work a fixed base. To rerun an exercise independently, branch again
from the same start point.

Build and test loop, from the repo root:

```
./setup/build-os161.sh            # rebuild userland + DUMBVM kernel
cd root && ../tools/bin/sys161 kernel          # interactive boot
../tools/bin/sys161 -X kernel "sy2;q"          # scripted test run
```
