# Package

version       = "0.2.0"
author        = "Yardanico (Daniil Yarantsev)"
description   = "NBT format implementation in Nim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 1.4.0"
requires "zip"

task test, "Runs the test suite":
  exec "nimble install -y zip"
  exec "nim c -r tests/bigtest.nim"
