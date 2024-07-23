import std/os
import std/osproc
import std/parseutils
import std/strformat
import std/strutils
import std/tables

import argparse
import winregistry

import re

import ./config.nim as cfg
import ./edit.nim
import ./facts.nim as facts
import ./gui.nim
import ./mmpfile.nim
import ./various.nim
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

    command("map-install"):
      arg("zip-file")
      option("-t", "--to")
      help("Install a packaged map, pass path to a .zip file.")
      run:
        let toPath = if opts.to != "": opts.to else: (os.parentDir(cfg.config.gamepath) / "data")

        if not os.dirExists(toPath):
          die(fmt"Target direction doesn't exist: {toPath}")

        try:
          mmpFile.install(opts.zip_file, toPath)
        except Exception as e:
          echoErr fmt"Failed to copy '{opts.zip_file}' to '{toPath}'"
          raise e

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
