import sequtils
import ../rnim
import unittest

# Intialize the embedded R environment.
let R = setupR()

source("tests/foo.R")

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

suite "R stdlib function calls":
  test "Calls without named arguments":
    check R.sum(@[1, 2, 3]).to(int) == 6
    # NOTE: cannot be called via `.()` call, use callEval directly
    check callEval(`+`, 5, 10).to(int) == 15
  test "Calls with named arguments":
    check R.seq(1, 10, by = 1).to(seq[int]) == toSeq(1 .. 10)

suite "R function with … arguments":
  test "Named param after …":
    check R.dotFn(param = "It got back!").to(string) == "It got back!"
