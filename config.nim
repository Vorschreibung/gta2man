import std/[
  os,
  streams,
  strformat,
  tables,
]

import winregistry
import winim
import yaml/loading, yaml/dumping

type
  Gta2ManConfig* = ref object
    gamePath*: string

let configPath* = os.joinPath(os.getAppDir(), "gta2man-cfg.yaml")
var config*: Gta2ManConfig

proc initConfig* =
  new(config)
  if not os.fileExists(configPath):
    let f = open(configPath, fmWrite)
    let strm = newFileStream(f)
    defer: strm.close()

    var dumper = Dumper()
    # dumper.dump(config, strm, tagStyle=tsNone, handles=(@[]))
    dumper.dump(config, strm)
  else:
    # let f = open(configPath, fmRead)
    # let strm = newFileStream(f)
    # defer: strm.close()

    let contents = syncio.readFile(configPath)

    load(contents, config)

proc getName*(): string =
  var
    h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\Network", samAll)

    return h.readString("PlayerName")
  except:
    return "Unknown"
  finally:
    close(h)

proc setName*(name: string) =
  var
    h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\Network", samAll)

    h.writeString("PlayerName", name)
  finally:
    close(h)

proc getIp*(): string =
  var
    h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\Network", samAll)

    var res = ""

    for ch in h.readBinary("TCPIPAddrStringd"):
      if ch == 0: continue
      add(res, char(ch))

    return res
  except:
    return "127.0.0.1"
  finally:
    close(h)

proc setIp*(ip: string) =
  var
    h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\Network", samAll)

    var ipContents: seq[byte]

    # write weird IP bytes (guessed)
    for c in ip:
      ipContents.add(byte(ord(c)))
      ipContents.add(0)
    ipContents.add(0)
    ipContents.add(0)

    h.writeBinary("TCPIPAddrStringd", ipContents)
    h.writeInt32("TCPIPAddrStrings", int32(ipContents.len))
    echo "wrote " & ip
  finally:
    close(h)

proc readDword*(key: string, field: string): int32 =
  var h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\{key}", samAll)
    return h.readInt32(field)
  finally:
    close(h)

proc writeDword*(key: string, field: string, value: int32) =
  var h: RegHandle

  try:
    h = createOrOpen(fmt"HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2\{key}", samAll)
    h.writeInt32(field, value)
  finally:
    close(h)

# @XXX table copied twice {{{
const dxCodeToString* = {
  1   : "Escape",
  2   : "1",
  3   : "2",
  4   : "3",
  6   : "5",
  8   : "7",
  10  : "9",
  11  : "0",
  12  : "Minus",
  13  : "Equals",
  14  : "Backspace",
  15  : "Tab",
  16  : "Q",
  17  : "W",
  18  : "E",
  19  : "R",
  20  : "T",
  21  : "Y",
  22  : "U",
  23  : "I",
  24  : "O",
  25  : "P",
  26  : "Left Bracket",
  27  : "Right Bracket",
  28  : "Enter",
  29  : "Left Control",
  30  : "A",
  31  : "S",
  32  : "D",
  33  : "F",
  34  : "G",
  35  : "H",
  36  : "J",
  37  : "K",
  38  : "L",
  39  : "Semicolon",
  40  : "Apostrophe",
  41  : "Tilde (~)",
  42  : "Left Shift",
  43  : "Back Slash",
  44  : "Z",
  45  : "X",
  46  : "C",
  47  : "V",
  48  : "B",
  49  : "N",
  50  : "M",
  51  : "Comma",
  52  : "Period",
  53  : "Forward Slash",
  54  : "Right Shift",
  55  : "Numpad *",
  56  : "Left Alt",
  57  : "Spacebar",
  58  : "Caps Lock",
  59  : "F1",
  60  : "F2",
  61  : "F3",
  62  : "F4",
  63  : "F5",
  64  : "F6",
  65  : "F7",
  66  : "F8",
  67  : "F9",
  68  : "F10",
  69  : "Num Lock",
  70  : "Scroll Lock",
  71  : "Numpad 7",
  72  : "Numpad 8",
  73  : "Numpad 9",
  74  : "Numpad -",
  75  : "Numpad 4",
  76  : "Numpad 5",
  77  : "Numpad 6",
  78  : "Numpad +",
  79  : "Numpad 1",
  80  : "Numpad 2",
  81  : "Numpad 3",
  82  : "Numpad 0",
  83  : "Numpad .",
  87  : "F11",
  88  : "F12",
  156 : "Numpad Enter",
  157 : "Right Control",
  181 : "Numpad /",
  184 : "Right Alt",
  199 : "Home",
  200 : "Up Arrow",
  201 : "Page Up",
  203 : "Left Arrow",
  205 : "Right Arrow",
  207 : "End",
  208 : "Down Arrow",
  209 : "Page Down",
  210 : "Insert",
  211 : "Delete",
  256 : "Left Mouse Button",
  257 : "Right Mouse Button",
  258 : "Middle Mouse/Wheel",
  259 : "Mouse Button 3",
  260 : "Mouse Button 4",
  261 : "Mouse Button 5",
  262 : "Mouse Button 6",
  263 : "Mouse Button 7",
  264 : "Mouse Wheel Up",
  265 : "Mouse Wheel Down",
}.toTable

