# Karatsuba Multiplication
This project performs a signed multiplication of numbers up to 64 digits using the Karatsuba multiplication method in the ARM assembly language. This algorithm achieves a complexity of <i>O(n<sup>log<sub>2</sub>3</sup>)</i> as opposed to the naive multiplication complexity of <i>O(n<sup>2</sup>)</i>.

It uses a recursive algorithm which splits the whole multiplication into 3 sub-multiplications and a recombination phase of complexity <i>O(n)</i>. In Master's theorem notation, this algorithm can be written as <i>T(n) = 3T(n/2) + O(n)</i>, and hence achieving an overall complexity of <i>O(n<sup>log<sub>2</sub>3</sup>).
