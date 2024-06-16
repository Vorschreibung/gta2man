# import yaml/serialization, streams

# import std/parsecfg
import std/strformat
import std/[strutils, streams]

import ./utils.nim as utils
import ./parseini.nim

const shippedAssets = [
  "bil.sty",
  "bob_e.gxt",
  "bob_f.gxt",
  "bob_g.gxt",
  "bob_i.gxt",
  "bob_s.gxt",
  "e.gxt",
  "f.gxt",
  "fstyle.sty",
  "g.gxt",
  "i.gxt",
  "s.gxt",
  "ste.sty",
  "wil.sty",
]

type
  MmpFileHost* = ref object
    gameType*: string
    fragLimit*: string
    pointLimit*: string
    timeLimit*: string
    speed*: int
    police*: bool

  MmpFileMap* = ref object
    upDate*: string
    creaDate*: string
    longDesc*: string
    tags*: string
    gta2version*: string
    author*: string
    readme*: string
    wantedlevel*: string
    dusksupport*: bool
    maparea*: string
    playarea*: string
    weapons*: string

  MmpFileMapFiles* = ref object
    description*: string
    gmpFile*: string
    styFile*: string
    scrFile*: string
    gxtFile*: string
    playerCount*: int

  MmpFile* = ref object
    mmpVersion*: int

    mapFiles*: MmpFileMapFiles
    map*: MmpFileMap
    # @TODO client

type
  StreamParser = ref object
    parsedSections: seq[string]
    parsedSectionMapFiles: bool
    parsedSectionMMP: bool
    parsedSectionMap: bool

proc parseMmpFile*(input: string): MmpFile =
  discard
  new(result)

  var strm = newStringStream(input)
  var dict = loadConfig(strm, "[config]")

  result.mmpVersion = utils.parseInt(dict.getSectionValue("MMP", "MMPVersion", "0"))

  new(result.mapFiles)
  result.mapFiles.description = dict.getSectionValue("MapFiles", "Description")
  result.mapFiles.gmpFile = dict.getSectionValue("MapFiles", "GMPFile")
  result.mapFiles.gxtFile = dict.getSectionValue("MapFiles", "GXTFile")
  result.mapFiles.scrFile = dict.getSectionValue("MapFiles", "SCRFile")
  result.mapFiles.styFile = dict.getSectionValue("MapFiles", "STYFile")

  # echo $dict
  # proc loadConfig*(stream: Stream, filename: string = "[stream]"): Config =
  #
proc parseMmpFileStream*(input: Stream): MmpFile =
  new(result)
  new(result.mapFiles)


  var p: CfgParser
  open(p, input, "[stream]")
  defer: close(p)

  var sp = StreamParser()

  var currentSection = ""

  template endSection =
    if currentSection != "":
      sp.parsedSections.add(currentSection)
      currentSection = ""

  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      endSection()
      break
    of cfgSectionStart:
      endSection()

      currentSection = e.section

      # check if we have parsed that section already, as we don't allow
      # duplicate sections
      if currentSection in sp.parsedSections:
        raise newException(Exception, fmt"Already parsed section: {currentSection}")

      # echo "new section: " & e.section
    of cfgKeyValuePair:
      case currentSection
      of "MapFiles":
        case e.key
        of "GMPFile": result.mapFiles.gmpFile = e.value
        of "STYFile": result.mapFiles.styFile = e.value
        of "SCRFile": result.mapFiles.scrFile = e.value
        of "GXTFile": result.mapFiles.gxtFile = e.value
        of "Description": result.mapFiles.description = e.value
        of "PlayerCount": result.mapFiles.playerCount = utils.parseInt(e.value)
        else:
          raise newException(Exception, fmt"unknown key '{e.key}' for section '{currentSection}'")
      of "MMP", "Map", "Host", "Client": # ignore
        discard
      else:
        raise newException(Exception, fmt"unknown section '{currentSection}'")


      # echo "key-value-pair: " & e.key & ": " & e.value
    of cfgError:
      endSection()
      raise newException(Exception, "error while parsing mmpfile: {e.msg}")
      # echo e.msg

  # echo repr sp

proc parseMmpFileStream*(inputStr: string): MmpFile =
  var input = newStringStream(inputStr)
  return parseMmpFileStream(input)
