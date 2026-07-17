# ASST1: Synchronization

Implement the sleeping synchronization primitives, then use them to
solve two toy concurrency problems.

Start from: `main`. Everything happens in the kernel; no userland work.

## Part 1: primitives

The interfaces are declared in `os161/kern/include/synch.h`; stub/
skeleton code is in `os161/kern/thread/synch.c`. Semaphores are already
implemented and are the model to follow (wait channels + spinlocks —
see `wchan.h`, `spinlock.h`). Spinlocks and interrupt control already
exist; do not busy-wait in anything you build here.

1. **Locks** (`lock_create/acquire/release/do_i_hold/destroy`).
   Requirements: mutual exclusion; only the holder may release;
   `lock_do_i_hold` must be accurate; must work with multiple CPUs
   (`cpus=4` in sys161.conf); holding a lock across a voluntary sleep
   must be possible (that's the point — this is a sleep-lock, not a
   spinlock).
2. **Condition variables** (`cv_create/wait/signal/broadcast/destroy`)
   with Mesa/no-hoare semantics: `cv_wait` atomically releases the
   lock and sleeps, reacquires before returning; `cv_signal` wakes one
   waiter, `cv_broadcast` all; a waker holds the lock when signalling;
   a woken thread must re-check its predicate.
3. **Reader-writer locks** (`rwlock_*` — add the interface yourself,
   mirroring the style of `synch.h`): any number of concurrent
   readers, writers exclusive; neither readers nor writers may starve
   under sustained contention. Design note required (in the code or
   commit message): explain the fairness scheme.

## Part 2: problems

Write these as new kernel test files (pattern: `kern/test/`, wire into
the menu via `kern/main/menu.c` and `kern/include/test.h`).

**Whale mating.** Whales need three participants to mate: a male, a
female, and a matchmaker. Spawn N of each type (say 10) as threads.
Each whale calls its role function (`male()` / `female()` /
`matchmaker()`), which must not return until a full trio has formed;
print start/end events so the interleaving is visible. No polling, no
timing assumptions.

**Buffalo intersection.** An unsignalled 4-way intersection with two
perpendicular roads divided into quadrants. Buffalo approach from all
four directions and either go straight, turn left, or turn right.
Rules: two buffalo may never occupy the same quadrant at once; once in
the intersection a buffalo must keep moving along its path (it may not
back up or leave except by completing its route); no deadlock; no
direction may starve. Model each buffalo as a thread; movement =
acquiring the quadrants along its path in order.

## Acceptance

- `sy2` (lock test), `sy3` and `sy4` (CV tests) pass repeatedly, on 1
  and 4 CPUs. (They hang or fail on the base system.)
- `sy1` still passes (no regressions in semaphores/wchans).
- Your own rwlock test + the two problem tests pass repeatedly on 1
  and 4 CPUs; output shows real interleaving, not serialization.
- `q` still shuts down cleanly after every test (no leaked threads, no
  held spinlocks — the kernel checks and will complain).
