; ============================================================
;  CPU EMULATOR - Custom Processor Simulation
;  MASM + Irvine32 | Windows x86 (32-bit)
;
;  Group Members:
;   Muhammad Saad Irfan   - Registers, Memory, ALU
;   Tayyab Mumtaz         - Control Flow, Tracing, I/O
;   Muhammad Shaheer Mustafa - Assembler, Instruction Parsing
;   Maheen Munir          - ISA Documentation, Test Programs
; ============================================================

INCLUDE Irvine32.inc

; ─── Constants ──────────────────────────────────────────────
NUM_REGS        EQU  8          ; R0 - R7
MEM_SIZE        EQU  256        ; 256 bytes of emulated memory
MAX_TRACE       EQU  64         ; max trace entries
MAX_PROG        EQU  128        ; max instructions in a program

; ─── Opcodes ────────────────────────────────────────────────
OP_MOV          EQU  00h
OP_ADD          EQU  01h
OP_SUB          EQU  02h
OP_AND          EQU  03h
OP_OR           EQU  04h
OP_JMP          EQU  05h
OP_JZ           EQU  06h
OP_JN           EQU  07h
OP_CMP          EQU  08h
OP_HALT         EQU  09h
OP_ROTBLEND     EQU  0Ah
OP_SCRAMBLE     EQU  0Bh
OP_BITFUSE      EQU  0Ch
OP_SNAPSHOT     EQU  0Dh
OP_MOVIMM       EQU  0Eh        ; MOV with immediate

; ─── Encoding helpers ───────────────────────────────────────
INST_SIZE       EQU  4
TRACE_ENTRY_SZ  EQU  48         ; opcode + PC + all regs snapshot

.DATA

; ─── CPU State ──────────────────────────────────────────────
cpu_regs        DWORD NUM_REGS DUP(0)   ; R0..R7
cpu_pc          DWORD 0                 ; Program Counter
cpu_flag_z      BYTE  0                 ; Zero flag
cpu_flag_n      BYTE  0                 ; Negative flag
cpu_flag_c      BYTE  0                 ; Carry flag
cpu_halted      BYTE  0                 ; Halt flag
cpu_cycles      DWORD 0                 ; Cycle count

; ─── Emulated Memory (256 bytes) ────────────────────────────
emul_memory     BYTE  MEM_SIZE DUP(0)

; ─── Program Storage ────────────────────────────────────────
program_mem     BYTE  MAX_PROG * INST_SIZE DUP(0)
prog_size       DWORD 0                 ; number of instructions loaded

; ─── Instruction Trace Buffer ───────────────────────────────
trace_buf       BYTE  MAX_TRACE * TRACE_ENTRY_SZ DUP(0)
trace_count     DWORD 0

; ─── Snapshot buffer (SNAPSHOT instruction) ─────────────────
snapshot_regs   DWORD NUM_REGS DUP(0)
snapshot_pc     DWORD 0
snapshot_fz     BYTE  0
snapshot_fn     BYTE  0
snapshot_fc     BYTE  0
snapshot_valid  BYTE  0

; ─── Strings ────────────────────────────────────────────────
str_banner      BYTE  "================================================", 0Dh, 0Ah
                BYTE  "   CPU EMULATOR  -  Custom ISA Processor", 0Dh, 0Ah
                BYTE  "   MASM + Irvine32  |  Fetch-Decode-Execute", 0Dh, 0Ah
                BYTE  "================================================", 0Dh, 0Ah, 0