const stringToDxCode* = {
  "Escape"             : 1,
  "1"                  : 2,
  "2"                  : 3,
  "3"                  : 4,
  "5"                  : 6,
  "7"                  : 8,
  "9"                  : 10,
  "0"                  : 11,
  "Minus"              : 12,
  "Equals"             : 13,
  "Backspace"          : 14,
  "Tab"                : 15,
  "Q"                  : 16,
  "W"                  : 17,
  "E"                  : 18,
  "R"                  : 19,
  "T"                  : 20,
  "Y"                  : 21,
  "U"                  : 22,
  "I"                  : 23,
  "O"                  : 24,
  "P"                  : 25,
  "Left Bracket"       : 26,
  "Right Bracket"      : 27,
  "Enter"              : 28,
  "Left Control"       : 29,
  "A"                  : 30,
  "S"                  : 31,
  "D"                  : 32,
  "F"                  : 33,
  "G"                  : 34,
  "H"                  : 35,
  "J"                  : 36,
  "K"                  : 37,
  "L"                  : 38,
  "Semicolon"          : 39,
  "Apostrophe"         : 40,
  "Tilde (~)"          : 41,
  "Left Shift"         : 42,
  "Back Slash"         : 43,
  "Z"                  : 44,
  "X"                  : 45,
  "C"                  : 46,
  "V"                  : 47,
  "B"                  : 48,
  "N"                  : 49,
  "M"                  : 50,
  "Comma"              : 51,
  "Period"             : 52,
  "Forward Slash"      : 53,
  "Right Shift"        : 54,
  "Numpad *"           : 55,
  "Left Alt"           : 56,
  "Spacebar"           : 57,
  "Caps Lock"          : 58,
  "F1"                 : 59,
  "F2"                 : 60,
  "F3"                 : 61,
  "F4"                 : 62,
  "F5"                 : 63,
  "F6"                 : 64,
  "F7"                 : 65,
  "F8"                 : 66,
  "F9"                 : 67,
  "F10"                : 68,
  "Num Lock"           : 69,
  "Scroll Lock"        : 70,
  "Numpad 7"           : 71,
  "Numpad 8"           : 72,
  "Numpad 9"           : 73,
  "Numpad -"           : 74,
  "Numpad 4"           : 75,
  "Numpad 5"           : 76,
  "Numpad 6"           : 77,
  "Numpad +"           : 78,
  "Numpad 1"           : 79,
  "Numpad 2"           : 80,
  "Numpad 3"           : 81,
  "Numpad 0"           : 82,
  "Numpad ."           : 83,
  "F11"                : 87,
  "F12"                : 88,
  "Numpad Enter"       : 156,
  "Right Control"      : 157,
  "Numpad /"           : 181,
  "Right Alt"          : 184,
  "Home"               : 199,
  "Up Arrow"           : 200,
  "Page Up"            : 201,
  "Left Arrow"         : 203,
  "Right Arrow"        : 205,
  "End"                : 207,
  "Down Arrow"         : 208,
  "Page Down"          : 209,
  "Insert"             : 210,
  "Delete"             : 211,
  "Left Mouse Button"  : 256,
  "Right Mouse Button" : 257,
  "Middle Mouse/Wheel" : 258,
  "Mouse Button 3"     : 259,
  "Mouse Button 4"     : 260,
  "Mouse Button 5"     : 261,
  "Mouse Button 6"     : 262,
  "Mouse Button 7"     : 263,
  "Mouse Wheel Up"     : 264,
  "Mouse Wheel Down"   : 265,
}.toTable
# }}}

proc readControlKey*(id: string): int =
  return readDword("Control", id)

proc writeControlKey*(id: string, code: int32) =
  echo fmt"wrote {code}"
  writeDword("Control", id, code)

proc readIpAddressFromWinapi*(): string =
  var adapterInfo: IP_ADAPTER_INFO
  var adapterInfoP: PIP_ADAPTER_INFO = addr(adapterInfo)
  var size = int32(sizeof(adapterInfo))
  var sizeP: PULONG = addr(size)
  discard GetAdaptersInfo(adapterInfoP, sizeP)
  var scandal = GetAdaptersInfo(adapterInfoP, sizeP)
  echo repr scandal
  echo repr adapterInfo
  echo repr adapterInfoP

  # var capacity: int32 = 256
  # var res: LPWSTR = newString(capacity)
  # proc GetAdaptersInfo*(AdapterInfo: PIP_ADAPTER_INFO, SizePointer: PULONG): ULONG {.winapi, stdcall, dynlib: "iphlpapi", importc.}
  return "TODO"
