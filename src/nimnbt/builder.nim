import ../nimnbt, tables

proc TAG_End*(): Tag =
  result = Tag(kind: End)

proc TAG_Byte*(name: string = "", val: int8 = 0): Tag =
  result = Tag(kind: Byte, name: name, byteVal: val)

proc TAG_Short*(name: string = "", val: int16 = 0): Tag =
  result = Tag(kind: Short, name: name, shortVal: val)

proc TAG_Int*(name: string = "", val: int32 = 0): Tag =
  result = Tag(kind: Int, name: name, intVal: val)

proc TAG_Long*(name: string = "", val: int64 = 0): Tag =
  result = Tag(kind: Long, name: name, longVal: val)

proc TAG_Float*(name: string = "", val: float32 = 0.0): Tag =
  result = Tag(kind: Float, name: name, floatVal: val)

proc TAG_Double*(name: string = "", val: float64 = 0.0): Tag =
  result = Tag(kind: Double, name: name, doubleVal: val)

proc TAG_Byte_Array*(name: string = "", val: seq[int8] = newSeq[int8]()): Tag =
  result = Tag(kind: ByteArray, name: name, bytes: val)

proc TAG_String*(name: string = "", val: string = ""): Tag =
  result = Tag(kind: String, name: name, str: val)

proc TAG_List*(name: string = "", typ: TagKind = End, val: seq[Tag] = newSeq[Tag]()): Tag =
  result = Tag(kind: List, name: name, values: val)
  result.typ = if val.len == 0: End else: val[0].kind

proc TAG_Compound*(name: string = "", tags: seq[Tag] = newSeq[Tag]()): Tag =
  result = Tag(kind: Compound, name: name)
  for tag in tags:
    result.compound[tag.name] = tag

proc TAG_Int_Array*(name: string = "", val: seq[int32] = newSeq[int32]()): Tag =
  result = Tag(kind: IntArray, name: name, ints: val)

proc TAG_Long_Array*(name: string = "", val: seq[int64] = newSeq[int64]()): Tag =
  result = Tag(kind: LongArray, name: name, longs: val)