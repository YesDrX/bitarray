import bitops
import strutils
import utils
export bitops, strutils, utils

## BitsArray Type
##     bits is a sequence of BlockInt (uint64/uint32/uint16/uint8, depending on CPU)
## 
##     len is the number of bits
## 
## BitsArray is saved in BlockInt blocks
## 
## For example, on a 64-bit machine, memory layout of BitsArray.bits is
## 
## |               |               |               |   |               |
## 
## |<---64 bits--->|<---64 bits--->|<---64 bits--->|...|<---64 bits--->|
## 
## |               |               |               |   |               |
## 
## Bits are left aligned, so when (len mod 64 != 0), the last (64 - len mod 64) bits memory is wasted.
## 
## You may change the underlying BlockInt definition (in utils) to force define BlockInt to a different len, say 16-bits on a 64-bits CPU.
## 
## NOTE: Bits are left aligned, so least significant bit is at location 0. So 10000110 is equal to 127 ('a'), rather than 134. Use proc reverseBits when necessary.
## 
## 
type
  BitsArray* = ref object
    bits*: seq[BlockInt]
    len*: int

proc newBitsArray*(len: int): BitsArray=
  ## Construct a new BitsArray with len bits.
  var
    int_len = len div BLOCK_LEN
  if len mod BLOCK_LEN > 0 : int_len += 1
  result = BitsArray(bits: newSeq[BlockInt](int_len), len: len)

proc blocks*(bit_arr: BitsArray): int=
  ## Get the number of blocks (BlockInt) saved. For example, a 70 bits array takes 2 blocks.
  result = bit_arr.len div BLOCK_LEN
  if bit_arr.len mod BLOCK_LEN > 0 : result += 1

proc `$`*(bit_arr: BitsArray): string=
  ## Return the 0-1 string representation of the BitsArray.
  result = ""
  if bit_arr.len mod BLOCK_LEN == 0:
    for i in 0 ..< bit_arr.blocks:
      result &= bit_arr.bits[i].toBin(BLOCK_LEN)
  else:
    for i in 0 ..< (bit_arr.blocks - 1):
      result &= bit_arr.bits[i].toBin(BLOCK_LEN)
    result &= bit_arr.bits[bit_arr.blocks-1].toBin(BLOCK_LEN)[0 .. (bit_arr.len mod BLOCK_LEN - 1)]

proc get_bit_position*(loc: int): (int, int)=
  ## Given a bit location (0<=loc<=len)
  ## return
  ##        (block location: int, location inside the block: int)
  ## 
  var
    block_loc = loc div BLOCK_LEN
    in_block_loc = loc mod BLOCK_LEN
  result = (block_loc, in_block_loc)

proc setBit*(bit_arr: BitsArray, loc: int) =
  ## Set bit value at location loc to be 1.
  ## 
  ## With macros from bitops, you may use setBits to set multiple bits.
  ## 
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  setBit(bit_arr.bits[block_loc], in_block_loc)

proc clearBit*(bit_arr: BitsArray, loc: int) =
  ## Set bit value at location loc to be 0.
  ## 
  ## With macros from bitops, you may use setBits to clear multiple bits.
  ## 
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  clearBit(bit_arr.bits[block_loc], in_block_loc)

proc flipBit*(bit_arr: BitsArray, loc: int) =
  ## Flip bit value at location loc.
  ## 
  ## With macros from bitops, you may use setBits to flip multiple bits.
  ## 
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  flipBit(bit_arr.bits[block_loc], in_block_loc)

proc testBit*(bit_arr: BitsArray, loc: int): bool =
  ## Check whether bit value at location loc is equal to 1.
  ## 
  var
    (block_loc, in_block_loc) = loc.get_bit_position
  testBit(bit_arr.bits[block_loc], in_block_loc)

proc countSetBits*(bit_arr: BitsArray): int =
  ## Counts the set bits in integer. (also called Hamming weight.)
  result = 0
  if bit_arr.len mod BLOCK_LEN > 0:
    for i in (bit_arr.len mod BLOCK_LEN) ..< BLOCK_LEN:
      bit_arr.bits[bit_arr.blocks-1].clearBit(i)
  for i in 0 ..< bit_arr.blocks:
    result += bit_arr.bits[i].countSetBits

