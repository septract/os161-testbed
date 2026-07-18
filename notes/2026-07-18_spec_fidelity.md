# Spec fidelity: how these exercises relate to the public assignments

Date: 2026-07-18. The write-ups in exercises/ were authored from
os161.org and public course materials before any solving began. On
this date they were re-verified against the most detailed public
OS/161 assignment descriptions, ops-class.org
(https://ops-class.org/asst/1/ .. /asst/3/), to confirm that anyone
attempting this repo's exercises is solving the canonically assigned
problems.

Verdict: the requirements are substantively identical.

- ASST1 ↔ ops-class ASST1: same primitives (locks, Mesa CVs,
  starvation-free reader-writer locks), same two synchronization
  problems — ops-class's "stoplight" is this repo's buffalo
  intersection with different animals; the rules match.
- ASST2 ↔ ops-class ASST2: the same 13 system calls (8 file,
  5 process), same fd/console/dup2 semantics, same abuse-resistance
  bar (badcall/crash/forkbomb), man-page error conformance.
- ASST3 ↔ ops-class ASST3: same components (coremap with multi-page
  kernel allocations, TLB fault handling with flush-or-ASID choice,
  per-process page tables of the student's design, sbrk, swap on the
  first disk tracked by a bitmap, an eviction policy), same
  machine-independent/machine-dependent source split, same staged
  grading shape, including running the coremap stage at 1 MB RAM.

One structural difference, deliberate: ops-class courses use a forked
OS/161 tree plus their test161 harness, which add tests and provided
problem-driver code that do not exist in pristine OS/161 2.0.3 (e.g.
lt*/cvt*/sp1/sp2 drivers, km5, consoletest/opentest/…, quint*). This
repo targets the pristine 2.0.3 tree, so:

- the base tree's equivalent tests are used (sy2–sy4 for locks/CVs;
  filetest/redirect/bigseek and friends for the file calls; the
  triple* programs where ops-class uses quint*), and
- where the public assignment supplies driver/test code (the two
  synchronization problems, the rwlock tests), writing that driver is
  part of this repo's exercise instead.

Net: attempting these exercises means solving the same problems, with
slightly more test-authoring work than the ops-class packaging.