str_sep         BYTE  "------------------------------------------------", 0Dh, 0Ah, 0
str_crlf        BYTE  0Dh, 0Ah, 0
str_reghead     BYTE  "  REGISTERS:", 0Dh, 0Ah, 0
str_flaghead    BYTE  "  FLAGS:", 0Dh, 0Ah, 0
str_tracehead   BYTE  0Dh, 0Ah, "  INSTRUCTION TRACE:", 0Dh, 0Ah, 0
str_memhead     BYTE  "  MEMORY DUMP (first 32 bytes):", 0Dh, 0Ah, 0
str_pc_lbl      BYTE  "  PC   = ", 0
str_cyc_lbl     BYTE  "  CYCLES = ", 0
str_r_lbl       BYTE  "  R", 0
str_eq          BYTE  " = ", 0
str_zf_lbl      BYTE  "  Z=", 0
str_nf_lbl      BYTE  "  N=", 0
str_cf_lbl      BYTE  "  C=", 0
str_halt_msg    BYTE  0Dh, 0Ah, "  [HALT] Processor stopped.", 0Dh, 0Ah, 0
str_run_msg     BYTE  "  Running program...", 0Dh, 0Ah, 0
str_load_msg    BYTE  "  Loading test program...", 0Dh, 0Ah, 0
str_done_msg    BYTE  "  Execution complete.", 0Dh, 0Ah, 0
str_snap_msg    BYTE  "  [SNAPSHOT] CPU state saved.", 0Dh, 0Ah, 0
str_rot_msg     BYTE  "  [ROTBLEND] Rotate+XOR executed.", 0Dh, 0Ah, 0
str_scr_msg     BYTE  "  [SCRAMBLE] Bit-shuffle executed.", 0Dh, 0Ah, 0
str_bif_msg     BYTE  "  [BITFUSE] Bit-interleave executed.", 0Dh, 0Ah, 0
str_fetch_lbl   BYTE  "  >> FETCH  PC=", 0
str_decode_lbl  BYTE  "  >> DECODE op=", 0
str_exec_lbl    BYTE  "  >> EXEC   result=", 0
str_op_names    BYTE  "MOV     "   ; 0
                BYTE  "ADD     "   ; 1
                BYTE  "SUB     "   ; 2
                BYTE  "AND     "   ; 3
                BYTE  "OR      "   ; 4
                BYTE  "JMP     "   ; 5
                BYTE  "JZ      "   ; 6
                BYTE  "JN      "   ; 7
                BYTE  "CMP     "   ; 8
                BYTE  "HALT    "   ; 9
                BYTE  "ROTBLEND"   ; A
                BYTE  "SCRAMBLE"   ; B
                BYTE  "BITFUSE "   ; C
                BYTE  "SNAPSHOT"   ; D
                BYTE  "MOV_IMM "   ; E
str_trace_entry BYTE  "  [Step ", 0
str_tc_pc       BYTE  "] PC=", 0
str_tc_op       BYTE  " Op=", 0
str_tc_dst      BYTE  " Dst=R", 0
str_tc_res      BYTE  " Res=", 0
str_menu        BYTE  0Dh, 0Ah
                BYTE  "  ==============================", 0Dh, 0Ah
                BYTE  "  MENU:", 0Dh, 0Ah
                BYTE  "  1) Load & Run Demo Program", 0Dh, 0Ah
                BYTE  "  2) Step-by-step execution", 0Dh, 0Ah
                BYTE  "  3) Show register state", 0Dh, 0Ah
                BYTE  "  4) Show memory dump", 0Dh, 0Ah
                BYTE  "  5) Show instruction trace", 0Dh, 0Ah
                BYTE  "  6) Exit", 0Dh, 0Ah
                BYTE  "  ==============================", 0Dh, 0Ah
                BYTE  "  Choice: ", 0
str_choice_bad  BYTE  "  Invalid choice.", 0Dh, 0Ah, 0
str_step_prompt BYTE  "  Press ENTER to step, 'q'+ENTER to quit: ", 0
str_already_hal BYTE  "  CPU is halted. Reset first.", 0Dh, 0Ah, 0
str_0x          BYTE  "0x", 0
str_hex_digit   BYTE  "0123456789ABCDEF"

; temp var for hex printing
hex_buf         BYTE  12 DUP(0)
tmp_dw          DWORD 0

.CODE

; ============================================================
;  UTILITY: Print DWORD in EAX as hex  "0x0000NNNN"
; ============================================================
PrintHex PROC
    pushad
    mov  edi, OFFSET hex_buf
    mov  BYTE PTR [edi],   '0'
    mov  BYTE PTR [edi+1], 'x'
    add  edi, 2
    mov  ecx, 8
    mov  esi, OFFSET str_hex_digit
PH_loop:
    rol  eax, 4
    mov  ebx, eax
    and  ebx, 0Fh
    mov  bl, [esi + ebx]
    mov  [edi], bl
    inc  edi
    loop PH_loop
    mov  BYTE PTR [edi], 0
    mov  edx, OFFSET hex_buf
    call WriteString
    popad
    ret
PrintHex ENDP

