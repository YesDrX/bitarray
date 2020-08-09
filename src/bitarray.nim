import bitops
import strutils

const
  BLOCK_LEN* = uint.sizeof * 8

type
  BitsArray* = ref object
    bits*: seq[uint]
    len*: int

proc newBitsArray*(len: int): BitsArray=
  var
    int_len = len div BLOCK_LEN
  if len mod BLOCK_LEN > 0 : int_len += 1
  result = BitsArray(bits: newSeq[uint](int_len), len: len)

proc blocks*(bit_arr: BitsArray): int=
  result = bit_arr.len div BLOCK_LEN
  if bit_arr.len mod BLOCK_LEN > 0 : result += 1

proc `$`*(bit_arr: BitsArray): string=
  result = ""
  if bit_arr.len mod BLOCK_LEN == 0:
    for i in 0 ..< bit_arr.blocks:
      result &= bit_arr.bits[i].int.toBin(BLOCK_LEN)
  else:
    for i in 0 ..< (bit_arr.blocks - 1):
      result &= bit_arr.bits[i].int.toBin(BLOCK_LEN)
    result &= bit_arr.bits[bit_arr.blocks-1].int.toBin(BLOCK_LEN)[0 .. (bit_arr.len mod BLOCK_LEN - 1)]

proc get_bit_position*(loc: int): (int, int)=
  var
    block_loc = loc div BLOCK_LEN
    in_block_loc = loc mod BLOCK_LEN
  result = (block_loc, BLOCK_LEN - in_block_loc - 1)

proc setBit*(bit_arr: BitsArray, loc: int) =
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  setBit(bit_arr.bits[block_loc], in_block_loc)

proc clearBit*(bit_arr: BitsArray, loc: int) =
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  clearBit(bit_arr.bits[block_loc], in_block_loc)

proc flipBit*(bit_arr: BitsArray, loc: int) =
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  flipBit(bit_arr.bits[block_loc], in_block_loc)

proc testBit*(bit_arr: BitsArray, loc: int): bool =
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  testBit(bit_arr.bits[block_loc], in_block_loc)

proc countSetBits*(bit_arr: BitsArray): int =
  result = 0
  if bit_arr.len mod BLOCK_LEN > 0:
    for i in (bit_arr.len mod BLOCK_LEN) ..< BLOCK_LEN:
      bit_arr.bits[bit_arr.blocks-1].clearBit(i)
  for i in 0 ..< bit_arr.blocks:
    result += bit_arr.bits[i].countSetBits

proc `&`*(a, b: BitsArray): BitsArray =
  assert( a.len == b.len)

  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitand(a.bits[i], b.bits[i])

proc `|`*(a, b: BitsArray): BitsArray =
  assert( a.len == b.len)

  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitor(a.bits[i], b.bits[i])

proc `~`*(a: BitsArray): BitsArray =
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitnot(a.bits[i])

proc `^`*(a,b : BitsArray): BitsArray =
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitxor(a.bits[i], b.bits[i])

proc `[]`*(a: BitsArray, loc: int): bool=
  result = a.testBit(loc)

proc `[]`*(a: BitsArray, locs: openArray[int]): BitsArray=
  result = newBitsArray(locs.len)
  for i, loc in locs:
    if a.testBit(loc):
      result.setBit(i)

proc `[]`*(a: BitsArray, locs: HSlice): BitsArray=
  var
    l = if (locs.a is BackwardsIndex): -locs.a.int else: locs.a.int
    r = if (locs.b is BackwardsIndex): -locs.b.int else: locs.b.int
  if r < 0: r = a.len + r
  if l < 0: l = a.len + l

  result = newBitsArray(r - l + 1)
  var
    i = 0
  for loc in l .. r:
    if a.testBit(loc):
      result.setBit(i)
    i += 1

proc `[]=`*(a: BitsArray, loc: int, value: bool) =
  if value:
    a.setBit(loc)
  else:
    a.clearBit(loc)

proc `[]=`*(a: BitsArray, locs: openArray[int], value: bool) =
  if value:
    for loc in locs:
      a.setBit(loc)
  else:
    for loc in locs:
      a.clearBit(loc)

proc `[]=`*(a: BitsArray, locs: HSlice, value: bool) =
  var
    l = if (locs.a is BackwardsIndex): -locs.a.int else: locs.a.int
    r = if (locs.b is BackwardsIndex): -locs.b.int else: locs.b.int
  if r < 0: r = a.len + r
  if l < 0: l = a.len + l

  var
    i = 0
  if value:
    for loc in l .. r:
      a.setBit(loc)
      i += 1
  else:
    for loc in l .. r:
      a.clearBit(loc)
      i += 1

proc copy*(a: BitsArray): BitsArray=
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = a.bits[i]

proc swap*(a, b: BitsArray) =
  assert(a.len == b.len)

  for i in 0 ..< a.blocks:
    swap(a.bits[i], b.bits[i])

proc setAll*(a: BitsArray) =
  for i in 0 ..< a.blocks:
    a.bits[i] = uint.high

proc clearAll*(a: BitsArray) =
  for i in 0 ..< a.blocks:
    a.bits[i] = uint.low

proc flipAll*(a: BitsArray) =
  for i in 0 ..< a.blocks:
    a.bits[i] = bitnot(a.bits[i])

proc sum*(a: BitsArray): int=
  result = a.countSetBits

proc nbytes*(a:BitsArray): int=
  result = a.blocks * uint.sizeof

export bitops, strutils

when isMainModule:
  var
    a = newBitsArray(70)
    b = newBitsArray(70)
  
  echo a
  echo b
  a.setBits(0,1,2)
  b.setAll
  echo a & b
  echo a | b
  echo a ^ b
  echo ~a
  echo a.nbytes