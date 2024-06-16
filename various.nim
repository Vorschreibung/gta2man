import osproc
import streams
import strtabs

# mostly copied from https://github.com/nim-lang/Nim/blob/version-1-6/lib/pure/osproc.nim#L1575 but supports passing args and skips shell
proc sh*(
    cmd: string,
    args: openArray[string],
    env: StringTableRef = nil,
    workingDir = "",
    input = "",
  ): tuple[
    output: string,
    exitCode: int,
  ] {.tags: [ExecIOEffect, ReadIOEffect, RootEffect], gcsafe.} =

  var p = startProcess(
    cmd,
    args = args,
    options = {poStdErrToStdOut, poUsePath},
    workingDir = workingDir,
    env = env,
  )
  var outp = outputStream(p)

  if input.len > 0:
    # There is no way to provide input for the child process
    # anymore. Closing it will create EOF on stdin instead of eternal
    # blocking.
    # Writing in chunks would require a selectors (eg kqueue/epoll) to avoid
    # blocking on io.
    inputStream(p).write(input)
  close inputStream(p)

  result = ("", -1)
  var line = newStringOfCap(120)
  while true:
    if outp.readLine(line):
      result[0].add(line)
      result[0].add("\n")
    else:
      result[1] = peekExitCode(p)
      if result[1] != -1: break
  close(p)