; ============================================================
;  UTILITY: Update Zero and Negative flags from EAX
; ============================================================
UpdateFlags PROC
    cmp  eax, 0
    je   UF_set_z
    mov  cpu_flag_z, 0
    jmp  UF_chk_n
UF_set_z:
    mov  cpu_flag_z, 1
UF_chk_n:
    test eax, 80000000h
    jnz  UF_set_n
    mov  cpu_flag_n, 0
    ret
UF_set_n:
    mov  cpu_flag_n, 1
    ret
UpdateFlags ENDP

; ============================================================
;  UTILITY: Set carry flag if CF set after last op
; ============================================================
SetCarry PROC
    jnc  SC_clear
    mov  cpu_flag_c, 1
    ret
SC_clear:
    mov  cpu_flag_c, 0
    ret
SetCarry ENDP

; ============================================================
;  CPU: Reset all state
; ============================================================
CPU_Reset PROC
    ; Zero registers
    mov  edi, OFFSET cpu_regs
    mov  ecx, NUM_REGS
    xor  eax, eax
CPU_R_loop:
    mov  [edi], eax
    add  edi, 4
    loop CPU_R_loop

    mov  cpu_pc,     0
    mov  cpu_flag_z, 0
    mov  cpu_flag_n, 0
    mov  cpu_flag_c, 0
    mov  cpu_halted, 0
    mov  cpu_cycles, 0
    mov  trace_count, 0

    ; Zero memory
    mov  edi, OFFSET emul_memory
    mov  ecx, MEM_SIZE / 4
    xor  eax, eax
CPU_M_loop:
    mov  [edi], eax
    add  edi, 4
    loop CPU_M_loop
    ret
CPU_Reset ENDP

; ============================================================
;  TRACE: Record current instruction to trace buffer
; ============================================================
Trace_Record PROC
    pushad
    
    ; Check buffer not full
    mov  eax, trace_count
    cmp  eax, MAX_TRACE
    jge  TR_skip

    ; Compute buffer offset
    imul eax, TRACE_ENTRY_SZ
    add  eax, OFFSET trace_buf
    mov  edi, eax

    ; Save opcode, dst, src, imm (4 bytes)
    mov  eax, cpu_pc
    sub  eax, INST_SIZE         ; pc was already advanced
    mov  esi, eax

    ; byte 0: opcode
    mov  bl, program_mem[esi]
    mov  [edi], bl
    inc  edi
    ; byte 1: dst
    mov  bl, program_mem[esi+1]
    mov  [edi], bl
    inc  edi
    ; byte 2: src
    mov  bl, program_mem[esi+2]
    mov  [edi], bl
    inc  edi
    ; byte 3: imm
    mov  bl, program_mem[esi+3]
    mov  [edi], bl
    inc  edi

    ; PC before
    mov  eax, cpu_pc
    sub  eax, INST_SIZE
    mov  [edi], eax
    add  edi, 4

    ; result
    mov  eax, tmp_dw
    mov  [edi], eax
    add  edi, 4

    ; Save all registers snapshot
    mov  esi, OFFSET cpu_regs
    mov  ecx, NUM_REGS
TR_regs:
    mov  eax, [esi]
    mov  [edi], eax
    add  esi, 4
    add  edi, 4
    loop TR_regs

    ; Save flags (4 bytes)
    mov  al, cpu_flag_z
    mov  [edi], al
    inc  edi
    mov  al, cpu_flag_n
    mov  [edi], al
    inc  edi
    mov  al, cpu_flag_c
    mov  [edi], al
    inc  edi
    mov  BYTE PTR [edi], 0   ; pad
    inc  edi

    inc  trace_count
TR_skip:
    popad
    ret
Trace_Record ENDP

; ============================================================
;  CPU: Fetch next instruction
; ============================================================
CPU_Fetch PROC
    ; Print fetch info
    mov  edx, OFFSET str_fetch_lbl
    call WriteString
    mov  eax, cpu_pc
    call PrintHex
    mov  edx, OFFSET str_crlf
    call WriteString

    ; Load 4 bytes from program_mem at cpu_pc
    mov  eax, cpu_pc
    cmp  eax, MAX_PROG * INST_SIZE
    jge  CF_oob
    mov  esi, eax

    movzx eax, program_mem[esi]     ; opcode
    shl   eax, 8
    movzx ebx, program_mem[esi+1]   ; dst
    or    eax, ebx
    shl   eax, 8
    movzx ebx, program_mem[esi+2]   ; src
    or    eax, ebx
    shl   eax, 8
    movzx ebx, program_mem[esi+3]   ; imm
    or    eax, ebx

    ; Advance PC
    add  cpu_pc, INST_SIZE
    ret
