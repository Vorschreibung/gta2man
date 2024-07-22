import os
import std/[
  net,
  osproc,
  sequtils,
  strutils,
  tables,
  threadpool,
]

import wNim/[
  wApp,
  wButton,
  wFont,
  wFrame,
  wIcon,
  wIpCtrl,
  wMenu,
  wListBox,
  wMenuBar,
  wPanel,
  wStaticBox,
  wStaticText,
  wStatusBar,
  wTextCtrl,
]
import winim
import wAuto

import ./config as cfg
import ./facts as facts
import ./res/resource
import ./validator_name
import ./various
import ./quickstart.nim as quickstart

const
  UseAutoLayout = not defined(legacy)
  Title = "gta2man"

type
  MenuID = enum idLayout1 = wIdUser, idMenuControls, idMenuExit

var settingsProc: osproc.Process

var enterKeyField: string
var enterKeyButton: wButton

let app = App(wSystemDpiAware)
let fgFrame = Frame(title=Title, size=(600, 400))
let bgFrame = Frame(title=Title, size=(600, 400))
let keyFrame = Frame(title="Press a key...", size=(200, 200))
fgFrame.icon = Icon("", 0) # load icon from exe file.

proc resizeFrame() =
  fgFrame.processEvent(Event(fgFrame, msg=wEvent_Size))

let panel1 = Panel(fgFrame)
let panel2 = Panel(bgFrame)
let panelControls = Panel(bgFrame)
let panelOffscreen = Panel(bgFrame)

# @TODO for some reason doesnt work ↓
# var lastPanel: wPanel = panel1

proc fgPanel(panel: wPanel) =
  panel1.reparent(bgFrame)
  panel2.reparent(bgFrame)
  panelOffscreen.reparent(bgFrame)
  panelControls.reparent(bgFrame)
  panel.reparent(fgFrame)
  resizeFrame()

let hostJoinButton = Button(panel2, label="Back / Join")

const style = wAlignCentre or wAlignMiddle or wBorderSimple

let staticBoxPlayerName = StaticBox(panel1, label="Playername")
let staticbox2 = StaticBox(panel1, label="Join")

let playerNameCtrl = TextCtrl(panel1, value=cfg.getName(), style=wBorderSunken)
playerNameCtrl.setFont(Font(pointSize=12, faceName="Consolas"))
playerNameCtrl.setMaxLength(15)

let joinIpCtrl = TextCtrl(panel1, value=cfg.getIp(), style=wBorderSunken)
joinIpCtrl.setFont(Font(pointSize=12, faceName="Consolas"))

let staticBoxOffscreen = StaticBox(panelOffscreen, label="")
let settingsButton = Button(panel1, label="Settings")
let controlsButton = Button(panel1, label="Controls")
let joinButton = Button(panel1, label="Join")
let hostButton = Button(panel1, label="Host")


# Threaded Globals
var shouldStop = false

let staticBoxControls = StaticBox(panelControls, label="Controls")

const controlKeys = cfg.stringToDxCode.keys().toSeq

proc controlAutoComplete(self: wTextCtrl): seq[string] =
  return controlKeys

proc createControlStaticText(label: string): wStaticText =
  result = StaticText(panelControls, label=label, style=wAlignMiddle or wAlignCenter)
proc createControlTextCtrl(): wTextCtrl =
  result = TextCtrl(panelControls, value="", style=wBorderSunken)
  result.enableAutoComplete(controlAutoComplete)


let controlForwardLabel           = createControlStaticText("Forward")
let controlForwardTextCtrl        = createControlTextCtrl()
let controlBackwardLabel          = createControlStaticText("Backward")
let controlBackwardTextCtrl       = createControlTextCtrl()
let controlLeftLabel              = createControlStaticText("Left")
let controlLeftTextCtrl           = createControlTextCtrl()
let controlRightLabel             = createControlStaticText("Right")
let controlRightTextCtrl          = createControlTextCtrl()
let controlAttackLabel            = createControlStaticText("Attack")
let controlAttackTextCtrl         = createControlTextCtrl()
let controlEnterExitLabel         = createControlStaticText("Enter/Exit")
let controlEnterExitTextCtrl      = createControlTextCtrl()
let controlHandbrakeJumpLabel     = createControlStaticText("Handbrake/Jump")
let controlHandbrakeJumpTextCtrl  = createControlTextCtrl()
let controlPreviousWeaponLabel    = createControlStaticText("Previous Weapon")
let controlPreviousWeaponTextCtrl = createControlTextCtrl()
let controlNextWeaponLabel        = createControlStaticText("Next Weapon")
let controlNextWeaponTextCtrl     = createControlTextCtrl()
let controlSpecialLabel           = createControlStaticText("Special")
let controlSpecialTextCtrl        = createControlTextCtrl()
let controlSpecial2Label          = createControlStaticText("Special2")
let controlSpecial2TextCtrl       = createControlTextCtrl()

