# import std/parsecfg
import std/[
  hashes,
  md5,
  os,
  sequtils,
  streams,
  strformat,
  strutils,
  tempfiles,
]

import miniz  # zip (de-)compression

import ./utils.nim as utils
import ./parseini.nim

# @XXX
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

const allowedFileNameCharacters =
  "abcdefghijklmnopqrstuvwxyz" &
  "0123456789" &
  "-"

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
    gciFile*: string
    gmpFile*: string
    gxtFile*: string
    mdFile*: string
    misFile*: string
    scrFile*: string
    styFile*: string
    version*: string
    playerCount*: int

  MmpFileRelease* = ref object
    formatVersion*: string
    checksum*: string
    originalDescription*: string

  MmpFile* = ref object
    mmpVersion*: int

    mapFiles*: MmpFileMapFiles
    map*: MmpFileMap
    release*: MmpFileRelease
    # @TODO client

    path*: string
    parentDirPath*: string

type
  StreamParser* = ref object
    parsedSections: seq[string]
    parsedSectionMapFiles: bool
    parsedSectionMMP: bool
    parsedSectionMap: bool

proc parseMmpFileStream*(input: Stream, path: string): MmpFile =
  new(result)
  new(result.mapFiles)
  new(result.map)
  new(result.release)

  result.path = path
  result.parentDirPath = os.parentDir(path)

  if path != "" and not os.fileExists(path):
    echo fmt"MMP File does not exist: {path}"
    quit(1)

  var p: CfgParser
  open(p, input, "[stream]")
  defer: close(p)

  var sp = StreamParser()

  var currentSection = ""

  template endSection =
    if currentSection != "":
      sp.parsedSections.add(currentSection)
      currentSection = ""

  proc parseBool(input: string): bool =
    case input
    of "true":  return true
    of "false": return false
    else:
      raise newException(Exception, fmt"Failed to parse boolean: '{input}', specify either 'true' or 'false'")

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
        of "Description": result.mapFiles.description = e.value
        of "GCIFile": result.mapFiles.gciFile = e.value
        of "GMPFile": result.mapFiles.gmpFile = e.value
        of "GXTFile": result.mapFiles.gxtFile = e.value
        of "MDFile": result.mapFiles.mdFile = e.value
        of "MISFile": result.mapFiles.misFile = e.value
        of "SCRFile": result.mapFiles.scrFile = e.value
        of "STYFile": result.mapFiles.styFile = e.value
        of "Version": result.mapFiles.version = e.value
        of "PlayerCount": result.mapFiles.playerCount = utils.parseInt(e.value)
        else:
          raise newException(Exception, fmt"unknown key '{e.key}' for section '{currentSection}'")
      of "Release":
        case e.key
        of "FormatVersion": result.release.formatVersion = e.value
        of "Checksum": result.release.checksum = e.value
        of "OriginalDescription": result.release.originalDescription = e.value
        else:
          raise newException(Exception, fmt"unknown key '{e.key}' for section '{currentSection}'")
      of "Map":
        case e.key
        of "UpDate":      result.map.upDate      = e.value
        of "CreaDate":    result.map.creaDate    = e.value
        of "LongDesc":    result.map.longDesc    = e.value
        of "Tags":        result.map.tags        = e.value
        of "GTA2Version": result.map.gta2version = e.value
        of "Author":      result.map.author      = e.value
        of "Readme":      result.map.readme      = e.value
        of "DuskSupport": result.map.dusksupport = parseBool(e.value)
        of "WantedLevel": result.map.wantedlevel = e.value
        of "MapArea":     result.map.maparea     = e.value
        of "PlayArea":    result.map.playarea    = e.value
        else:
          raise newException(Exception, fmt"unknown key '{e.key}' for section '{currentSection}'")
      of "MMP", "Host", "Client": # ignore
        discard
      else:
        raise newException(Exception, fmt"unknown section '{currentSection}'")

    of cfgError:
      endSection()
      raise newException(Exception, fmt"error while parsing mmpfile: {e.msg}")

proc parseMmpFileStream*(inputStr: string, path: string): MmpFile =
  var input = newStringStream(inputStr)
  return parseMmpFileStream(input, path)

proc loadMmpFile*(path: string): MmpFile =
  let fileExt = os.splitFile(path).ext
  assert fileExt == ".mmp"

  let strm = newFileStream(path, fmRead)
  defer: close(strm)

  return parseMmpFileStream(strm, os.absolutePath(path))

iterator files*(mmp: MmpFile, skipMmpItself=false): tuple[kind: string, path: string, fileName: string] =
  template yieldNeighbourFile(kind: string, fileName: string) =
    if fileName != "" and fileName notin shippedAssets:
      assert splitFile(fileName).ext == "." & kind  # sanity check
      yield(kind, mmp.parentDirPath / fileName, filename)

  yieldNeighbourFile("gci", mmp.mapFiles.gciFile)
  yieldNeighbourFile("gmp", mmp.mapFiles.gmpFile)
  yieldNeighbourFile("gxt", mmp.mapFiles.gxtFile)
  yieldNeighbourFile("scr", mmp.mapFiles.scrFile)
  yieldNeighbourFile("sty", mmp.mapFiles.styFile)
  yieldNeighbourFile("mis", mmp.mapFiles.misFile)

  if not skipMmpItself:
    yield("mmp", mmp.path, os.splitPath(mmp.path).tail)