CF_oob:
    mov  eax, OP_HALT
    shl  eax, 24
    ret
CPU_Fetch ENDP

; ============================================================
;  CUSTOM INSTRUCTION: ROTBLEND Rdst, Rsrc, #n
; ============================================================
Exec_ROTBLEND PROC
    pushad
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]    ; Rdst value

    movzx ecx, tmp_imm
    and   ecx, 1Fh              ; clamp to 0-31
    rol   eax, cl               ; rotate left

    movzx esi, tmp_src
    shl   esi, 2
    xor   eax, cpu_regs[esi]    ; XOR with Rsrc

    ; Store result
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags

    mov   edx, OFFSET str_rot_msg
    call  WriteString
    popad
    ret
Exec_ROTBLEND ENDP

; ============================================================
;  CUSTOM INSTRUCTION: SCRAMBLE Rdst, #key
; ============================================================
Exec_SCRAMBLE PROC
    pushad
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]

    ; Step 1: XOR with key broadcast to all bytes
    mov   cl, tmp_imm
    movzx ecx, cl
    imul  ecx, ecx, 01010101h   ; broadcast byte to all 4 bytes
    xor   eax, ecx

    ; Step 2: Swap nibbles
    mov   ebx, eax
    and   ebx, 0F0F0F0F0h       ; mask for high nibbles
    shr   ebx, 4
    and   eax, 00F0F0F0Fh       ; mask for low nibbles
    shl   eax, 4
    or    eax, ebx

    ; Step 3: Rotate right by 7
    ror   eax, 7

    ; Store result
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags

    mov   edx, OFFSET str_scr_msg
    call  WriteString
    popad
    ret
Exec_SCRAMBLE ENDP

; ============================================================
;  CUSTOM INSTRUCTION: BITFUSE Rdst, Ra, Rb
; ============================================================
Exec_BITFUSE PROC
    pushad
    ; Get Ra
    movzx esi, tmp_src
    shl   esi, 2
    mov   ecx, cpu_regs[esi]    ; Ra
    and   ecx, 0FFFFh           ; lower 16 bits

    ; Get Rb (imm field used for Rb index)
    movzx esi, tmp_imm
    shl   esi, 2
    mov   edx, cpu_regs[esi]    ; Rb
    and   edx, 0FFFFh

    ; Interleave
    xor   eax, eax
    mov   edi, 0
BF_loop:
    cmp  edi, 16
    jge  BF_done

    ; Ra bit
    bt   ecx, edi
    jnc  BF_b1_off
    push ecx
    mov  ecx, edi
    shl  ecx, 1                 ; 2i
    bts  eax, ecx
    pop  ecx
BF_b1_off:
    ; Rb bit
    bt   edx, edi
    jnc  BF_b2_off
    push ecx
    mov  ecx, edi
    shl  ecx, 1
    inc  ecx                    ; 2i+1
    bts  eax, ecx
    pop  ecx
BF_b2_off:
    inc  edi
    jmp  BF_loop
BF_done:
    ; Store result
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags

    mov   edx, OFFSET str_bif_msg
    call  WriteString
    popad
    ret
Exec_BITFUSE ENDP

; ============================================================
;  CUSTOM INSTRUCTION: SNAPSHOT
; ============================================================
Exec_SNAPSHOT PROC
    pushad
    ; Copy registers
    mov  esi, OFFSET cpu_regs
    mov  edi, OFFSET snapshot_regs
    mov  ecx, NUM_REGS
CPU_S_cp:
    mov  eax, [esi]
    mov  [edi], eax
    add  esi, 4
    add  edi, 4
    loop CPU_S_cp

    mov  eax, cpu_pc
    mov  snapshot_pc, eax
    mov  al, cpu_flag_z
    mov  snapshot_fz, al
    mov  al, cpu_flag_n
    mov  snapshot_fn, al
    mov  al, cpu_flag_c
    mov  snapshot_fc, al
    mov  snapshot_valid, 1
    mov  tmp_dw, 0

    mov  edx, OFFSET str_snap_msg
    call WriteString
    popad
    ret
