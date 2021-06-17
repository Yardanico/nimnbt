import ../src/nimnbt, ../src/nimnbt/[parse, convert]
import unittest, tables, os


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

suite "Check convert":
  checkpoint "Convert to NBT (gzip compressed)"

  test "Tag -> NBT -> Tag -> NBT":
    var tag = parseNbtFile(getAppDir() / "bigtest_gzip.nbt")
    var nbt = toNbtCompressed(tag)
    var nbt2 = parseNbt(nbt).toNbtCompressed
    check(nbt == nbt2)

  test "Compound":
    var tag = Tag(kind: Compound, name: "Test")
    var nbt = toNbt(tag).parseNbt
    check(nbt.kind == Compound)
    check(nbt.name == "Test")
    check(nbt.len == 0)
  
  test "Compound with one value":
    var tag = Tag(kind: Compound)
    tag.compound["Test"] = Tag(kind: Compound, name: "Test")
    var nbt = toNbt(tag).parseNbt
    check(nbt.len == 1)
    check(nbt["Test"].kind == Compound)
    check(nbt["Test"].name == "Test")
    check(nbt["Test"].len == 0)

  test "nested compound test":
    var tag = Tag(kind: Compound)
    var tag_nested = Tag(kind: Compound, name: "nested compound test")
    var tag_egg = Tag(kind: Compound, name: "egg")
    tag_egg.compound["name"] = Tag(kind: String, name: "name", str: "Eggbert")
    tag_egg.compound["value"] = Tag(kind: Float, name: "value", floatVal: 0.5)
    var tag_ham = Tag(kind: Compound, name: "ham")
    tag_ham.compound["name"] = Tag(kind: String, name: "name", str: "Hampus")
    tag_ham.compound["value"] = Tag(kind: Float, name: "value", floatVal: 0.75)
    tag_nested.compound["egg"] = tag_egg
    tag_nested.compound["ham"] = tag_ham
    tag.compound["nested compound test"] = tag_nested
    var nbt = toNbt(tag).parseNbt


    let nested = nbt["nested compound test"]
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
    var tag = Tag(kind: Compound)
    tag.compound["intTest"] = Tag(kind: Int, name: "intTest", intVal: 2147483647)
    var nbt = toNbt(tag).parseNbt
    check(nbt["intTest"].intVal == 2147483647)

  test "byteTest":
    var tag = Tag(kind: Compound)
    tag.compound["byteTest"] = Tag(kind: Byte, name: "byteTest", byteVal: 127)
    var nbt = toNbt(tag).parseNbt
    check(nbt["byteTest"].byteVal == 127)

  test "stringTest":
    var tag = Tag(kind: Compound)
    tag.compound["stringTest"] = Tag(kind: String, name: "stringTest", str: "HELLO WORLD THIS IS A TEST STRING \xc3\x85\xc3\x84\xc3\x96!")
    var nbt = toNbt(tag).parseNbt
    check(nbt["stringTest"].str == "HELLO WORLD THIS IS A TEST STRING \xc3\x85\xc3\x84\xc3\x96!")
