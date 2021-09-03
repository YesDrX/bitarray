import bitops

type BlockInt* = uint
when int.sizeof == 16:
  # maybe in the future, we can have 128-bit cpu.
  const BLOCK_LEN_POWER_2* = 7
elif int.sizeof == 8:
  const BLOCK_LEN_POWER_2* = 6
elif int.sizeof == 4:
  const BLOCK_LEN_POWER_2* = 5
elif int.sizeof == 2:
  const BLOCK_LEN_POWER_2* = 4
elif int.sizeof == 1:
  const BLOCK_LEN_POWER_2* = 3
else:
  quit "what kind of cpu you have?"

## BLOCK_LEN 
##      is the number of bits taken by one BlockInt (64 on a 64-bit CPU.)
## 
## BLOCK_HEADS_BITS
##      is a sequence of length (BLOCK_LEN + 1), in which BLOCK_HEADS_BITS[i] is a BlockInt with i leading 1 (set) bits.
## 
## BLOCK_TAILS_BITS
##      is a sequence of length (BLOCK_LEN + 1), in which BLOCK_TAILS_BITS[i] is a BlockInt with i trailing 1 (set) bits.
## 


const
  BLOCK_LEN* = BlockInt.sizeof * 8

var
  BLOCK_HEADS_BITS* = newSeq[BlockInt](BLOCK_LEN + 1)
  BLOCK_TAILS_BITS* = newSeq[BlockInt](BLOCK_LEN + 1)
BLOCK_HEADS_BITS[BLOCK_LEN] = BlockInt.high
BLOCK_TAILS_BITS[BLOCK_LEN] = BlockInt.high
for i in countdown(BLOCK_LEN-1, 0, 1):
  BLOCK_HEADS_BITS[i] = BLOCK_HEADS_BITS[i + 1].shl(1)
  BLOCK_TAILS_BITS[i] = BLOCK_TAILS_BITS[i + 1].shr(1)

proc toBin*(x: BlockInt): string {.noSideEffect.} =
  ## Converts `x` (BlockInt) into its binary representation.
  ##
  ## The resulting string is always `len` characters long. No leading ``0b``
  ## prefix is generated.
  ## 
  for j in countdown(BLOCK_LEN-1, 0):
    result = result & (if testBit(x,j): "1" else: "0")

# when isMainModule:
#   echo "HEAD BITS WITH LEADING ONES"
#   for bit in BLOCK_HEADS_BITS:
#     echo bit.toBin(64)
#   echo "HEAD BITS WITH TAIL ONES"
#   for bit in BLOCK_TAILS_BITS:
#     echo bit.toBin(64)