Exec_SNAPSHOT ENDP

; ============================================================
;  CPU: Decode & Execute
; ============================================================
CPU_Execute PROC
    ; Unpack
    push eax
    shr  eax, 24
    mov  tmp_opcode, al
    pop  eax
    
    push eax
    shr  eax, 16
    and  eax, 0FFh
    mov  tmp_dst, al
    pop  eax

    push eax
    shr  eax, 8
    and  eax, 0FFh
    mov  tmp_src, al
    pop  eax

    mov  tmp_imm, al

    ; Print decode
    mov  edx, OFFSET str_decode_lbl
    call WriteString
    movzx eax, tmp_opcode
    call PrintHex
    mov  edx, OFFSET str_crlf
    call WriteString

    ; Dispatch
    movzx eax, tmp_opcode
    cmp  eax, OP_MOV
    je   E_do_mov
    cmp  eax, OP_ADD
    je   E_do_add
    cmp  eax, OP_SUB
    je   E_do_sub
    cmp  eax, OP_AND
    je   E_do_and
    cmp  eax, OP_OR
    je   E_do_or
    cmp  eax, OP_JMP
    je   E_do_jmp
    cmp  eax, OP_JZ
    je   E_do_jz
    cmp  eax, OP_JN
    je   E_do_jn
    cmp  eax, OP_CMP
    je   E_do_cmp
    cmp  eax, OP_HALT
    je   E_do_halt
    cmp  eax, OP_ROTBLEND
    je   E_do_rotblend
    cmp  eax, OP_SCRAMBLE
    je   E_do_scramble
    cmp  eax, OP_BITFUSE
    je   E_do_bitfuse
    cmp  eax, OP_SNAPSHOT
    je   E_do_snapshot
    cmp  eax, OP_MOVIMM
    je   E_do_movimm
    jmp  E_done

E_do_mov:
    movzx esi, tmp_src
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_movimm:
    movzx eax, tmp_imm
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_add:
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_src
    shl   esi, 2
    add   eax, cpu_regs[esi]
    call  SetCarry
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_sub:
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_src
    shl   esi, 2
    sub   eax, cpu_regs[esi]
    call  SetCarry
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_and:
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_src
    shl   esi, 2
    and   eax, cpu_regs[esi]
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_or:
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_src
    shl   esi, 2
    or    eax, cpu_regs[esi]
    movzx esi, tmp_dst
    shl   esi, 2
    mov   cpu_regs[esi], eax
    mov   tmp_dw, eax
    call  UpdateFlags
    jmp   E_done

E_do_jmp:
    movzx eax, tmp_imm
    shl   eax, 2
    mov   cpu_pc, eax
    mov   tmp_dw, eax
    jmp   E_done

E_do_jz:
    cmp  cpu_flag_z, 1
    jne  E_jz_skip
    movzx eax, tmp_imm
    shl   eax, 2
    mov   cpu_pc, eax
    mov   tmp_dw, eax
    jmp   E_done
E_jz_skip:
    mov  eax, cpu_pc
    mov  tmp_dw, eax
    jmp  E_done

E_do_jn:
    cmp  cpu_flag_n, 1
    jne  E_jn_skip
    movzx eax, tmp_imm
    shl   eax, 2
    mov   cpu_pc, eax
    mov   tmp_dw, eax
    jmp   E_done
E_jn_skip:
    mov  eax, cpu_pc
    mov  tmp_dw, eax
    jmp  E_done

E_do_cmp:
    movzx esi, tmp_dst
    shl   esi, 2
    mov   eax, cpu_regs[esi]
    movzx esi, tmp_src
    shl   esi, 2
    sub   eax, cpu_regs[esi]
    call  UpdateFlags
    mov   tmp_dw, eax
    jmp   E_done

E_do_halt:
    mov  cpu_halted, 1
    mov  tmp_dw, 0
    mov  edx, OFFSET str_halt_msg
    call WriteString
    jmp  E_done

E_do_rotblend:
    call  Exec_ROTBLEND
    jmp   E_done

E_do_scramble:
    call  Exec_SCRAMBLE
    jmp   E_done

E_do_bitfuse:
    call  Exec_BITFUSE
    jmp   E_done

E_do_snapshot:
    call  Exec_SNAPSHOT
    jmp   E_done

