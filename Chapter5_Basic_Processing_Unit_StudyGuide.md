# Chapter 5 — Basic Processing Unit

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 151–191 (Sections 5.1 → 5.7.2)

> How to use this guide: read it top to bottom. Each section builds on the previous one.
> Terms in **bold** are the ones you must be able to define. Code blocks are the exact
> register-transfer step sequences from the textbook, explained line-by-line. The
> "Checkpoint" boxes are what you should be able to answer before moving on.

---

## Table of Contents

1. [The Big Picture — What a Processor Does](#1-the-big-picture)
2. [Section 5.1 — Some Fundamental Concepts](#2-section-51--some-fundamental-concepts)
3. [Data Processing Hardware & Multi-Stage Structure](#3-data-processing-hardware--multi-stage-structure)
4. [Section 5.2 — Instruction Execution (the Five Steps)](#4-section-52--instruction-execution-the-five-steps)
5. [Section 5.3 — Hardware Components (Register File, ALU, Datapath)](#5-section-53--hardware-components)
6. [Section 5.3.3 — The Datapath (Figure 5.8)](#6-section-533--the-datapath-figure-58)
7. [Section 5.3.4 — The Instruction Fetch Section](#7-section-534--the-instruction-fetch-section)
8. [Section 5.4 — Instruction Fetch and Execution Steps](#8-section-54--instruction-fetch-and-execution-steps)
9. [Section 5.4.1 — Branching & Subroutine Calls](#9-section-541--branching--subroutine-calls)
10. [Section 5.4.2 — Waiting for Memory (MFC)](#10-section-542--waiting-for-memory-mfc)
11. [Section 5.5 — Control Signals](#11-section-55--control-signals)
12. [Section 5.6 — Hardwired Control](#12-section-56--hardwired-control)
13. [Section 5.7 — CISC-Style Processors & Microprogrammed Control](#13-section-57--cisc-style-processors--microprogrammed-control)
14. [Step-Sequence Reference Card](#14-step-sequence-reference-card)
15. [Glossary of Every Register & Signal](#15-glossary-of-every-register--signal)
16. [Self-Test Questions](#16-self-test-questions)

---

## 1. The Big Picture

The **processing unit** (also called the **central processing unit, CPU**, or simply the
**processor**) is the part of the computer that executes machine-language instructions and
coordinates the activities of the other units. This chapter opens the processor up and shows
its internal structure: how it **fetches**, **decodes**, and **executes** instructions.

A program is a sequence of machine-language instructions. The processor's job is a tight,
endless loop:

| Phase | What happens |
|-------|--------------|
| **Fetch** | Read the next instruction from memory into the processor. |
| **Decode** | Work out what operation the instruction asks for. |
| **Execute** | Actually perform that operation (compute, read/write memory, etc.). |

The textbook notes that real processors chase high performance by making functional units
work **in parallel** — through **pipelining** (start a new instruction before the previous one
finishes) and **superscalar** operation (start several instructions at once). Those are
Chapter 6 topics. Chapter 5 deliberately keeps it simple: **one instruction completes before
the next is fetched.**

> **Checkpoint:** Name the three phases every instruction goes through. *(Fetch, decode,
> execute.)*

---

## 2. Section 5.1 — Some Fundamental Concepts

Two special registers drive the whole fetch cycle:

- **PC (Program Counter)** — holds the **address of the next instruction** to be fetched.
  After a fetch, the PC is updated to point to the following instruction. A branch or jump
  loads a *different* value into the PC.
- **IR (Instruction Register)** — holds the instruction *after* it is fetched, so the control
  circuitry can **decode** (interpret) it. The IR keeps the instruction until execution is done.

### The three fundamental steps (RISC, 32-bit, one word per instruction)

The textbook writes these in **register transfer notation**, where `[X]` means "the contents
of X" and `←` means "is loaded with".

```
1.  IR ← [[PC]]       ; fetch: the word at the address in PC becomes the instruction
2.  PC ← [PC] + 4     ; increment PC by 4 (memory is byte-addressable, word = 4 bytes)
3.  Carry out the operation specified by the instruction in the IR
```

- **`IR ← [[PC]]`** — the double brackets mean: take the contents of PC (an address), go to
  memory at that address, and load *those* contents into the IR. Steps 1 is the **instruction
  fetch phase**.
- **`PC ← [PC] + 4`** — advance to the next word. Why **+4**? Memory is **byte-addressable**
  and a word is 4 bytes, so consecutive instructions are 4 addresses apart.
- **Step 3** is the **instruction execution phase**.

### What "execute" can involve

With few exceptions, carrying out an instruction means performing one or more of:

- Read a memory location and load it into a processor register.
- Read data from one or more processor registers.
- Perform an **arithmetic or logic** operation and place the result in a register.
- Store data from a register into a memory location.

### The main hardware components (Figure 5.1)

| Component | Role |
|-----------|------|
| **Processor-memory interface** | Transfers data to/from memory on Read and Write operations. |
| **Instruction address generator** | Updates the PC after every fetch. |
| **Register file** | A fast memory unit holding the general-purpose registers. |
| **ALU** | Performs the arithmetic/logic computation named by an instruction. |
| **Control circuitry** | Decodes the IR and drives everything else. |
| **IR** | Holds the current instruction. |

> **Checkpoint:** Why is the PC incremented by 4 and not by 1? *(Memory is byte-addressable
> and each instruction occupies one 4-byte word, so the next instruction is 4 addresses
> away.)*

---

## 3. Data Processing Hardware & Multi-Stage Structure

Before the datapath, the chapter explains the general shape of all data-processing hardware
(Figure 5.2): data sit in **registers**, flow through a **combinational logic circuit** (such as
an adder), and the result is latched into a register.

- Registers are built from **edge-triggered flip-flops**: new data load on the **active edge**
  of the clock. The book assumes the **rising edge** is active.
- The **clock period** (time between two rising edges) must be **long enough** for the
  combinational circuit to produce a correct result.

### Why split one big circuit into stages?

A complex combinational block can be broken into simpler **sub-circuits cascaded into a
multi-stage structure** (Figure 5.3). If **n stages** are used, the operation finishes in **n
clock cycles**, but each sub-circuit is smaller, so it finishes faster and a **shorter clock
period** can be used.

The key payoff: the multi-stage structure is **suitable for pipelined operation** (Chapter 6)
and fits **RISC-style** instruction sets especially well. This chapter focuses on that
multi-stage structure; Section 5.7 covers the traditional alternative for **CISC-style**
processors.

> **Analogy (the assembly line):** A single worker building a whole car by hand = one giant
> slow combinational circuit. An assembly line with specialised stations = the multi-stage
> structure. Each station is simpler and faster, and once the line is full you finish a car
> every short cycle — that is pipelining.

> **Checkpoint:** If one 600 ps combinational circuit is split into three 200 ps stages,
> what have you gained and what have you paid? *(Gained: a much shorter clock period, so each
> stage runs faster and the structure can be pipelined. Paid: the operation now takes 3 clock
> cycles instead of 1.)*

---

## 4. Section 5.2 — Instruction Execution (the Five Steps)

The chapter assumes a processor with **five hardware stages**, a common RISC arrangement.
Execution of **every** instruction is divided into **five steps**, one per stage, each taking
one clock cycle.

### 5.2.1 Load instruction

```asm
Load  R5, X(R7)   ; Index mode: load the word at address X + [R7] into R5
```

Fetching and executing it as five steps:

```
1. Fetch the instruction and increment the program counter.
2. Decode the instruction and read register R7 in the register file.
3. Compute the effective address  X + [R7].
4. Read the memory source operand.
5. Load the operand into the destination register R5.
```

### 5.2.2 Arithmetic / logic instruction

```asm
Add  R3, R4, R5   ; R3 ← [R4] + [R5]
```

An Add differs from Load in two ways: it has **two source registers (or a register + an
immediate)**, and it needs **no memory operand**. It could finish in four steps, but to let
**all** instructions share the same five-stage hardware, a **"No action"** step is inserted:

```
1. Fetch the instruction and increment the program counter.
2. Decode the instruction and read registers R4 and R5.
3. Compute the sum  [R4] + [R5].
4. No action.
5. Load the result into the destination register R3.
```

With an **immediate** operand (`Add R3, R4, #1000`), steps 2 and 3 become "read R4" and
"compute `[R4] + 1000`" — the immediate value is already available in the IR.

### 5.2.3 Store instruction

```asm
Store  R6, X(R8)  ; store [R6] into memory location X + [R8]
```

Same five-step shape as Load, except the **final write-back step takes no action**:

```
1. Fetch the instruction and increment the program counter.
2. Decode the instruction and read registers R6 and R8.
3. Compute the effective address  X + [R8].
4. Store the contents of R6 into memory at X + [R8].
5. No action.
```

### The universal five-step sequence (Figure 5.4)

| Step | Action |
|------|--------|
| 1 | Fetch an instruction and increment the program counter. |
| 2 | Decode the instruction and read registers from the register file. |
| 3 | Perform an ALU operation. |
| 4 | Read or write memory data if the instruction involves a memory operand. |
| 5 | Write the result into the destination register, if needed. |

### Why one addressing mode is enough

This sequence works for **all** RISC-style instructions because the addressing modes are
**special cases of the Index mode**:

- Most RISC processors keep **R0 permanently equal to 0**. Using R0 as the index register
  makes the effective address simply the immediate value X — this is **Absolute** mode.
- Setting the offset X to zero makes the effective address just `[Ri]` — this is **Indirect**
  mode.

So only the **Index mode** needs hardware support, greatly simplifying the processor. Picking
R0 or zeroing X is the job of the **assembler/compiler** — classic RISC philosophy: simple
fast hardware, smarter compiler.

> **Checkpoint:** Why extend the Add instruction to five steps when it only needs four?
> *(So every instruction uses the same five-stage hardware, which keeps control simple and
> enables uniform pipelining.)*

---

## 5. Section 5.3 — Hardware Components

### 5.3.1 Register file

The general-purpose registers live in a **register file** — a small, fast memory block of
storage elements with access circuitry.

- It is **dual-ported**: two registers can be **read at the same time**, appearing on outputs
  **A** and **B**. Two address inputs (wired to the source-register fields of the IR) pick
  which two.
- It has a data input **C** with its own address input (wired to the IR's destination-register
  field) for **writing** a result back.

Two ways to build a dual-ported file (Figure 5.5):

| Implementation | How it works |
|----------------|--------------|
| **Single memory block** | One set of registers with duplicate data paths so two can be read at once. |
| **Two memory blocks** | Two identical copies; every write updates both; each read uses one copy. |

### 5.3.2 ALU

The **arithmetic and logic unit** manipulates data: arithmetic (add, subtract) and logic
(AND, OR, XOR). Conceptually (Figure 5.6):

- Register-file output **A** connects directly to ALU input **InA**.
- Register-file output **B** goes to a multiplexer **MuxB**, which selects either **B** or the
  **immediate value** from the IR to drive ALU input **InB**.
- The ALU output connects back to the register file's data input **C** so results can be
  written to the destination register.

> **Checkpoint:** What does MuxB choose between, and why is it needed? *(Between register-file
> output B and the immediate value in the IR; it lets the same ALU input serve both
> register-register and register-immediate instructions.)*

---

## 6. Section 5.3.3 — The Datapath (Figure 5.8)

Instruction processing has a **fetch phase** and an **execution phase**, so the hardware is
split into two sections. The fetch section also decodes and generates control signals; the
execution section reads operands, computes, and stores results. The execution hardware,
organised as stages 2–5, is called the **datapath**.

### Inter-stage registers

Between stages sit **inter-stage registers** that hold one stage's result so the next stage can
use it on the next clock cycle. These are the ones to memorise:

| Register | Purpose |
|----------|---------|
| **RA** | Holds register-file output A; drives ALU input InA. |
| **RB** | Holds register-file output B; feeds MuxB. |
| **RZ** | Holds the ALU result (or computed effective address). |
| **RM** | Holds data to be stored to memory (for Store instructions). |
| **RY** | Holds the value to be written back to the register file. |
| **PC-Temp** | Temporarily holds the PC when saving a subroutine/interrupt return address. |

### The five stages mapped to hardware (Figure 5.7)

| Stage | Hardware | Does |
|-------|----------|------|
| 1 | Instruction fetch | Fetch instruction into IR, increment PC. |
| 2 | Source registers | Decode, read source registers into RA/RB. |
| 3 | ALU | Compute; result → RZ. |
| 4 | Memory access | Read/write memory operand. |
| 5 | Destination register | Write result into register file. |

### Walking the datapath per instruction type

- **Computational (Add):** no action in step 4; **MuxY** selects RZ so the result moves RZ →
  RY in step 4, then RY → register file in step 5. The register file is in **both** stage 2
  (source registers) **and** stage 5 (destination register).
- **Load:** ALU computes the effective address in step 3 (→ RZ); memory is read in step 4;
  **MuxY** selects the memory data into RY; written to the register file in step 5.
- **Store:** data to be stored is read into RB (stage 2), moved **RB → RM** in step 3, then
  **RM → memory** in step 4; no action in step 5. RM exists precisely to keep the store data
  flowing correctly through the stages.

### Return addresses

Subroutine-call instructions save the return address in a general-purpose register the book
calls **LINK**; interrupts use one called **IRA**. Both need the PC's contents routed to the
register file, so **MuxY has a third input** carrying the return address (produced by the
instruction address generator).

> **Deep dive — why RM exists:** A Store reads its data in stage 2 but does not write memory
> until stage 4. Without a dedicated register, that data would have nowhere valid to sit as it
> passes stage 3. RM is the "holding pen" that carries the store data across the ALU stage so
> the multi-stage data flow stays correct.

> **Checkpoint:** In which two stages does the register file participate, and why? *(Stage 2,
> because it holds the source registers being read; and stage 5, because it holds the
> destination register being written.)*

---

## 7. Section 5.3.4 — The Instruction Fetch Section

The fetch section (Figure 5.9) decides **which address** goes to memory and what happens to
the fetched word.

- Memory addresses come from **two** sources: the **PC** (when fetching an instruction) and
  **RZ** (when accessing a data operand). Multiplexer **MuxMA** picks between them.
- The **instruction address generator** contains the PC and updates it after each fetch.
- The fetched word is loaded into the **IR**, examined by the **control circuitry**, and also
  fed to the **Immediate** block.

### The Immediate block

Some instructions carry an **immediate value**. A 16-bit immediate is **extended to 32 bits**:

- **Sign-extended** for arithmetic instructions.
- **Padded with zeros** for logic instructions.

The extended value is forwarded to **MuxB** (for ALU use) and is also used to compute the
**branch target address**.

### The instruction address generator (Figure 5.10)

An **adder** does two jobs:

1. **Increment PC by 4** during straight-line execution.
2. **Compute a branch/call target** by adding a branch offset to the PC.

The adder's two inputs:

- Input 1: the PC.
- Input 2: **MuxINC**, which selects either the constant **4** or the **branch offset**
  (sign-extended immediate).

The adder output reaches the PC through **MuxPC**, which chooses between the adder result and
register **RA** (RA is used for subroutine linkage, where the target address comes from a
register). **PC-Temp** temporarily holds the PC while a return address is being saved.

> **Checkpoint:** What two values can MuxINC add to the PC, and when is each used? *(The
> constant 4 during straight-line execution; the branch offset when executing a branch.)*

---

## 8. Section 5.4 — Instruction Fetch and Execution Steps

Now the step sequences in full register-transfer notation. The instruction encoding (Figure
5.12) places source register addresses in **IR31–27** (Rsrc1) and **IR26–22** (Rsrc2), and the
destination in **IR21–17** (three-register format) or **IR26–22** (other formats).

### Add R3, R4, R5 (Figure 5.11)

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction, RA ← [R4], RB ← [R5]
Step 3:  RZ ← [RA] + [RB]
Step 4:  RY ← [RZ]
Step 5:  R3 ← [RY]
```

Line-by-line:
- **Step 1** fetches the word at `[PC]` into the IR and bumps the PC by 4.
- **Step 2** reads the two source fields (R4, R5) into RA and RB.
- **Step 3** sets MuxB to input 0 (selecting RB), the ALU adds, result → RZ.
- **Step 4** MuxY selects input 0, moving RZ → RY; the destination field IR21–17 is routed
  to port C.
- **Step 5** asserts the register-file Write, so RY → R3.

### Load R5, X(R7) (Figure 5.13)

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction, RA ← [R7]
Step 3:  RZ ← [RA] + Immediate value X
Step 4:  Memory address ← [RZ], Read memory, RY ← Memory data
Step 5:  R5 ← [RY]
```

The immediate X (from the IR, extended) is selected by MuxB in step 3 and added to RA to
form the **effective address**.

### Store R6, X(R8) (Figure 5.14)

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction, RA ← [R8], RB ← [R6]
Step 3:  RZ ← [RA] + Immediate value X,  RM ← [RB]
Step 4:  Memory address ← [RZ], Memory data ← [RM], Write memory
Step 5:  No action
```

### Two important observations

1. **One-cycle memory assumption.** The steps assume a memory Read/Write finishes in one
   clock cycle. That is realistic **only when the data is in the cache** (on-chip, nearly as
   fast as the register file). A main-memory access takes several cycles — handled by the MFC
   mechanism in §5.4.2.
2. **Reading registers while decoding.** Step 2 reads source registers *at the same time* as
   it decodes the OP code. This is possible because **source register addresses occupy the
   same bit positions in every instruction**, so the hardware can read them before decoding
   finishes. If the data turn out not to be needed, later stages simply ignore RA/RB. (Two
   registers are **always** read in step 2, even when the figures only mention one.)

> **Checkpoint:** Why can a RISC processor read source registers before it finishes decoding
> the instruction? *(Because source-register addresses are always in the same IR bit
> positions, so the register file can be addressed immediately.)*

---

## 9. Section 5.4.1 — Branching & Subroutine Calls

Straight-line execution increments the PC by 4 each fetch until a **branch** or **subroutine
call** loads a new address.

### Branch addressing

- **Branch** instructions give the target **relative to the PC**: a **branch offset**
  (immediate) is added to the current PC. The offset has fewer bits than a full word (room is
  needed for the OP code and condition), so a branch's reach is **limited**.
- **Subroutine calls** reach a **larger range** — no condition means more bits for the
  address. Many RISC machines also have Jump/Call forms that use a general-purpose register
  for a full 32-bit address.

### Unconditional branch (Figure 5.15)

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction
Step 3:  PC ← [PC] + Branch offset
Step 4:  No action
Step 5:  No action
```

Execution finishes in step 3. Note **why the offset is measured from the instruction after the
branch**: the PC was already incremented by 4 in step 1, so step 3 adds the offset to the
*already-updated* PC.

### Conditional branch (Figure 5.16)

```asm
Branch_if_[R5]=[R6]  LOOP
```

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction, RA ← [R5], RB ← [R6]
Step 3:  Compare [RA] to [RB]; if [RA] = [RB] then PC ← [PC] + Branch offset
Step 4:  No action
Step 5:  No action
```

In processors **without condition-code flags**, the branch instruction itself specifies a
**compare-and-test**. The comparison could be done by subtracting `[R5] − [R6]` in the ALU
and checking the result sign/zero/overflow/carry signals — but subtraction is slow. A
dedicated **comparator** (which can live inside the ALU block) produces greater-than,
equal, less-than signals faster. Both the compare **and** the test happen in step 3, so the
clock cycle must be long enough for both.

### Subroutine call (Figure 5.17)

```asm
Call_Register  R9   ; call the subroutine whose address is in R9
```

```
Step 1:  Memory address ← [PC], Read memory, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction, RA ← [R9]
Step 3:  PC-Temp ← [PC], PC ← [RA]
Step 4:  RY ← [PC-Temp]
Step 5:  Register LINK ← [RY]
```

- Step 2 reads R9 into RA.
- Step 3: MuxPC selects its 0 input so RA → PC (jump to the subroutine), and the old PC is
  saved in **PC-Temp**.
- The return address cannot go straight to the register file (writes happen in step 5), so it
  travels **PC-Temp → RY (step 4) → LINK (step 5)**. The LINK address is built into the control
  circuitry.

**Return-from-subroutine** encodes the LINK register address in bits **IR31–27** (the field
wired to Address A), so LINK is read into RA on fetch and transferred to the PC via MuxPC.
Return-from-interrupt works the same way but uses a different return register.

> **Checkpoint:** Why is the branch offset measured from the instruction *after* the branch?
> *(Because the PC is incremented by 4 during the fetch in step 1, so the target is computed
> relative to that already-updated PC.)*

---

## 10. Section 5.4.2 — Waiting for Memory (MFC)

Memory accesses are only sometimes one cycle. When data is **in the cache**, it is; when it
must come from **main memory**, several cycles are needed. The **processor-memory interface**
tells the control circuitry which case it is, using a signal:

- **MFC (Memory Function Completed)** — asserted by the interface when a requested Read or
  Write has finished.

The control circuitry checks MFC in any step that issues a memory request:

- **Cache hit:** MFC is asserted **within the same clock cycle** — execution continues
  uninterrupted.
- **Main-memory access:** MFC is delayed — the control circuitry **extends the step** for as
  many clock cycles as needed until MFC appears.

The textbook uses the command **Wait for MFC** to mark a step that must be extended if
necessary. Step 1 (instruction fetch) always needs it:

```
Memory address ← [PC], Read memory, Wait for MFC,
IR ← Memory data, PC ← [PC] + 4
```

It is also needed in **step 4 of Load and Store** instructions.

> **Checkpoint:** What does the MFC signal tell the processor, and what does the processor do
> while waiting for it? *(MFC signals that a memory Read/Write has completed; while waiting,
> the control circuitry extends the current execution step over additional clock cycles.)*

---

## 11. Section 5.5 — Control Signals

Every hardware component is governed by **control signals**: which multiplexer input is
selected, what the ALU does, when a register loads, and so on.

### Always-enabled vs. selectively-enabled registers

- **Inter-stage registers (RA, RB, RZ, RY, RM, PC-Temp)** are **always enabled** — data flows
  stage to stage on every clock edge.
- The **PC, IR, and register file** must **not** change every cycle; they are enabled **only**
  when a particular step calls for it.

### The datapath control signals (Figures 5.18–5.19)

| Signal | Controls |
|--------|----------|
| **RF_write** | Enables writing data into the selected register-file register. |
| **Address A / Address B** | 5-bit inputs (from IR31–27 and IR26–22) selecting the two registers to read. |
| **Address C / MuxC (C_select)** | Selects the destination register address: IR21–17, IR26–22, or the LINK address. |
| **B_select** | MuxB: selects RB (=0) or the immediate value for ALU input InB. |
| **ALU_op** | A k-bit code choosing the ALU operation (Add, Subtract, AND, OR, XOR, …). |
| **Y_select** | MuxY: selects RZ, memory data, or the return address into RY. |

The register file has **three 5-bit address inputs** (32 registers). MuxC and MuxY each need
**two select bits** because they choose among **three** inputs.

### Memory and IR control signals (Figure 5.19)

| Signal | Controls |
|--------|----------|
| **MA_select** | MuxMA: selects PC (step 1 fetch) or RZ (step 4 operand access) as the memory address. |
| **MEM_read / MEM_write** | Initiate a memory Read or Write. |
| **MFC** | Asserted by the interface when the operation completes. |
| **IR_enable** | Loads a new instruction into the IR — activated only after MFC during a fetch. |
| **Extend** | Two bits selecting the immediate format: sign-extended 16-bit, zero-extended 16-bit, or 26-bit. |

### Address-generator control signals (Figure 5.20)

| Signal | Controls |
|--------|----------|
| **INC_select** | MuxINC: adds the constant 4 or the branch offset to the PC. |
| **PC_select** | MuxPC: selects the updated address (adder) or register RA for loading into the PC. |
| **PC_enable** | Loads the new value into the PC. |

> **Deep dive — why some multiplexer selects never change:** The ALU is used only in step 3,
> so **MuxB's** choice only matters in step 3; the same selection can be kept in all steps
> without harm. **MuxY** is similar. But **MuxMA must change**: it picks the PC in step 1 and
> RZ in step 4. This observation is what lets some selects be a function of the instruction
> alone, simplifying the control logic.

> **Checkpoint:** Why do MuxC and MuxY each require two control bits while MuxB needs only one?
> *(MuxC and MuxY choose among three inputs; MuxB chooses between two.)*

---

## 12. Section 5.6 — Hardwired Control

How are the control signals produced in the right order at the right time? There are **two
approaches: hardwired control and microprogrammed control.** This section covers **hardwired**.

An instruction executes in a sequence of steps, one per clock cycle, so a **step counter**
tracks progress. The control-signal settings depend on four things:

1. Contents of the **step counter**.
2. Contents of the **instruction register (IR)**.
3. The **result** of a computation or comparison.
4. **External inputs** such as interrupt requests.

### The control-signal generator (Figure 5.21)

- The **instruction decoder** interprets the OP code and addressing-mode bits in the IR and
  sets one of the outputs **INS1 … INSm** to 1.
- The **step counter** sets one of **T1 … T5** to 1 each clock cycle to say which step is
  running. Because every instruction completes in five steps, a **modulo-5 counter** is used.
- The **control signal generator** is a **combinational circuit** that produces the signals
  from all these inputs.

Example — step 1 (fetch), identified by **T1**:
- Set **MA_select = 1** (choose the PC as the memory address).
- Activate **MEM_read**.
- When **MFC** is asserted, activate **IR_enable** to load the IR.
- Set **INC_select = 0** and **PC_select = 1**, then activate **PC_enable** so the PC is
  incremented by 4 at the end of T1.

### 5.6.1 Datapath control signals as logic expressions

The desired setting of each signal is read off from the step sequences. Two examples:

```
RF_write  = T5 · (ALU + Load + Call)
B_select  = Immediate
```

- **`RF_write = T5 · (ALU + Load + Call)`** — write to the register file **in step 5** for any
  arithmetic/logic instruction (**ALU**), any **Load**, or any **Call** (subroutine-call /
  software-interrupt). It depends on both the instruction and the timing signal.
- **`B_select = Immediate`** — because MuxB's selection need not vary step to step, it can be
  a function of the **instruction only**: select the immediate for every instruction that uses
  one.

### 5.6.2 Dealing with memory delay

The step counter normally advances every cycle, but a step issuing **MEM_read/MEM_write**
must not end until **MFC** arrives. To extend a step, the counter is **disabled**:

```
Counter_enable = WMFC + MFC
```

- **WMFC** is asserted in any step that issues a **Wait for MFC**.
- Read it as: enable the counter when we are **not** waiting (WMFC = 0 makes the term
  `WMFC` — meaning "not waiting" — true), **or** when MFC has arrived. In words: advance unless
  we are waiting for memory and MFC has not yet come.

The PC must be incremented **only once** even if a step stretches over several cycles:

```
PC_enable = T1 · MFC + T3 · BR
```

- `T1 · MFC` — during fetch, enable the PC only when MFC is received (so it increments once).
- `T3 · BR` — enable it in step 3 for all branching instructions (**BR**), when the branch
  target is loaded.

> **Checkpoint:** Why is MFC included in the `PC_enable` expression for step 1? *(So the PC is
> incremented exactly once — only when the memory read actually completes — even if step 1 is
> stretched over several clock cycles waiting for main memory.)*

---

## 13. Section 5.7 — CISC-Style Processors & Microprogrammed Control

RISC's uniform five-stage approach works because all instructions are one word and only
Load/Store touch memory. **CISC** instruction sets are more flexible — instructions can
**operate directly on memory operands** and span **several words** — so they need a different
organisation.

### The CISC organisation (Figure 5.22)

The big difference: an **Interconnect** block replaces the fixed multi-stage data flow. The
Interconnect provides paths to transfer data **between any two components** as needed, in no
prescribed pattern. Consequences:

- Inter-stage registers like RZ and RY are **not needed**.
- Instead, **temporary registers** (**Temp1**, **Temp2**) hold intermediate results during
  execution.

### Buses and tri-state gates (Figure 5.23)

The traditional way to build the Interconnect is with **buses** — sets of lines many devices
share.

- A gate that drives a bus line is a **bus driver**. Because every connected device could
  drive the bus, only **one** may do so at a time.
- The driver is a **tri-state gate**: a control input turns it **on** (places a 0 or 1 on the
  bus) or **off** (electrically disconnected).
- Each register bit has two control signals: **Rin** (1 = load the bus value into the
  flip-flop) and **Rout** (1 = drive the flip-flop's value onto the bus through the tri-state
  gate).

### 5.7.1 A three-bus interconnect (Figure 5.24)

A three-bus implementation lets a whole register-register operation complete in one cycle.

```asm
Add  R5, R6   ; R5 ← [R5] + [R6]   (two-operand CISC instruction)
```

Steps (Figure 5.25):

```
Step 1:  Memory address ← [PC], Read memory, Wait for MFC, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction
Step 3:  R5 ← [R5] + [R6]
```

- Step 1 sends the PC over **bus B** to the memory interface; the fetched instruction returns
  over **bus C** into the IR; **Wait for MFC** covers multi-cycle access.
- Step 2 decodes and begins reading R5 and R6 — but their contents are not ready until step 3.
- Step 3 sends R5 and R6 over **buses A and B** to the ALU, which adds, and the sum returns
  over **bus C** into R5.

Note the contrast with RISC: in a RISC instruction (Figure 5.11) source registers are read in
step 2 **in parallel with decoding**, because the register-address fields are always in the
same place. CISC instructions do **not** always put register addresses in the same fields, so
reading cannot start until the instruction is **at least partially decoded** — hence reading
may not finish in step 2.

### A memory-operating CISC instruction (Figure 5.26)

```asm
And  X(R7), R9   ; memory[X + [R7]] ← memory[X + [R7]] AND [R9]
```

This touches memory **four times**: fetch OP-code word, fetch the 32-bit offset X, read the
memory operand, write the result back.

```
Step 1:  Memory address ← [PC], Read memory, Wait for MFC, IR ← Memory data, PC ← [PC] + 4
Step 2:  Decode instruction
Step 3:  Memory address ← [PC], Read memory, Wait for MFC, Temp1 ← Memory data, PC ← [PC] + 4
Step 4:  Temp2 ← [Temp1] + [R7]
Step 5:  Memory address ← [Temp2], Read memory, Wait for MFC, Temp1 ← Memory data
Step 6:  Temp1 ← [Temp1] AND [R9]
Step 7:  Memory address ← [Temp2], Memory data ← [Temp1], Write memory, Wait for MFC
```

- Step 3 fetches the offset X into **Temp1**.
- Step 4 computes the effective address `[Temp1] + [R7]` into **Temp2**.
- Step 5 reads the memory operand into **Temp1** (reusing it).
- Step 6 performs the AND, result in **Temp1**.
- Step 7 writes the result back to the address still held in **Temp2**.

These two examples show the defining CISC trait: **the number of execution steps varies from
instruction to instruction** — there is **no uniform sequence** as there was for RISC.

### 5.7.2 Microprogrammed control

Instead of generating control signals with hardwired combinational logic, a **"software"**
approach stores the settings in a special memory:

- The **microprogram** (distinct from the program the processor runs) is stored on-chip in a
  small fast memory called the **microprogram memory** or **control store**.
- If **n** control signals are needed, each step's settings are an **n-bit control word**, also
  called a **microinstruction**. Each bit is the setting of one control signal for that step.
- The sequence of microinstructions for one machine instruction is a **microroutine**. Steps 1
  and 2 (fetch and decode) are common to all instructions; the instruction-specific microroutine
  starts at **step 3**.

### The microprogrammed control unit (Figure 5.27)

- A **microinstruction address generator** produces the control-store address, tracking it with
  a **microprogram counter (µPC)**.
- During step 2 the generator **decodes the IR** to get the **starting address** of the
  microroutine and loads it into the µPC.
- As execution proceeds, the µPC is **incremented** to read successive microinstructions.
- A special bit called **End** marks the last microinstruction of a microroutine. When **End =
  1**, the address generator returns to the microinstruction for step 1, fetching the next
  machine instruction.

### Hardwired vs. microprogrammed — the verdict

| | Hardwired | Microprogrammed |
|--|-----------|-----------------|
| Mechanism | Combinational logic + step counter | Control words in a control store |
| Flexibility | Lower | High (easy to change microroutines) |
| Speed | Faster | Slower |
| Best for | RISC (simple signals, speed matters) | CISC (complex, variable instructions) |

The book's conclusion: because RISC control signals are simple to generate and logic-circuit
cost is no longer a major factor, **hardwired control has become the preferred choice**.
Microprogramming was more popular in the past.

> **Checkpoint:** What marks the end of a microroutine, and what happens when it is reached?
> *(The End bit; when End = 1 the microinstruction address generator jumps back to the step-1
> microinstruction to fetch the next machine instruction.)*

---

## 14. Step-Sequence Reference Card

| Instruction | 5-step summary (RISC) |
|-------------|-----------------------|
| **Add R3,R4,R5** | fetch+PC+4 · read R4,R5 · RZ=RA+RB · RY=RZ · R3=RY |
| **Load R5,X(R7)** | fetch+PC+4 · read R7 · RZ=RA+X · read mem→RY · R5=RY |
| **Store R6,X(R8)** | fetch+PC+4 · read R8,R6 · RZ=RA+X,RM=RB · write mem · no action |
| **Branch (uncond.)** | fetch+PC+4 · decode · PC=PC+offset · no action · no action |
| **Branch_if cond.** | fetch+PC+4 · read R5,R6 · compare, if eq PC=PC+offset · no action · no action |
| **Call_Register R9** | fetch+PC+4 · read R9 · PC-Temp=PC,PC=RA · RY=PC-Temp · LINK=RY |

| Hardware block | What it is |
|----------------|-----------|
| **PC** | Program counter — address of next instruction. |
| **IR** | Instruction register — holds current instruction. |
| **Register file** | Dual-ported bank of general-purpose registers (ports A, B read; C write). |
| **ALU** | Arithmetic/logic unit; inputs InA, InB; output Out. |
| **RA, RB** | Inter-stage registers holding source operands. |
| **RZ** | Inter-stage register holding ALU result / effective address. |
| **RM** | Inter-stage register holding Store data across the ALU stage. |
| **RY** | Inter-stage register holding write-back value. |
| **PC-Temp** | Holds PC while saving a return address. |
| **MuxB** | Selects RB or immediate into ALU input InB. |
| **MuxY** | Selects RZ, memory data, or return address into RY. |
| **MuxMA** | Selects PC or RZ as the memory address. |
| **MuxINC** | Selects 4 or branch offset to add to PC. |
| **MuxPC** | Selects adder output or RA into PC. |
| **Temp1, Temp2** | CISC temporary registers for intermediate results. |

### Key control-signal logic expressions

| Expression | Meaning |
|-----------|---------|
| `RF_write = T5 · (ALU + Load + Call)` | Write register file in step 5 for ALU, Load, Call. |
| `B_select = Immediate` | MuxB picks the immediate for immediate-using instructions. |
| `Counter_enable = WMFC + MFC` | Advance step counter unless waiting for an incomplete memory op. |
| `PC_enable = T1 · MFC + T3 · BR` | Increment PC once at fetch (on MFC) and at step 3 of branches. |

---

## 15. Glossary of Every Register & Signal

**Core registers**
- **PC** — Program Counter; address of the next instruction. Incremented by 4 per fetch.
- **IR** — Instruction Register; holds the instruction being executed/decoded.
- **PC-Temp** — temporary store for the PC while saving a return address.
- **LINK** — general-purpose register holding a subroutine return address.
- **IRA** — general-purpose register holding an interrupt return address.
- **PS / IPS** — Processor Status register and its interrupt-time backup (Example 5.5–5.6).

**Datapath inter-stage registers**
- **RA, RB** — hold the two source operands read from the register file.
- **RZ** — holds the ALU result or a computed effective address.
- **RM** — holds Store data as it crosses the ALU stage to reach memory in step 4.
- **RY** — holds the value destined for the register file in step 5.
- **Temp1, Temp2** — CISC temporary registers for intermediate results.

**Functional blocks**
- **Register file** — fast dual-ported memory of general-purpose registers (ports A, B, C).
- **ALU** — arithmetic and logic unit (Add, Subtract, AND, OR, XOR; condition signals).
- **Instruction address generator** — contains the PC and the adder that updates it.
- **Processor-memory interface** — moves data to/from memory, raises MFC.
- **Immediate block** — sign- or zero-extends a 16-bit (or 26-bit) immediate to 32 bits.
- **Interconnect** — CISC block giving flexible any-to-any data paths (implemented with buses).

**Multiplexers**
- **MuxB** — RB vs. immediate → ALU input InB (control: B_select).
- **MuxY** — RZ vs. memory data vs. return address → RY (control: Y_select, 2 bits).
- **MuxC** — IR21–17 vs. IR26–22 vs. LINK → Address C (control: C_select, 2 bits).
- **MuxMA** — PC vs. RZ → memory address (control: MA_select).
- **MuxINC** — 4 vs. branch offset → adder (control: INC_select).
- **MuxPC** — adder vs. RA → PC (control: PC_select).

**Control signals**
- **RF_write** — enable a write into the register file.
- **ALU_op** — k-bit code selecting the ALU operation.
- **MEM_read / MEM_write** — start a memory Read / Write.
- **MFC** — Memory Function Completed; asserted when a memory op finishes.
- **IR_enable** — load a new instruction into the IR (after MFC during fetch).
- **Extend** — 2-bit immediate-format selector.
- **PC_enable** — load a new value into the PC.
- **Counter_enable** — advance the step counter.
- **WMFC** — Wait-for-MFC flag; set when a step must extend until MFC.
- **Rin / Rout** — per-bit bus load / drive controls (CISC bus registers).

**Timing / control concepts**
- **T1 … T5** — step-counter outputs; exactly one is 1 each clock cycle (modulo-5 counter).
- **INS1 … INSm** — instruction-decoder outputs; one per recognised instruction group.
- **µPC** — microprogram counter; addresses the control store.
- **Control store / microprogram memory** — on-chip memory holding microinstructions.
- **Microinstruction / control word** — n-bit word, one bit per control signal, for one step.
- **Microroutine** — the sequence of microinstructions implementing one machine instruction.
- **End** — microinstruction bit marking the last step of a microroutine.
- **BR** — the group of all branching instructions (used in control logic).

---

## 16. Self-Test Questions

Try these without looking back. Answers in the sections cited.

1. Write the three fundamental steps of instruction execution in register-transfer notation,
   and explain why the PC is incremented by 4. *(§2)*
2. What advantage does a multi-stage structure have over a single large combinational circuit,
   and what is the cost? *(§3)*
3. List the universal five-step action sequence of Figure 5.4. *(§4)*
4. Why can every RISC addressing mode be treated as a special case of the Index mode? *(§4)*
5. Name the six inter-stage registers in the datapath and state what each holds. *(§6)*
6. Why does the register file appear in both stage 2 and stage 5? *(§6)*
7. In the fetch section, what two sources can supply the memory address, and which multiplexer
   chooses between them? *(§7)*
8. Write the five steps for `Load R5, X(R7)` and identify where the effective address is
   computed. *(§8)*
9. Why is a branch offset measured relative to the instruction following the branch? *(§9)*
10. How does a processor without condition-code flags evaluate a conditional branch? *(§9)*
11. What is the MFC signal, and what command marks a step that must wait for it? *(§10)*
12. Which datapath registers are always enabled and which are enabled only on demand, and why?
    *(§11)*
13. Explain the logic expression `RF_write = T5 · (ALU + Load + Call)`. *(§12)*
14. Why must MFC appear in the `PC_enable` expression for the fetch step? *(§12)*
15. Give two defining differences between the RISC datapath (Fig 5.8) and the CISC organisation
    (Fig 5.22). *(§13)*
16. In microprogrammed control, what is a microroutine, and what role does the End bit play?
    *(§13)*
17. State two reasons hardwired control is preferred over microprogrammed control for RISC
    processors. *(§13)*

---

*End of study guide. Open this file in any Markdown viewer (VS Code, Obsidian, Typora,
GitHub) to read it with formatting, or export to PDF from there.*
