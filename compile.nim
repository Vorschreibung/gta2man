import os
import std/exitprocs
import strutils

import wAuto
import wNim
import winim/lean

import ./facts.nim as facts
import ./various.nim

# This is, to be fair a fairly hackish but functional, wrapper around `mis2.exe`
# that provides a comfort CLI to compile `.mis` files to `.scr` files.

var miss2proc: Process

# Makes sure the spawned miss2.exe is closed upon Exception throw or normal
# process exit.
template exitHandler =
  try:
    miss2proc.kill()
  except Exception:
    discard

# Like wAuto.waitAny but specific to our miss2proc
template miss2WaitAny*(condition: untyped, timeout: untyped = 0): untyped =
  block:
    var
      timer = GetTickCount()
      window {.inject.}: wAuto.Window
      found = false

    while not found:
      for win in miss2proc.allWindows():
        window = win
        if condition:
          found = true
          break

      sleep(35)
      if timeout != 0 and (GetTickCount() -% timer) > timeout * 1000:
        window = wAuto.Window 0
        break

    discardable window

proc loadScript(win: Window, path: string) =
  send("!f", window=win)
  send("l", window=win)

  let openWin = miss2WaitAny(window.title == "Open" and window.text.contains("Mission Scripts"))

  # @TODO instead of popping the window up shown and then hiding it, force open
  # the dialogue to be hidden before it is even shown via event hooks:
  # https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowshookexa?redirectedfrom=MSDN
  # openWin.hide()

  echo(">" & path & "<")
  # sleep(9000)
  # send("%TMP%\\o.mis", window=openWin, raw=true)
  send(path, window=openWin, raw=true)
  sleep(100)
  send("{ENTER}", window=openWin)

proc compileScript(win: Window) =
  send("!r", window=win)
  send("{ENTER}", window=win)

# Reads the contents of given listbox and returns 1 if it's contents speak of a
# FATAL ERROR
proc readListBox(hwnd: HWND): int =
  result = 0

  let lb = wNim.ListBox(hwnd)
  let lbCount = lb.getCount()

  for i in 0..<lbCount:
    let text = lb.getText(i)

    # check for static error line
    if text == "*** FATAL ERROR ***":
      result = 1

    echo(text)

proc compile_inner*(misfile_raw: string): int =
  let misfile = os.expandFilename(misfile_raw)
  let misfileParts = misfile.splitFile()
  let scrfile = misfileParts.dir / (misfileParts.name & ".scr")

  let tmpMisfile = os.getEnv("TMP") / "o.mis"
  let tmpScrfile = os.getEnv("TMP") / "o.SCR"

  echoErr("Initializing miss2.exe ...")

  # We always copy the misfile to the local directory of the 'miss2' compiler
  # with a static name and after successful compilation move the produced '.scr'
  # output back afterwards.
  os.copyFile(misfile, tmpMisfile)

  # Clean potential previous scr tmp outputs
  if os.fileExists(tmpScrfile):
    os.removeFile(tmpScrfile)

  # Always kill miss2proc on process exit
  exitprocs.addExitProc(proc() =
    exitHandler()
  )

  # Start 'miss2.exe' in the background
  # @NOTE: miss2.exe will always crash if it's not started in it's own
  #        workingDir, this has nothing to do with us
  miss2proc = wAuto.run(facts.miss2Bin, workingDir=facts.miss2Dir, options={poHide})
  let miss2win = miss2WaitAny(window.title == "GTA2script Compiler V9.6")

  # Find it's main listbox
  var miss2listbox: HWND
  for child in miss2win.getChildren():
    miss2listbox = child.getHandle()

  if miss2listbox == 0:
    echoErr("Couldn't find 'ListBox' child within 'miss2.exe'")
    return 2

  discard readListBox(miss2listbox)

  # Load misfile
  loadScript(miss2win, tmpMisfile)
  echoErr("Loaded: " & misfile)

  # Compile misfile
  echoErr("Compiling ...")
  compileScript(miss2win)
  result = readListBox(miss2listbox)

  # Copy tmp scrfile back on success
  if result == 0:
    os.moveFile(tmpScrfile, scrfile)

  exitHandler()

# Compile a .mis file into an .scr file
proc compile*(misfile_raw: string): int =
  try:
    return compile_inner(misfile_raw)
  except Exception as e:
    exitHandler()
    raise e

when isMainModule:
  quit(compile("./test.mis"))
