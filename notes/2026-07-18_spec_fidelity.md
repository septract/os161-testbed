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

## Harvard CS161 (2017) cross-check — added 2026-07-18

Same date, second validation pass: exercises 1–3 were also compared
against Harvard's own assignment pages
(https://www.eecs.harvard.edu/~cs161/assignments/a1.html … a3.html),
and exercise 4 was authored from a4.html. Findings:

- **ASST2** matches Harvard closely: the identical 13 syscalls, the
  same console/fd/fork/execv/waitpid semantics, no conflicts.
- **ASST1** diverges by design: Harvard's a1 is locks + CVs + 18
  code-reading questions + five student-written unit tests, with two
  *provided* synchronization problems (elves, airballoon; ungraded).
  Our write-up instead follows the ops-class shape: adds
  reader-writer locks, and has the student author the two toy
  problems (whalemating, intersection). Same core primitives.
- **ASST3** matches Harvard on all core mechanics (coremap, TLB
  handling with flush-or-ASID choice, paging with clean-page
  shortcut, sbrk). Harvard extras our write-up does not require: a
  background paging-daemon thread that writes out dirty pages, page-
  fault/pageout statistics counters, an explicit mechanism-vs-policy
  separation for replacement algorithms, tighter memory targets
  (boot in 512 KB, stress tests in 1 MB — ours: 1–2 MB stress
  stage), and an ASST3-OPT optimized build config. These are noted
  as optional extensions, not retrofitted into the spec, since
  asst1–3 attempts were already graded against the write-ups as
  published.
- **Course mechanics dropped everywhere, deliberately**: Harvard's
  code-reading questions, design-document deliverables, peer
  reviews, submit/ directories, tags, and point rubrics are replaced
  by this repo's EVALUATION.md protocol. (Exception: 04-fs.md keeps
  a design-document requirement — for journaling, the design *is*
  the assignment, and Harvard weighted it 30%.)
- **ASST4 adaptation**: Harvard's a4 assumes handout infrastructure
  (fs syscalls, SFS directories, fine-grained locking, buffer cache,
  and a physical-journal container) that is not public and is absent
  from pristine OS/161 2.0.3. 04-fs.md therefore folds those in as
  Parts 1–4, following the structure the base tree itself proposes
  in os161/design/assignments.txt; Part 5 is the Harvard assignment
  proper (record schema, WAL instrumentation, mount-time recovery,
  with the same ground rules: not all-synchronous, no corruption, no
  garbage exposure, no full-volume scan, crash-tolerant recovery).
  The test kit Harvard used (doom counter, frack, poisondisk, sfsck)
  ships in the pristine tree and is used unchanged.