let backButtonControls = Button(panelControls, label="Back")

let menuBar = MenuBar(fgFrame)
let menu = Menu(menuBar, "File")
menu.append(idMenuExit, "Exit")


proc layout1() =
  panel1.autolayout """
    spacing: 8
    V:|-[staticBoxPlayerName(60)]-[staticbox2]-|
    V:|-[staticBoxOffscreen(60)]-|
    H:|-[staticBoxPlayerName(200)]-[staticBoxOffscreen(200)]-|
    H:|-[staticbox2]-|

    outer: staticBoxPlayerName
    H:|[playerNameCtrl]|
    V:|[playerNameCtrl]|

    outer: staticBoxOffscreen
    V:|[controlsButton]|
    V:|[settingsButton]|
    H:|[settingsButton]-[controlsButton]|


    outer: staticbox2
    V:|{stack1:[joinIpCtrl(joinButton)]-[joinButton]}|
    V:|[hostButton]|
    H:|[stack1(hostButton)]-[hostButton]|
  """

proc layout2() =
  panel2.autolayout """
    spacing: 8
    H:|-[hostJoinButton]-|
    V:|-[hostJoinButton]-|
  """

proc layoutPanelControls() =
  panelControls.autolayout """
    spacing: 8
    H:|-[staticBoxControls]-|
    H:|[backButtonControls]|
    V:|-[staticBoxControls]-[backButtonControls(30)]|

    outer: staticBoxControls
    V:|[controlForwardTextCtrl(20)]-[controlBackwardTextCtrl(20)]-[controlLeftTextCtrl(20)]-[controlRightTextCtrl(20)]-[controlAttackTextCtrl(20)]-[controlEnterExitTextCtrl(20)]-[controlHandbrakeJumpTextCtrl(20)]-[controlPreviousWeaponTextCtrl(20)]-[controlNextWeaponTextCtrl(20)]-[controlSpecialTextCtrl(20)]-[controlSpecial2TextCtrl(20)]|

    V:|[controlForwardLabel(20)]-[controlBackwardLabel(20)]-[controlLeftLabel(20)]-[controlRightLabel(20)]-[controlAttackLabel(20)]-[controlEnterExitLabel(20)]-[controlHandbrakeJumpLabel(20)]-[controlPreviousWeaponLabel(20)]-[controlNextWeaponLabel(20)]-[controlSpecialLabel(20)]-[controlSpecial2Label(20)]|

    H:|[controlForwardLabel]-[controlForwardTextCtrl]|
    H:|[controlBackwardLabel]-[controlBackwardTextCtrl]|
    H:|[controlLeftLabel]-[controlLeftTextCtrl]|
    H:|[controlRightLabel]-[controlRightTextCtrl]|
    H:|[controlAttackLabel]-[controlAttackTextCtrl]|
    H:|[controlEnterExitLabel]-[controlEnterExitTextCtrl]|
    H:|[controlHandbrakeJumpLabel]-[controlHandbrakeJumpTextCtrl]|
    H:|[controlPreviousWeaponLabel]-[controlPreviousWeaponTextCtrl]|
    H:|[controlNextWeaponLabel]-[controlNextWeaponTextCtrl]|
    H:|[controlSpecialLabel]-[controlSpecialTextCtrl]|
    H:|[controlSpecial2Label]-[controlSpecial2TextCtrl]|
  """

proc settingsThread() =
  {.gcsafe.}:
    let settingsProc = osproc.startProcess(facts.gta2ManagerBin, args=[], workingDir=facts.gta2Dir, options={poStdErrToStdout})
    settingsButton.disable()
    discard settingsProc.waitForExit()
    settingsButton.enable()

proc stopThread() =
  {.gcsafe.}:
    shouldStop = true
    joinButton.disable()

    while true:
      if shouldStop == false:
        break
      os.sleep(100)

    joinButton.setLabel("Join")

    joinIpCtrl.enable()
    joinButton.enable()
    hostButton.enable()

