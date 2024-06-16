# Getting Nim to run on WinXP

## fixing threads
checkout `mingw-64`, enter `mingw-w64/mingw-w64-libraries/winpthreads`, configure it with  
`--host=i686-w64-mingw32 CFLAGS="-D_WIN32_WINNT=_WIN32_WINNT_WINXP"`
and compile it, you'll find the build files in
`mingw-w64/mingw-w64-libraries/winpthreads/.libs/libwinpthread-1.dll` if you
build it inplace (which you shouldn't ofc)

this has to be done so that the `.dll` does not depend on `KERNEL32.DLL →
GetTickCount64`, which doesn't exist on WinXP

we then need to disable the windows-handling `when defined(windows):` in
`nim/lib/system/syslocks.nim`, which makes it fallback to the `pthread` API,
using our previously compiled `winpthreads-1.dll`

## fixing random
we then need to circumvent the `Bcrypt.dll` requirement via using
`BCryptGenRandom` also missing in WinXP, and use `CryptGenRandom` from
`windows.h` instead

replace the `when defined(windows):`-section in
`nim/lib/std/sysrand.nim` with:

```
import winlean

const
  STATUS_SUCCESS = 0x00000000

{.passc: "-UWIN32_LEAN_AND_MEAN".}

type ULONG_PTR = int
type HCRYPTPROV = ULONG_PTR
var PROV_RSA_FULL {.importc, header: "<windows.h>".}: DWORD
var CRYPT_VERIFYCONTEXT {.importc, header: "<windows.h>".}: DWORD

{.push, stdcall, dynlib: "Advapi32.dll".}

when useWinUnicode:
  proc CryptAcquireContext(
    phProv: ptr HCRYPTPROV, pszContainer: WideCString,
    pszProvider: WideCString, dwProvType: DWORD, dwFlags: DWORD
  ): WinBool {.importc: "CryptAcquireContextW".}
else:
  proc CryptAcquireContext(
    phProv: ptr HCRYPTPROV, pszContainer: cstring, pszProvider: cstring,
    dwProvType: DWORD, dwFlags: DWORD
  ): WinBool {.importc: "CryptAcquireContextA".}

proc CryptGenRandom(
  hProv: HCRYPTPROV, dwLen: DWORD, pbBuffer: pointer
): WinBool {.importc: "CryptGenRandom".}

{.pop.}

var cryptProv: HCRYPTPROV = 0

proc urandomInit() =
  let success = CryptAcquireContext(
    addr cryptProv, nil, nil, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT
  )
  if success == 0:
    raise newException(OSError, "Call to CryptAcquireContext failed")

proc randomBytes(pbBuffer: pointer, cbBuffer: Natural): int {.inline.} =
  if cryptProv == 0:
    urandomInit()

  let success = CryptGenRandom(cryptProv, DWORD(cbBuffer), pbBuffer)
  if success == 0:
    raise newException(OSError, "Call to CryptGenRandom failed")

template urandomImpl(result: var int, dest: var openArray[byte]) =
  let size = dest.len
  if size == 0:
    return

  result = randomBytes(addr dest[0], size)
```
partially adopted from <https://github.com/oprypin/nim-random/blob/master/src/random/urandom.nim>