proc `&`*(a, b: BitsArray): BitsArray =
  ## Computes the bitwise and of a and b.
  ## 
  assert( a.len == b.len)

  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitand(a.bits[i], b.bits[i])

proc `|`*(a, b: BitsArray): BitsArray =
  ## Computes the bitwise or of a and b.
  ## 
  assert( a.len == b.len)

  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitor(a.bits[i], b.bits[i])

proc `~`*(a: BitsArray): BitsArray =
  ## Computes the bitwise not of a.
  ## 
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitnot(a.bits[i])

proc `^`*(a,b : BitsArray): BitsArray =
  ## Computes the bitwise xor of a and b.
  ## 
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = bitxor(a.bits[i], b.bits[i])

proc `[]`*(a: BitsArray, loc: int): bool=
  ## Test bit value at loc.
  ## 
  result = a.testBit(loc)

proc `[]`*(a: BitsArray, locs: openArray[int]): BitsArray=
  ## Slice the BitsArray with the given locs.
  ## 
  result = newBitsArray(locs.len)
  for i, loc in locs:
    if a.testBit(loc):
      result.setBit(i)

proc `[]`*(a: BitsArray, locs: HSlice): BitsArray=
  ## Slice the BitsArray with the given locs.
  ## 
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
  ## Assign bit at loc to value.
  ## 
  if value:
    a.setBit(loc)
  else:
    a.clearBit(loc)

proc `[]=`*(a: BitsArray, locs: openArray[int], value: bool) =
  ## Assign bit at locs to value.
  ## 
  if value:
    for loc in locs:
      a.setBit(loc)
  else:
    for loc in locs:
      a.clearBit(loc)

proc `[]=`*(a: BitsArray, locs: HSlice, value: bool) =
  ## Assign bit at locs to value.
  ## 
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
  ## Make a new copy of BitsArray (different memory locations).
  ## 
  result = newBitsArray(a.len)
  for i in 0 ..< a.blocks:
    result.bits[i] = a.bits[i]

proc swap*(a, b: BitsArray) =
  ## Swap a and b.
  assert(a.len == b.len)

  for i in 0 ..< a.blocks:
    swap(a.bits[i], b.bits[i])

proc setAll*(a: BitsArray) =
  ## Set all bits to be 1.
  ## 
  for i in 0 ..< a.blocks:
    a.bits[i] = BlockInt.high

proc clearAll*(a: BitsArray) =
  ## Set all bits to be 0.
  ## 
  for i in 0 ..< a.blocks:
    a.bits[i] = BlockInt.low

proc flipAll*(a: BitsArray) =
  ## Flip all bits.
  ## 
  for i in 0 ..< a.blocks:
    a.bits[i] = bitnot(a.bits[i])

proc sum*(a: BitsArray): int=
  ## Return number of bits of value 1.
  ##
  result = a.countSetBits

proc nbytes*(a:BitsArray): int=
  ## Return number of bytes (8 * bits) taken by the BitsArray.bits.
  ##
  result = a.blocks * BlockInt.sizeof

proc `shl`*(a: BitsArray, steps: SomeInteger): BitsArray=
  ## Return a new BitsArray, where bits are shifted left by steps.
  ##
  runnableExamples:
    var a = newBitsArray(70)
    a.setBits(69)
    var b = a.shl(69)
    doAssert a.`$` == "0000000000000000000000000000000000000000000000000000000000000000000001"
    doAssert b.`$` == "1000000000000000000000000000000000000000000000000000000000000000000000"
  
  result = newBitsArray(a.len)
  var
    blocks_to_abandon = steps div BLOCK_LEN
    blocks_to_keep = a.blocks - blocks_to_abandon
    shifts_in_block = steps mod BLOCK_LEN
    block_idx: int
    left_shifted: BlockInt = 0.BlockInt

  for i in countdown(blocks_to_keep-1,0):
    block_idx = i + blocks_to_abandon
    result.bits[i] = a.bits[block_idx].shr(shifts_in_block)
    if i > 0:
      result.bits[i] = result.bits[i].bitor(left_shifted)
    left_shifted = a.bits[block_idx].bitand(BLOCK_HEADS_BITS[shifts_in_block])

