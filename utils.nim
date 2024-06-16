import std/parseutils

# @TODO move to template
proc parseInt*(str: string): int =
  discard parseInt(str, result)
