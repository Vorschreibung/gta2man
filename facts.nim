import os

let appDir* = os.expandFilename(os.getAppDir())
let miss2Dir* = appDir / "miss2"
let miss2Bin* = miss2Dir / "miss2.exe"
let gta2Dir* = appDir / "game"
let gta2Bin* = gta2Dir / "gta2.exe"
let gta2ManagerBin* = gta2Dir / "gta2manager.exe"
let mapEditDir* = appDir / "map-editor"
let mapEditBin* = mapEditDir / "Editor.exe"
let sevenZipDir* = appDir / "7z"
let sevenZipBin* = sevenZipDir / "7zr.exe"