proc `shr`*(a: BitsArray, steps: SomeInteger): BitsArray=
  ## Return a new BitsArray, where bits are shifted right by steps.
  ##
  runnableExamples:
    var a = newBitsArray(70)
    a.setBits(0)
    var b = a.shr(69)
    doAssert a.`$` == "1000000000000000000000000000000000000000000000000000000000000000000000"
    doAssert b.`$` == "0000000000000000000000000000000000000000000000000000000000000000000001"  
  result = newBitsArray(a.len)
  var
    blocks_to_abandon = steps div BLOCK_LEN
    blocks_to_keep = a.blocks - blocks_to_abandon
    shifts_in_block = steps mod BLOCK_LEN
    block_idx: int
    right_shifted: BlockInt = 0.BlockInt
  
  for i in 0 ..< blocks_to_keep:
    block_idx = a.blocks - (i + blocks_to_abandon) - 1
    result.bits[a.blocks - i - 1] = a.bits[block_idx].shl(shifts_in_block)
    if i > 0:
      result.bits[a.blocks - i - 1] = result.bits[a.blocks - i - 1].bitor(right_shifted)
    right_shifted = a.bits[block_idx].bitand(BLOCK_TAILS_BITS[shifts_in_block])

proc firstSetBit*(a: BitsArray): int=
  ## Return first location of first bit of value 1. If no bit is of value 1, -1 is returned.
  ##

  result = -1
  for i in 0 ..< a.blocks:
    if a.bits[i] > 0:
      return i * BLOCK_LEN + a.bits[i].firstSetBit - 1

proc lastSetBit*(a: BitsArray): int=
  ## Return last location of first bit of value 1. If no bit is of value 1, -1 is returned.
  ##
  result = -1
  for i in countdown(a.blocks-1, 0, 1):
    if a.bits[i] > 0:
      return i * BLOCK_LEN + a.bits[i].firstSetBit - 1

proc countLeadingZeroBits*(a: BitsArray): int=
  ## Return number of leading zero bits.
  ## 
  let
    firstOne = a.firstSetBit
  if firstOne < 0:
    result = a.len
  else:
    result = firstOne

proc countTrailingZeroBits*(a: BitsArray): int=
  ## Return number of trailing zero bits.
  ## 
  let
    lastOne = a.lastSetBit
  if lastOne < 0:
    result = a.len
  else:
    result = a.len - lastOne - 1

proc expand*(a: BitsArray, len: int) =
  ## Expand BitsArray to be of length len.
  ## 
  assert(len >= a.len)
  let
    extra_bits = len - a.len
    existing_blocks = a.blocks
    wasted_bits = a.len mod BLOCK_LEN
  a.bits[a.blocks-1] = a.bits[a.blocks-1].bitand(BLOCK_HEADS_BITS[BLOCK_LEN - wasted_bits])
  a.len = len
  let
    new_blocks = a.blocks - a.blocks
  if new_blocks > 0:
    a.bits.add(BlockInt.low)

proc concat*(a, b: BitsArray): BitsArray=
  ## Concatenate b to the right of a.
  ##
  runnableExamples:
    doAssert "a".toBitsArray.`$` == "10000110"
    doAssert "b".toBitsArray.`$` == "01000110"
    doAssert ("a".toBitsArray).concat("b".toBitsArray).`$` == "1000011001000110"

  if a.len == 0:
    return b.copy
  elif b.len == 0:
    return a.copy
  else:
    var
      wasted_bits_a = if a.len mod BLOCK_LEN > 0 : (a.len mod BLOCK_LEN) else: 0
      wasted_bits_b = if b.len mod BLOCK_LEN > 0 : (b.len mod BLOCK_LEN) else: 0
    result = newBitsArray(a.len + b.len)
    if  wasted_bits_a > 0:
      var
        head_b = b.copy()
        shifted_b = b.shl(wasted_bits_a)
      head_b.len = BLOCK_LEN
      head_b.bits[0] = head_b.bits[0].bitand(BLOCK_HEADS_BITS[a.len mod BLOCK_LEN])
      head_b = head_b.shr(a.len mod BLOCK_LEN)
      for i in 0 ..< a.blocks:
        result.bits[i] = a.bits[i]
      result.bits[a.blocks-1] = result.bits[a.blocks-1].bitand(BLOCK_HEADS_BITS[a.len mod BLOCK_LEN])
      result.bits[a.blocks-1] = result.bits[a.blocks-1].bitor(head_b.bits[0])
      for i in a.blocks ..< result.blocks:
        result.bits[i] = shifted_b.bits[i - a.blocks]
    else:
      for i in 0 ..< a.blocks:
        result.bits[i] = a.bits[i]
      for i in a.blocks ..< result.blocks:
        result.bits[i] = b.bits[i - a.blocks]