proc copyFilesToDir*(mmp: MmpFile, dirPath: string, ext: string="") =
  for file in mmp.files():
    if ext != "" and os.splitFile(file.path).ext != ext:
      continue
    let fpath = file.path
    let fromPath: string = fpath  # @XXX somehow crashes without doing this
    # echo "copying ... " & fromPath
    os.copyFile(fromPath, dirPath / "data" / os.splitPath(fpath).tail)

proc validate*(mmp: MmpFile) =
  # Check if files exist
  for (kind, path, fileName) in mmp.files():
    # skipp shipped assets
    # let fname = os.splitPath(path).tail
    # if shippedAssets.contains(fname):
    #   echo "> Skipping " & fname
    #   continue

    if not os.fileExists(path):
      raise newException(Exception, "VALIDATION-ERROR: Map is referring to nonexisting ." & kind & ": '" & path & "'")

  # @TODO check file names of all files for validity (must not be longer than X
  # and consist of only XYZ... characters)
  for (kind, path, fileName) in mmp.files():
    # @INFO map file names (including extension) must never be longer than 22
    # characters
    assert fileName.len <= 22

    let fileNameWithoutExtension = fileName.rsplit(".", 1)[0]
    for c in fileNameWithoutExtension:
      assert c in allowedFileNameCharacters

proc checksum*(mmp: MmpFile): string =
  var chksum: MD5Context
  chksum.md5Init()

  const readSize = 4096*8

  for file in mmp.files():
    # @XXX '.scr' files are **NOT** idempotent, meaning that the same '.mis'
    # will produce binary-different '.scr' files every time passed through the
    # compiler
    if file.fileName.endsWith(".scr"):
      continue

    doAssert os.fileExists(file.path)
    var
      buf: array[readSize, uint8]
      read = 0

    var testOut = newFileStream("debug." & file.fileName, fmWrite)
    defer: testOut.close()

    var strm = newFileStream(file.path, fmRead)
    defer: strm.close()
    while true:
      read = strm.readData(addr(buf), readSize)
      testOut.writeData(addr(buf), read)
      chksum.md5Update(buf)

      if read < readSize:
        break

  var final: MD5Digest
  chksum.md5Final(final)
  return $final

proc package*(mmp: MmpFile, writeMmpStanza = true): string =
  mmp.validate()

  let
    fullChksum = mmp.checksum()
    chksum = fullChksum[0..13]
    mapFileName = fmt"rls-{chksum}"

  assert (mapFileName & ".mmp").len == 22

  # collect files
  var files: seq[miniz.AddFileEntry]

  # @XXX mmp hotpatch tmpfile
  let tmpFile = tempfiles.createTempFile(prefix="gta2man-mmp-", suffix="")
  defer: tmpFile.path.removeFile()

  # @TODO produce a 'mapFileName.txt'

  for file in mmp.files(skipMmpItself=true):
    # add sibling .mis file for .scr
    if file.fileName.endsWith(".scr"):  # @XXX @TODO replace with 'MISFile' at a later point
      let misPath = file.path[0..^5] & ".mis"
      assert fileExists(misPath)

    files.add((path: file.path, fileName: mapFileName & os.splitFile(file.fileName).ext))

  block hotpatch_mmp:
    let contents = readFile(mmp.path)

    let strm = newFileStream(tmpFile.cfile)
    defer: strm.close()

    if writeMmpStanza:
      strm.writeLine("; released via https://github.com/Rafflesiaceae/gta2man")
      strm.writeLine("")

    var trackedMapFiles: seq[string] = @["MISFile"]
    for file in mmp.files(skipMmpItself=true):
      trackedMapFiles.add(file.fileName.splitFile().ext[1..^1].toUpper() & "File")

    let contentsLines = contents.splitLines()

    # find Version
    var version = ""
    block findVersion:
      for line in contentsLines:
        if line == "[MapFiles]": continue
        if line.startsWith("["): break
        if line.startsWith("Version"):
          version = line.split("=", maxsplit=1)[1].strip()

    var
      mapName = ""
      originalDescription = ""

    for line in contentsLines:
      block hotpatchLine:
        for tmf in trackedMapFiles:
          if line.startsWith(tmf):
            strm.writeLine(tmf & " = " & mapFileName & "." & tmf.split("File")[0].toLower())
            break hotpatchLine

        if line.startsWith("Description"):  # @XXX
          originalDescription = line.split("=", maxsplit=1)[1].strip()
          mapName = originalDescription
          if version != "":
            mapName &= fmt" v{version}"
          mapName &= fmt" ({chksum})"
          strm.writeLine(fmt"Description = {mapName}")
        else:
          strm.writeLine(line)

    strm.writeLine("")
    strm.writeLine("[Release]")
    # @TODO checksums for each individual mapfile (.gmp etc.)
    strm.writeLine("FormatVersion = 0")
    strm.writeLine(fmt"Checksum = {chksum}")
    strm.writeLine(fmt"OriginalDescription = {originalDescription}")

    files.add((path: tmpFile.path, fileName: mapFileName & os.splitFile(mmp.path).ext))

  # write zip files
  result = fmt"{mapFileName}.zip"
  miniz.zip(files, result, deterministic=true)

proc install*(inputPath: string, outputPath: string) =
  miniz.unzip(inputPath, outputPath)

proc yamlRepr*(mmp: MmpFileMap): string =
  discard
