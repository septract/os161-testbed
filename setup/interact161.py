#!/usr/bin/env python3
"""
Drive sys161 through a pseudo-terminal, answering console prompts.

System/161 only enables console *input* when its stdin is a terminal,
so tests that read from the console (sbrktest 18/21, malloctest 7, an
interactive /bin/sh session) cannot be driven by shell pipes. This
script allocates a pty, runs sys161 on it, and answers prompts from an
expect/send list, echoing everything to stdout.

Usage:
  interact161.py TIMEOUT ['expect' 'send']... -- sys161 [args...]

Example (answer sbrktest's seed prompt; run from root/):
  ../setup/interact161.py 300 'Enter random seed: ' '31337\n' -- \
      ../tools/bin/sys161 -X kernel "p /testbin/sbrktest 18;q"

Expect strings are plain substrings (not regexes), matched in order
against console output; each send string has \\n escapes expanded.
Exits with sys161's exit code, or 124 on overall timeout.
"""
import errno
import os
import pty
import select
import sys
import time


def main():
    if len(sys.argv) < 3 or '--' not in sys.argv:
        sys.stderr.write(__doc__)
        return 2
    timeout = float(sys.argv[1])
    rest = sys.argv[2:]
    sep = rest.index('--')
    pairs = rest[:sep]
    cmd = rest[sep+1:]
    if len(pairs) % 2 != 0:
        sys.stderr.write("interact161: expect/send arguments must "
                         "come in pairs\n")
        return 2
    scripts = [(pairs[i].encode(),
                pairs[i+1].encode().decode('unicode_escape').encode())
               for i in range(0, len(pairs), 2)]

    pid, fd = pty.fork()
    if pid == 0:
        try:
            os.execv(cmd[0], cmd)
        except OSError as e:
            sys.stderr.write("interact161: exec %s: %s\n" % (cmd[0], e))
            os._exit(127)

    deadline = time.time() + timeout
    buf = b''
    step = 0
    status = 124
    exited = False
    try:
        while time.time() < deadline:
            r, _, _ = select.select([fd], [], [], 1.0)
            if fd in r:
                try:
                    data = os.read(fd, 4096)
                except OSError as e:
                    if e.errno == errno.EIO:   # child closed the pty
                        break
                    raise
                if not data:
                    break
                sys.stdout.buffer.write(data)
                sys.stdout.buffer.flush()
                if step < len(scripts):
                    buf += data
                    pat, resp = scripts[step]
                    if pat in buf:
                        os.write(fd, resp)
                        buf = b''
                        step += 1
            wpid, wstatus = os.waitpid(pid, os.WNOHANG)
            if wpid == pid:
                exited = True
                status = os.waitstatus_to_exitcode(wstatus)
                break
        if exited:
            # drain whatever output is still buffered in the pty
            while True:
                r, _, _ = select.select([fd], [], [], 0.5)
                if fd not in r:
                    break
                try:
                    data = os.read(fd, 4096)
                except OSError:
                    break
                if not data:
                    break
                sys.stdout.buffer.write(data)
                sys.stdout.buffer.flush()
    finally:
        if not exited:
            try:
                os.kill(pid, 9)
                os.waitpid(pid, 0)
            except (ProcessLookupError, ChildProcessError):
                pass
        os.close(fd)
    return status


sys.exit(main())
