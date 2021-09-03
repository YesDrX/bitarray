import strutils
import powerOfTwos

## The following operations are slow, and they are only intended to get decimal string representation.

const
    ln2Toln10* = "0.3010299956639811952137388947244930267681898814621085413104274611271081892744245094869272521181861720406844771914309953790947678811335235059996923337046955750645029642541934026618197343116029435011839028981785826171544395318619290463538846995202393108496124625404002633125946214788458473182826726839823261965427935076313175483509271389649469177857689180507900075995480878154597145850319648776261224922908291181909514989971716198604776765000678205179125573286286683420004029205098370845722248954942975621497072446597086136896092219094827612143914965282351678264923148040277462432441633115387382593038830393806332161302390518805821319156854616929053015051319269853784884187183200657535694683929717421320109058968908505856246409872183968766485398562351612773026389278782608498366810303084314155608139436176745488566634245381237339324224695943490602120445042968274606884785461156847684106437979500465969917745657540864018464079456529544341077408293999745400737217016801948890554856910694003754116899634157592972180644303810281520"

proc slowSmallerThan*(a, b : string) : bool=
    if a.len < b.len:
        return true
    if a.len == b.len and a < b:
        return true
    return false

proc slowSub*(a, b: string): string=
    if a == b:
        return "0"
    elif slowSmallerThan(a, b):
        return "-" & slowSub(b, a)
    else:
        var
            borrow = 0
            digit, left_digit, right_digit: int
        for i in 1 .. a.len:
            left_digit = int(a[a.len - i]) - 48
            right_digit = if b.len >= i: int(b[b.len - i]) - 48 else: 0
            digit = left_digit - right_digit - borrow
            if digit < 0:
                digit += 10
                borrow = 1
            else:
                borrow = 0
            result = digit.`$` & result
        result = result.strip(chars={'0'}, trailing=false)
        if result.len == 0: result = "0"    

proc slowAdd*(a, b: string): string=
    if a.startswith("-") and b.startswith("-"):
        return "-" & slowAdd(a[1..(a.len-1)],b[1..(a.len-1)])
    elif a.startswith("-"):
        return slowSub(b,a[1..(a.len-1)])
    elif b.startswith("-"):
        return slowSub(a,b[1..(b.len-1)])
    else:
        var
            a_len = a.len
            b_len = b.len
            carry = 0
            digit_a, digit_b, digit : int
        
        for i in 1 .. max(a_len, b_len):
            digit_a = if a_len >= i: int(a[a_len - i])-48 else: 0
            digit_b = if b_len >= i: int(b[b_len - i])-48 else: 0
            digit = digit_a + digit_b + carry
            carry = digit div 10
            digit = digit mod 10
            result = digit.`$` & result
        if carry != 0: result = carry.`$` & result
        result = result.strip(chars={'0'}, trailing=false)
        if result.len == 0: result = "0"

proc slowMultiply*(a, b : string): string=
    if a.startswith("-") and b.startswith("-"):
        return slowMultiply(a[1..(a.len-1)],b[1..(b.len-1)])
    elif a.startswith("-"):
        return "-" & slowMultiply(a[1..(a.len-1)],b)
    elif b.startswith("-"):
        return "-" & slowMultiply(a,b[1..(b.len-1)])
    else:
        var
            a_len = a.len
            b_len = b.len
            left, right : string
        
        if a_len < b_len:
            left = b
            right = a
        else:
            left = a
            right = b

        var
            middle = newSeq[string](right.len)
            digit, left_digit, right_digit : int
            carry = 0
            middle_result : string
        
        for i in 1 .. right.len:
            carry = 0
            middle_result = ""
            right_digit = int(right[right.len - i]) - 48
            for j in 1 .. left.len:
                left_digit = int(left[left.len - j]) - 48
                digit = left_digit * right_digit + carry
                carry = digit div 10
                digit = digit mod 10

                middle_result = digit.`$` & middle_result
            if carry != 0: middle_result = carry.`$` & middle_result
            middle_result &= "0".repeat(i-1)
            middle[i-1] = middle_result

        result = "0"
        for middle_result in middle:
            result = slowAdd(result, middle_result)

proc getQuotient(a, b : string): (string,string)=
    var tmp: string
    for try_digit in countdown(9,1):
        tmp = slowMultiply(try_digit.`$`, b)
        if tmp == a:
            return (try_digit.`$`, "0")
        elif slowSmallerThan(tmp, a):
            return (try_digit.`$`, slowSub(a, tmp))
     
proc slowDivide*(a, b: string, digits: int): string=
    if a.startswith("-") and b.startswith("-"):
        return slowDivide(a[1..(a.len-1)], b[1..(b.len-1)], digits)
    elif a.startswith("-"):
        return "-" & slowDivide(a[1..(a.len-1)], b, digits)
    elif b.startswith("-"):
        return "-" & slowDivide(a, b[1 .. (b.len-1)], digits)
    else:
        var
            decimals = 0
            c = a
            quotient, remainder: string
            digits_left = true
            idx = b.len-1
            flag = 0
        
        # echo "c=",c,",b=",b
        if slowSmallerThan(c, b):
            while slowSmallerThan(c, b):
                decimals += 1
                c &= "0"
                digits_left = false
                result &= "0"
            while slowSmallerThan(c[0 .. idx], b):
                idx += 1
            remainder = c[0 .. idx]
        else:
            remainder = c[0 .. idx]
            digits_left = false

        while true:
            if remainder == "0": break
            if result.len >= digits+1: break

            flag = 0
            while slowSmallerThan(remainder, b):
                flag += 1
                if digits_left:
                    remainder &= c[idx]
                    idx += 1
                    if idx == c.len: digits_left = false
                else:
                    remainder &= "0"
                    decimals += 1
                    if flag > 1:
                        result &= "0"
            # if decimals <= 5:
                # echo "remainder=",remainder,",b=",b,",result=",result,",decimals=",decimals
            (quotient, remainder) = getQuotient(remainder, b)
            # echo "quotient=",quotient,",remainder=",remainder
            result &= quotient
        
        if decimals > 0:
            result = result[0 .. (result.len-decimals-1)] & "." & result[(result.len-decimals) .. (result.len-1)]
        else:
            return result & ".0"

proc blocksToDecimal*(x : seq[uint]): string=
    result = "0"
    for i in 1 .. x.len:
        result = slowAdd(result, slowMultiply(x[x.len-i].`$`, POWER_OF_TWO[(i-1).shl(6)]))
    

when isMainModule:
    # echo slowDivide("1","3",10)
    # echo slowDivide("4","3",10)
    # echo slowDivide("355","133",10)
    # echo slowDivide("1","100",10)
    # echo slowDivide("4","2",10)

    echo getQuotient("14319451959237480602209391966837419245360869586085326264720724851155532002676452079672642132912314187714679754609499860037198430378536688350222513020782289810256437153989606051133400630739489388122520004115872623737965276803368791807679393553237147648","14319451959237480602209391966837419245360869586085326264720724851155532002676452079672642132912314187714679754609499860037198430378536688350222513020782289810256437153989606051133400630739489388122520004115872623737965276803368791807679393553237147648")