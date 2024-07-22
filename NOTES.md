# NOTES
## Registry
On GTA2 v11.44 all keys sit below `HKEY_CURRENT_USER\Software\DMA Design Ltd\GTA2`

## File Extensions
```
*.gmp - maps / map layouts (including zone definitions)
*.gxt - texts
*.m3d - 3d models
*.mis - plaintext scripts, ignored by GTA2 during runtime
*.mmp - multiplayer map definition
*.scr - compiled binary scripts, loaded and run by GTA2
*.sty - graphics
```

## DLLS (v11.44)
All of these have different file sizes.
```
binkw32.dll     - RAD Tools Bink Video                                 (video)

# video d3d
d3ddll.dll      - DMA: gbh_DrawQuad/gbh_BlitBuffer [Name: 3dfxdll.dll] (video)
dmavideo.dll    - DMA: Vid_FlipBuffers/Vid_FindMode                    (video) [window-handling?]
                  imports: DDRAW.DLL (DirectDrawCreate, DirectDrawEnumerateA)

# video glide
3dfx.dll        - DMA: same functions/name as `d3ddll.dll`             (video)
                  imports: GLIDE2X.DLL (_gr*, _guDrawTriangleWithClip)
dmaglide.dll    - DMA: same functions/name as `dmavideo.dll`           (video) [window-handling?]
                  imports: GLIDE2X.DLL (_gr*, e.g.: _grGlideInit, _grBufferSwap)

mss32.dll       - Miles Sound System                                   (audio)

polygon.dll     - DMA: AddPrimitive/DoPolygon                          (video)
d3dpoly.dll     - DMA: same functions/name as `polygon.dll`            (video)
```

## Rendering
GTA2 seems to have been written for:
- DirectX 6.1
  via `d3ddll.dll`
- GLIDE2X.DLL - Glide ...? (Possibilities: Glide 2.11, Glide 2.45, Glide 3.1 and Glide 3.1 Napalm)  
  via `3dfx.dll`

```
> Well, I did some testing with this. At first I thought GTA2 used directdraw, and
> i even wrote a ddraw.dll that GTA2 loads without complaining. This ddraw.dll
> just redirects every function call to the real ddraw.dll, but of course I could
> also have it report its activities to a bot. However, turns out that GTA2
> doesn't use directdraw that much at all, but instead an own library, d3ddll.dll,
> designed by DMA themselves.
```
https://gtamp.com/forum/viewtopic.php?t=377

### Switching to Glide (WIP)
Didn't really work out well, but for reference:

1. regedit -> `HKEY_CURRENT_USER` -> Software -> DMA Design -> Screen:  
   set `rendername` (a String/REG_SZ) to `3dfx.dll`  
   set `videoname` (a String/REG_SZ) to `dmaglide.dll`  
2. Launch GTA2 directly, i.e. no manager because it overwrites those registry keys


## Network
```
2300 TCP - for both lobby and network play
```

---

## MISS2 Compiler
- Output (.scr) is non-deterministic, i.e. the same .mis will always create
  binary-different .scr files.  
  As such .scr files must not be part of the release checksum.

- There's a max number of Commands/Statements, i.e. scripts can't surpass a
  certain size.

## Map Editor
### Shortcuts
`d` → Cursor Draw  
`i` → Cursor Pick  
`v` → Cursor Select  

`Shift-a` → Grown Selection Down  
`Shift-q` → Grown Selection Up  