proc joinThread() =
  {.gcsafe.}:
    joinButton.setLabel("Stop")
    hostButton.disable()
    joinIpCtrl.disable()

    let gamePath = cfg.config.gamePath
    var gameDir = gamePath
    gameDir.removeSuffix("gta2.exe")

    let ip = joinIpCtrl.getLineText(0)

    let stopped = waitForGta2Host(ip, shouldStop)
    if stopped:
      shouldStop = false
      return

    fgFrame.hide()
    quickstart.setupJoinGame()
    discard sh(cmd=gamePath, args=["-j"], workingDir=gameDir)
    fgFrame.show()

    joinIpCtrl.enable()
    joinButton.enable()
    hostButton.enable()

proc initGui*() =
  block hideConsoleImmediately:
    let consoleWindow = GetConsoleWindow()
    ShowWindow(consoleWindow, SW_HIDE)

  fgFrame.idLayout1 do (): layout1()
  fgFrame.idMenuExit do (): fgFrame.close()

  fgFrame.wEvent_Close do (): quit(0)

  panel1.wEvent_Size do (): layout1()
  panel2.wEvent_Size do (): layout2()
  panelControls.wEvent_Size do (): layoutPanelControls()

  joinIpCtrl.wEvent_Text do(event: wEvent):
    let ipText = joinIpCtrl.getLineText(0)

    var res = ""
    var dotCount = 0
    var nonDotCount = 0
    for c in ipText:
      if c in {'0'..'9'}:
        if nonDotCount >= 3:
          continue
        inc(nonDotCount)
        res.add(c)
      elif c == '.':
        nonDotCount = 0
        if dotCount >= 3:
          continue
        inc(dotCount)
        res.add(c)

    if ipText != res:
      joinIpCtrl.changeValue(res)

    cfg.setIp(res)

  playerNameCtrl.wEvent_Text do():
    let playerName = playerNameCtrl.getLineText(0)
    let validationResult = validatePlayerName(playerName)
    if validationResult.violations > 0:
      playerNameCtrl.setBackgroundColor(wRed)
      playerNameCtrl.setToolTip(computeMsg(validationResult))
    else:
      playerNameCtrl.setToolTip("")
      # reset bg color
      if playerNameCtrl.getBackgroundColor() != wWhite:
        playerNameCtrl.setBackgroundColor(wWhite)

      cfg.setName(playerName)

  joinButton.wEvent_Button do ():
    let label = joinButton.getLabel()
    case label
    of "Join":
      spawn joinThread()
    of "Stop":
      spawn stopThread()
    else:
      raise newException(Exception, "unknown case: " & label)

  hostButton.wEvent_Button do (): fgPanel(panel2)
  hostJoinButton.wEvent_Button do (): fgPanel(panel1)
  controlsButton.wEvent_Button do (): fgPanel(panelControls)
  settingsButton.wEvent_Button do ():
    spawn settingsThread()

  backButtonControls.wEvent_Button do (): fgPanel(panel1) # @TODO fix & use lastPanel

  keyFrame.wEvent_KeyDown do (event: wEvent):
    let keyCode: int32 = event.getKeyCode()
    cfg.writeDword("Control", enterKeyField, keyCode)
    echo keyCode
    keyFrame.hide()

  template setControlEvent(controlTextCtrl: untyped, id: string) =
    controlTextCtrl.changeValue(cfg.dxCodeToString[cfg.readControlKey(id)])

    controlTextCtrl.wEvent_Text do():
      let val = controlTextCtrl.getValue()
      if cfg.stringToDxCode.hasKey(val):
        controlTextCtrl.setToolTip("")
        if controlTextCtrl.getBackgroundColor() != wWhite:
          controlTextCtrl.setBackgroundColor(wWhite)
        cfg.writeControlKey(id, cfg.stringToDxCode[val])
      else:
        controlTextCtrl.setBackgroundColor(wRed)
        controlTextCtrl.setToolTip("Unknown DirectX Scan Code")

  setControlEvent(controlForwardTextCtrl        , "0")
  setControlEvent(controlBackwardTextCtrl       , "1")
  setControlEvent(controlLeftTextCtrl           , "2")
  setControlEvent(controlRightTextCtrl          , "3")
  setControlEvent(controlAttackTextCtrl         , "4")
  setControlEvent(controlEnterExitTextCtrl      , "5")
  setControlEvent(controlHandbrakeJumpTextCtrl  , "6")
  setControlEvent(controlPreviousWeaponTextCtrl , "7")
  setControlEvent(controlNextWeaponTextCtrl     , "8")
  setControlEvent(controlSpecialTextCtrl        , "9")
  setControlEvent(controlSpecial2TextCtrl       , "10")

  layout1()
  fgFrame.center()
  fgFrame.show()
  app.mainLoop()
