[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
[![MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# bitarray
A simple bitarray library for nim.

# Installation
```
git clone https://github.com/YesDrX/bitarray.git
cd bitarray
nimble install
```
or
```
nimble install bitarray
```

# Example
```nim
import bitarray
when isMainModule:
  var
    a = newBitsArray(10)
    b = newBitsArray(10)
  
  echo a
  echo b
  a.setBits(0,1,2)
  b.setAll
  echo a & b
  echo a | b
  echo a ^ b
  echo ~a
```
```
0000000000
0000000000
1110000000
1111111111
0001111111
0001111111
```
