# Evaluation protocol

The point of this repo is to attempt the OS/161 exercises *cold* — the
way a student would — and to let others rerun the same experiment. That
only means something if solutions never leak into the attempt.

## Information rules

Allowed:

- Everything in this repo: the base source, the in-tree man pages
  (`os161/man/`), the exercise write-ups in this directory.
- The public assignment *descriptions* (ops-class.org, Harvard CS161
  pages) — specs, not solutions.
- General OS literature: textbooks (OSTEP, Doeppner, Tanenbaum...),
  papers, MIPS architecture manuals, gcc/gdb docs.

Not allowed:

- Anyone's OS/161 assignment solutions: GitHub repos of completed
  os161 coursework, blog walkthroughs of the assignments, course
  solution sets. (Searching the web for os161 topics finds these
  instantly — don't search for assignment-specific terms; search for
  concepts.)
- The os161.org instructors' area (password-protected solution code).
- Asking an AI/search tool to produce the solution for one of these
  specific assignments. Asking about concepts (how do Mesa CVs differ
  from Hoare, what is a coremap) is fine; the line is
  assignment-specific code or design.

Provenance discipline: if reference material beyond the allowed list
somehow informs a design decision, record it in the commit message so
the attempt's inputs stay auditable.

## Mechanics

- Every attempt is a branch (`asstN/<attempt-name>`) from the declared
  start point (see exercises/README.md). The diff against the start
  point *is* the submission.
- Commit as you go; the history should show the actual path taken,
  including dead ends. No squashing away the process.
- The evaluator (human, possibly assisted by tooling that has NOT seen
  solutions either) reviews the diff and runs the acceptance tests in
  the exercise write-up, on 1 and 4 CPUs, several times — OS/161 bugs
  are frequently timing-dependent, and one green run proves little.
  `sys161`'s random seed (`root/sys161.conf`, slot 28) can be pinned
  for reproduction or varied for coverage.
- Regressions count: every previously-passing test must still pass.

## Grading dimensions (per exercise)

1. **Correctness**: acceptance tests pass repeatedly, both CPU counts.
2. **Robustness**: hostile inputs (`badcall`, `crash`, `forkbomb`
   where applicable) don't take the kernel down; clean shutdown after
   every test.
3. **Design quality**: data-structure and locking choices are sound
   and explained (commit messages or comments); no busy-waiting, no
   giant-lock shortcuts where the spec asks for real concurrency.
4. **Code quality**: matches the tree's style; builds with the tree's
   `-Werror`; no leaks (`khu` where relevant).
