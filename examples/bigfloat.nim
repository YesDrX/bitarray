import ../src/bitarray

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

proc `$`*(x : Float1024): string=
    if x.isInfinite:
        if x.isPositive:
            return "+inf"
        else:
            return "-inf"
    elif x.isNaN:
        return "nan"
    else:
        if x.testBit(0):
            result &= "-"
        result &= "tbd"

when isMainModule:
    var
        a = initFloat1024()
    a.setAll
    # a.clearBit(0)
    echo a