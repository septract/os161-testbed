# ASST2: System calls and processes

Make the kernel able to run user programs properly: implement the file
and process system calls. When this works, `p /bin/sh` gives a usable
shell.

Start from: an accepted ASST1 (you will want your locks/CVs).

## What exists already

- The user/kernel crossing: `kern/arch/mips/syscall/syscall.c`
  dispatches on the syscall number with only `reboot` and `__time`
  implemented. `kern/arch/mips/locore/trap.c` handles the trap.
- ELF loading and a way to start one program: `kern/syscall/loadelf.c`,
  `kern/syscall/runprogram.c`, menu command `p`.
- `copyin/copyout/copyinstr` for safely moving data across the
  user/kernel boundary (`kern/include/copyinout.h`) — user-supplied
  pointers must never be dereferenced directly.
- The VFS layer (`vfs_open`, `VOP_READ`, ...) — the file syscalls are
  a thin, correct layer over it.
- `struct proc` exists minimally (`kern/proc/proc.c`).

The authoritative semantics for every call are the in-tree man pages:
`os161/man/syscall/*.html`. Error numbers in `kern/include/kern/errno.h`.

## To implement

File syscalls: `open`, `read`, `write`, `lseek`, `close`, `dup2`,
`chdir`, `__getcwd`. This requires a per-process file descriptor table
and an open-file object (offset, flags, refcount, vnode, lock) that
survives `fork` sharing and `dup2` aliasing. fds 0/1/2 must be
connected to the console (`con:`) at first program start. `lseek` on
the MIPS ABI passes a 64-bit offset in a register pair and returns one
— look at how the ABI docs in `syscall(2)` describe it.

Process syscalls: `getpid`, `fork`, `execv`, `waitpid`, `_exit`. This
requires: a pid table with allocation/reuse rules; parent/child
relationships; `fork` copying the address space (dumbvm has
`as_copy`) and trapframe (child returns 0 via `enter_forked_process`);
`execv` copying argv in and out with proper alignment and an overall
`ARG_MAX` limit; `waitpid` with status encoding per the man page and
correct behavior for exited-but-unwaited children (zombies) and
orphans; `_exit` releasing everything without leaking.

Also: `kill_curthread` in trap.c — a user program that faults must be
killed cleanly (becoming an exit status observable via `waitpid`), not
panic the kernel; and the menu's `p`/`s` should now wait for the
program to finish instead of returning immediately.

## Acceptance

Userland tests, run via `p /testbin/...` (and eventually from `/bin/sh`):

- Basics: `palin` (write to console), `filetest`, `redirect`,
  `tail`, `argtest`, `add` (argv handling)
- Processes: `forktest`, `bigfork`, `multiexec`, `bigexec`, `farm`,
  `hog`, `sty` via shell pipelines if ambitious
- Abuse: `badcall` (every syscall with garbage arguments — nothing may
  panic), `crash` (every way to die — each must kill only that
  process), `forkbomb` (must not take the kernel down; running out of
  pids/memory must fail gracefully)
- `/bin/sh` works interactively: run programs, `exit` works

All on 1 and 4 CPUs. The base kernel tests (`tt1`, `sy1`–`sy4`) must
still pass.
