import ../rnim

proc addXY*(x, y: SEXP): SEXP {.exportc: "addXY", cdecl, dynlib.} =
  # assuming x, y are floats
  let
    xNim = x.to(float)
    yNim = y.to(float)
  result = nimToR(xNim + yNim)



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
