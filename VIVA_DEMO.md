# Viva Demonstration Guide: CPU Emulator Project

This guide provides a structured 10-minute demo script for your viva tomorrow.

## Part 1: The "Big Picture" (3 Minutes)
**Speaker: Shaheer (GUI & Debugger)**
1. **Open the GUI (`gui/index.html`)**: Start here because it is visually striking.
2. **Action**: Click **"Run All"**.
3. **What to say**: 
   - "Good morning. We have implemented a 32-bit RISC processor emulator. Here you see the **Fetch-Decode-Execute** cycle running live."
   - "Point at the **FDE Strip**: We show exactly what happens at each stage: Fetching from memory, Decoding the opcode, and Executing the arithmetic."
   - "Mention the **Register Bars**: Notice how registers change color automatically when their values update."

---

## Part 2: The Core Logic (3 Minutes)
**Speaker: Saad (ALU & Registers)**
1. **Switch to the Console (`cpu_emulator.exe`)**: Show the "raw" MASM output.
2. **Action**: Select **Option 2 (Step-by-step execution)**.
3. **What to say**:
   - "The backend is written in pure **MASM assembly** using the Irvine32 library."
   - "Let's step through the first few instructions. Press ENTER."
   - "Explain the **Flags**: Observe how the Zero (Z) or Negative (N) flags light up after a `SUB` or `CMP` operation. This is handled by our `UpdateFlags` procedure in Assembly."

---

## Part 3: Custom Instructions (2 Minutes)
**Speaker: Maheen (ISA & Test Programs)**
1. **Refer to the Code**: Show `cpu_emulator.asm` around line 450 (the custom handlers).
2. **Action**: Explain **ROTBLEND** or **SCRAMBLE**.
3. **What to say**:
   - "Instead of basic math, we built instructions like **ROTBLEND** (Rotate + XOR) and **SCRAMBLE**."
   - "These aren't just for show—they simulate **cryptographic primitives**. `ROTBLEND` spreads a single bit's influence across the register (Diffusion), while XOR adds Confusion."
   - "Explain **SNAPSHOT**: This instruction copies the entire register file into a static memory buffer, allowing us to 'freeze' time for debugging."

---

## Part 4: The Trace Buffer (2 Minutes)
**Speaker: Tayyab (Control Flow & Tracing)**
1. **Action**: Select **Option 5 (Show instruction trace)** in the console.
2. **What to say**:
   - "To help users debug, we implemented a **Hardware Trace Buffer**."
   - "Every cycle, the CPU records a 48-byte snapshot of the entire processor state. This includes the PC, the result, and every register R0-R7."
   - "This allows us to see exactly how a bug happened several cycles after the fact—just like professional debugging hardware."

---

## 5 Pro-Tips for the Viva:
1. **The "Wait" Answer**: If the professor asks how it's 60% done, say: *"We have the core engine (FDE), the ISA, and the Visualizer complete. Our next 40% focus is on the User Assembler (converting text files into these opcodes autonomously) and I/O port mapping."*
2. **Know your Opcode**: Every instruction is **4 bytes**. If asked why, say: *"Fixed-width encoding makes Fetching extremely fast because the hardware always knows the next instruction is exactly 4 bytes away."*
3. **The "Scramble" Logic**: If asked how Scramble works, say: *"It performs a key-seeded XOR, followed by a nibble-swap (internal byte shuffle), and a bit-rotation."*
4. **Irvine32 role**: *"We use Irvine32 for console I/O and hex printing, but the actual CPU logic (bit shifts, rotations, flag updates) is our custom implementation."*
5. **GUI Connection**: *"The GUI is currently a mirrors the emulated state. In the final version, we plan to use a WebSocket bridge or file-watching to update it in real-time."*
