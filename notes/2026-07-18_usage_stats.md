# Informal baseline: cost of the first full run (buildout + 3 assignments)

An informal baseline for future attempts against this testbed to
compare themselves to. One data point, no controls — treat it as an
anchor, not a benchmark.

Usage stats reported by Claude Code at the end of the run (2026-07-18).
Scope: everything — toolchain port/buildout, exercise authoring, ASST1
+ ASST2 + ASST3 solutions with instructor assessments and review-fix
cycles, the sys161 CRAM-overflow diagnosis, the spec audit (which
caught the execv bug), and publishing.

    Total cost:            $389.70
    Total duration (API):  4h 15m 2s
    Total duration (wall): 1d 1h 26m
    Total code changes:    5956 lines added, 312 lines removed

    Usage by model:
      claude-haiku-4-5:  94.7k in, 5.7k out, 2 web searches      ($0.14)
      claude-fable-5:    12.6k in, 688.0k out,
                         283.8M cache read, 2.2M cache write     ($362.69)
      claude-opus-4-8:   411 in, 220.8k out,
                         27.7M cache read, 1.2M cache write      ($26.87)

Observations:

- Cost is dominated by the primary model's output tokens and cache
  reads — the signature of a very long agentic session with heavy
  tool use over a large tree, not of bulk code generation.
- API time (4.25h) vs wall time (25.4h): most wall-clock went to
  sys161 simulation runs, toolchain/kernel builds, and gaps between
  human check-ins — the model was computing for about a sixth of it.
- The secondary Opus usage is background/agent work (assessment runs
  and auxiliary sessions).
- ~5.9k lines added spans the whole repo: setup scripts, exercise
  specs, three assignment solutions, kernel test code, and notes.
  For scale, ops-class estimates ~2.9k non-comment solution lines for
  ASST1+ASST2 alone, with ASST3 on top.
- For comparison, the assignments are typically a semester-long
  sequence for a student pair, on an environment the course provides
  rather than one built from source.

Caveats: one run, one model family, no controls; the run included
substantial non-assignment work (the environment itself, the simulator
bug, publishing). Per-assignment cost attribution isn't recoverable
from these aggregates.

Future attempts: record your own end-of-run stats in a dated note like
this one (cost, API/wall durations, lines changed, model mix, and what
the run included), so comparisons stay honest about scope.
