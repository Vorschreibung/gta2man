import os
import std/strformat
import std/osproc

import winregistry

import ./facts.nim as facts
import ./mmpfile.nim

proc editMap*(file: string): int =
  let mmp = loadMmpFile(file)

  block setSty:
    var
      h: RegHandle
      keyName = "HKEY_CURRENT_USER"

    try:
      h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\Gta2 Editor\App Defaults", samAll)
      h.writeString("App Style File", facts.gta2Dir / "data" / mmp.mapFiles.styFile)
    finally:
      close(h)

  let gmpFile = mmp.parentDirPath / mmp.mapFiles.gmpFile
  mmp.copyFilesToDir(facts.gta2Dir, ext=".sty")

  discard osproc.execProcess(facts.mapEditBin, args=[gmpFile], workingDir=facts.mapEditDir, options={poStdErrToStdout})
  return 0

proc edit*(file: string) =
  let fileExt = os.splitFile(file).ext
  case fileExt
  of ".gmp":
    echo "EDITING GMP"
  else:
    raise newException(Exception, "Unsupported file extension for editing: " & fileExt)
