import ../src/rnim

#[
Compile this with

nim c --app:lib --gc:arc tNimFromR.nim

and then run the corresponding R test:

Rscript tCallNimFromR.R

If it doesn't throw an error the tests passed.

(ARC is optional)
]#

func addXYInt*(x, y: SEXP): SEXP {.exportR.} =
  # assuming x, y are ints
  let
    xNim = x.to(int)
    yNim = y.to(int)
  result = nimToR(xNim + yNim)

proc addXYFloat*(x, y: SEXP): SEXP {.exportR.} =
  # assuming x, y are floats
  let
    xNim = x.to(float)
    yNim = y.to(float)
  result = nimToR(xNim + yNim)

proc addVecs*(x, y: SEXP): SEXP {.exportR.} =
  let
    xNim = x.to(seq[float])
    yNim = y.to(seq[float])
  var res = newSeq[float](xNim.len)
  for i in 0 ..< xNim.len:
    res[i] = (xNim[i] + yNim[i]).float
  result = nimToR(res)

#[
I think the below is only relevant for complicated modules
let callMethods* = [
  R_CallMethodDef(name: "addXY".cstring,
                  fun: cast[DL_FUNC](addXY),
                  numArgs: 2.cint),
  R_CallMethodDef(name: nil, fun: nil, numArgs: 0)
]

proc updateStackBottom() {.inline.} =
  when not defined(gcDestructors):
    var a {.volatile.}: int
    nimGC_setStackBottom(cast[pointer](cast[uint](addr a)))
    when compileOption("threads") and not compileOption("tlsEmulation"):
      if not gcInited:
        gcInited = true
        setupForeignThreadGC()

proc R_init_tNimFromR*(info: ptr DllInfo) {.exportc: "R_init_tNimFromR", cdecl, dynlib.} =
  updateStackBottom()
  echo "now"
  echo callMethods[0].unsafeAddr.isNil
  R_RegisterRoutines(info, nil, callMethods[0].unsafeAddr, nil, nil)
  echo ":("

proc R_unload_tNimFromR*(info: ptr DllInfo) {.exportc: "R_unload_tNimFromR", cdecl, dynlib.} =
  # what to do?
  discard

]#
