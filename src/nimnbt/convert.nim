import ../nimnbt, streams, endians, tables
import zip/zlib 

const isLittle = system.cpuEndian == littleEndian

template endian(x: untyped): untyped =
  ## A convenient template to swap endianness of variables to big endian
  # When we are on big-endian platform, we don't need to change endianness
  when not isLittle:
    x
  else:
    var val = x
    when isLittle:
      when sizeof(x) == 2:
        bigEndian16(addr val, addr val)
      elif sizeof(x) == 4:
        bigEndian32(addr val, addr val)
      elif sizeof(x) == 8:
        bigEndian64(addr val, addr val)
      else: discard
    val

proc writeString(strm: StringStream, str: string) =
  strm.write(endian(str.len.uint16))
  strm.write(str)

proc toNbtInternal(t: Tag, strm: StringStream, withName: bool = true, kind: TagKind = End) =
  var k = if kind == End: t.kind else: kind
  if (kind == End):
    strm.write(t.kind.uint8)
  if withName: strm.writeString(t.name)

  case k
  of End: return
  of Byte:
    strm.write(t.byteVal)
  of Short:
    strm.write(endian(t.shortVal))
  of Int:
    strm.write(endian(t.intVal))
  of Long:
    strm.write(endian(t.longVal))
  of Float:
    strm.write(endian(t.floatVal))
  of Double:
    strm.write(endian(t.doubleVal))
  of ByteArray:
    strm.write(endian(t.bytes.len.uint32)) # size
    for b in t.bytes:
      strm.write(endian(b.int8))
  of String:
    strm.writeString(t.str)
  of List:
    strm.write(endian(t.typ.uint8)) # type
    strm.write(endian(t.values.len.uint32)) # size
    for v in t.values:
      toNbtInternal(v, strm, false, t.typ)
  of Compound:
    for k, v in t.compound.pairs:
      toNbtInternal(v, strm)
    strm.write(endian(0'u8)) # end
  of IntArray:
    strm.write(endian(t.ints.len.uint32)) # size
    for i in t.ints:
      strm.write(endian(i.int32))
  of LongArray:
    strm.write(endian(t.longs.len.uint32)) # size
    for l in t.longs:
      strm.write(endian(l.int64))




proc toNbt*(t: Tag): string =
  ## Convert tags to NBT data structure
  var strm = newStringStream()
  t.toNbtInternal(strm)
  strm.setPosition 0
  result = strm.readAll

proc toNbtCompressed*(t: Tag, compress_type: ZStreamHeader = GZIP_STREAM): string =
  ## Convert tags to NBT data structure with compress
  result = compress(toNbt(t), 6, compress_type)