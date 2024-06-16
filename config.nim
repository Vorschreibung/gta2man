import std/strformat
import std/marshal
import std/os

import yaml/serialization, streams, yaml/presenter

type
  Gta2ManConfig* = ref object
    gamePath*: string

let configPath* = os.joinPath(os.getAppDir(), "gta2man-cfg.yaml")
var config*: Gta2ManConfig

proc initConfig* =
  new(config)
  if not os.fileExists(configPath):
    # config.gamePath = "FUCKER"
    let f = open(configPath, fmWrite)
    let strm = newFileStream(f)
    defer: strm.close()

    # dump(config, strm, tagStyle=tsNone, handles=(@[]))
    dump(config, strm)
  else:
    # let f = open(configPath, fmRead)
    # let strm = newFileStream(f)
    # defer: strm.close()

    let contents = io.readFile(configPath)
    # echo contents

    # var ficker: Gta2ManConfig
    # new(ficker)
    # echo "GEH OIDA"
    load(contents, config)
    # echo repr ficker
    # config = ficker

    # echo "GNEHHHHHHHHh"
    # echo repr config


# const allowedCharacters* =
#   "abcdefghijklmnopqrstuvwxyz" &
#   "ABCDEFGHIJKLMNOPQRSTUVWXYZ" &
#   "0123456789" &
#   """!"$%&'()*+,-./?~:;""" &
#   "\t "

# type
#   SetNameException* = ref object of Exception
#     lenViolation*: bool
#     actualLen*: int
#     allowedLen*: int
#     disallowedCharacters*: seq[char]

# proc `$`*(e: SetNameException): string =
#   result = "foo"

# proc computeMsg*(e: SetNameException) {.raises: [ValueError, IOError, OSError]} =
#   e.msg = "Failed to set name"
#   if e.lenViolation:
#     e.msg &= fmt", name len {e.actualLen} must be <= {e.allowedLen}"
#   if len(e.disallowedCharacters) > 0:
#     let disallowedCharacters = $$e.disallowedCharacters
#     e.msg &= fmt", contains disallowed characters: {disallowedCharacters}"

# proc setName*(newName: string) {.raises: [SetNameException, ValueError, IOError, OSError]} =
#   # Name rules:
#   #   - supported special characters:
#   #       !"$%&'()*+,-./?~:;
#   #   - supported whitespaces:
#   #       space tab
#   # NOTE: '#' glitches player names in a weird fashion, seems to change color or something?, it's disallowed anyhow

#   echo allowedCharacters

#   var error = false
#   let e = SetNameException()

#   const allowedLen = 15
#   let actualLen = len(newName)
#   if actualLen > allowedLen:
#     error = true
#     e.actualLen = actualLen
#     e.allowedLen = allowedLen
#     e.lenViolation = true

#   for c in newName:
#     if c notin allowedCharacters:
#       error = true
#       e.disallowedCharacters.add(c)

#   if error:
#     e.computeMsg()
#     raise e

#   echo newName
