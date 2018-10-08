# NBT parsing in Nim. Implemented with the help from http://wiki.vg/NBT
import streams, endians, tables
import zip/zlib # Wrapper for the libzip library


type
  TagKind* = enum
    End, Byte, Short, Int, Long, Float, Double, ByteArray, 
    String, List, Compound, IntArray, LongArray
  
  Tag* = object
    name*: string
    case kind*: TagKind
    of End: discard
    of Byte: byteVal*: int8
    of Short: shortVal*: int16
    of Int: intVal*: int32
    of Long: longVal*: int64
    of Float: floatVal*: float32
    of Double: doubleVal*: float64  # XXX: this might be incorrect
    of ByteArray: bytes*: seq[int8]
    of String: str*: string
    of List:
      typ*: TagKind  ## List type 
      values*: seq[Tag]
    of Compound: compound*: Table[string, Tag]
    of IntArray: ints: seq[int32]
    of LongArray: longs: seq[int64]


const isLittle = system.cpuEndian == littleEndian

template endian(x: untyped, size: static[int]): untyped =
  ## A convenient template to swap endianness of variables to big endian
  var val = x
  when isLittle:
    when size == 16:
      bigEndian16(addr val, addr val)
    elif size == 32:
      bigEndian32(addr val, addr val)
    elif size == 64:
      bigEndian64(addr val, addr val)
    else: discard
  val


proc readString(s: Stream): string {.inline.} = 
  # Thankfully strings in NBT are UTF-8 (same as in Nim)
  let len = endian(s.readUint16(), 16)
  if len == 0: ""
  else: s.readStr(int(len))


proc parseNbtInternal(s: Stream, tagKind = End, parseName = true): Tag =
  result.kind = if tagKind == End: TagKind(s.readUint8()) else: tagKind
  if result.kind == End: return

  if parseName: result.name = s.readString()

  case result.kind
  of End: return
  of Byte:
    result.byteVal = s.readInt8()
  of Short: 
    result.shortVal = endian(s.readInt16(), 16)
  of Int:
    result.intVal = endian(s.readInt32(), 32)
  of Long:
    result.longVal = endian(s.readInt64(), 64)
  of Float:
    result.floatVal = endian(s.readFloat32(), 32)
  of Double:
    result.doubleVal = endian(s.readFloat64(), 64)
  of ByteArray:
    let size = endian(s.readInt32(), 32)
    var i = 0
    result.bytes = newSeqOfCap[int8](size)

    while i < size:
      result.bytes.add(s.readInt8())
      inc(i)
  of String:
    result.str = s.readString()
  of List:
    result.typ = TagKind(s.readUint8())
    let size = endian(s.readInt32(), 32)
    var i = 0
    result.values = newSeqOfCap[Tag](size)

    while i < size:
      # Tags in lists don't have names at all
      result.values.add(s.parseNbtInternal(result.typ, parseName = false))
      inc(i)
  of Compound:
    result.compound = initTable[string, Tag]()
    while true:
      var nextTag = s.parseNbtInternal()
      if nextTag.kind == End: break
      result.compound[nextTag.name] = nextTag
  of IntArray:
    let size = endian(s.readInt32(), 32)
    var i = 0
    result.ints = newSeqOfCap[int32](size)

    while i < size:
      result.ints.add(endian(s.readInt32(), 32))
      inc(i)
  of LongArray:
    let size = endian(s.readInt32(), 32)
    var i = 0
    result.longs = newSeqOfCap[int64](size)

    while i < size:
      result.longs.add(endian(s.readInt64(), 64))
      inc(i)


proc decompress(s: string): StringStream {.inline.} = 
  result = newStringStream(
    if s[0..2] == "\x1f\x8b\x08": 
      uncompress(s, len(s), GZIP_STREAM)
    elif s[0] == 'x' and s[1] in {'\x01', '\x9c', '\xDA'}:
      uncompress(s, len(s), ZLIB_STREAM)
    else:
      s
  )


proc parseNbt*(s: Stream): Tag {.inline.} = 
  ## Parses NBT data structure from the stream *s*.
  ##
  ## *s* may be compressed via gzip/zlib
  result = parseNbtInternal(s)


proc parseNbtFile*(filename: string): Tag {.inline.} = 
  ## Parses NBT data structure from the file *filename*.
  ##
  ## File may be compressed via gzip/zlib
  let data = readFile(filename)
  result = parseNbtInternal(decompress(data))


proc parseNbt*(s: string): Tag {.inline.} = 
  ## Parses NBT data structure from the string *s*
  ##
  ## *s* may be compressed via gzip/zlib
  result = parseNbtInternal(decompress(s))

proc `[]`*(t: Tag, name: string): Tag {.inline.} = 
  ## A convenient proc to access tag in the compound
  t.compound[name]


proc len*(t: Tag): int {.inline.} = 
  ## A convenient proc to access length of some container types
  ## Works for ByteArray, String, List, Compound, IntArray, LongArray
  case t.kind
  of ByteArray: t.bytes.len
  of String: t.str.len
  of List: t.values.len
  of Compound: t.compound.len
  of IntArray: t.ints.len
  of LongArray: t.longs.len
  else: raise newException(ValueError, "invalid tag kind!")