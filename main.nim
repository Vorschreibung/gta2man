import std/os
import std/osproc
import std/strformat
import std/strutils
import std/tables

import argparse
import winregistry

import re

import ./config.nim as cfg
import ./mmpfile.nim

proc main =
  initConfig()

  var res:string
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
      option("-c", "--command")
      run:
        # var f = open(opts.mmpfile, fmRead)
        let strm = newFileStream(opts.mmpfile, fmRead)
        defer: close(strm)
        let mmp = parseMmpFileStream(strm)
        # echo repr mmp


        let mapDir = parentDir(opts.mmpfile)
        let gamePath = cfg.config.gamepath
        let gameDir = parentDir(gamePath)

        block: # copy the map
          for fpath in [
            joinPath(mapDir, mmp.mapFiles.styFile),
            joinPath(mapDir, mmp.mapFiles.gmpFile),
            joinPath(mapDir, mmp.mapFiles.scrFile),
            joinPath(mapDir, mmp.mapFiles.gxtFile),
            opts.mmpfile,
          ]:
            if os.fileExists(fpath):
              os.copyFile(fpath, joinPath(gameDir, "data", os.splitPath(fpath).tail))

        block: # write registry
          var
            h: RegHandle
            keyName = "HKEY_CURRENT_USER"

          try:
            h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Debug", samAll)

            h.writeString("stylename", mmp.mapFiles.styFile)
            h.writeString("mapname", mmp.mapFiles.gmpFile)
            h.writeString("scriptName", mmp.mapFiles.scrFile)
          # except OSError:
            # echo "err: ", getCurrentExceptionMsg()
          finally:
            close(h)

          try:
            h = createOrOpen(fmt"{keyName}\Software\DMA Design Ltd\GTA2\Option", samAll)

            var gxtFile = mmp.mapFiles.gxtFile
            removeSuffix(gxtFile, ".gxt")
            h.writeString("language", gxtFile)
            # h.writeString("mapname", mmp.mapFiles.gmpFile)
            # h.writeString("scriptName", mmp.mapFiles.scrFile)
          # except OSError:
            # echo "err: ", getCurrentExceptionMsg()
          finally:
            close(h)
          discard

        block: # start the game
          echo fmt"> running: {gamePath}"
          setCurrentDir(gameDir)
          discard execCmd(gamePath)

    command("set-player-name"):
      arg("player-name")
      option("-c", "--command")
      run:
        echo opts.player_name

    command("preprocess"):
      arg("misp")
      run:
        let reConst = re(r"^\s*CONST\s*(const_[a-z0-9]+)\s*=\s*([^\\\/]+).*$", flags = {reMultiLine})

        var consts = initTable[string, string]()

        let contents = io.readFile(opts.misp)
        # var matches: seq[string]
        var matches: array[2, string]
        # var matches: array[1, string]
        for line in splitLines(contents):
          # echo "YAY"
          # let matches = line.findAll(reConst)
          # if len(matches) > 0:
          if line.find(reConst, matches) >= 0:
            # echo len(matches)
            # echo matches
            consts[matches[0]] = matches[1]
            echo "// [MISP(consumed)] " & line
          else:
            echo line

        # echo opts.misp

  try:
    p.run(commandLineParams())
  except UsageError:
    stderr.writeLine getCurrentExceptionMsg()
    quit(1)

when isMainModule:
  main()
