import strformat
import std/marshal

# NOTE '#' glitches player names in a weird fashion, seems to change color or something?, it's disallowed anyhow
# NOTE tabs would work, but could be abused quite easily to create overly long names and blow up layouts, ergo disallowed

const allowedLen = 15
const allowedCharacters =
  "abcdefghijklmnopqrstuvwxyz" &
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ" &
  "0123456789" &
  """!"$%&'()*+,-./?~:;""" &
  " " # space

type
  ValidatePlayerNameResult* = object
    violations*: uint8
    lenViolation*: bool
    actualLen*: int
    allowedLen*: int
    disallowedCharacters*: seq[char]

proc computeMsg*(r: ValidatePlayerNameResult): string {.raises: [ValueError, IOError, OSError]} =
  if r.violations == 0:
    return ""

  result = "Failed to validate player name"
  if r.lenViolation:
    result &= fmt", name len {r.actualLen} must be <= {r.allowedLen}"
  if len(r.disallowedCharacters) > 0:
    let disallowedCharacters = $$r.disallowedCharacters
    result &= fmt", contains disallowed characters: {disallowedCharacters}"

proc validatePlayerName*(newName: string): ValidatePlayerNameResult {.raises: [ValueError, IOError, OSError]} =
  let actualLen = len(newName)
  if actualLen > allowedLen:
    result.violations+=1
    result.actualLen = actualLen
    result.allowedLen = allowedLen
    result.lenViolation = true

  for c in newName:
    if c notin allowedCharacters:
      result.disallowedCharacters.add(c)

  if len(result.disallowedCharacters) > 0:
    result.violations+=1
