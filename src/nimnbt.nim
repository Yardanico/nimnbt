# A Nim library for parsing NBT file format used in Minecraft
# https://wiki.vg/NBT was used as a reference to the format

import tables, json
import zip/zlib               # Wrapper for the libzip library


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
    of Double: doubleVal*: float64 # XXX: this might be incorrect
    of ByteArray: bytes*: seq[int8]
    of String: str*: string
    of List:
      typ*: TagKind           ## List type
      values*: seq[Tag]
    of Compound: compound*: Table[string, Tag]
    of IntArray: ints*: seq[int32]
    of LongArray: longs*: seq[int64]


template `[]`*(t: Tag, name: string): Tag =
  ## A convenient proc to access tag in the compound
  assert t.kind == Compound
  t.compound[name]


template `in`*(t: Tag, name: string): bool =
  ## Check if an item with *name* is in the compound
  assert t.kind == Compound
  name in t.compound


proc len*(t: Tag): int =
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

proc toJson*(s: Tag): JsonNode =
  ## Converts an NBT tag to the JSON for printing/serialization
  case s.kind
    of Byte:
      result = newJInt(s.byteVal)
    of Short:
      result = newJInt(s.shortVal)
    of Int:
      result = newJInt(s.intVal)
    of Long:
      result = newJInt(s.longVal)
    of Float:
      result = newJFloat(s.floatVal)
    of Double:
      result = newJFloat(s.doubleVal)
    of ByteArray:
      result = newJArray()
      for itm in s.bytes:
        result.add(newJInt(itm))
    of String:
      result = newJString(s.str)
    of List:
      result = newJArray()
      for itm in s.values:
        result.add(toJson(itm))
    of Compound:
      result = newJObject()
      for k, v in s.compound:
        result.add(k, toJson(v))
    of IntArray:
      result = newJArray()
      for itm in s.bytes:
        result.add(newJInt(itm))
    of LongArray:
      var arr = newJArray()
      for itm in s.bytes:
        arr.add(newJInt(itm))
    of End:
      return

proc `$`*(t: Tag): string =
  ## Converts Tag to a string for easier debugging/visualising
  $toJson(t).pretty()
