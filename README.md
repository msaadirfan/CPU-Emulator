# CPU Emulator — Custom ISA Processor
## Computer Architecture & Assembly Language — End Semester Project

---

## Group Members & Roles

| Member | Role | Implemented |
|---|---|---|
| Muhammad Saad Irfan | Registers, Memory, ALU, Arithmetic/Data Instructions | `cpu_regs`, `emul_memory`, `UpdateFlags`, MOV/ADD/SUB/AND/OR |
| Tayyab Mumtaz | Control Flow, Branching, Tracing, I/O, Testing | JMP/JZ/JN, `Trace_Record`, `Display_Trace`, console I/O |
| Muhammad Shaheer Mustafa | Assembler Design, Instruction Parsing, GUI | `CPU_Fetch`/decode dispatch, `gui/index.html` |
| Maheen Munir | ISA Documentation, Test Programs | `test_program.asm`, opcode table, instruction comments |

---

## Architecture Overview

### Custom ISA Design

The emulated CPU is a **32-bit, 8-register, RISC-style processor**:

- **8 general-purpose registers**: R0–R7 (each 32-bit)
- **Program Counter (PC)**: 32-bit, advances by 4 bytes per instruction
- **3 flags**: Zero (Z), Negative (N), Carry (C)
- **256-byte emulated memory**
- **Fixed-length encoding**: every instruction is exactly 4 bytes

### Instruction Encoding (4 bytes)

```
 Byte 0    Byte 1    Byte 2    Byte 3
[OPCODE]  [DST REG] [SRC REG] [IMM/ADDR]
```

---

## Instruction Set Reference

### Standard Instructions
- `MOV_IMM Rdst, #n` (0x0E): Rdst ← n
- `MOV Rdst, Rsrc` (0x00): Rdst ← Rsrc
- `ADD Rdst, Rsrc` (0x01): Rdst ← Rdst + Rsrc
- `SUB Rdst, Rsrc` (0x02): Rdst ← Rdst − Rsrc
- `JMP addr` (0x05): PC ← addr*4
- `HALT` (0x09)

### Custom Instructions
- `ROTBLEND Rdst, Rsrc, #n` (0x0A): Rdst ← ROL(Rdst, n) XOR Rsrc
- `SCRAMBLE Rdst, #key` (0x0B): Rdst ← bit-scramble(Rdst, key)
- `BITFUSE Rdst, Ra, Rb` (0x0C): Rdst ← interleaveBits(Ra, Rb)
- `SNAPSHOT` (0x0D): Save full CPU state

---

## How to Build & Run

### Console Version (MASM)
1. Edit `build_and_run.bat` to set your `MASM_PATH` and `IRVINE_PATH`.
2. Double-click `build_and_run.bat`.

### GUI Version (Visualizer)
1. Open `gui/index.html` in any web browser.
2. Use the **Run All** or **Step** buttons to visualize the fetch-decode-execute cycle.
