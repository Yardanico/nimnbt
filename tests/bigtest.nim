import ../src/nimnbt, streams, unittest, tables, os




suite "bigtest.nbt":
  #var data = newFileStream("bigtest.nbt")

  checkpoint "Parsing NBT (gzip compressed)"
  var tag = parseNbtFile(getAppDir() / "bigtest_gzip.nbt")

  test "root compound":
    check(tag.kind == Compound)
    check(tag.name == "Level")
    check(tag.len == 11)

  test "nested compound test":
    let nested = tag["nested compound test"]
    check(nested.len == 2)
    checkpoint("egg")
    let egg = nested["egg"]
    check(egg.len == 2)
    check(egg["name"].str == "Eggbert")
    check(egg["value"].floatVal == 0.5)
    checkpoint("ham")
    let ham = nested["ham"]
    check(ham.len == 2)
    check(ham["name"].str == "Hampus")
    check(ham["value"].floatVal == 0.75)

  test "intTest":
    check(tag["intTest"].intVal == 2147483647)

  test "byteTest":
    check(tag["byteTest"].byteVal == 127)

  test "stringTest":
    check(tag["stringTest"].str == "HELLO WORLD THIS IS A TEST STRING \xc3\x85\xc3\x84\xc3\x96!")

  test "listTest (long)":
    let list = tag["listTest (long)"]
    check(list.len == 5)
    var values: seq[int64]
    for value in list.values:
      values.add(value.longVal)
    check(values == @[11'i64, 12, 13, 14, 15])

  test "doubleTest":
    check(tag["doubleTest"].doubleVal == 0.49312871321823148'f64)

  test "floatTest":
    check(tag["floatTest"].floatVal == 0.49823147058486938'f32)

  test "longTest":
    check(tag["longTest"].longVal == 9223372036854775807)

  test "listTest (compound)":
    let list = tag["listTest (compound)"]
    check(list.len == 2)
    for i, value in list.values:
      check(value.len == 2)
      check(value["created-on"].longVal == 1264099775885'i64)
      check(value["name"].str == "Compound tag #" & $i)

  test "byteArrayTest":
    const name = "byteArrayTest (the first 1000 values of (n*n*255+n*7)%100, starting with n=0 (0, 62, 34, 16, 8, ...))"
    for n in 0 ..< 1000:
      check(tag[name].bytes[n] == (n * n * 255 + n * 7) mod 100)

  test "shortTest":
    let shortTag = tag["shortTest"]
    check(shortTag.shortVal == 32767)
