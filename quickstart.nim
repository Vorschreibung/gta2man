import std/exitprocs
import std/os
import std/osproc
import std/streams
import std/strformat
import std/strutils

import winregistry
import wAuto as wAuto
import wNim
import winim

import ./config.nim as cfg
import ./mmpfile.nim
import ./various.nim

proc tryDelValue(handle: RegHandle, key: string) =
  try: handle.delvalue(key)
  except Exception: discard

proc setupJoinGame*() =
  discard

proc resetQuickstart*() =
  var
    h: RegHandle
    keyName = "HKEY_CURRENT_USER"

  # remove .sty/.gmp/.scr
  try:
    h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Debug", samAll)

    h.tryDelValue("skip_frontend")
    h.tryDelValue("stylename")
    h.tryDelValue("mapname")
    h.tryDelValue("scriptname")
  finally:
    close(h)

  # remove .gxt
  try:
    h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Option", samAll)

    h.writeString("Language", "e")
  finally:
    close(h)

proc multiplayer*(gameDir: string, mmp: MmpFile, players: int) =
  echo "> Starting multiplayer quickstart for: " & $players & " players"
  let gamePath = gameDir / "gta2.exe"

  echoErr("Initializing host ...")

  var procs: seq[wAuto.Process]

  # Makes sure the spawned miss2.exe is closed upon Exception throw or normal
  # process exit.
  template exitHandler =
    for aproc in procs:
      try: aproc.kill()
      except Exception: discard

  # Kill procs on exit also in the case of SIGSEVs
  exitprocs.addExitProc(proc() =
    exitHandler()
  )

  try:
    cfg.setName("P1")
    let hostProc = wAuto.run(gamePath & " -c", workingDir=gameDir)
    procs.add(hostProc)

    let hostWin = wAutoProcWaitAny(hostProc, window.title == "Network GTA2")

    var playerListView: HWND
    var startButton: HWND

    var i = 0
    for win in hostWin.allWindows():
      inc(i)

      # @XXX index is hardcoded by order, we'll see how stable this is, but
      # seems fine for now
      case i
      of 7:  # Player List View
        assert win.getClassName() == "SysListView32"
        playerListView = win.getHandle()
      of 12:  # Start Button
        assert win.getClassName() == "Button"
        startButton = win.getHandle()
      else:
        discard

    block waitForPlayers:
      let handle = playerListView
      let expectedCount = players
      var count = 0

      # spawn clients
      setupJoinGame()
      for i in 1..<players:
        cfg.setName("P" & $(i+1))
        procs.add(wAuto.run(gamePath & " -j", workingDir=gameDir))
        sleep(1000)

      while count < expectedCount:
        count = SendMessage(handle, LVM_GETITEMCOUNT, 0, 0)
        sleep(50)

    echoErr("Got all " & $players & " players, let's go ...")
    # click startButton
    SendMessage(startButton, BM_CLICK, 0, 0)

    # wait for host process to close
    discard hostProc.waitClose()
    echo "> Done"
  finally:
    exitHandler()

proc singleplayer*(gameDir: string, mmp: MmpFile) =
  block: # write registry
    var
      h: RegHandle
      keyName = "HKEY_CURRENT_USER"

    # set .sty/.gmp/.scr & co
    try:
      h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Debug", samAll)

      h.writeInt32("skip_frontend", 0)

      h.writeString("stylename", mmp.mapFiles.styFile)
      h.writeString("mapname", mmp.mapFiles.gmpFile)
      h.writeString("scriptName", mmp.mapFiles.scrFile)
    finally:
      close(h)

    # set .gxt
    try:
      h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Option", samAll)

      var gxtFile = mmp.mapFiles.gxtFile
      removeSuffix(gxtFile, ".gxt")
      h.writeString("Language", gxtFile)
    finally:
      close(h)

    discard

  block: # start the game
    echo fmt"> running: {gameDir}"
    setCurrentDir(gameDir)
    discard execCmd(gameDir / "gta2.exe")

proc quickstart*(mmpfile: string, players: int = 1) =
  let strm = newFileStream(mmpfile, fmRead)
  defer: close(strm)
  let mmpfileAbs = os.absolutePath(mmpfile)
  let mmp = parseMmpFileStream(strm, mmpfileAbs)

  mmp.validate()

  let gamePath = cfg.config.gamepath
  let gameDir = parentDir(gamePath)

  mmp.copyFilesToDir(gameDir)

  if players == 1:
    singleplayer(gameDir, mmp)
  else:
    multiplayer(gameDir, mmp, players)
