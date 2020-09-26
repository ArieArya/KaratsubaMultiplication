               ;       This algorithm is based on the Karatsuba Algorithm, in which two N digit numbers multiplied will be split into
               ;       four main segments: a, b, c, and d. e.g. for 1234 * 5678, a = 12, b = 34, c = 56, d = 78. From here, the result
               ;       of the multiplication is given by 10^N(ac) + 10^N/2(ad+bc) + bd. Further, a simplification is made to reduce
               ;       the need to calculate a fourth product, by noting that (a+b)(c+d) - ac - bd = ad+bc, as required. Hence, a code
               ;       for subtraction is also used in this code.

               ;       This implementation contains 7 main recursive layers for: 64 digits, 32 digits, 16 digits, 8 digits, 4 digits,
               ;       2 digits, and 1 digit multiplication. Each layer above will recursively call into its sublayers in order to perform
               ;       its own multiplication. When it reaches the 1 digit layer, a lookup table for 1 by 1 multiplication is used to
               ;       improve efficiency.

BCDBIGMUL      STMFD   SP!, {R0-R2, R4-R11, LR}
               CMP     R3, #1
               BLEQ    BRANCHTO8
               CMP     R3, #2
               BLEQ    BRANCHTO16
               CMP     R3, #4
               BLEQ    BRANCHTO32
               CMP     R3, #8
               BLEQ    BRANCHTO64
               LDMFD   SP!, {R0-R2, R4-R11, PC}
               END
               ;       Branch to Karatsuba Multiplication for K = 1
BRANCHTO8      STMFD   SP!, {R0, R3, R6-R9, LR}
               MOV     R8, #0
               LDR     R6, [R0] ; loads in x
               CMP     R6, #0x50000000 ; check if x is negative
               BLO     BRANCH8SKIP1
               ADD     R8, R8, #1
               MOV     R9, R6
               BL      SIGNED8SUB ; if x is negative, temporarily convert it to positive
               MOV     R6, R0
BRANCH8SKIP1   LDR     R7, [R1] ; loads in y, and repeat process as above
               CMP     R7, #0x50000000
               BLO     BRANCH8SKIP2
               ADD     R8, R8, #1
               MOV     R9, R7
               BL      SIGNED8SUB
               MOV     R7, R0
BRANCH8SKIP2   BL      LVL8DIGIT
               LDR     R9, =DATALV8
               CMP     R8, #1
               BNE     BRANCH8SKIP3
               BL      SIGNED16SUB ; converts back to negative if x and y have different signs
