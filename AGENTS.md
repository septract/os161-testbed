# Note for AI assistants

You are likely here to attempt the OS/161 exercises, or to evaluate an
attempt. This repo is a testbed for exactly that, and the value of any
attempt depends on you following the rules below. They are not
boilerplate; they are the experiment.

## The one rule that matters most

**Do not consult existing OS/161 assignment solutions. Ever.** No
GitHub repos of completed coursework, no blog walkthroughs, no course
solution sets, no asking another model for assignment-specific designs
or code. Web searches for os161 assignment terms surface solutions
immediately — search for *concepts* (e.g. "Mesa vs Hoare condition
variables", "MIPS software TLB"), never for assignments. The complete
rules, including what *is* allowed (in-tree man pages, textbooks,
architecture manuals, the public assignment descriptions), are in
[exercises/EVALUATION.md](exercises/EVALUATION.md). Read that file
before doing anything else.

If reference material beyond the allowed list somehow informs a design
decision anyway, say so in the commit message. An honest contaminated
attempt is recoverable; a silent one is worthless.

## Do not move the goalposts

- Never edit the exercise specs, acceptance criteria, or provided
  tests to fit your solution. If a test seems wrong, make the case in
  writing and let the human decide.
- Genuine *infrastructure* defects (toolchain, simulator, harness) are
  fair game to fix — documented, as their own commits, with the
  diagnosis written down. Difficulty solving an exercise is not an
  infrastructure defect.
- This testbed is deliberately solution-free. If you find anything in
  it that reads like a solution hint, flag it as contamination rather
  than using it.

## Working practices (from exercises/EVALUATION.md)

- Work on a branch `asstN/<attempt-name>` from the declared start
  point; the diff against the start point is the submission.
- Commit as you go. History should show the real path, dead ends
  included; never squash the process away.
- Run every test named in an exercise's acceptance section, on 1 and
  4 CPUs, more than once — OS/161 bugs are timing-dependent, and one
  green run proves little. Do not skip a listed test as "covered by"
  another.

## Practical notes for running the system

- Build: `./setup/build-toolchain.sh` then `./setup/configure-os161.sh`
  then `./setup/build-os161.sh`; verify with `./setup/smoke-test.sh`.
- Run tests from `root/`: `../tools/bin/sys161 -X kernel "cmds;q"`.
  Vary RAM/CPUs by editing a copy of `root/sys161.conf`.
- Tests that read from the console (some take seeds or commands on
  stdin) need a real tty: drive them with `setup/interact161.py`.
- Kill stray `sys161` processes after hung or detached runs; they hold
  the disk-image locks and silently block the next run.
- Kernel debugging works: `sys161 -w kernel` creates `.sockets/gdb`;
  attach with `mips-unknown-elf-gdb kernel` +
  `target remote .sockets/gdb`.

## If you are the evaluator

Same contamination rules apply to you. Review the actual diff, rerun
the acceptance tests yourself from clean rebuilds, treat hangs as
failures, and grade against the dimensions in EVALUATION.md. Your
report should let a reader reconstruct what you ran and what happened.
