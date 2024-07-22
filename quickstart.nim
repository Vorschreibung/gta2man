import std/exitprocs
import std/os
import std/osproc
import std/streams
import std/strformat
import std/strutils
# import winlean

import winregistry
import wAuto as wAuto
# import wNim as wNim
import wNim
import winim

# from wNim import SendMessage
import ./config.nim as cfg
import ./mmpfile.nim
import ./various.nim

# proc regDeleteValueRaw*(handle: RegHandle, lpValueName: WideCString): LONG
#   {.stdcall, dynlib: "advapi32", importc: "RegDeleteValueW".}

# proc regDeleteValue*(handle: RegHandle, lpValueName: string) =
#   discard regDeleteValueRaw(handle, newWideCString(lpValueName))

proc tryDelValue(handle: RegHandle, key: string) =
  try: handle.delvalue(key)
  except Exception: discard

proc setupJoinGame*() =
  discard
  # var
  #   h: RegHandle
  #   keyName = "HKEY_CURRENT_USER"

  # # remove .sty/.gmp/.scr
  # try:
  #   h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Network", samAll)
  #   h.writeInt32("show_player_names", 0)
  # finally:
  #   close(h)

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

    # h.delSubkey("stylename", samWow32)
    # h.writeString("stylename", "ste.sty")
    # h.writeString("mapname", "")
    # h.writeString("scriptname", "")

    # for name in h.enumValueNames():
    #   echo name
    # echo "values " & $h.countValues()
    # echo "countSubkeys " & $h.countSubkeys()

    # h.delSubkey("skip_frontend")
    # h.writeInt32("skip_frontend", 0)

    # h.delTree("stylename")
    # h.delTree("mapname")
    # h.delTree("scriptName")
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
    discard
    # wAuto.shellExecute(gamePath, parameters="-c", workingDir=gameDir)
    # let hostProc = wAuto.run(gamePath & " -c", workingDir=gameDir, options={poHide})
    cfg.setName("P1")
    let hostProc = wAuto.run(gamePath & " -c", workingDir=gameDir)
    procs.add(hostProc)

    let hostWin = wAutoProcWaitAny(hostProc, window.title == "Network GTA2")
    # echo "Got the window baby!"
    # sleep(1000)
    # hostWin.hide()
    # echo "Contents:"

    var playerListView: HWND
    var startButton: HWND

    var i = 0
    for win in hostWin.allWindows():
      inc(i)
      # if win.getClassName() == "ListBox":
      #   echo "> HIDE!"
      #   win.hide()

      # echo $win
      # echo "title     " & win.getTitle()
      # echo "classname " & win.getClassName()

      # let hostWinPos = hostWin.getPosition()
      # let winPos = win.getPosition()
      # let winRelPos: wPoint = (x: (winPos.x - hostWinPos.x), y: (winPos.y - hostWinPos.y))
      # echo "pos       " & $winRelPos


      # var pt: winim.POINT
      # MapWindowPoints(win.handle, hostWin.handle, &pt, 1)
      # echo "mapwinpoi " & $pt

      # let id = $pt & ":" & $win.getSize() & ":" & $win.getClassName()
      # echo id
      # echo "↑ " & win.getText()

      # let hideId = [
      #   # "(x: 7, y: 7):(width: 206, height: 17):SysHeader32",
      #   "(x: 7, y: 7):(width: 210, height: 130):SysListView32"
      # ]

      # @XXX index is hardcoded by order, we'll see how stable this is, but
      # seems fine for now
      case i
      of 7:  # Player List View
        assert win.getClassName() == "SysListView32"
        playerListView = win.getHandle()
      of 12:  # Start Button
        assert win.getClassName() == "Button"
        startButton = win.getHandle()
        # startButton.init(win.getHandle())
        # startButton = wNim.Button(win.getHandle())
        # startButton = wButton.init(win.getHandle())
      else:
        discard

      # if id in hideId:
      # if i == 79999999999:
        # win.hide()


          # echo "count: " & $count

        # var lvi: LVITEM
        # for j in 0..count:
        #   # discard SendMessage(handle, LVM_GETITEMTEXT, j, LPARAM(unsafeAddr(lvi)))
        #   SendMessage(handle, LVM_GETITEMTEXT, j, &lvi)
        #   echo lvi.pszText
        #   echo $lvi


        # var lc: wListCtrl
        # lc.init(win.handle)
        # # let lb = wNim.ListCtrl(win.handle)
        # let lbCount = lc.getItemCount()

        # for i in 0..<lbCount:
        #   let text = lc.getItemText(i, 0)
        #   echo(text)

      # case $pt
      # of
      #   "",
      #   "EMPTY":
      #     win.hide()

      # win.hide()

    block waitForPlayers:
      # echo "> AYO"

      let handle = playerListView
      # let count = SendMessage(handle, LVM_GETITEMCOUNT, 0, 0)
      let expectedCount = players
      var count = 0

      # spawn clients
      setupJoinGame()
      for i in 1..<players:
        cfg.setName("P" & $(i+1))
        procs.add(wAuto.run(gamePath & " -j", workingDir=gameDir))
        sleep(1000)

      while count < expectedCount:
        # echo "count: " & $count & " expectedCount: " & $expectedCount
        count = SendMessage(handle, LVM_GETITEMCOUNT, 0, 0)
        sleep(50)

      # echo "> READY"

    echoErr("Got all " & $players & " players, let's go ...")
    # click startButton
    SendMessage(startButton, BM_CLICK, 0, 0)

    # sleep(20000)
    # wait for host process to close
    discard hostProc.waitClose()
    echo "> Done"
    # let miss2win = wAuto.waitAny(window.title == "GTA2script Compiler V9.6")
    # wAuto.run()
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
    # except OSError:
      # echo "err: ", getCurrentExceptionMsg()
    finally:
      close(h)

    # set .gxt
    try:
      h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Option", samAll)

      var gxtFile = mmp.mapFiles.gxtFile
      removeSuffix(gxtFile, ".gxt")
      h.writeString("Language", gxtFile)
      # h.writeString("mapname", mmp.mapFiles.gmpFile)
      # h.writeString("scriptName", mmp.mapFiles.scrFile)
    # except OSError:
      # echo "err: ", getCurrentExceptionMsg()
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

  # let mapDir = parentDir(mmpfile)

  mmp.copyFilesToDir(gameDir)

  if players == 1:
    singleplayer(gameDir, mmp)
  else:
    multiplayer(gameDir, mmp, players)
