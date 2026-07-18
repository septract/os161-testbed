# Bug report: System/161 2.0.8 heap buffer overflow in per-CPU CRAM (breaks multiprocessor boot on some hosts)

Draft prepared 2026-07-18 for submission to the System/161 maintainers
(os161.org). Self-contained; the one-line patch is at the bottom.

---

**Subject:** sys161 2.0.8: heap buffer overflow in LAMEbus per-CPU CRAM
(LAMEBUS_CRAM_SIZE=128 vs. 256-byte decoded window); breaks cpus>=2 boot
on some hosts, deterministic under AddressSanitizer

## Summary

System/161 2.0.8 allocates each CPU's CRAM scratch area at 128 bytes
(`LAMEBUS_CRAM_SIZE`, bus/busdefs.h:39) but decodes a 256-byte guest
register window over it (`LBC_CRAM_START` 0x300 .. `LBC_CRAM_END` 0x400,
bus/lamebus.c:94-95), and `lamebus_controller_{fetch,store}_cpu` index
the buffer with any offset in that window — up to byte 255 of a 128-byte
`malloc()` block.

The overflow is exercised by *normal multiprocessor boot*: `set_cpue()`
starts each secondary CPU with its boot stack pointer at the *end* of
its CRAM window (`cramoffset ... + LBC_CRAM_END`, bus/lamebus.c:276-281),
so the secondary's very first stack pushes (the 24-byte
`cpu_start_secondary` frame that OS/161's own start.S establishes) land
in the second 128 bytes — past the end of the heap allocation. Every
`cpus>=2` boot of the stock OS/161 kernel writes ~24 bytes of guest
stack data into adjacent host heap memory.

## Impact

What gets corrupted depends on the host allocator's heap layout, so the
bug has presumably been latent for years on the usual x86/Linux hosts.
On macOS/arm64 (Apple clang build) the adjacent allocation is the
simulator's own MIPS CPU register array: with `cpus=2` or `cpus=3` the
boot CPU's simulated `$sp` is zeroed mid-boot and the guest kernel
wedges in an exception storm before the `cpu1:` banner prints —
`cpus=1` and `cpus=4` happen to land harmlessly. (This was originally
mistaken for a guest kernel bug; it reproduces with a pristine
unmodified OS/161 2.0.3 kernel.)

## Reproduction (deterministic, any host)

Build sys161 2.0.8 with AddressSanitizer and boot any OS/161 kernel
with `31 mainboard ramsize=2M cpus=2`:

    ./configure mipseb
    # add -fsanitize=address -g to CFLAGS and LIBS in build-sys161/defs.mk
    make
    ./sys161 -X kernel "q"

ASan reports, at the moment the second CPU starts:

    ERROR: AddressSanitizer: heap-buffer-overflow
    WRITE of size 4 at 0x...37c thread T0
      #0 lamebus_controller_store
      #1 domem
      #2 cpu_cycles
    0x...37c is located 124 bytes after 128-byte region
    allocated by thread T0 here:
      #1 domalloc
      #2 lamebus_commonmainboard_init

(The faulting offset — 124 bytes past a 128-byte region = window byte
252 — is `sw ra, 20(sp)` of the secondary's first stack frame.)

Without ASan, on macOS/arm64 the symptom is: `cpus=2` or `cpus=3`
hangs after the `cpu0:` banner; `trace161 -tx` shows the *boot* CPU
suddenly faulting with `sp=0` immediately after the kernel's CPUE
write.

## Root cause

`bus/busdefs.h:39`:

    #define LAMEBUS_CRAM_SIZE            128

versus `bus/lamebus.c:94-95`:

    #define LBC_CRAM_START		0x300
    #define LBC_CRAM_END		0x400

The window is 0x100 = 256 bytes; the backing buffer
(`cpus[i].cpu_cram = domalloc(LAMEBUS_CRAM_SIZE)`, bus/lamebus.c:604)
is half that. The fetch/store paths bound-check against the *window*
(`offset >= LBC_CRAM_START && offset < LBC_CRAM_END`) and then index
`cpu_cram + (offset - LBC_CRAM_START)` with no check against the
buffer size. A comment at the struct field (bus/lamebus.c:54) suggests
the allocation was once an inline array and was converted to malloc
("This used to be cpu_cram[LAMEBUS_CRAM_SIZE], see dev_disk.c"), which
may be when the size and the window drifted apart.

## Fix

Size the buffer to match the decoded window:

    --- a/bus/busdefs.h
    +++ b/bus/busdefs.h
    @@ -36,4 +36,4 @@
     /*
      * Size of per-cpu scratch area
      */
    -#define LAMEBUS_CRAM_SIZE            128
    +#define LAMEBUS_CRAM_SIZE            256

(Equivalently, LBC_CRAM_START could become 0x380 to shrink the window
to 128 bytes, but the guest-visible LAMEbus spec — and OS/161's
`LB_CTLCPU_SIZE`-derived stack placement — treats 0x300-0x400 as CRAM,
so growing the buffer preserves the documented layout.)

Verified after the fix: ASan-clean full boots; `cpus=2` and `cpus=3`
(previously hanging on macOS/arm64) boot and run the OS/161 test
battery to clean shutdown; `cpus=1`/`cpus=4` unchanged.

## Environment where observed

- System/161 2.0.8 built from the os161.org tarball with Apple clang
  (CommandLineTools, macOS 26, arm64 / Apple Silicon)
- Guest: OS/161 2.0.3 (also reproduced with an unmodified base kernel)
- Also confirmed via source instrumentation: the corrupted host memory
  was `mycpus[0].r[29]` (the boot CPU's simulated stack pointer), and
  the corrupting writes were the secondary's `htonl()`-converted stack
  words arriving through `lamebus_controller_store_cpu`.
