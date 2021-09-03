import ../src/bitarray
import precisionOperation
from powerOfTwos import POWER_OF_TWO

type
    ## |<-1 sign bit->|<-191 exp bits->|<-832 significand bits->|
    ## special numbers
    ## +inf : |0|111...111|000...000|
    ## -inf : |1|111...111|000...000|
    ## nan  : |0|111...111|000...001|
    ## nan  : |0|111...111|111...111|
    ## nan  : |0|111...111|100...001|
    Float1024* = ref object of BitsArray
    
const
    FLOAT1024_BITS* = 1024
    SIGN_BITS* = 1
    EXP_BITS* = 191
    SIGNIFICANT_BITS* = 832
    SIGNIFICANT_DIGITS* = 250

proc initFloat1024*():Float1024 =
    return cast[Float1024](newBitsArray(1024))

proc isPositive*(x : Float1024): bool=
    return not x.testBit(0)

proc isNegative*(x : Float1024): bool=
    return x.testBit(0)

proc isInfinite*(x : Float1024): bool=
    if x[SIGN_BITS ..< SIGN_BITS+EXP_BITS].countSetBits == EXP_BITS and
        x[SIGN_BITS+EXP_BITS ..< FLOAT1024_BITS].countSetBits == 0:
            return true
    return false

proc isNaN*(x : Float1024): bool=
    if x.testBit(0):
        return false
    if not x[SIGN_BITS ..< SIGN_BITS+EXP_BITS].countSetBits == EXP_BITS:
        return false
    var
        significand_set_bits = x[SIGN_BITS+EXP_BITS ..< FLOAT1024_BITS].countSetBits
    if significand_set_bits != 1 and significand_set_bits != 2 and significand_set_bits != SIGNIFICANT_BITS:
        return false
    if significand_set_bits == 1 and not x.testBit(FLOAT1024_BITS-1):
        return false
    if significand_set_bits == 2 and not (x.testBit(FLOAT1024_BITS-1) and x.testBit(SIGN_BITS+EXP_BITS)):
        return false
    return true

proc getDecimalRepresentaion(x: Float1024): string=
    var
        exp_part = x[SIGN_BITS .. SIGN_BITS+EXP_BITS-1]
        significand_part = x[SIGN_BITS+EXP_BITS .. (x.len-1)]
        sign_dec, exp_dec, sig_dec: string
    sign_dec = if x.testBit(0): "-" else: ""
    exp_part.expand(EXP_BITS+1)
    exp_part = exp_part.shr(1)
    exp_dec = blocksToDecimal(exp_part.bits)
    exp_dec = slowSub(exp_dec, POWER_OF_TWO[EXP_BITS-1])
    exp_dec = slowAdd(exp_dec, "1")
    exp_dec = slowMultiply(exp_dec, ln2Toln10[2..(ln2Toln10.len-1)])
    exp_dec = exp_dec[0 .. (exp_dec.len-(ln2Toln10.len-2)-1)]
    sig_dec = slowDivide(blocksToDecimal(significand_part.bits), POWER_OF_TWO[SIGNIFICANT_BITS-1], SIGNIFICANT_DIGITS)
    return sign_dec & sig_dec & " E " & exp_dec

proc `$`*(x : Float1024): string=
    if x.isInfinite:
        if x.isPositive:
            return "+inf"
        else:
            return "-inf"
    elif x.isNaN:
        return "nan"
    else:
        return x.getDecimalRepresentaion

when isMainModule:
    var
        a = initFloat1024()
    a.setAll
    # a.clearBit(0)
    echo a
    # echo slowAdd("-1","1")