E_done:
    ; Print result
    mov  edx, OFFSET str_exec_lbl
    call WriteString
    mov  eax, tmp_dw
    call PrintHex
    mov  edx, OFFSET str_crlf
    call WriteString

    inc  cpu_cycles
    call Trace_Record
    ret
CPU_Execute ENDP

; ============================================================
;  DISPLAY: Registers
; ============================================================
Display_Regs PROC
    pushad
    mov  edx, OFFSET str_sep
    call WriteString
    mov  edx, OFFSET str_reghead
    call WriteString

    mov  ecx, 0
DR_loop:
    cmp  ecx, NUM_REGS
    jge  DR_done

    mov  edx, OFFSET str_r_lbl
    call WriteString
    mov  eax, ecx
    call WriteDec
    mov  edx, OFFSET str_eq
    call WriteString

    mov  esi, ecx
    shl  esi, 2
    mov  eax, cpu_regs[esi]
    call PrintHex
    call CRLF

    inc  ecx
    jmp  DR_loop
DR_done:
    mov  edx, OFFSET str_pc_lbl
    call WriteString
    mov  eax, cpu_pc
    call PrintHex
    call CRLF

    mov  edx, OFFSET str_cyc_lbl
    call WriteString
    mov  eax, cpu_cycles
    call WriteDec
    call CRLF

    ; Flags
    mov  edx, OFFSET str_flaghead
    call WriteString
    mov  edx, OFFSET str_zf_lbl
    call WriteString
    movzx eax, cpu_flag_z
    call WriteDec
    mov  edx, OFFSET str_nf_lbl
    call WriteString
    movzx eax, cpu_flag_n
    call WriteDec
    mov  edx, OFFSET str_cf_lbl
    call WriteString
    movzx eax, cpu_flag_c
    call WriteDec
    call CRLF
    popad
    ret
Display_Regs ENDP

; ============================================================
;  DISPLAY: Memory
; ============================================================
Display_Memory PROC
    pushad
    mov  edx, OFFSET str_memhead
    call WriteString
    mov  ecx, 0
DM_row:
    cmp  ecx, 32
    jge  DM_done
    mov  edx, OFFSET str_0x
    call WriteString
    mov  eax, ecx
    call PrintHex
    mov  edx, OFFSET str_eq
    call WriteString
    movzx eax, emul_memory[ecx]
    call WriteDec
    call CRLF
    inc  ecx
    jmp  DM_row
DM_done:
    popad
    ret
Display_Memory ENDP

; ============================================================
;  DISPLAY: Trace
; ============================================================
Display_Trace PROC
    pushad
    mov  edx, OFFSET str_tracehead
    call WriteString
    mov  ecx, 0
DT_loop:
    cmp  ecx, trace_count
    jge  DT_done

    mov  eax, ecx
    imul eax, TRACE_ENTRY_SZ
    add  eax, OFFSET trace_buf
    mov  esi, eax

    mov  edx, OFFSET str_trace_entry
    call WriteString
    mov  eax, ecx
    call WriteDec
    mov  edx, OFFSET str_tc_pc
    call WriteString
    mov  eax, [esi+4]
    call PrintHex
    mov  edx, OFFSET str_tc_op
    call WriteString
    movzx eax, BYTE PTR [esi]
    imul eax, 8
    add  eax, OFFSET str_op_names
    mov  edx, eax
    call WriteString
    mov  edx, OFFSET str_tc_dst
    call WriteString
    movzx eax, BYTE PTR [esi+1]
    call WriteDec
    mov  edx, OFFSET str_tc_res
    call WriteString
    mov  eax, [esi+8]
    call PrintHex
    call CRLF
    inc  ecx
    jmp  DT_loop
DT_done:
    popad
    ret
Display_Trace ENDP