BRANCH8SKIP3   LDR     R6, [R9]
               STR     R6, [R2]
               LDR     R6, [R9, #4]
               STR     R6, [R2, #4]
               LDMFD   SP!, {R0, R3, R6-R9, PC}
               ;       Branch to Karatsuba Multiplication for K = 2
BRANCHTO16     STMFD   SP!, {R0, R3, R5-R9, LR}
               MOV     R6, #0
               LDR     R5, =DATA16INPUTS
               LDR     R8, [R0, #4]
               CMP     R8, #0x50000000
               BLO     BRANCH16SKIP1
               ADD     R6, R6, #1
               MOV     R9, R0
               BL      SIGNED16SUB
BRANCH16SKIP1  LDR     R8, [R0] ; load x into DATA16INPUTS
               STR     R8, [R5, #4]
               LDR     R8, [R0, #4]
               STR     R8, [R5]
               LDR     R8, [R1, #4] ; check if x is negative
               CMP     R8, #0x50000000
               BLO     BRANCH16SKIP2
               ADD     R6, R6, #1
               MOV     R9, R1
               BL      SIGNED16SUB ; if x is negative, temporarily convert it to positive
BRANCH16SKIP2  LDR     R8, [R1] ; load y into DATA16INPUTS and repeat above steps
               STR     R8, [R5, #12]
               LDR     R8, [R1, #4]
               STR     R8, [R5, #8]
               BL      LVL16DIGIT
               LDR     R9, =DATALV16
               CMP     R6, #1
               BNE     BRANCH16SKIP3
               BL      SIGNED32SUB ; converts back to negative if x and y have different signs
BRANCH16SKIP3  LDR     R8, [R9]
               STR     R8, [R2]
               LDR     R8, [R9, #4]
               STR     R8, [R2, #4]
               LDR     R8, [R9, #8]
               STR     R8, [R2, #8]
               LDR     R8, [R9, #12]
               STR     R8, [R2, #12]
               LDMFD   SP!, {R0, R3, R5-R9, PC}
               ;       Branch to Karatsuba Multiplication for K = 4
BRANCHTO32     STMFD   SP!, {R0, R3, R5-R9, LR}
               MOV     R6, #0
               LDR     R5, =DATA32INPUTS
               LDR     R8, [R0, #12] ; check if x is negative
               CMP     R8, #0x50000000
               BLO     BRANCH32SKIP1
               ADD     R6, R6, #1
               MOV     R9, R0
               BL      SIGNED32SUB ; if x is negative, temporarily convert it to positive
BRANCH32SKIP1  LDR     R8, [R0] ; start loading x into DATA32INPUTS
               STR     R8, [R5, #12]
               LDR     R8, [R0, #4]
               STR     R8, [R5, #8]
               LDR     R8, [R0, #8]
               STR     R8, [R5, #4]
               LDR     R8, [R0, #12]
               STR     R8, [R5]
               LDR     R8, [R1, #12] ; check if y is negative, and repeat above steps
               CMP     R8, #0x50000000
               BLO     BRANCH32SKIP2
               ADD     R6, R6, #1
               MOV     R9, R1
               BL      SIGNED32SUB
BRANCH32SKIP2  LDR     R8, [R1] ; start loading y into DATA32INPUTS
               STR     R8, [R5, #28]
               LDR     R8, [R1, #4]
               STR     R8, [R5, #24]
               LDR     R8, [R1, #8]
               STR     R8, [R5, #20]
               LDR     R8, [R1, #12]
               STR     R8, [R5, #16]
               BL      LVL32DIGIT
               LDR     R9, =DATALV32
               CMP     R6, #1
               BNE     BRANCH32SKIP3
               BL      SIGNED64SUB ; converts back to negative if x and y have different signs
BRANCH32SKIP3  LDR     R8, [R9]
               STR     R8, [R2]
               LDR     R8, [R9, #4]
               STR     R8, [R2, #4]
               LDR     R8, [R9, #8]
               STR     R8, [R2, #8]
               LDR     R8, [R9, #12]
               STR     R8, [R2, #12]
               LDR     R8, [R9, #16]
               STR     R8, [R2, #16]
               LDR     R8, [R9, #20]
               STR     R8, [R2, #20]
               LDR     R8, [R9, #24]
               STR     R8, [R2, #24]
               LDR     R8, [R9, #28]
               STR     R8, [R2, #28]
               LDMFD   SP!, {R0, R3, R5-R9, PC}
               ;       Branch to Karatsuba Multiplication for K = 8
BRANCHTO64     STMFD   SP!, {R0, R3, R5-R9, LR}
               MOV     R8, #0
               LDR     R5, =DATA64INPUTS
               LDR     R6, [R0, #28] ; check if x is negative
               CMP     R6, #0x50000000
               BLO     BRANCH64SKIP1
               ADD     R8, R8, #1
               MOV     R9, R0
               BL      SIGNED64SUB ; if x is negative, temporarily convert it to positive
BRANCH64SKIP1  LDR     R6, [R0] ; start loading x into DATA64INPUTS
               STR     R6, [R5, #28]
               LDR     R6, [R0, #4]
               STR     R6, [R5, #24]
               LDR     R6, [R0, #8]
               STR     R6, [R5, #20]
               LDR     R6, [R0, #12]
               STR     R6, [R5, #16]
               LDR     R6, [R0, #16]
               STR     R6, [R5, #12]
               LDR     R6, [R0, #20]
               STR     R6, [R5, #8]
               LDR     R6, [R0, #24]
               STR     R6, [R5, #4]
               LDR     R6, [R0, #28]
               STR     R6, [R5]
               LDR     R6, [R1, #28] ; check if y is negative, and repeat above steps
               CMP     R6, #0x50000000
               BLO     BRANCH64SKIP2
               ADD     R8, R8, #1
               MOV     R9, R1
               BL      SIGNED64SUB
BRANCH64SKIP2  LDR     R6, [R1] ; start loading y into DATA64INPUTS
               STR     R6, [R5, #60]
               LDR     R6, [R1, #4]
               STR     R6, [R5, #56]
               LDR     R6, [R1, #8]
               STR     R6, [R5, #52]
               LDR     R6, [R1, #12]
               STR     R6, [R5, #48]
               LDR     R6, [R1, #16]
               STR     R6, [R5, #44]
               LDR     R6, [R1, #20]
               STR     R6, [R5, #40]
               LDR     R6, [R1, #24]
               STR     R6, [R5, #36]
               LDR     R6, [R1, #28]
               STR     R6, [R5, #32]
               BL      LVL64DIGIT
               LDR     R9, =DATALV64
               CMP     R8, #1
               BNE     BRANCH64SKIP3
               BL      SIGNED128SUB ; converts back to negative if x and y have different signs
BRANCH64SKIP3  LDR     R6, [R9]
               STR     R6, [R2]
               LDR     R6, [R9, #4]
               STR     R6, [R2, #4]
               LDR     R6, [R9, #8]
               STR     R6, [R2, #8]
               LDR     R6, [R9, #12]
               STR     R6, [R2, #12]
               LDR     R6, [R9, #16]
               STR     R6, [R2, #16]
               LDR     R6, [R9, #20]
               STR     R6, [R2, #20]
               LDR     R6, [R9, #24]
               STR     R6, [R2, #24]
               LDR     R6, [R9, #28]
               STR     R6, [R2, #28]
               LDR     R6, [R9, #32]
               STR     R6, [R2, #32]
               LDR     R6, [R9, #36]
               STR     R6, [R2, #36]
               LDR     R6, [R9, #40]
               STR     R6, [R2, #40]
               LDR     R6, [R9, #44]
               STR     R6, [R2, #44]
               LDR     R6, [R9, #48]
               STR     R6, [R2, #48]
               LDR     R6, [R9, #52]
               STR     R6, [R2, #52]
               LDR     R6, [R9, #56]
               STR     R6, [R2, #56]
               LDR     R6, [R9, #60]
               STR     R6, [R2, #60]
               LDMFD   SP!, {R0, R3, R5-R9, PC}
               ;       Function which flips the sign of a number (i.e. N -> -N) for different lengths (8, 16, 32, 64 digits)
SIGNED8SUB     STMFD   SP!, {R4-R5, LR}
               MOV     R5, #0
               MOV     R11, #0
               MOV     R10, R9
               BL      BCD8SUB
               MOV     R0, R4
               LDMFD   SP!, {R4-R5, PC}
SIGNED16SUB    STMFD   SP!, {R4-R5, LR}
               MOV     R5, #0 ; by default R5 = 0 (subtraction overflow)
               MOV     R11, #0
               LDR     R10, [R9]
               BL      BCD8SUB
               CMP     R11, R10
               MOVLO   R5, #1 ; compare after subtraction for next overflow
               STR     R4, [R9]
               LDR     R10, [R9, #4]
               BL      BCD8SUB
               STR     R4, [R9, #4]
               LDMFD   SP!, {R4-R5, PC}
SIGNED32SUB    STMFD   SP!, {R4-R5, LR}
               MOV     R5, #0 ; by default R5 = 0 (subtraction overflow)
               MOV     R11, #0
               LDR     R10, [R9]
               BL      BCD8SUB
               CMP     R11, R10 ; compare after subtraction for next overflow
               MOVLO   R5, #1
               STR     R4, [R9]
               LDR     R10, [R9, #4]
               BL      BCD8SUB
               ADD     R5, R5, R10 ; R5 + R10 must always be greater than R11 (0) for overflow
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #4]
               LDR     R10, [R9, #8]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #8]
               LDR     R10, [R9, #12]
               BL      BCD8SUB
               STR     R4, [R9, #12]
               LDMFD   SP!, {R4-R5, PC}
SIGNED64SUB    STMFD   SP!, {R4-R5, LR}
               MOV     R5, #0 ; by default R5 = 0 (subtraction overflow)
               MOV     R11, #0
               LDR     R10, [R9]
               BL      BCD8SUB
               CMP     R11, R10 ; compare after subtraction for next overflow
               MOVLO   R5, #1
               STR     R4, [R9]
               LDR     R10, [R9, #4]
               BL      BCD8SUB
               ADD     R5, R5, R10 ; R5 + R10 must always be greater than R11 (0) for overflow
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #4]
               LDR     R10, [R9, #8]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #8]
               LDR     R10, [R9, #12]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #12]
               LDR     R10, [R9, #16]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #16]
               LDR     R10, [R9, #20]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #20]
               LDR     R10, [R9, #24]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #24]
               LDR     R10, [R9, #28]
               BL      BCD8SUB
               STR     R4, [R9, #28]
               LDMFD   SP!, {R4-R5, PC}
SIGNED128SUB   STMFD   SP!, {R4-R5, LR}
               MOV     R5, #0 ; by default R5 = 0 (subtraction overflow)
               MOV     R11, #0
               LDR     R10, [R9]
               BL      BCD8SUB
               CMP     R11, R10 ; compare after subtraction for next overflow
               MOVLO   R5, #1
               STR     R4, [R9]
               LDR     R10, [R9, #4]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5 ; R5 + R10 must always be greater than R11 (0) for overflow
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #4]
               LDR     R10, [R9, #8]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #8]
               LDR     R10, [R9, #12]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #12]
               LDR     R10, [R9, #16]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #16]
               LDR     R10, [R9, #20]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #20]
               LDR     R10, [R9, #24]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #24]
               LDR     R10, [R9, #28]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #28]
               LDR     R10, [R9, #32]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #32]
               LDR     R10, [R9, #36]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #36]
               LDR     R10, [R9, #40]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #40]
               LDR     R10, [R9, #44]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #44]
               LDR     R10, [R9, #48]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #48]
               LDR     R10, [R9, #52]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #52]
               LDR     R10, [R9, #56]
               BL      BCD8SUB
               ADD     R5, R5, R10
               CMP     R11, R5
               MOV     R5, #0
               MOVLO   R5, #1
               STR     R4, [R9, #56]
               LDR     R10, [R9, #60]
               BL      BCD8SUB
               STR     R4, [R9, #60]
               LDMFD   SP!, {R4-R5, PC}

               ;------------------------------------- UNLOOPED BCD ADDITION FROM PART A ---------------------------------------------
               ;----------------- This function has inputs R10, R11, R5, output is R4 with unsigned overflow of R12 -----------------
               ;------------------------------- Performs R4=R10+R11, with R5 as carry in input --------------------------------------
BCD8ADD        STMFD   SP!, {LR, R0-R2, R6, R8}
               MOV     R4, #0
               MOV     R6, #0xF
               MOV     R12, #0
               ADD     R10, R10, R5
               AND     R1, R6, R10
               AND     R0, R6, R11
               ADD     R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8
               AND     R1, R6, R10, LSR #4
               AND     R0, R6, R11, LSR #4
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #4
               AND     R1, R6, R10, LSR #8
               AND     R0, R6, R11, LSR #8
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #8
               AND     R1, R6, R10, LSR #12
               AND     R0, R6, R11, LSR #12
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #12
               AND     R1, R6, R10, LSR #16
               AND     R0, R6, R11, LSR #16
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #16
               AND     R1, R6, R10, LSR #20
               AND     R0, R6, R11, LSR #20
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #20
               AND     R1, R6, R10, LSR #24
               AND     R0, R6, R11, LSR #24
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #24
               AND     R1, R6, R10, LSR #28
               AND     R0, R6, R11, LSR #28
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #28
               MOVGE   R12, #1
               LDMFD   SP!, {PC, R0-R2, R6, R8}
               ;----------------------------------------- BCD ADDITION WITH 4 DIGITS ------------------------------------------------
               ;--------------------------------- This function has inputs R10, R11, with output R4 ---------------------------------
               ;----------------------------------------------- Performs R10+R11 ----------------------------------------------------
BCD4ADD        STMFD   SP!, {LR, R8}
               MOV     R4, #0
               MOV     R6, #0xF
               AND     R1, R6, R10
               AND     R0, R6, R11
               ADD     R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8
               AND     R1, R6, R10, LSR #4
               AND     R0, R6, R11, LSR #4
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #4
               AND     R1, R6, R10, LSR #8
               AND     R0, R6, R11, LSR #8
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #8
               AND     R1, R6, R10, LSR #12
               AND     R0, R6, R11, LSR #12
               ADCS    R8, R1, R0
               CMP     R8, #10
               SUBGE   R8, R8, #10
               ADD     R4, R4, R8, LSL #12
               LDMFD   SP!, {PC, R8}
               ;---------------------------------------------- BCD SUBTRACTION ------------------------------------------------------
               ;-------------------------------- This function has inputs R10, R11, R5, output is R4 --------------------------------
               ;--------------------------------- Performs R4 = R11-R10, with R5 as carry in input -----------------------------------
BCD8SUB        STMFD   SP!, {LR, R3, R5, R10}
               LDR     R3, =0x9999999A
               SUB     R3, R3, R5
               SUB     R10, R3, R10
               MOV     R5, #0
               BL      BCD8ADD
               LDMFD   SP!, {PC, R3, R5, R10}

               ;----------------------------- Performs Karatsuba Multiplication of two 64 digit numbers -----------------------------
LVL64DIGIT     STMFD   SP!, {LR, R2, R6, R8-R9}
               LDR     R6, =DATA64INPUTS
               LDR     R2, =LVL64TEMPMEM ; to store a*c, b*d and (a+b)(c+d) in temporary memory
               LDR     R9, =DATALV32
               LDR     R1, =DATA32INPUTS
               MOV     R5, #0
               ;       store a into DATA32INPUTS for recursive multiplication
               LDR     R0, [R6]
               STR     R0, [R1]
               LDR     R0, [R6, #4]
               STR     R0, [R1, #4]
               LDR     R0, [R6, #8]
               STR     R0, [R1, #8]
               LDR     R0, [R6, #12]
               STR     R0, [R1, #12]
               ;       store c into DATA32INPUTS for recursive multiplication
               LDR     R0, [R6, #32]
               STR     R0, [R1, #16]
               LDR     R0, [R6, #36]
               STR     R0, [R1, #20]
               LDR     R0, [R6, #40]
               STR     R0, [R1, #24]
               LDR     R0, [R6, #44]
               STR     R0, [R1, #28]
               BL      LVL32DIGIT ; calculates a*c recursively going downward in branch
               ;       store a*c in LVL32TEMPMEM
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               LDR     R0, [R9, #16]
               STR     R0, [R2], #4
               LDR     R0, [R9, #20]
               STR     R0, [R2], #4
               LDR     R0, [R9, #24]
               STR     R0, [R2], #4
               LDR     R0, [R9, #28]
               STR     R0, [R2], #4
               ;       store b into DATA32INPUTS for recursive multiplication
               LDR     R0, [R6, #16]
               STR     R0, [R1]
               LDR     R0, [R6, #20]
               STR     R0, [R1, #4]
               LDR     R0, [R6, #24]
               STR     R0, [R1, #8]
               LDR     R0, [R6, #28]
               STR     R0, [R1, #12]
               ;       store d into DATA32INPUTS for recursive multiplication
               LDR     R0, [R6, #48]
               STR     R0, [R1, #16]
               LDR     R0, [R6, #52]
               STR     R0, [R1, #20]
               LDR     R0, [R6, #56]
               STR     R0, [R1, #24]
               LDR     R0, [R6, #60]
               STR     R0, [R1, #28]
               BL      LVL32DIGIT ; calculates b*d recursively going downward in branch
               ;       store b*d in LVL32TEMPMEM
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               LDR     R0, [R9, #16]
               STR     R0, [R2], #4
               LDR     R0, [R9, #20]
               STR     R0, [R2], #4
               LDR     R0, [R9, #24]
               STR     R0, [R2], #4
               LDR     R0, [R9, #28]
               STR     R0, [R2], #4
               ;       calculate (a+b) and store on DATA32INPUTS for recursive multiplication
               LDR     R11, [R6, #12]
               LDR     R10, [R6, #28]
               BL      BCD8ADD
               STR     R4, [R1, #12]
               LDR     R11, [R6, #8]
               LDR     R10, [R6, #24]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #8]
               LDR     R11, [R6, #4]
               LDR     R10, [R6, #20]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #4]
               LDR     R11, [R6]
               LDR     R10, [R6, #16]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1]
               MOV     R8, R12
               ;       calculate (c+d) and store on DATA32INPUTS for recursive multiplication
               MOV     R5, #0
               LDR     R11, [R6, #44]
               LDR     R10, [R6, #60]
               BL      BCD8ADD
               STR     R4, [R1, #28]
               LDR     R11, [R6, #40]
               LDR     R10, [R6, #56]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #24]
               LDR     R11, [R6, #36]
               LDR     R10, [R6, #52]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #20]
               LDR     R11, [R6, #32]
               LDR     R10, [R6, #48]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #16]
               CMP     R12, #1
               ADDEQ   R8, R8, #2 ; R8 #0 means no overflow, R8 #1 means 1st overflow, #2 means 2nd overflow, #3 means both overflow
               CMP     R8, #0
               MOV     R5, #0
               BEQ     LVL640OVERFLOW
               CMP     R8, #1
               BEQ     LVL641OVERFLOW
               CMP     R8, #2
               BEQ     LVL642OVERFLOW
               B       LVL643OVERFLOW
               ;       here neither (a+b) or (c+d) overflows
LVL640OVERFLOW BL      LVL32DIGIT
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               LDR     R0, [R9, #16]
               STR     R0, [R2], #4
               LDR     R0, [R9, #20]
               STR     R0, [R2], #4
               LDR     R0, [R9, #24]
               STR     R0, [R2], #4
               LDR     R0, [R9, #28]
               STR     R0, [R2], #4
               MOV     R3, #0 ; contains overflow
               B       LVL64ADDUP
               ;       here (a+b) overflows
LVL641OVERFLOW BL      LVL32DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               ;       add the 2 least significant 32-bit blocks of the overlaps
               LDR     R10, [R9, #16]
               LDR     R11, [R1, #28]
               BL      BCD8ADD
               STR     R4, [R2], #4
               LDR     R11, [R9, #20]
               LDR     R10, [R1, #24]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the 2 most significant 32-bit blocks of the overlaps
               LDR     R11, [R9, #24]
               LDR     R10, [R1, #20]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               LDR     R11, [R9, #28]
               LDR     R10, [R1, #16]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12
               B       LVL64ADDUP
               ;       here (c+d) overflows
LVL642OVERFLOW BL      LVL32DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               ;       add the 2 least significant 32-bit blocks of the overlaps
               LDR     R10, [R9, #16]
               LDR     R11, [R1, #12]
               BL      BCD8ADD
               STR     R4, [R2], #4
               LDR     R11, [R9, #20]
               LDR     R10, [R1, #8]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the 2 most significant 32-bit blocks of the overlaps
               LDR     R11, [R9, #24]
               LDR     R10, [R1, #4]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               LDR     R11, [R9, #28]
               LDR     R10, [R1]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12
               B       LVL64ADDUP
               ;       here both (a+b) and (c+d) overflows
LVL643OVERFLOW BL      LVL32DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               ;       add the first least significant 32-bit block of the 3 overlaps
               LDR     R11, [R9, #16]
               LDR     R10, [R1, #12]
               BL      BCD8ADD
               MOV     R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #28]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the 2nd block of the 3 overlaps
               ADD     R10, R7, R12 ; captures overlap from both addition
               LDR     R11, [R9, #20]
               BL      BCD8ADD
               MOV     R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #8]
               BL      BCD8ADD
               ADD     R7, R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #24]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the third block of the 3 overlaps
               ADD     R10, R7, R12 ; captures overlap from both addition
               LDR     R11, [R9, #24]
               BL      BCD8ADD
               MOV     R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #4]
               BL      BCD8ADD
               ADD     R7, R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #20]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the fourth most significant 32-bit block of the 3 overlaps
               ADD     R10, R7, R12 ; captures overlap from both addition
               LDR     R11, [R9, #28]
               BL      BCD8ADD
               ADD     R7, R12, #1 ; temporarily holds overlap (+1 since last overflow always has an extra 1)
               MOV     R11, R4
               LDR     R10, [R1]
               BL      BCD8ADD
               ADD     R7, R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #16]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ADD     R3, R7, R12 ; final overlap
LVL64ADDUP     ;       Performs (a+b)(c+d) - ac - bd
               MOV     R5, #0 ; reset overflow
               LDR     R0, =DATALV64
               MOV     R1, #0 ; temporary comparator for subtraction overflow
               ;       subtraction of 8th 32-bit block
               LDR     R11, [R2, #-32]
               LDR     R10, [R2, #-64] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-96] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-32] ; start replacing the (a+b)(c+d) block with (ad+bc)
               ;       subtraction of 7th 32-bit block
               LDR     R11, [R2, #-28]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-60] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-92] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-28]
               ;       subtraction of 6th 32-bit block
               LDR     R11, [R2, #-24]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-56] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-88] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-24]
               ;       subtraction of 5th 32-bit block
               LDR     R11, [R2, #-20]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-52] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-84] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-20]
               ;       subtraction of 4th 32-bit block
               LDR     R11, [R2, #-16]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-48] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-80] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-16]
               ;       subtraction of 3rd 32-bit block
               LDR     R11, [R2, #-12]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-44] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-76] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-12]
               ;       subtraction of 2nd 32-bit block
               LDR     R11, [R2, #-8]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-40] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-72] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-8]
               ;       subtraction of 1st 32-bit block
               LDR     R11, [R2, #-4]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-36] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-68] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-4]
               SUB     R3, R3, R1 ; for every overflow from here, R3 is removed by 1
               ;       Computes the result of 10^64(ac) + 10^32(ad+bc) + bd
               ;       store bd at the back 4 32-bit blocks
               LDR     R1, [R2, #-64]
               STR     R1, [R0]
               LDR     R1, [R2, #-60]
               STR     R1, [R0, #4]
               LDR     R1, [R2, #-56]
               STR     R1, [R0, #8]
               LDR     R1, [R2, #-52]
               STR     R1, [R0, #12]
               ;       add back of (ad+bc) with front of bd
               LDR     R11, [R2, #-32]
               LDR     R10, [R2, #-48]
               BL      BCD8ADD
               STR     R4, [R0, #16]
               MOV     R5, R12
               LDR     R11, [R2, #-28]
               LDR     R10, [R2, #-44]
               BL      BCD8ADD
               STR     R4, [R0, #20]
               MOV     R5, R12
               LDR     R11, [R2, #-24]
               LDR     R10, [R2, #-40]
               BL      BCD8ADD
               STR     R4, [R0, #24]
               MOV     R5, R12
               LDR     R11, [R2, #-20]
               LDR     R10, [R2, #-36]
               BL      BCD8ADD
               STR     R4, [R0, #28]
               MOV     R5, R12
               ;       add front of (ad+bc) with back of ac
               LDR     R11, [R2, #-16]
               LDR     R10, [R2, #-96]
               BL      BCD8ADD
               STR     R4, [R0, #32]
               MOV     R5, R12
               LDR     R11, [R2, #-12]
               LDR     R10, [R2, #-92]
               BL      BCD8ADD
               STR     R4, [R0, #36]
               MOV     R5, R12
               LDR     R11, [R2, #-8]
               LDR     R10, [R2, #-88]
               BL      BCD8ADD
               STR     R4, [R0, #40]
               MOV     R5, R12
               LDR     R11, [R2, #-4]
               LDR     R10, [R2, #-84]
               BL      BCD8ADD
               STR     R4, [R0, #44]
               ADD     R10, R3, R12 ; overall overflow to final 4 blocks
               ;       final front ac block
               LDR     R11, [R2, #-80]
               MOV     R5, #0
               BL      BCD8ADD
               STR     R4, [R0, #48]
               LDR     R11, [R2, #-76]
               MOV     R10, R12
               BL      BCD8ADD
               STR     R4, [R0, #52]
               LDR     R11, [R2, #-72]
               MOV     R10, R12
               BL      BCD8ADD
               STR     R4, [R0, #56]
               LDR     R11, [R2, #-68]
               MOV     R10, R12
               BL      BCD8ADD
               STR     R4, [R0, #60]
               LDMFD   SP!, {PC, R2, R6, R8-R9}
               ;----------------------------- Performs Karatsuba Multiplication of two 32 digit numbers -----------------------------
LVL32DIGIT     STMFD   SP!, {LR, R1-R2, R6, R9}
               LDR     R6, =DATA32INPUTS
               LDR     R2, =LVL32TEMPMEM ; to store a*c, b*d and (a+b)(c+d) in temporary memory
               LDR     R9, =DATALV16
               LDR     R1, =DATA16INPUTS
               MOV     R5, #0 ; initalize overflow to 0
               ;       store a into DATA16INPUTS for recursive multiplication
               LDR     R0, [R6]
               STR     R0, [R1]
               LDR     R0, [R6, #4]
               STR     R0, [R1, #4]
               ;       store c into DATA16INPUTS for recursive multiplication
               LDR     R0, [R6, #16]
               STR     R0, [R1, #8]
               LDR     R0, [R6, #20]
               STR     R0, [R1, #12]
               BL      LVL16DIGIT ; calculates a*c
               ;       store a*c in LVL32TEMPMEM
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               ;       store b into DATA16INPUTS for recursive multiplication
               LDR     R0, [R6, #8]
               STR     R0, [R1]
               LDR     R0, [R6, #12]
               STR     R0, [R1, #4]
               ;       store d into DATA16INPUTS for recursive multiplication
               LDR     R0, [R6, #24]
               STR     R0, [R1, #8]
               LDR     R0, [R6, #28]
               STR     R0, [R1, #12]
               BL      LVL16DIGIT ; calculates b*d
               ;       store b*d in LVL32TEMPMEM
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               ;       calculates (a+b) and store into DATA16INPUTS for recursive multiplication
               LDR     R10, [R6, #4]
               LDR     R11, [R6, #12]
               BL      BCD8ADD
               STR     R4, [R1, #4]
               LDR     R10, [R6]
               LDR     R11, [R6, #8]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1]
               MOV     R8, R12
               ;       calculates (c+d) and store into DATA16INPUTS for recursive multiplication
               MOV     R5, #0
               LDR     R11, [R6, #20]
               LDR     R10, [R6, #28]
               BL      BCD8ADD
               STR     R4, [R1, #12]
               LDR     R11, [R6, #16]
               LDR     R10, [R6, #24]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R1, #8]
               CMP     R12, #1
               ADDEQ   R8, R8, #2 ; R8 #0 means no overflow, R8 #1 means 1st overflow, #2 means 2nd overflow, #3 means both overflow
               CMP     R8, #0
               MOV     R5, #0
               BEQ     LVL320OVERFLOW
               CMP     R8, #1
               BEQ     LVL321OVERFLOW
               CMP     R8, #2
               BEQ     LVL322OVERFLOW
               B       LVL323OVERFLOW
               ;       here neither (a+b) or (c+d) overflows
LVL320OVERFLOW BL      LVL16DIGIT
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               LDR     R0, [R9, #8]
               STR     R0, [R2], #4
               LDR     R0, [R9, #12]
               STR     R0, [R2], #4
               MOV     R3, #0
               B       LVL32ADDUP
               ;       here (a+b) overflows
LVL321OVERFLOW BL      LVL16DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               ;       add the least significant 32-bit block of the overlaps
               LDR     R10, [R9, #8]
               LDR     R11, [R1, #12]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the most significant 32-bit block of the overlaps
               LDR     R11, [R9, #12]
               LDR     R10, [R1, #8]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12 ; overflow bit
               B       LVL32ADDUP
               ;       here (c+d) overflows
LVL322OVERFLOW BL      LVL16DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               ;       add the least significant 32-bit block of the overlaps
               LDR     R11, [R9, #8]
               LDR     R10, [R1, #4]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the most significant 32-bit block of the overlaps
               LDR     R11, [R9, #12]
               LDR     R10, [R1]
               MOV     R5, R12
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12 ; overflow bit
               B       LVL32ADDUP
               ;       here both (a+b) and (c+d) overflows
LVL323OVERFLOW BL      LVL16DIGIT
               LDR     R0, [R9] ; stores multiplication without overflow bit to memory
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               ;       add the least significant 32-bit block of the overlaps
               LDR     R11, [R9, #8]
               LDR     R10, [R1, #4]
               BL      BCD8ADD
               MOV     R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #12]
               BL      BCD8ADD
               STR     R4, [R2], #4
               ;       add the most significant 32-bit block of the overlaps
               ADD     R10, R7, R12 ; captures overlap from both addition
               LDR     R11, [R9, #12]
               BL      BCD8ADD
               ADD     R7, R12, #1 ; temporarily holds overlap (+1 since last overflow always has 1 extra)
               MOV     R11, R4
               LDR     R10, [R1]
               BL      BCD8ADD
               ADD     R7, R7, R12
               MOV     R11, R4
               LDR     R10, [R1, #8]
               BL      BCD8ADD
               ADD     R3, R7, R12 ; final overflow
               STR     R4, [R2], #4
LVL32ADDUP     ;       performs (a+b)(c+d) - ac - bd
               MOV     R5, #0 ; reset overflow for subtraction
               LDR     R0, =DATALV32
               MOV     R1, #0
               ;       subtraction of 4th 32-bit block
               LDR     R11, [R2, #-16]
               LDR     R10, [R2, #-32] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1 ; if subtraction result is negative, must remove 1 from next register
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-48] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-16] ; start replacing the (a+b)(c+d) block with (ad+bc)
               ;       subtraction of 3rd 32-bit block
               LDR     R11, [R2, #-12]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-28] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-44] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-12]
               ;       subtraction of 2nd 32-bit block
               LDR     R11, [R2, #-8]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-24] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-40] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-8]
               ;       subtraction of 1st 32-bit block
               LDR     R11, [R2, #-4]
               MOV     R10, R1
               CMP     R11, R10
               MOV     R1, #0
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-20] ; subtract by bd
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-36] ; subtract by ac
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-4]
               SUB     R3, R3, R1 ; for every overflow from here, R3 is removed by 1
               ;       Computes the result of 10^32(ac) + 10^16(ad+bc) + bd
               ;       store bd at back 32-bit block
               LDR     R1, [R2, #-32]
               STR     R1, [R0]
               LDR     R1, [R2, #-28]
               STR     R1, [R0, #4]
               ;       add back of (ad+bc) with front of bd
               LDR     R11, [R2, #-16]
               LDR     R10, [R2, #-24]
               BL      BCD8ADD
               STR     R4, [R0, #8]
               MOV     R5, R12
               LDR     R11, [R2, #-12]
               LDR     R10, [R2, #-20]
               BL      BCD8ADD
               STR     R4, [R0, #12]
               MOV     R5, R12
               ;       add front of (ad+bc) with back of ac
               LDR     R11, [R2, #-8]
               LDR     R10, [R2, #-48]
               BL      BCD8ADD
               STR     R4, [R0, #16]
               MOV     R5, R12
               LDR     R11, [R2, #-4]
               LDR     R10, [R2, #-44]
               BL      BCD8ADD
               STR     R4, [R0, #20]
               ADD     R10, R3, R12 ; overall overflow to final 2 blocks
               ;       final front ac block
               LDR     R11, [R2, #-40]
               MOV     R5, #0
               BL      BCD8ADD
               STR     R4, [R0, #24]
               LDR     R11, [R2, #-36]
               MOV     R10, R12
               BL      BCD8ADD
               STR     R4, [R0, #28]
               LDMFD   SP!, {PC, R1-R2, R6, R9}
               ;----------------------------- Performs Karatsuba Multiplication of two 16 digit numbers -----------------------------
LVL16DIGIT     STMFD   SP!, {LR, R1-R2, R4-R6, R9}
               LDR     R4, =DATA16INPUTS
               LDR     R2, =LVL16TEMPMEM ; to store a*c, b*d and (a+b)(c+d) in temporary memory
               LDR     R9, =DATALV8
               MOV     R5, #0
               LDR     R6, [R4]
               LDR     R7, [R4, #8] ; extract a and c into R6 and R7, and calculates a*c
               BL      LVL8DIGIT
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               MOV     R8, R6 ; temporarily stores a in R8
               MOV     R3, R7 ; temporarily stores c in R3
               LDR     R6, [R4, #4] ; extract b and d into R6 and R7, and calculates b*d
               LDR     R7, [R4, #12]
               BL      LVL8DIGIT
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               ;       performs (a+b)(c+d)
               MOV     R10, R8 ; a+b
               MOV     R11, R6
               BL      BCD8ADD
               MOV     R6, R4
               MOV     R8, R12
               MOV     R10, R3 ; c+d
               MOV     R11, R7
               BL      BCD8ADD
               MOV     R7, R4
               CMP     R12, #1
               ADDEQ   R8, R8, #2 ; R8 #0 means no overflow, R8 #1 means 1st overflow, #2 means 2nd overflow, #3 means both overflow
               CMP     R8, #0
               BEQ     LVL160OVERFLOW
               CMP     R8, #1
               BEQ     LVL161OVERFLOW
               CMP     R8, #2
               BEQ     LVL162OVERFLOW
               B       LVL163OVERFLOW
               ;       here neither (a+b) or (c+d) overflows
LVL160OVERFLOW BL      LVL8DIGIT
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R0, [R9, #4]
               STR     R0, [R2], #4
               MOV     R3, #0 ; overflow bit
               B       LVL16ADDUP
               ;       here (a+b) overflows
LVL161OVERFLOW BL      LVL8DIGIT ; stores multiplication without overflow bit to memory
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R10, [R9, #4]
               MOV     R11, R7
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12 ; overflow bit
               B       LVL16ADDUP
               ;       here (c+d) overflows
LVL162OVERFLOW BL      LVL8DIGIT ; stores multiplication without overflow bit to memory
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R10, [R9, #4]
               MOV     R11, R6
               BL      BCD8ADD
               STR     R4, [R2], #4
               MOV     R3, R12 ; overflow bit
               B       LVL16ADDUP
               ;       here both (a+b) and (c+d) overflows
LVL163OVERFLOW MOV     R3, #1 ; final overflow always has 1 extra
               BL      LVL8DIGIT ; stores multiplication without overflow bit to memory
               LDR     R0, [R9]
               STR     R0, [R2], #4
               LDR     R10, [R9, #4]
               MOV     R11, R6
               BL      BCD8ADD
               ADD     R3, R3, R12
               MOV     R10, R4
               MOV     R11, R7
               BL      BCD8ADD
               ADD     R3, R3, R12
               STR     R4, [R2], #4
               ;       performing (a+b)(c+d) - ac - bd
LVL16ADDUP     LDR     R0, =DATALV16
               MOV     R1, #0
               LDR     R11, [R2, #-8]
               LDR     R10, [R2, #-24]
               CMP     R11, R10
               ADDLO   R1, R1, #1 ; if subtraction result is negative, must remove 1 from next register
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-16]
               CMP     R11, R10
               ADDLO   R1, R1, #1
               BL      BCD8SUB
               STR     R4, [R2, #-8]
               CMP     R1, #1
               BLT     LV16SKIP1
               LDR     R11, [R2, #-4] ; subtracts next 32-bit block by R1 (overflow)
               MOV     R10, R1
               CMP     R11, R10
               SUBLO   R3, R3, #1
               BL      BCD8SUB
               STR     R4, [R2, #-4]
LV16SKIP1      LDR     R11, [R2, #-4]
               LDR     R10, [R2, #-20] ; subtract by least significant 32-bit block of ac
               CMP     R11, R10
               SUBLO   R3, R3, #1
               BL      BCD8SUB
               MOV     R11, R4
               LDR     R10, [R2, #-12] ; subtract by least significant 32-bit block of bd
               CMP     R11, R10
               SUBLO   R3, R3, #1
               BL      BCD8SUB
               STR     R4, [R2, #-4]
               ;       Computes the result of 10^16(ac) + 10^8(ad+bc) + bd
               ;       store least significant 32-bit block of bd at back result block
               LDR     R1, [R2, #-16]
               STR     R1, [R0]
               ;       add back of (ad+bc) with front of bd
               LDR     R11, [R2, #-8]
               LDR     R10, [R2, #-12]
               BL      BCD8ADD
               STR     R4, [R0, #4]
               ;       add front of (ad+bc) with back of ac
               MOV     R5, R12
               LDR     R11, [R2, #-24]
               LDR     R10, [R2, #-4]
               BL      BCD8ADD
               ADD     R10, R3, R12
               STR     R4, [R0, #8]
               ;       store front of ac at final register
               LDR     R11, [R2, #-20] ; front of ac
               CMP     R10, #0
               BEQ     LV16SKIP2
               MOV     R5, #0 ; set overflow from R5 to 0
               BL      BCD8ADD
               MOV     R11, R4
LV16SKIP2      STR     R11, [R0, #12]
               LDMFD   SP!, {PC, R1-R2, R4-R6, R9}
               ;----------------------------- Performs Karatsuba Multiplication of two 8 digit numbers -----------------------------
LVL8DIGIT      STMFD   SP!, {LR, R2-R11}
               MOV     R4, R6 ; here, the inputs are R6 and R7
               MOV     R5, R7
               LDR     R10, =0xFFFF
               ADR     R9, DATALV4
               MOV     R6, R5, LSR #16 ; extract a and c, and computes a*c
               MOV     R7, R4, LSR #16
               MOV     R8, R6 ; R8 is now a
               MOV     R3, R7 ; R3 is now c
               BL      LVL4DIGIT
               LDR     R0, [R9]
               AND     R6, R5, R10 ; extract b and d, and computes b*d
               AND     R7, R4, R10
               BL      LVL4DIGIT
               LDR     R1, [R9]
               ;       performs (a+b)(c+d)
               MOV     R5, #0
               MOV     R10, R8 ; a+b
               MOV     R11, R6
               BL      BCD8ADD
               MOV     R6, R4
               MOV     R10, R3 ; c+d
               MOV     R11, R7
               BL      BCD8ADD
               MOV     R7, R4
               LDR     R10, =0xFFFF
               MOV     R8, #0
               CMP     R6, R10
               ADDGT   R8, R8, #1
               CMP     R7, R10
               ADDGT   R8, R8, #2 ; if R8 #0, no overflow, if R8 #1, means 1st overflows, if R8 #2, means 2nd overflow, if R8 #3, both overflow
               CMP     R8, #0
               BEQ     LVL80OVERFLOW
               CMP     R8, #1
               BEQ     LVL81OVERFLOW
               CMP     R8, #2
               BEQ     LVL82OVERFLOW
               B       LVL83OVERFLOW
               ;       here neither (a+b) or (c+d) overflows
LVL80OVERFLOW  BL      LVL4DIGIT
               LDR     R2, [R9] ; R2 stores result (a+b)(c+d)
               MOV     R3, #0
               B       LVL8ADDUP
               ;       here (a+b) overflows
LVL81OVERFLOW  AND     R6, R6, R10
               BL      LVL4DIGIT ; stores multiplication without overflow bit to memory
               LDR     R10, [R9]
               MOV     R11, R7, LSL #16
               BL      BCD8ADD
               MOV     R3, R12 ; overflow bit
               MOV     R2, R4 ; store result of multiplication into R2
               B       LVL8ADDUP
               ;       here (c+d) overflows
LVL82OVERFLOW  AND     R7, R7, R10
               BL      LVL4DIGIT
               LDR     R10, [R9]
               MOV     R11, R6, LSL #16
               BL      BCD8ADD
               MOV     R3, R12 ; overflow bit
               MOV     R2, R4 ; store result of multiplication into R2
               B       LVL8ADDUP
               ;       here both (a+b) and (c+d) overflows
LVL83OVERFLOW  AND     R7, R7, R10
               AND     R6, R6, R10
               BL      LVL4DIGIT
               LDR     R10, [R9]
               MOV     R11, R6, LSL #16
               BL      BCD8ADD
               MOV     R3, R12 ; overflow bit
               MOV     R10, R4
               MOV     R11, R7, LSL #16
               BL      BCD8ADD
               ADD     R3, R3, R12
               ADD     R3, R3, #1 ; last overflow always has 1 extra
               MOV     R2, R4
LVL8ADDUP      MOV     R11, R2 ; performs (a+b)(c+d) - ac - bd
               MOV     R10, R0
               CMP     R11, R10
               SUBLO   R3, R3, #1 ; if subtraction result is negative, must remove 1 from next register
               BL      BCD8SUB
               MOV     R11, R4
               MOV     R10, R1
               CMP     R11, R10
               SUBLO   R3, R3, #1 ; if R10 larger than R11, must remove extra overflow bit
               BL      BCD8SUB
               MOV     R6, R4 ; stores (ad+bc) in R6
               ;       Computes the result of 10^8(ac) + 10^4(ad+bc) + bd
               MOV     R10, R6, LSL #16
               MOV     R11, R1
               BL      BCD8ADD
               MOV     R7, R4
               MOV     R10, R0
               ADD     R11, R12, R3, LSL #16
               BL      BCD8ADD
               MOV     R10, R4
               MOV     R11, R6, LSR #16
               BL      BCD8ADD
               MOV     R8, R4
               ADR     R9, DATALV8
               STR     R7, [R9], #4
               STR     R8, [R9]
               LDMFD   SP!, {PC, R2-R11}
               ;----------------------------- Performs Karatsuba Multiplication of two 4 digit numbers -----------------------------
LVL4DIGIT      STMFD   SP!, {LR, R3-R11}
               MOV     R5, #0
               MOV     R8, R6 ; here, the inputs are R6 and R7
               MOV     R2, R7
               ADR     R9, DATALV2
               MOV     R6, R8, LSR #8 ; extract a and d, and calculates a*d
               AND     R7, R2, #0xFF
               BL      LVL2DIGIT
               LDR     R11, [R9] ; R11 is now a*d
               AND     R6, R8, #0xFF ; extract b and c, and calculates b*c
               MOV     R7, R2, LSR #8
               BL      LVL2DIGIT
               LDR     R10, [R9] ; R10 is now b*c
               BL      BCD8ADD
               MOV     R3, R4 ; temporarily store result of (ad+bc) into R3
               MOV     R6, R8, LSR #8 ; extract a and c, and calculates a*c
               MOV     R7, R2, LSR #8
               BL      LVL2DIGIT
               LDR     R10, [R9] ; R0 is now a*c
               AND     R6, R8, #0xFF ; extract b and d, and calculates b*d
               AND     R7, R2, #0xFF
               BL      LVL2DIGIT
               LDR     R11, [R9] ; R1 is now b*d
               MOV     R10, R10, LSL #16
               BL      BCD8ADD ; gets 10^4(ac) + bd
               MOV     R10, R4
               MOV     R11, R3, LSL #8 ; gets 10^4(ac) + 10^2(ad+bc) + bd
               BL      BCD8ADD
               ADR     R9, DATALV4
               STR     R4, [R9]
               LDMFD   SP!, {PC, R3-R11}
               ;----------------------------- Performs Karatsuba Multiplication of two 2 digit numbers -----------------------------
LVL2DIGIT      STMFD   SP!, {LR, R0-R1, R4-R5, R8-R11}
               MOV     R8, R6 ; here, the inputs are R6 and R7
               MOV     R5, R7
               ADR     R9, DATALV1
               MOV     R6, R8, LSR #4 ; extract a and d, and calculates a*d
               AND     R7, R5, #0xF
               BL      LVL1DIGIT
               LDR     R10, [R9] ; R10 is now a*d
               AND     R6, R8, #0xF ; extract b and c, and calculates b*c
               MOV     R7, R5, LSR #4
               BL      LVL1DIGIT
               LDR     R11, [R9] ; R11 is now b*c
               BL      BCD4ADD ; calculates (ad+bc)
               MOV     R6, R8, LSR #4 ; extract a and c, and calculates a*c
               MOV     R7, R5, LSR #4
               BL      LVL1DIGIT
               LDR     R10, [R9] ; R10 is now a*c
               MOV     R10, R10, LSL #8
               MOV     R11, R4, LSL #4 ; R4 is (ad+bc), so gets 10*(ad+bc)
               BL      BCD4ADD ; gets 10^2*ac + 10*(ad+bc)
               AND     R6, R8, #0xF ; extract b and d
               AND     R7, R5, #0xF
               BL      LVL1DIGIT
               LDR     R10, [R9] ; R10 is now b*d
               MOV     R11, R4
               BL      BCD4ADD ; calculates result of 10^2*ac + 10*(ad+bc) + bd
               ADR     R9, DATALV2
               STR     R4, [R9]
               LDMFD   SP!, {PC, R0-R1, R4-R5, R8-R11}
               ;----------------------------- Performs Karatsuba Multiplication of two 1 digit numbers -----------------------------
LVL1DIGIT      STMFD   SP!, {LR}
               ADR     R0, MULTLOOKUP ; uses multiplication lookup table for efficiency
               LDR     R0, [R0, R6, LSL #2]
               LDRB    R0, [R0, R7]
               STR     R0, [R9]
               LDMFD   SP!, {PC}
               ;-------------------------------------- INPUT MEMORY AND TEMPORARY MEMORY SPACE --------------------------------------
DATALV64       FILL    64
DATALV32       FILL    32
DATALV16       FILL    16
DATALV8        FILL    8
DATALV4        FILL    4
DATALV2        FILL    4
DATALV1        FILL    4
LVL16TEMPMEM   FILL    24
LVL32TEMPMEM   FILL    48
LVL64TEMPMEM   FILL    96
DATA16INPUTS   FILL    16
DATA32INPUTS   FILL    32
DATA64INPUTS   FILL    64
               ;---------------------------------------- 1 DIGIT MULTIPLICATION LOOKUP TABLE ----------------------------------------
MULTLOOKUP     DCD     MULT0, MULT1, MULT2, MULT3, MULT4, MULT5, MULT6, MULT7, MULT8, MULT9
MULT0          DCB     0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0, 0
MULT1          DCB     0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0, 0
MULT2          DCB     0x0, 0x2, 0x4, 0x6, 0x8, 0x10, 0x12, 0x14, 0x16, 0x18, 0, 0
MULT3          DCB     0x0, 0x3, 0x6, 0x9, 0x12, 0x15, 0x18, 0x21, 0x24, 0x27, 0, 0
MULT4          DCB     0x0, 0x4, 0x8, 0x12, 0x16, 0x20, 0x24, 0x28, 0x32, 0x36, 0, 0
MULT5          DCB     0x0, 0x5, 0x10, 0x15, 0x20, 0x25, 0x30, 0x35, 0x40, 0x45, 0, 0
MULT6          DCB     0x0, 0x6, 0x12, 0x18, 0x24, 0x30, 0x36, 0x42, 0x48, 0x54, 0, 0
MULT7          DCB     0x0, 0x7, 0x14, 0x21, 0x28, 0x35, 0x42, 0x49, 0x56, 0x63, 0, 0
MULT8          DCB     0x0, 0x8, 0x16, 0x24, 0x32, 0x40, 0x48, 0x56, 0x64, 0x72, 0, 0
MULT9          DCB     0x0, 0x9, 0x18, 0x27, 0x36, 0x45, 0x54, 0x63, 0x72, 0x81, 0, 0




