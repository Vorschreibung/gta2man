import checksums/md5
import std/net
import std/os
import std/osproc
import std/streams
import std/strtabs

import wAuto as wAuto
from winim/lean import GetTickCount, discardable

proc echoErr*(msg: string) =
  writeLine(stderr, "> " & msg)
  flushFile(stderr)

proc die*(msg: string) =
  echoErr(msg)
  quit(1)

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

proc md5FromFile(path: string): MD5Digest =
  discard

proc waitForGta2Host*(ip: string, shouldStop: var bool): bool =
  let socket = newSocket()
  while true:
    try:
      if shouldStop:
        return true

      socket.connect(ip, Port(2300), timeout=400)
      socket.close()
      return false
    except TimeoutError:
      discard # noop
    except Exception:
      discard
    os.sleep(200)

template wAutoProcWaitAny*(process: wAuto.Process, condition: untyped, timeout: untyped = 0): untyped =
  block:
    var
      timer = GetTickCount()
      window {.inject.}: wAuto.Window
      found = false

    while not found:
      for win in process.allWindows():
        window = win
        if condition:
          found = true
          break

      sleep(35)
      if timeout != 0 and (GetTickCount() -% timer) > timeout * 1000:
        window = wAuto.Window 0
        break

    discardable window

template SendMessage*(hwnd, msg, wparam, lparam: typed): untyped =
  SendMessage(hwnd, msg, cast[WPARAM](wparam), cast[LPARAM](lparam))