proc toBitsArray*[T: not string](a: T): BitsArray=
  ## Convert any basic type, such as int,float,bool, to a BitsArray.
  ## 
  runnableExamples:
    doAssert true.toBitsArray.`$` == "10000000"
    doAssert int8.low.toBitsArray.`$` == "00000001"

  assert a.sizeof <= BlockInt.sizeof
  result = newBitsArray(a.sizeof * 8)
  result.bits[0] = cast[BlockInt](a)

proc toBitsArray*(a: string): BitsArray=
  ## Convert string to its bits representation.
  ##
  runnableExamples:
    doAssert "a".toBitsArray.`$` == "10000110"
    doAssert "b".toBitsArray.`$` == "01000110"
    doAssert "ab".toBitsArray.`$` == "1000011001000110"

  result = newBitsArray(a.len * 8)
  var
    tmp: BitsArray
  for i in 0 ..< (a.len div BlockInt.sizeof):
    tmp = a[i * BlockInt.sizeof].toBitsArray
    for j in 1 ..< BlockInt.sizeof:
      tmp = tmp.concat(a[i * BlockInt.sizeof + j].toBitsArray)
    result.bits[i] = cast[BlockInt](a[i])
  if a.len mod BlockInt.sizeof > 0:
    var
      i = a.len div BlockInt.sizeof
    tmp = a[i * BlockInt.sizeof].toBitsArray
    for j in 1 ..< (a.len mod BlockInt.sizeof):
      tmp = tmp.concat(a[i * BlockInt.sizeof + j].toBitsArray)
    result.bits[result.blocks - 1] = tmp.bits[0]

proc binToBitsArray*(a: string): BitsArray=
  ## Convert a binary representation string to BitsArray
  ##
  runnableExamples:
    doAssert "010101".binToBitsArray.`$` == "010101"

  result = newBitsArray(a.len)
  for i in 0 ..< a.len:
    if a[i] == '1': result.setBits(i)

proc reverseBits*(a: BitsArray): BitsArray=
  ## Return the bit reversal of a.
  ## 
  runnableExamples:
    doAssert 7.uint16.toBitsArray.`$` == "1110000000000000"
    doAssert 7.uint16.toBitsArray.reverseBits.`$` == "0000000000000111"
  
  result = newBitsArray(a.len)
  var
    wasted_bits = if a.len mod BLOCK_LEN > 0: (BLOCK_LEN - a.len mod BLOCK_LEN) else : 0
    shifted_a : BitsArray
  if wasted_bits > 0:
    shifted_a = a.shr(wasted_bits)
  else:
    shallowCopy(shifted_a, a)
  for i in a.blocks-1 .. 0:
    result.bits[i - a.blocks + 1] = shifted_a.bits[i].reverseBits

when isMainModule:
  var
    a = newBitsArray(70)
    b = newBitsArray(70)
  
  echo "    a = ",a
  echo "    b = ",b
  echo "set bits ..."
  a.setBits(0,1,2,3,4,69)
  b.setBits(6,7,8,9,65)
  echo "    a = ",a
  echo "    b = ",b
  echo "a & b = ", a & b
  echo "a | b = ", a | b
  echo "a ^ b = ", a ^ b
  echo "   ~a = ", ~a
  echo "a.shl(1) =",a.shl(1)
  echo "a.shl(2) =",a.shl(2)
  echo "a.shl(3) =",a.shl(3)
  echo "a.shl(69)=",a.shl(69)
  echo "a.shr(1) =",a.shr(1)
  echo "a.shr(2) =",a.shr(2)
  echo "a.shr(3) =",a.shr(3)
  echo "a.shr(69)=",a.shr(69)

  a.expand(100)
  echo a