; ============================================================
;  PROGRAM LOADER
; ============================================================
Load_Demo_Program PROC
    pushad
    call CPU_Reset
    mov  edx, OFFSET str_load_msg
    call WriteString
    xor  ebx, ebx

    ; MOV_IMM R0, #10
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 0
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 10
    add  ebx, 4

    ; MOV_IMM R1, #25
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 1
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 25
    add  ebx, 4

    ; ADD R0, R1
    mov  program_mem[ebx],   OP_ADD
    mov  program_mem[ebx+1], 0
    mov  program_mem[ebx+2], 1
    mov  program_mem[ebx+3], 0
    add  ebx, 4

    ; MOV_IMM R2, #0x5A
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 2
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 5Ah
    add  ebx, 4

    ; ROTBLEND R0, R2, #3
    mov  program_mem[ebx],   OP_ROTBLEND
    mov  program_mem[ebx+1], 0
    mov  program_mem[ebx+2], 2
    mov  program_mem[ebx+3], 3
    add  ebx, 4

    ; MOV_IMM R3, #0xAB
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 3
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 0ABh
    add  ebx, 4

    ; SCRAMBLE R3, #0x1F
    mov  program_mem[ebx],   OP_SCRAMBLE
    mov  program_mem[ebx+1], 3
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 1Fh
    add  ebx, 4

    ; MOV_IMM R4, #240
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 4
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 0F0h
    add  ebx, 4

    ; MOV_IMM R5, #15
    mov  program_mem[ebx],   OP_MOVIMM
    mov  program_mem[ebx+1], 5
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 15
    add  ebx, 4

    ; BITFUSE R6, R4, R5
    mov  program_mem[ebx],   OP_BITFUSE
    mov  program_mem[ebx+1], 6
    mov  program_mem[ebx+2], 4
    mov  program_mem[ebx+3], 5
    add  ebx, 4

    ; SNAPSHOT
    mov  program_mem[ebx],   OP_SNAPSHOT
    mov  program_mem[ebx+1], 0
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 0
    add  ebx, 4

    ; HALT
    mov  program_mem[ebx],   OP_HALT
    mov  program_mem[ebx+1], 0
    mov  program_mem[ebx+2], 0
    mov  program_mem[ebx+3], 0
    add  ebx, 4

    popad
    ret
Load_Demo_Program ENDP

; ============================================================
;  EXECUTION MODES
; ============================================================
Run_Program PROC
    pushad
    mov  edx, OFFSET str_run_msg
    call WriteString
RP_cycle:
    cmp  cpu_halted, 1
    je   RP_halted
    cmp  cpu_pc, MAX_PROG * INST_SIZE
    jge  RP_halted
    call CPU_Fetch
    call CPU_Execute
    jmp  RP_cycle
RP_halted:
    mov  edx, OFFSET str_done_msg
    call WriteString
    popad
    ret
Run_Program ENDP

Step_Instruction PROC
    cmp  cpu_halted, 1
    je   SI_halted
    call CPU_Fetch
    call CPU_Execute
    call Display_Regs
    ret
SI_halted:
    mov  edx, OFFSET str_already_hal
    call WriteString
    ret
Step_Instruction ENDP

; ============================================================
;  GLOBAL DATA for Decode
; ============================================================
.DATA
tmp_opcode BYTE 0
tmp_dst    BYTE 0
tmp_src    BYTE 0
tmp_imm    BYTE 0

; ============================================================
;  MAIN
; ============================================================
.CODE
main PROC
    call Clrscr
    mov  edx, OFFSET str_banner
    call WriteString
    call Load_Demo_Program

M_menu:
    mov  edx, OFFSET str_menu
    call WriteString
    call ReadChar
    call WriteChar
    call CRLF

    cmp  al, '1'
    je   M_opt1
    cmp  al, '2'
    je   M_opt2
    cmp  al, '3'
    je   M_opt3
    cmp  al, '4'
    je   M_opt4
    cmp  al, '5'
    je   M_opt5
    cmp  al, '6'
    je   M_exit
    
    mov  edx, OFFSET str_choice_bad
    call WriteString
    jmp  M_menu

M_opt1:
    call Load_Demo_Program
    call Run_Program
    call Display_Regs
    jmp  M_menu

M_opt2:
    call Load_Demo_Program
M_step_loop:
    mov  edx, OFFSET str_step_prompt
    call WriteString
    call ReadChar
    call WriteChar
    call CRLF
    cmp  al, 'q'
    je   M_menu
    call Step_Instruction
    cmp  cpu_halted, 1
    je   M_menu
    jmp  M_step_loop

M_opt3:
    call Display_Regs
    jmp  M_menu

M_opt4:
    call Display_Memory
    jmp  M_menu

M_opt5:
    call Display_Trace
    jmp  M_menu

M_exit:
    exit
main ENDP
END main
