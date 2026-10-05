# Chapter 1 — Basic Structure of Computers

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 1–22 (Sections 1.1 → 1.7)

> How to use this guide: read it top to bottom. Each section builds on the previous one.
> Terms in **bold** are the ones you must be able to define. Tables lay out the comparisons
> you will be tested on, and the worked binary examples are the exact ones from the
> textbook. The "Checkpoint" boxes are what you should be able to answer before moving on.

---

## Table of Contents

1. [The Big Picture — What a Computer Is](#1-the-big-picture)
2. [Section 1.1 — Computer Types](#2-section-11--computer-types)
3. [Section 1.2 — Functional Units](#3-section-12--functional-units)
4. [The Five Units in Detail (Input, Memory, ALU, Output, Control)](#4-the-five-units-in-detail)
5. [Section 1.3 — Basic Operational Concepts](#5-section-13--basic-operational-concepts)
6. [The Processor Internals (PC, IR, Registers)](#6-the-processor-internals)
7. [Section 1.4 — Number Representation and Arithmetic](#7-section-14--number-representation-and-arithmetic)
8. [Signed-Number Systems & 2's-Complement](#8-signed-number-systems--2s-complement)
9. [Addition, Subtraction, Sign Extension & Overflow](#9-addition-subtraction-sign-extension--overflow)
10. [Floating-Point Numbers](#10-floating-point-numbers)
11. [Section 1.5 — Character Representation (ASCII)](#11-section-15--character-representation-ascii)
12. [Section 1.6 — Performance](#12-section-16--performance)
13. [Section 1.7 — Historical Perspective](#13-section-17--historical-perspective)
14. [Instruction & Concept Reference Card](#14-instruction--concept-reference-card)
15. [Glossary of Every Term & Acronym](#15-glossary-of-every-term--acronym)
16. [Self-Test Questions](#16-self-test-questions)

---

## 1. The Big Picture

This book is about **computer organization** — the function and design of the units of a
digital computer that **store and process information**. The whole machine exists to run a
**program**: a list of instructions that governs the input, storage, processing, and output
of information.

Two words frame everything in the chapter:

- **Computer hardware** — the physical stuff: electronic circuits, magnetic and optical
  storage, displays, electromechanical devices, communication facilities.
- **Computer architecture** — the *specification* of an **instruction set** and the
  functional behavior of the hardware units that implement those instructions.

Everything a computer handles is one of two kinds of information:

| Category | What it is |
|----------|-----------|
| **Instructions** (machine instructions) | Explicit commands that govern information transfer and specify arithmetic/logic operations. |
| **Data** | Numbers and characters used as **operands** by the instructions. |

Both are encoded as strings of **bits** (binary digits, each 0 or 1), because present-day
hardware uses digital circuits with only **two stable states**.

> **Checkpoint:** What is the difference between an instruction and data? *(An instruction
> is a command telling the processor what to do; data are the numbers and characters the
> instruction operates on. Both live in memory and are encoded as bits.)*

---

## 2. Section 1.1 — Computer Types

Since the 1940s, digital computers have evolved into types that vary widely in size, cost,
power, and purpose. The textbook divides modern computers into **four general categories**,
plus one emerging access model.

| Type | Purpose & distinguishing trait |
|------|-------------------------------|
| **Embedded computers** | Built into a larger device to monitor and control a physical process. Special-purpose, often invisible to the user. Appliances, vehicles, telecom, automation. |
| **Personal computers** | Widespread individual use. Sub-types: **Desktop** (general needs), **Workstation** (higher compute + graphics for engineering/science), **Portable/Notebook** (smaller, battery-powered, mobile). |
| **Servers and Enterprise systems** | Large machines shared by many users over a network; host large databases and do information processing for organizations. |
| **Supercomputers and Grid computers** | Highest performance, most expensive, physically largest. Supercomputers do weather forecasting, simulation, scientific work. **Grid computers** combine many PCs and disks in a distributed high-speed network managed as one resource — a cheaper alternative. |

**Cloud computing** is an emerging *access trend*: users reach widely distributed computing
and storage servers over the Internet, and providers charge on a **pay-as-you-use** basis
like a utility.

> **Checkpoint:** How does a grid computer differ from a supercomputer? *(A supercomputer
> is a single very expensive high-performance machine; a grid combines many ordinary PCs
> and disks over a high-speed network, managed as one coordinated resource, to reach high
> performance more cost-effectively.)*

---

## 3. Section 1.2 — Functional Units

A computer consists of **five functionally independent main parts** (Figure 1.1):

1. **Input** unit
2. **Memory** unit
3. **Arithmetic and logic** unit (ALU)
4. **Output** unit
5. **Control** unit

They are tied together by an **interconnection network**, which lets the units exchange
information and coordinate their actions.

Two grouping names you must know:

- **Processor** = the arithmetic and logic circuits **plus** the main control circuits.
- **I/O unit** (input-output) = the input and output equipment taken together.

The operation of a computer in four lines:

- Accept programs and data through an **input** unit and store them in **memory**.
- Fetch stored information under program control into the **ALU**, where it is processed.
- Send processed information out through an **output** unit.
- Have all activity **directed by the control unit**.

> **Analogy (an office):** think of the computer as a small office. The **input** unit is
> the mail slot where work arrives, **memory** is the filing cabinet holding both the task
> instructions and the paperwork, the **ALU** is the clerk doing the actual arithmetic, the
> **output** unit is the outgoing mail tray, and the **control** unit is the manager who
> tells everyone when to act.

> **Checkpoint:** Name the five functional units and say which two together are called the
> "processor". *(Input, memory, ALU, output, control; the ALU plus the main control
> circuits are the processor.)*

---

## 4. The Five Units in Detail

### 4.1 Input Unit

Accepts coded information. The most common input device is the **keyboard**: pressing a key
automatically translates the letter or digit into its **binary code** and transmits it to
the processor. Other human-interaction devices include the **touchpad, mouse, joystick,
trackball**, plus **microphones** (audio sampled into digital codes) and **cameras** (video).
Digital communication facilities like the **Internet** also feed input from other computers.

### 4.2 Memory Unit

Stores programs and data. There are **two classes** of storage:

| Class | Also called | Properties |
|-------|-------------|-----------|
| **Primary memory** | Main memory | Fast, electronic speed. Holds programs *while they execute*. **Volatile** detail: not stated here, but it is expensive and loses data at power-off (see secondary). |
| **Secondary storage** | — | Cheaper, **permanent**, larger, slower. Magnetic disks, optical disks DVD or CD, flash memory. |

Key primary-memory vocabulary:

- Memory is made of **semiconductor storage cells**, each holding **one bit**.
- Cells are handled in fixed-size groups called **words**. The number of bits per word is
  the **word length** — typically **16, 32, or 64 bits**.
- Each word has a distinct **address** — consecutive numbers starting from **0**.
- **Random-access memory (RAM)** — any location can be accessed in a short, **fixed** time
  regardless of its position. That time is the **memory access time**, roughly a few
  nanoseconds up to about **100 ns** for current RAM.

**Cache memory** is a smaller, faster RAM between the processor and main memory, usually on
the same chip. It holds sections of the program currently executing plus associated data.
It starts **empty**; as execution proceeds, fetched instructions and data are **copied**
into it. The payoff is **program loops** and repeatedly accessed data: those items are then
fetched quickly from the cache instead of slow main memory.

> **Deep dive — why cache helps a loop:** the first time through a loop, instructions come
> from slow main memory and a copy lands in the cache. On every later iteration, the
> processor finds them already in the fast cache. A 100-instruction loop run 25 times pays
> the slow price once and the fast price for the remaining passes — exactly the speedup
> computed in Example 1.2 below.

### 4.3 Arithmetic and Logic Unit (ALU)

Where most operations run: **addition, subtraction, multiplication, division, comparison**,
and logic operations. Operands are brought **into the processor** first, where the ALU acts
on them. Operands live in high-speed storage elements called **registers**, each holding
**one word**. Register access is **even faster** than cache access.

### 4.4 Output Unit

The counterpart of input — sends processed results to the outside world. Classic example: a
**printer** (laser/photocopying or ink jet), which is **mechanical and slow** compared to the
electronic processor. Some units, like **graphic displays with touchscreens**, do both input
and output, which is why the combined name **I/O unit** is used.

### 4.5 Control Unit

The **nerve center** that coordinates all other units: it sends control signals and senses
unit states. **I/O transfers** and **processor-memory transfers** are governed by **timing
signals** the control circuits generate. In practice the control circuitry is **physically
distributed** throughout the computer, carried by a large set of **control lines** (wires)
used for timing and synchronization.

| Unit | One-line job |
|------|-------------|
| Input | Bring coded information in. |
| Memory | Store programs and data (primary fast, secondary permanent). |
| ALU | Perform arithmetic and logic on register operands. |
| Output | Send results out. |
| Control | Generate timing signals and coordinate everyone. |

> **Checkpoint:** Why are registers faster to access than cache? *(Registers are inside the
> processor itself and hold a single word each; access times to registers are even shorter
> than to the on-chip cache.)*

---

## 5. Section 1.3 — Basic Operational Concepts

Activity in a computer is governed by **instructions** stored in memory. Individual
instructions are brought from memory into the processor, which executes them. The chapter
uses three canonical instructions.

```asm
Load   R2, LOC        ; read memory location LOC into register R2
Add    R4, R2, R3     ; R4 = contents of R2 + contents of R3
Store  R4, LOC        ; copy register R4 into memory location LOC
```

### Line-by-line meaning

- **`Load R2, LOC`** — reads the contents of the memory location labelled **LOC** and loads
  them into register **R2**. The original contents of **LOC are preserved**; the old value of
  **R2 is overwritten**.
- **`Add R4, R2, R3`** — adds the contents of **R2** and **R3** and places the sum in **R4**.
  R2 and R3 are **unchanged**; the previous value of R4 is **overwritten**.
- **`Store R4, LOC`** — copies the operand in **R4** to memory location **LOC**. LOC is
  overwritten; **R4 is preserved**.

### Executing `Load R2, LOC` step by step (Example 1.1)

The address of the instruction starts in the **PC**. The required steps are:

1. Send the address in **PC** to the memory, issue a **Read** command.
2. Wait for the word to arrive, load it into **IR**, where the control circuitry **decodes**
   it to determine the operation.
3. **Increment PC** to point to the next instruction.
4. Send the address value **LOC** from the instruction in IR to memory, issue **Read**.
5. Wait for the word, then load it into register **R2**.

### Load and Store mechanics

For **Load/Store**, transfers between memory and processor begin by sending the **address**
of the desired location to the memory unit and asserting the right **control signals**; the
data then move to or from memory.

### Interrupts (first mention)

Normal execution may be **preempted** if a device needs urgent service — e.g. a monitoring
device detecting a dangerous condition. The device raises an **interrupt signal** (a request
for service). The processor runs an **interrupt-service routine**. Because the diversion can
alter processor state, that state (the **PC**, the **general-purpose registers**, and some
control information) is **saved in memory** first, then **restored** afterwards so the
interrupted program continues.

> **Checkpoint:** After `Load R2, LOC` runs, what happened to LOC and to R2? *(LOC keeps its
> original contents; R2 is overwritten with a copy of them.)*

---

## 6. The Processor Internals

Figure 1.2 shows how the processor connects to main memory and names the special registers.

| Register | Full name | Role |
|----------|-----------|------|
| **IR** | Instruction Register | Holds the instruction **currently being executed**; its output drives the control circuits. |
| **PC** | Program Counter | Holds the memory **address of the next instruction** to fetch; "points to" the next instruction. Updated during each instruction. |
| **R0 … Rn-1** | General-purpose registers | Also called processor registers; hold operands loaded from memory, among other roles. |

The **processor-memory interface** is the circuit that manages data transfer between main
memory and the processor:

- To **read**: it sends the address plus a **Read** signal, waits for the word, and transfers
  it to the right register.
- To **write**: it sends both the address and the word plus a **Write** signal.

### The fetch-execute cycle (typical operating steps)

1. A program must be in **main memory** to run; it is often brought there from secondary
   storage through the input unit.
2. Execution begins when **PC** points to the first instruction.
3. PC contents go to memory with a **Read**; the fetched instruction is loaded into **IR**.
4. The instruction is **interpreted and executed**; operands in memory are fetched by
   sending their address and doing a Read, landing in processor registers.
5. The ALU performs the operation; results go to a register and, if needed, are **Stored**
   back to memory with a Write.
6. At some point **PC is incremented** so it points to the next instruction, and the cycle
   repeats.

> **Checkpoint:** What does it mean to say "the PC points to the next instruction"? *(The PC
> holds the memory address of the instruction that will be fetched next; it is updated during
> execution so that it already names the following instruction when the current one finishes.)*

---

## 7. Section 1.4 — Number Representation and Arithmetic

The most natural way to represent a number is a string of bits — a **binary number**. We
start with integers, then arithmetic, then a brief look at floating point.

### Unsigned integers

Consider an **n-bit vector** `B = b(n-1) ... b1 b0` where each bit is 0 or 1. It represents an
**unsigned** value in the range **0 to 2^n − 1**, using **positional binary notation**:

```
V(B) = b(n-1) × 2^(n-1) + ... + b1 × 2^1 + b0 × 2^0
```

Each bit's weight is a power of two; the rightmost bit is the **low-order** bit (weight 2^0),
the leftmost is the **high-order** bit.

> **Checkpoint:** What is the largest unsigned value an 8-bit vector can hold? *(2^8 − 1 =
> 255.)*

---

## 8. Signed-Number Systems & 2's-Complement

We must represent **positive and negative** numbers. The textbook gives **three systems**;
in all three, the **leftmost bit is 0 for positive and 1 for negative**. Positive values look
identical in every system — only the **negatives differ**.

| System | How a negative is formed | Zero | Extra note |
|--------|--------------------------|------|-----------|
| **Sign-and-magnitude** | Flip only the most significant bit of the positive value. e.g. +5 = 0101, −5 = 1101. | Two zeros (+0 and −0) | Most natural to read; worst for arithmetic. |
| **1's-complement** | Complement **every** bit of the positive number. e.g. −3 = complement of 0011 = 1100. Equivalent to subtracting from 2^n − 1. | Two zeros (+0 and −0) | Better than sign-magnitude but carry-out needs correction. |
| **2's-complement** | Subtract the number from 2^n; equivalently, **add 1 to the 1's-complement**. | **Only one** zero | Represents one extra negative value (−8 in 4 bits). Most efficient for add/subtract; used in modern computers. |

### 4-bit reference (Figure 1.3)

| Bit pattern | Sign-and-magnitude | 1's-complement | 2's-complement |
|-------------|--------------------|----------------|----------------|
| 0111 | +7 | +7 | +7 |
| 0000 | +0 | +0 | +0 |
| 1000 | −0 | −7 | **−8** |
| 1001 | −1 | −6 | −7 |
| 1101 | −5 | −2 | −3 |
| 1111 | −7 | −0 | −1 |

### Forming the 2's-complement — the recipe

```
1. Write the 1's-complement (flip every bit).
2. Add 1.
```

Example: 2's-complement of 01101 (which is +13) → flip to 10010 → add 1 → **10011**.

> **Why 2's-complement wins:** it has a single representation for zero and, as the next
> section shows, lets the **same adder hardware** do both addition and subtraction with the
> carry-out simply **ignored** — no correction step like 1's-complement needs.

> **Checkpoint:** In 4-bit 2's-complement, which value is representable that the other two
> systems cannot show? *(−8, because 2's-complement has only one zero and so gains one extra
> negative value.)*

---

## 9. Addition, Subtraction, Sign Extension & Overflow

### Addition of 1-bit numbers (Figure 1.4)

```
0+0 = 0, carry 0
0+1 = 1, carry 0
1+0 = 1, carry 0
1+1 = 0, carry 1   (the 2-bit vector 10 = value 2)
```

Multi-bit addition works like decimal by hand: add bit pairs from the **low-order (right)
end**, propagating a **carry-out** that becomes the **carry-in** of the next pair to the left.

### The 2's-complement add rule and subtract rule

- **ADD:** add the two n-bit representations and **ignore the carry-out** of the most
  significant bit. The result is the correct 2's-complement value **if it lies in the range
  −2^(n-1) through +2^(n-1) − 1**.
- **SUBTRACT X − Y:** form the **2's-complement of Y**, then **add** it to X using the add
  rule.

### Worked example (+7 added to −3)

```
   0 1 1 1      (+7)
 + 1 1 0 1      (-3)
 ---------
 1 0 1 0 0
 ^
 carry-out ignored  ->  0100 = +4   correct
```

The ignored carry-out is a natural consequence of **mod N arithmetic**: moving around the
mod-16 circle (Figure 1.5), the step after 1111 wraps back to 0000 instead of 10000.

### Why not 1's-complement?

In 1's-complement, the carry-out **cannot** simply be ignored: if `c(n) = 0` the result is
correct, but if `c(n) = 1` you must **add 1** to fix it. That extra correction is why
1's-complement is less convenient than 2's-complement.

### Sign extension

To store a value in **more bits** than it currently uses:

- **Positive number** → add **0s** on the left.
- **Negative 2's-complement number** → **replicate the sign bit (1)** to the left as many
  times as needed. This is called **sign extension** and keeps the value unchanged (compare
  the mod-16, mod-32, mod-64 circles — the negatives match with 1s added on the left).

### Overflow

**Arithmetic overflow** happens when the true result falls **outside** the representable
range (−8 through +7 for 4 bits).

- For **unsigned** addition, a carry-out of 1 from the MSB signals overflow.
- For **signed** 2's-complement, the **carry-out is NOT a reliable indicator**. Example:
  +7 + +4 = 1011 = −5 (carry-out 0, still wrong); −4 + −6 = 0110 = +6 (carry-out 1, wrong).

**Signed overflow detection rule:** overflow can occur **only when both summands have the
same sign**, and it has occurred when the **sign of the sum differs** from the sign of the
summands. Adding numbers of different signs can **never** overflow.

### Worked conversions (Example 1.3)

5-bit 2's-complement:

- **7 and 13:** 7 = 00111, 13 = 01101. **Add:** 00111 + 01101 = 10100 (negative) →
  **overflow** (two positives gave a negative). **Subtract 7 − 13:** 2's-complement of
  01101 = 10011; 00111 + 10011 = 11010 = **−6**, correct.
- **−12 and 9:** −12 = 10100, 9 = 01001. **Add:** 10100 + 01001 = 11101 = **−3**, correct.
  **Subtract −12 − 9:** 2's-complement of 01001 = 10111; 10100 + 10111 = 01011 (positive) →
  **overflow**.

> **Checkpoint:** You add two 4-bit 2's-complement numbers, both negative, and the result's
> sign bit is 0. Did overflow occur? *(Yes — same-sign operands produced a result whose sign
> differs from the summands.)*

---

## 10. Floating-Point Numbers

Integers put the binary point at the far right (after b0). A 32-bit 2's-complement integer
covers **−2^31 to +2^31 − 1** (a bit under ±10^10). Reinterpreting the same 32 bits as a
**fraction** (binary point just right of the sign bit) covers roughly −1 to +1 with a
smallest magnitude near 10^−10. Neither **fixed-point** range suits much scientific work.

The fix is to let the **binary point float** — adjusted automatically as computation
proceeds. A **floating-point number** is represented by:

- a **sign** for the number,
- some **significant bits**,
- a **signed scale-factor exponent** for an **implied base of 2** (the base is fixed, so it
  need not be stored).

The **IEEE standard** 32-bit format uses a **sign bit, 23 significant bits, and 8 exponent
bits**, giving a decimal range of roughly **±10^−38 to ±10^38** — adequate for most science
and engineering. A **64-bit** IEEE format adds more significant and exponent bits for higher
precision and larger range. (Full floating-point detail is in Chapter 9.)

> **Checkpoint:** Why does floating point need the base stored only implicitly? *(The base is
> fixed at 2 for binary floating point, so it is always the same and need not appear in the
> representation; only the sign, significant bits, and signed exponent are stored.)*

---

## 11. Section 1.5 — Character Representation (ASCII)

The most common character encoding is **ASCII** (American Standard Code for Information
Interchange). Facts to memorize:

- Alphanumeric characters, operators, punctuation, and control characters use **7-bit codes**.
- It is convenient to store a character in an **8-bit byte**: the code fills the **low-order 7
  bits**, and the **high-order bit is usually 0**.
- Codes for alphabetic and numeric characters are in **increasing sequential order** when read
  as unsigned binary — which makes **sorting** easy.
- The **low-order 4 bits** of the ASCII codes for digits 0–9 are the first ten binary values;
  this 4-bit encoding is the **binary-coded decimal (BCD)** code.

A few landmark codes from Table 1.1 (bit positions 6543210):

| Character | Meaning |
|-----------|---------|
| **NUL** | Null / idle (0000000) |
| **SPACE** | Space (0100000) |
| **CR** | Carriage return |
| **LF** | Line feed |
| **DEL** | Delete / idle |

Worked reading (Problem 1.9 style): the byte **01010011** as an unsigned binary number is
**83**; as a 7-bit ASCII code (low 7 bits = 1010011) it is the letter **S**.

> **Checkpoint:** Why does ASCII's ordering make sorting easier? *(Because letters and digits
> have codes that increase in sequence, comparing them as unsigned binary numbers already
> puts them in alphabetical/numeric order.)*

---

## 12. Section 1.6 — Performance

The most important performance measure is **how quickly a computer executes programs**.
Execution speed is affected by: the **instruction set design**, the **hardware**, the
**software** (including the operating system), the **implementation technology**, and the
**compiler** that translates high-level language into machine language.

### 12.1 Technology

**Very Large Scale Integration (VLSI)** fabricates a processor's circuits on a single chip.
The key lever is **transistor size**: smaller transistors **switch faster**. Decades of
shrinking transistors brought two advantages:

1. Instructions execute **faster**.
2. **More transistors per chip** → more logic functionality and more memory capacity.

### 12.2 Parallelism — doing operations at the same time

| Level | Mechanism | Idea |
|-------|-----------|------|
| **Instruction-level** | **Pipelining** | Overlap the steps of successive instructions — e.g. fetch the next instruction while the ALU works on the current one. Reduces total execution time. (Chapter 6.) |
| **Multicore** | **Cores on one chip** | Several processing units (**cores**) on a single chip. Dual-core, quad-core, octo-core. The whole chip is the **processor**. |
| **Multiprocessor** | **Shared-memory** | Many processors (each possibly multicore) with access to all memory — a **shared-memory multiprocessor**. Higher performance at higher cost and complexity. |
| **Multicomputer** | **Message-passing** | Interconnected complete computers, each with its **own** memory, sharing data by **exchanging messages** over a network — **message-passing multicomputers**. |

### Quantifying cache benefit (Example 1.2)

Program of 500 instructions with a 100-instruction loop run 25 times; main memory access =
10 units, cache access = 1 unit; cache starts empty and is big enough to hold the loop.

```
Without cache:  T       = 400 × 10 + 100 × 10 × 25 = 29,000
With cache:     Tcache  = 500 × 10 + 100 × 1  × 24 =  7,400
Speedup:        T / Tcache = 29,000 / 7,400 = 3.92
```

The loop pays the slow main-memory price **once** (first pass, counted in the 500 × 10) and
the fast cache price for the remaining **24** passes — hence the near-4x speedup.

> **Checkpoint:** Give the single technology factor that most directly makes instructions run
> faster. *(Smaller transistors, which switch between 0 and 1 states more quickly — the core
> benefit of advancing VLSI fabrication.)*

---

## 13. Section 1.7 — Historical Perspective

Electronic digital computers have been developed since the **1940s**, after centuries of
mechanical calculating devices (gear wheels, levers, pulleys) and **punched-card** control.
**Electromechanical relays** did logic in the late 1930s / early 1940s. During **World War
II**, the first electronic computer was built at the **University of Pennsylvania** using
**vacuum tube** technology. Development is split into **four generations**.

| Generation | Years | Defining technology | Milestones |
|------------|-------|---------------------|-----------|
| **First** | 1945–1955 | **Vacuum tubes** | **Stored-program** concept (program + data in the same memory). Assembly language. 100–1000x faster than mechanical. Mercury delay-line memory, then magnetic core and magnetic tape. |
| **Second** | 1955–1965 | **Transistors** (invented at AT&T Bell Labs, late 1940s) | Magnetic core memory, magnetic drum and disk storage. First high-level languages (**Fortran**) and compilers. IBM rises. |
| **Third** | 1965–1975 | **Integrated circuits** (TI, Fairchild) | IC memories replace magnetic core. Microprogramming, parallelism, pipelining. Operating systems share the machine among programs. **Cache** (makes memory seem faster) and **virtual memory** (makes it seem larger). IBM System 360, DEC PDP minicomputers. |
| **Fourth** | 1975–present | **VLSI** | A whole processor on one chip = a **microprocessor**. Intel, Motorola, TI, AMD, etc. Multiple cores + cache on one chip. **FPGAs** (Field Programmable Gate Arrays) from Altera, Xilinx for custom embedded designs. Embedded systems, notebooks, mobile phones, networked PCs, cloud. |

Two concepts worth highlighting from the third generation because they recur throughout the
book:

- **Cache memory** — makes the main memory *appear faster* than it really is.
- **Virtual memory** — makes the main memory *appear larger* than it really is.

> **Checkpoint:** What single idea introduced in the first generation still defines computers
> today? *(The stored-program concept — programs and their data share the same memory, making
> it easy to change or load programs.)*

---

## 14. Instruction & Concept Reference Card

### The three canonical instructions (Section 1.3)

| Instruction | What it does | Preserved | Overwritten |
|-------------|--------------|-----------|-------------|
| `Load R2, LOC` | Read memory LOC into register R2 | LOC | R2 |
| `Add R4, R2, R3` | R4 = R2 + R3 | R2, R3 | R4 |
| `Store R4, LOC` | Copy register R4 into memory LOC | R4 | LOC |

### Number-system cheat sheet

| Topic | Rule |
|-------|------|
| Unsigned value | `V = sum of b(i) × 2^i` ; range 0 to 2^n − 1 |
| Sign bit | 0 = positive, 1 = negative (all three systems) |
| 1's-complement of X | flip every bit (= subtract from 2^n − 1) |
| 2's-complement of X | 1's-complement then add 1 (= subtract from 2^n) |
| 2's-comp range (n bits) | −2^(n-1) to +2^(n-1) − 1 |
| ADD rule | add representations, ignore MSB carry-out |
| SUBTRACT X − Y | add X and the 2's-complement of Y |
| Sign extension | positives pad with 0; negatives replicate the sign bit 1 |
| Signed overflow | only if both summands same sign AND sum's sign differs |

### Key registers (Figure 1.2)

| Register | Role |
|----------|------|
| **PC** | Address of the next instruction |
| **IR** | The instruction currently executing |
| **R0..Rn-1** | General-purpose operand registers |

---

## 15. Glossary of Every Term & Acronym

**Structure & units**
- **Computer organization** — function and design of the units that store and process info.
- **Computer architecture** — the instruction-set spec plus hardware functional behavior.
- **Processor** — the ALU plus the main control circuits.
- **ALU** — Arithmetic and Logic Unit; executes most operations.
- **Control unit** — generates timing signals and coordinates the units.
- **I/O unit** — input and output equipment collectively.
- **Interconnection network** — the means by which units exchange information.
- **Register** — high-speed processor storage element; holds one word.
- **PC** — Program Counter; address of the next instruction.
- **IR** — Instruction Register; holds the instruction being executed.
- **Processor-memory interface** — circuit managing transfers between memory and processor.

**Memory**
- **Primary / main memory** — fast electronic memory holding running programs.
- **Secondary storage** — cheaper, permanent, larger, slower (disks, optical, flash).
- **Word** — a fixed-size group of bits handled together; **word length** = bits per word.
- **Address** — the consecutive number identifying a word location, starting at 0.
- **RAM** — Random-Access Memory; fixed access time regardless of location.
- **Memory access time** — time to access one word (ns to about 100 ns).
- **Cache** — small fast RAM near the processor holding currently-used code and data.

**Numbers**
- **Bit** — binary digit, 0 or 1.
- **Positional binary notation** — each bit weighted by a power of two.
- **Unsigned integer** — non-negative value, range 0 to 2^n − 1.
- **Sign-and-magnitude** — negatives flip only the sign bit.
- **1's-complement** — negatives flip every bit; two zeros; needs carry correction.
- **2's-complement** — 1's-complement plus 1; one zero; used in modern computers.
- **Carry-out / carry-in** — bit propagated between adjacent bit positions.
- **Sign extension** — widening a value by replicating the sign bit (or padding 0s).
- **Arithmetic overflow** — true result outside the representable range.
- **Floating-point number** — sign + significant bits + signed exponent, base 2 implied.
- **IEEE standard** — 32-bit (1 sign, 23 significant, 8 exponent) and 64-bit formats.
- **Fixed-point** — integer or fraction with a fixed binary-point position.

**Characters**
- **ASCII** — 7-bit character code; stored in an 8-bit byte, high bit usually 0.
- **BCD** — Binary-Coded Decimal; the low 4 bits of the ASCII digit codes.
- **CR / LF / NUL / DEL** — carriage return, line feed, null, delete control codes.

**Performance & history**
- **VLSI** — Very Large Scale Integration; many transistors on one chip.
- **Pipelining** — instruction-level parallelism overlapping instruction steps.
- **Core** — one processing unit on a chip; **multicore** = several on one chip.
- **Multiprocessor** — many processors sharing all memory (shared-memory).
- **Multicomputer** — interconnected computers sharing data by message passing.
- **Microprocessor** — a complete processor on a single chip.
- **FPGA** — Field Programmable Gate Array; configurable chip for custom designs.
- **Virtual memory** — makes main memory appear larger than it is.
- **Stored-program concept** — program and data share the same memory.
- **Interrupt / interrupt-service routine** — device service request and its handler.
- **Speedup** — ratio of execution time without an improvement to time with it.

---

## 16. Self-Test Questions

Try these without looking back. Answers in the sections cited.

1. List the four general categories of modern computers and one use for each. *(§2)*
2. Name the five functional units and state which two make up the "processor". *(§3)*
3. What is the difference between primary memory and secondary storage? *(§4.2)*
4. Explain how a cache speeds up a program loop, in your own words. *(§4.2, §12)*
5. Why are registers faster than cache? *(§4.3)*
6. Describe what each of the three instructions `Load`, `Add`, `Store` preserves and
   overwrites. *(§5, §14)*
7. List the steps to execute `Load R2, LOC` starting from the PC. *(§5)*
8. What do the PC and IR each hold? *(§6)*
9. Give the formula for the unsigned value of an n-bit vector. *(§7)*
10. How do you form the 2's-complement of a number, and why does it beat 1's-complement for
    arithmetic? *(§8, §9)*
11. State the add rule and subtract rule for 2's-complement. *(§9)*
12. Give the rule for detecting signed overflow when adding. *(§9)*
13. How is a negative 2's-complement number sign-extended to more bits? *(§9)*
14. What three parts represent a floating-point number, and what range does IEEE 32-bit cover?
    *(§10)*
15. How many bits does ASCII use, how is it stored in a byte, and what is BCD? *(§11)*
16. What single technology factor most directly speeds up instruction execution? *(§12)*
17. Name the defining technology of each of the four generations. *(§13)*

---

*End of study guide. Open this file in any Markdown viewer (VS Code, Obsidian, Typora,
GitHub) to read it with formatting, or export to PDF from there.*
