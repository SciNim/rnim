import ../src/rnim
import std / [sequtils, unittest]

#[
Compile this with

nim c --app:lib --gc:arc tNimFromR.nim

and then run the corresponding R test:

Rscript tCallNimFromR.R

If it doesn't throw an error the tests passed.

(ARC is optional)
]#

func addXYInt*(x: SEXP, y: SEXP): SEXP {.exportR.} =
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

proc printVec*(v: SEXP) {.exportR.} =
  let nv = initNumericVector[float](v)
  for i in 0 .. nv.high:
    echo nv[i]

  for x in nv:
    echo x

  for i, x in nv:
    echo "index ", i, " contains ", x

proc modifyVec*(v: SEXP) {.exportR.} =
  var nv = initRawVector[float](v)
  for x in mitems(nv):
    x = x + 1.0

proc checkVector[T](v: NumericVector[T]) =
  ## checks the given vector to be our expectation
  let exp = @[1, 2, 3, 4, 5].mapIt(it.T)
  check v.len == exp.len
  for i in 0 ..< v.len:
    check v[i] == exp[i]

proc checkSexp*(s: SEXP) {.exportR.} =
  proc checkType[T](s: SEXP) =
    let nv = initNumericVector[T](s)
    checkVector(nv)
  checkType[int32](s)
  checkType[cint](s)
  checkType[int](s)
  checkType[int64](s)
  checkType[float](s)
  checkType[float32](s)
  checkType[cdouble](s)
  checkType[cfloat](s)
  #checkType[uint8](s)

proc checkVector[T](v: RawVector[T]) =
  ## checks the given vector to be our expectation
  let exp = @[1, 2, 3, 4, 5].mapIt(it.T)
  check v.len == exp.len
  for i in 0 ..< v.len:
    check v[i] == exp[i]

proc checkSexpRaw*(s: SEXP) {.exportR.} =
  proc checkType[T](s: SEXP) =
    let nv = initRawVector[T](s)
    checkVector(nv)
  checkType[int32](s)
  checkType[cint](s)
  ## The following for example do *NOT* work, because the data type and sizes have to match for a
  ## raw vector!
  ## A `RawVector` is just casting the data!
  #checkType[int](s)
  #checkType[float](s)
  #checkType[cdouble](s)


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
