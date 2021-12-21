# Package

version       = "0.1.4"
author        = "Vindaar"
description   = "A library to interface between Nim and R"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.3.7"

task test, "Run all tests":
  # tests that call R from Nim side
  exec "nim c -r tests/tRfromNim.nim"
  # tests that call Nim from R side
  # compile shared library
  exec "cd tests && nim c --app:lib tNimFromR.nim"
  # call the code
  exec "Rscript tests/tCallNimFromR.R"

  # and the examples
  exec "nim c -r examples/hello_README.nim"
