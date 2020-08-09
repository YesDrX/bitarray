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
when isMainModule:
  var
    a = newBitsArray(9000000)
    b = newBitsArray(9000000)
  
  echo a.sum
  a.setAll
  echo a.sum
  echo a.blocks
  echo (a | b).sum()
  echo (a ^ b).sum()
```
```
0
9000000
140625
9000000
9000000
```
