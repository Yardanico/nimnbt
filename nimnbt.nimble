# Package

version       = "0.1.0"
author        = "Yardanico (Daniil Yarantsev)"
description   = "NBT parsing in Nim"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.18.1"
requires "zip"

task test, "Runs the test suite":
  exec "nimble install -y zip"
  exec "nim c -r tests/bigtest.nim"