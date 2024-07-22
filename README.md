# gta2man
---
A collection of tools around GTA2, compiles for WIN32.

- [Notes](./NOTES.md)  
- [Caveats](./CAVEATS.md)  

# Usage
Running `gta2man` pops up a GUI (WIP) that's supposed to eventually become a
`gta2manager.exe` replacement - that allows joining a hosted game, setting
playername / controls etc.

After running it for the first time, edit `gta2man-cfg.yaml` that pops up in the
same directory and set the gamepath.

It's main functionality so far lies in the ↓

## CLI
```
quickstart       Quickstart a map in SP, pass path to an .mmp file.
quickstart-reset Reset previously set quickstart settings
set-player-name
mis-compile      Compile a .mis file to .scr via 'miss2'
map-copy         Copy map files to game directory, pass path to an .mmp file.
map-edit         Edit a map with the map editor, pass path to an .mmp file.
map-install      Install a packaged map, pass path to a .zip file.
map-package      Package a map for release, outputs a .zip file, pass path to an .mmp file.
map-validate     Validate a map, pass path to an .mmp file.
version
```

# Build
Use `nim == 2.0.2`  
`$ make build`

# Test
`$ make test`
