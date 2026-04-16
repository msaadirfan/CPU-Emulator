; ============================================================
;  TEST PROGRAM: Custom ISA Processor Demo
;  Course: Computer Architecture & Assembly Language
;
;  Register Map:
;   R0  - General purpose / accumulator
;   R1  - General purpose
;   R2  - Key / security constant
;   R3  - SCRAMBLE target
;   R4  - BITFUSE input A
;   R5  - BITFUSE input B
;   R6  - BITFUSE output
;   R7  - Temporary / compare value
; ============================================================

    MOV_IMM  R0, #10       ; R0 = 10
    MOV_IMM  R1, #25       ; R1 = 25
    ADD      R0, R1        ; R0 = 10+25 = 35
    MOV_IMM  R2, #0x5A     ; R2 = 0x5A (security key seed)
    ROTBLEND R0, R2, #3    ; R0 = ROL(R0, 3) XOR R2
    MOV_IMM  R3, #0xAB     ; R3 = 0xAB = 1010_1011b
    SCRAMBLE R3, #0x1F     ; R3 = permute(R3, key=0x1F)
    MOV_IMM  R4, #0xF0     ; R4 = 1111_0000b
    MOV_IMM  R5, #0x0F     ; R5 = 0000_1111b
    BITFUSE  R6, R4, R5    ; Interleave bits: Even bits from R4, Odd from R5
    SNAPSHOT               ; Save state to snapshot buffer
    MOV_IMM  R7, #1        ; R7 = 1
    CMP      R0, R7        ; Compare R0 and R7
    SUB      R0, R1        ; R0 = R0 - R1
    HALT                   ; Stop execution
