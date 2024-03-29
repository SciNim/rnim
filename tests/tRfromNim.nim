import sequtils, strutils
import ../src/rnim
import unittest

# Intialize the embedded R environment.
let R = setupR()

R.source("tests/foo.R")

suite "Basic types from Nim to R and back":
  # Setup a call to the R function
  proc testType[T](x: T) =
    test "Basic types: " & $(typeof(T)):
      let ret = R.add1(x)
      let nimRes = ret.to(typeof(x))
      when T is seq:
        check nimRes == x.mapIt(it + type(it)(1))
      else:
        check nimRes == typeof(x)((x + 1))

  testType(31)
  testType(31.float64)
  testType(31.float)
  testType(31.float32)
  testType(31.uint8)
  testType(31.uint16)
  testType(31.uint32)
  testType(31.uint64)
  testType(31.int8)
  testType(31.int16)
  testType(31.int32)
  testType(31.int64)

  testType(@[1, 2, 3, 4, 5])
  testType(@[1.float64, 2, 3, 4, 5])
  testType(@[1.float, 2, 3, 4, 5])
  testType(@[1.float32, 2, 3, 4, 5])
  testType(@[1.uint8, 2, 3, 4, 5])
  testType(@[1.uint16, 2, 3, 4, 5])
  testType(@[1.uint32, 2, 3, 4, 5])
  testType(@[1.uint64, 2, 3, 4, 5])
  testType(@[1.int8, 2, 3, 4, 5])
  testType(@[1.int16, 2, 3, 4, 5])
  testType(@[1.int32, 2, 3, 4, 5])
  testType(@[1.int64, 2, 3, 4, 5])

  test "Basic types: string":
    let testStr = "123456789abcdefghijklmnopqrstuvxyz"
    check R.makeString(testStr).to(string) == testStr

suite "NumericVector from Nim seq":
  let x = @[1.0, 2.0, 3.0, 4.0]
  let xR = x.nimToR
  var nv = initNumericVector[float](xR)
  echo nv
  test "Basic comparisons":
    for i in 0 ..< nv.len:
      check nv[i] == x[i]

  test "Modify values":
    for i in 0 ..< nv.len:
      nv[i] = nv[i] * nv[i]

  echo nv
  # `xR` points to same memory as `nv`. Check they contain the same,
  # by constructing a raw vector of `xR` (could also construct another `NumericVector` of course)
  test "Two different vectors of same object share same memory":
    let rv = initRawVector[float](xR)
    let xBackNim = xR.to(seq[float])
    for i in 0 ..< nv.len:
      check rv[i] == nv[i]
      check xBackNim[i] == nv[i]
    echo rv
    echo xR

  # check comparison
  test "Comparison":
    check nv == nv

suite "R stdlib function calls":
  test "Calls without named arguments":
    check R.sum(@[1, 2, 3]).to(int) == 6
    # NOTE: cannot be called via `.()` call, use callEval directly
    check callEval(`+`, 5, 10).to(int) == 15
  test "Calls with named arguments":
    check R.seq(1, 10, by = 1).to(seq[int]) == toSeq(1 .. 10)
    check R.seq(1, 10, by = 2).to(seq[int]) == toSeq(countup(1, 10, 2))

suite "R function with … arguments":
  test "Named param after …":
    check R.dotFn(param = "It got back!").to(string) == "It got back!"

suite "Unusual R function names":
  test "Call function with a . in its name":
    let a = @[1, 2, 3]
    let b = @[2, 4, 6]
    let df = callEval("data.frame", col1 = a, col2 = b)
    ## TODO: fixup this test. Somehow get the correct string reperesentation for the DF
    let exp = """
c(1, 2, 3), c(2, 4, 6)
"""
    check R.makeString(df).to(string).strip == exp.strip

suite "Rctx macro":
  test "Multiple calls":
    let x = @[5, 10, 15]
    let y = @[2.0, 4.0, 6.0]

    var df2: SEXP
    Rctx:
      let df = data.frame(Col1 = x, Col2 = y)
      df2 = data.frame(Col1 = x, Col2 = y)

    ## TODO: fix up this test!
    let exp = """
c(5, 10, 15), c(2, 4, 6)
"""
    check R.makeString(df).to(string).strip == exp.strip
    check R.makeString(df2).to(string).strip == exp.strip
