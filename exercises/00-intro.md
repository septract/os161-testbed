# ASST0: Getting started

Goal: a working environment and enough familiarity with the code base
and tools to do real work. Nothing is implemented in this exercise.

## Tasks

1. Build the toolchain and the system; boot it (see repo README
   quickstart). `./setup/smoke-test.sh` must pass.
2. Run the base kernel tests from the menu (`?t` lists them):
   `tt1`, `tt2`, `tt3` (threads), `km1`, `km2` (kmalloc), `sy1`
   (semaphores), `at`, `bt`, `tlt` (data structures).
3. Boot variants: try `cpus=4` in `root/sys161.conf` and rerun `tt1`;
   try a larger/smaller `ramsize`.
4. Read the source tree and be able to answer, at minimum:
   - Where does execution enter the kernel on a trap? Trace the path
     from the exception vector to `mips_trap` to a syscall or
     interrupt handler and back out.
   - What happens between `start.S` and `kmain`? What is set up before
     the first C code runs?
   - How does a thread get created and how does context switch work
     (`thread_fork`, `thread_switch`, `switchframe_switch`)?
   - What does the "dumbvm" actually do? Why can't it run `GENERIC`?
   - How does the build work: what do `configure`, `defs.mk`,
     `kern/conf/config`, and `bmake install` each contribute?
5. Debugger check: boot with `sys161 -w -p 16161 kernel` (outside any
   sandbox that blocks sockets), attach with
   `mips-unknown-elf-gdb kernel` / `target remote :16161`, set a
   breakpoint on `menu`, continue, and step through a menu command.

## Where things are

```
os161/kern/arch/mips/       machine-dependent: traps, TLB, context switch
os161/kern/arch/sys161/     platform glue: LAMEbus, start.S
os161/kern/main/            kmain, menu
os161/kern/thread/          threads, scheduling, synch primitives (ASST1 lives here)
os161/kern/syscall/         syscall layer (ASST2 lives here)
os161/kern/vm/              kmalloc + dumbvm (ASST3 replaces this)
os161/kern/vfs/ + fs/       VFS layer, sfs, emufs
os161/userland/             libc, /bin, /sbin, /testbin
os161/man/                  the OS/161 manual: syscalls, libc, programs
```

## Done when

Smoke test passes, the questions above can be answered concretely with
file/function references, and a gdb session against the running kernel
works.
