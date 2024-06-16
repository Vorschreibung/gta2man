import os, strformat, sequtils, sugar, strutils, osproc
import std/marshal
import std/unittest
import std/jsonutils
import std/json

import ../validator_name
import ../mmpfile.nim
import ../utils.nim

var lastException: ref Exception

template toBeauJson(a: untyped): string =
  json.pretty(toJson(a))

template mustRaise(actions: untyped): untyped =
  var didRaise = true
  try:
    actions
    didRaise = false
  except Exception as e:
    lastException = e

  if not didRaise:
    raise newException(Exception, "expected block to raise, but did not raise")

proc testValidatePlayerName =
  var res: ValidatePlayerNameResult

  # basic
  res = validatePlayerName("foo( ! )bar")
  check res == ValidatePlayerNameResult(
    violations: 0,
  )

  # len just too long
  res = validatePlayerName("1234567890123456")
  check res == ValidatePlayerNameResult(
    violations: 1,
    lenViolation: true,
    actualLen: 16,
    allowedLen: 15,
  )

  # len just right
  res = validatePlayerName("123456789012345")
  check res == ValidatePlayerNameResult(
    violations: 0,
  )

  # wrong chars
  res = validatePlayerName("@#[]<>=")
  check res == ValidatePlayerNameResult(
    violations: 1,
    disallowedCharacters: @['@', '#', '[', ']', '<', '>', '='],
  )

proc testParseMmpFile =
  var mmp: MmpFile
  mmp = parseMmpFileStream(
  """
[MapFiles]
GMPFile = map-bernaar-map.gmp
STYFile = ste.sty
SCRFile = map-bernaar-map.scr
Description = Bernaar's Map

GXTFile = map-bernaar-map.gxt

[MMP]
MMPVersion = 3

[Map]
UpDate = 2011-05-12
CreaDate = 2000-12-19
LongDesc = It is a real frag map, with stunts and jumps in it. It has the same size as Hidden Surprise.
Tags = city
GTA2Version = 11.39
Author = Bernaar
Readme = Ber_Read me.txt
DuskSupport = false
WantedLevel = 1
MapArea = 102 101 188 204
PlayArea = 105 107 185 201

[Host]

[Client]
show_player_names = true
lighting = noon
  """
  )
  check toBeauJson(mmp) == """{
  "mmpVersion": 0,
  "mapFiles": {
    "description": "Bernaar's Map",
    "gmpFile": "map-bernaar-map.gmp",
    "styFile": "ste.sty",
    "scrFile": "map-bernaar-map.scr",
    "gxtFile": "map-bernaar-map.gxt",
    "playerCount": 0
  },
  "map": null
}"""

  # assert no duplicate sections
  mustRaise:
    mmp = parseMmpFileStream(
    """
  [MapFiles]
  GMPFile = map-bernaar-map.gmp
  [MapFiles]
  GMPFile = map-bernaar-map.gmp
    """
    )
  check lastException.msg == "Already parsed section: MapFiles"

proc testUtils =
  check utils.parseInt("10241024") == 10241024
  check utils.parseInt("-2") == -2

proc main =
  os.setCurrentDir(os.getAppDir())

  testValidatePlayerName()
  testParseMmpFile()
  testUtils()

when isMainModule:
  main()
