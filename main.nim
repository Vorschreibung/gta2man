import std/os
import std/osproc
import std/parseutils
import std/strformat
import std/strutils
import std/tables

import argparse
import winregistry
# import wAuto as wAuto

import re

# from ./edit_map.nim import edit_map
import ./config.nim as cfg
import ./edit.nim
import ./facts.nim as facts
import ./gui.nim
import ./mmpfile.nim
from ./compile.nim import compile
from ./quickstart.nim import quickstart, resetQuickstart

proc main =
  initConfig()

  let args = commandLineParams()
  if args.len == 0:
    initGui()
    quit(0)

  var res: string
  var p = newParser:
    help("{prog} is a collection of tools to manage your gta2 installation")
    # flag("-n", "--dryrun")
    # option("--name", default=some("bob"), help = "Name to use")

    # command("ls"):
    #   run:
    #     res = "did ls " & opts.parentOpts.name

    # command("run"):
    #   option("-c", "--command")
    #   run:
    #     let name = opts.parentOpts.name
    #     if opts.parentOpts.dryrun:
    #       res = "would have run: " & opts.command & " " & name
    #     else:
    #       res = "ran " & opts.command & " " & name

    command("quickstart"):
      arg("mmpfile")
      option("-p", "--players")
      help("Quickstart a map in SP, pass path to an .mmp file.")
      run:
        var players: uint = 1
        if opts.players != "":
          discard parseUInt(opts.players, players)
          assert players >= 1 and players <= 6

        quickstart(opts.mmpfile, int(players))

    command("quickstart-reset"):
      help("Reset previously set quickstart settings")
      run:
        resetQuickstart()

    command("set-player-name"):
      arg("player-name")
      run:
        cfg.setName(opts.player_name)

    command("mis-compile"):
      arg("mis-file")
      help("Compile a .mis file to .scr via 'miss2'")
      run:
        quit(compile(opts.mis_file))

    command("map-copy"):
      arg("mmpfile")
      # option("-c", "--command")
      help("Copy map files to game directory, pass path to an .mmp file.")
      run:
        let mmp = loadMmpFile(opts.mmpfile)

        let gamePath = cfg.config.gamepath
        let gameDir = parentDir(gamePath)

        mmp.copyFilesToDir(gameDir)

    command("map-edit"):
      arg("mmp-file")
      help("Edit a map with the map editor, pass path to an .mmp file.")
      run:
        quit(editMap(opts.mmp_file))

    # command("package-map"):
    #   arg("mmp-file")
    #   help("Package a map, pass .mmp file")
    #   run:
    #     let mmp = loadMmpFile(opts.mmp_file)
    #     packageMap(mmp)
    #     quit(0)

    # command("preprocess"):
    #   arg("misp")
    #   run:
    #     let reConst = re(r"^\s*CONST\s*(const_[a-z0-9]+)\s*=\s*([^\\\/]+).*$", flags = {reMultiLine})

    #     var consts = initTable[string, string]()

    #     let contents = syncio.readFile(opts.misp)
    #     # var matches: seq[string]
    #     var matches: array[2, string]
    #     # var matches: array[1, string]
    #     for line in splitLines(contents):
    #       # echo "YAY"
    #       # let matches = line.findAll(reConst)
    #       # if len(matches) > 0:
    #       if line.find(reConst, matches) >= 0:
    #         # echo len(matches)
    #         # echo matches
    #         consts[matches[0]] = matches[1]
    #         echo "// [MISP(consumed)] " & line
    #       else:
    #         echo line

    #     # echo opts.misp

    command("map-install"):
      arg("zip-file")
      option("-t", "--to")
      help("Install a packaged map, pass path to a .zip file.")
      run:
        let toPath = if opts.to != "": opts.to else: "./foo"
        mmpFile.install(opts.zip_file, toPath)

    command("map-package"):
      arg("mmp-file")
      help("Package a map for release, outputs a .zip file, pass path to an .mmp file.")
      run:
        let mmp = loadMmpFile(opts.mmp_file)
        let packagedFilePath = mmp.package()
        echo packagedFilePath

    command("map-validate"):
      arg("mmp-file")
      help("Validate a map, pass path to an .mmp file.")
      run:
        let mmp = loadMmpFile(opts.mmp_file)
        mmp.validate()

    # command("bounce"):
    #   run:
    #     # var
    #     #   buf: array[readSize, uint8]
    #     #   strm = newFileStream(mmp.mapFiles.gmpFile, fmRead)
    #     #   testOut = newFileStream("manipulation", fmWrite)
    #     #   read = 0
    #     # var strm = newStringStream("abcde")
    #     var strm = newFileStream("./.syncy.json", fmRead)
    #     defer: strm.close()
    #     var buffer: array[6, char]
    #     discard strm.readData(addr(buffer), 1024)
    #     echo $buffer
    #     # doAssert buffer == ['a', 'b', 'c', 'd', 'e', '\x00']
    #     # doAssert strm.atEnd() == true

    command("version"):
      run:
        echo "v0.1"

  try:
    p.run(commandLineParams())
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  main()
