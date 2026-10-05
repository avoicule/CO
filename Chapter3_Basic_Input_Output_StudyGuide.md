# Chapter 3 — Basic Input/Output

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 95–114 (Sections 3.1 → 3.2.5)

> How to use this guide: read it top to bottom. Each section builds on the previous one.
> Terms in **bold** are the ones you must be able to define. Code blocks are the exact
> instructions from the textbook, explained line-by-line. The "Checkpoint" boxes are
> what you should be able to answer before moving on.

---

## Table of Contents

1. [The Big Picture — Why I/O Exists](#1-the-big-picture)
2. [Section 3.1 — Accessing I/O Devices](#2-section-31--accessing-io-devices)
3. [The Device Interface (Data / Status / Control registers)](#3-the-device-interface)
4. [The Keyboard & Display Register Map](#4-the-keyboard--display-register-map)
5. [Section 3.1.2 — Program-Controlled I/O (Polling)](#5-section-312--program-controlled-io-polling)
6. [Section 3.1.3 — The RISC-Style Program (Figure 3.4)](#6-section-313--the-risc-style-program-figure-34)
7. [Section 3.1.4 — The CISC-Style Program (Figure 3.5)](#7-section-314--the-cisc-style-program-figure-35)
8. [Section 3.2 — Interrupts](#8-section-32--interrupts)
9. [Section 3.2.1 — Enabling & Disabling Interrupts](#9-section-321--enabling--disabling-interrupts)
10. [Section 3.2.2 — Handling Multiple Devices](#10-section-322--handling-multiple-devices)
11. [Section 3.2.3 — Controlling I/O Device Behavior](#11-section-323--controlling-io-device-behavior)
12. [Section 3.2.4 — Processor Control Registers](#12-section-324--processor-control-registers)
13. [Section 3.2.5 — The Interrupt Program (Figure 3.8)](#13-section-325--the-interrupt-program-figure-38)
14. [Instruction Reference Card](#14-instruction-reference-card)
15. [Glossary of Every Flag & Register](#15-glossary-of-every-flag--register)
16. [Self-Test Questions](#16-self-test-questions)

---

## 1. The Big Picture

A computer is useless if it cannot talk to the outside world. **Input/Output (I/O)** is
the machinery that lets the processor exchange data with devices: keyboard, display,
sensors, motors, network cards, etc.

The central problem of this chapter is **speed mismatch**:

| Thing | Typical speed |
|-------|--------------|
| Human typing on a keyboard | a few characters / second |
| Display accepting characters | a few thousand characters / second |
| Processor executing instructions | billions / second |

Because the processor is *vastly* faster than any I/O device, it must have a way to
**synchronize** — to wait for the slow device to be ready. This chapter teaches two
synchronization strategies:

1. **Polling** (Program-Controlled I/O) — the CPU repeatedly asks "are you ready yet?"
2. **Interrupts** — the device taps the CPU on the shoulder when it is ready.

Everything else in the chapter is detail around these two ideas.

> **Checkpoint:** Why can't the processor just send a character to the display the
> instant it wants to? *(Because the display may still be busy with the previous
> character; sending too early loses data.)*

---

## 2. Section 3.1 — Accessing I/O Devices

### The core idea: Memory-Mapped I/O

The processor already knows how to read and write **memory** using addresses (Load/Store
with addressing modes). The textbook's trick is: **make I/O devices look like memory.**

> "each I/O device must appear to the processor as consisting of some addressable
> locations, just like the memory. Some addresses in the address space of the processor
> are assigned to these I/O locations, rather than to the main memory."

Step by step:

1. The CPU has an **address space** — a big range of numbered locations.
2. Normally every address points to a cell of RAM.
3. With **memory-mapped I/O**, a few addresses are *stolen* from RAM and instead wired
   to a hardware device.
4. Those stolen addresses are physically small storage circuits called **flip-flops**,
   grouped into **I/O registers**.

**Analogy (the postman):** RAM is an apartment block with mailboxes 1–900. The keyboard
and display are handed mailboxes 901–910 right next door. The postman (CPU) uses the
*exact same* delivery routine for all of them — but dropping a letter in box 901 sends
it to the keyboard, not to a resident.

### Why this is powerful

Because the device is just "memory", **any instruction that touches memory can touch the
device**. No special I/O instructions needed:

```asm
Load   R2, DATAIN      ; read from an input device register into R2
Store  R2, DATAOUT     ; write R2's contents to an output device register
```

### What is a flip-flop? (supporting concept)

A **flip-flop** is the smallest unit of electronic memory — it stores exactly **one bit**
(a 0 or a 1). It is *bistable*: it holds its value indefinitely while powered.

- 8 flip-flops side by side = an **8-bit register** (holds 1 byte, e.g. one ASCII char).
- 32 flip-flops = a **32-bit register** (holds a full word/address).

So when the textbook says I/O registers are "flip-flops organized in the form of
registers", it just means: tiny banks of 1-bit memory cells living inside the device chip.

> **Checkpoint:** What does "memory-mapped" literally mean? *(Device registers are
> assigned real addresses inside the CPU's normal address space, so Load/Store reach
> them.)*

### The alternative: Port-Mapped I/O (mentioned on p.102)

Some processors (notably Intel x86) instead have a **separate I/O address space** reached
only by special `In` and `Out` instructions. This chapter uses memory-mapped I/O
throughout because "it is used in most computers."

---

## 3. The Device Interface

An I/O device does not connect to the bus directly. It connects through a **device
interface** — a circuit that contains the registers the CPU reads and writes. There are
**three kinds of register** in a typical interface:

| Register type | Purpose |
|---------------|---------|
| **DATA** | Buffers the actual byte being transferred (the character). |
| **STATUS** | Reports the current state of the device (ready? data waiting?). |
| **CONTROL** | Lets software configure the device (e.g. enable interrupts). |

```
         Interconnection network (the bus)
   ┌───────────┼───────────────┼───────────┐
   │           │               │           │
 Processor   DATA / STATUS / CONTROL  (Keyboard interface)
             DATA / STATUS / CONTROL  (Display interface)
```

All three register types are accessed **as if they were memory locations** — the whole
point of memory-mapped I/O.

---

## 4. The Keyboard & Display Register Map

This is **Figure 3.3** — memorize it, every later program uses these exact addresses.

### Keyboard interface

| Address | Register | Important bits |
|---------|----------|----------------|
| `0x4000` | `KBD_DATA`   | 8-bit ASCII code of the pressed key |
| `0x4004` | `KBD_STATUS` | **KIN** (bit 1), **KIRQ** (bit 0) |
| `0x4008` | `KBD_CONT`   | **KIE** (bit 1) |

### Display interface

| Address | Register | Important bits |
|---------|----------|----------------|
| `0x4010` | `DISP_DATA`   | 8-bit character to display |
| `0x4014` | `DISP_STATUS` | **DOUT** (bit 2), **DIRQ** (bit 1) |
| `0x4018` | `DISP_CONT`   | **DIE** (bit 2) |

### What each bit means

- **KIN** (Keyboard INput, bit 1 of KBD_STATUS) — set to **1 by hardware** when a new
  character is sitting in `KBD_DATA`. **Cleared to 0 automatically** when the CPU reads
  `KBD_DATA`.
- **KIRQ** (Keyboard Interrupt ReQuest, bit 0 of KBD_STATUS) — set to **1 by hardware**
  when the keyboard has raised an interrupt that has not been serviced yet.
- **KIE** (Keyboard Interrupt Enable, bit 1 of KBD_CONT) — set to **1 by software** to
  allow the keyboard to raise interrupts; 0 to forbid it.
- **DOUT** (Display OUTput ready, bit 2 of DISP_STATUS) — **1** means the display is free
  to accept a new character. Writing to `DISP_DATA` clears it to 0.
- **DIE** (Display Interrupt Enable, bit 2 of DISP_CONT) — software switch for display
  interrupts.

> **Why the addresses are +4 apart:** In a 32-bit machine, words are 4 bytes. Putting
> DATA at `0x4000`, STATUS at `0x4004`, CONTROL at `0x4008` keeps everything
> **word-aligned** (addresses are multiples of 4), which is standard practice.

> **Important address-size note:** `KBD_DATA` holds only **1 byte** (an ASCII char),
> which is why we use `LoadByte`, not `Load`. A full `Load R5, KBD_DATA` would read 4
> bytes (`0x4000`–`0x4003`) and accidentally pull in adjacent registers.

---

## 5. Section 3.1.2 — Program-Controlled I/O (Polling)

**Program-controlled I/O** means the CPU does *everything* itself, in a loop, by hand.
Reading a key with polling is a three-step dance:

```
READWAIT   Read the KIN flag
           Branch to READWAIT if KIN = 0     ; keep looping while no key
           Transfer data from KBD_DATA to R5 ; got one — read it
```

What happens physically:

1. User presses a key → keyboard circuit writes the ASCII code into `KBD_DATA` **and**
   sets `KIN = 1`.
2. The CPU is spinning in the loop, reading `KBD_STATUS` over and over.
3. While `KIN = 0`, it stays in the loop (wasting cycles).
4. The instant `KIN = 1`, it exits and reads `KBD_DATA` into `R5`.
5. Reading `KBD_DATA` makes the hardware **auto-clear KIN back to 0**, ready for the next key.

Output (writing to the display) is the mirror image, using **DOUT**:

```
WRITEWAIT  Read the DOUT flag
           Branch to WRITEWAIT if DOUT = 0   ; wait until display free
           Transfer data from R5 to DISP_DATA
```

Writing to `DISP_DATA` clears `DOUT` to 0 (display is now busy again).

> **Initial state assumption:** `KIN` starts at 0 (no key yet) and `DOUT` starts at 1
> (display is free). The device control circuits set this up at power-on.

> **Checkpoint:** What is the single biggest downside of polling? *(The CPU wastes almost
> all its time spinning in the wait loop doing no useful work.)*

---

## 6. Section 3.1.3 — The RISC-Style Program (Figure 3.4)

**Task:** read a whole line of typed characters, store each in memory, echo each to the
display, and stop when the user presses **Carriage Return (CR = Enter)**.

**Key RISC rule — the Load/Store philosophy:** a RISC processor **cannot** test, add, or
compare a value that lives in memory/I/O. It must first `Load` it into a register, operate
there, then `Store` it back. This is why the program is long.

```asm
          Move             R2, #LOC          ; R2 = address of memory buffer (pointer)
          MoveByte         R3, #CR           ; R3 = ASCII code for Carriage Return

READ:     LoadByte         R4, KBD_STATUS    ; copy keyboard status byte into R4
          And              R4, R4, #2        ; isolate bit 1 (KIN) using mask 00000010
          Branch_if_[R4]=0 READ              ; if KIN was 0 → loop, keep waiting
          LoadByte         R5, KBD_DATA      ; key pressed → read char (auto-clears KIN)

          StoreByte        R5, (R2)          ; store char into memory at address in R2
          Add              R2, R2, #1        ; advance pointer to next byte

ECHO:     LoadByte         R4, DISP_STATUS   ; copy display status into R4
          And              R4, R4, #4        ; isolate bit 2 (DOUT) using mask 00000100
          Branch_if_[R4]=0 ECHO              ; if display busy → loop
          StoreByte        R5, DISP_DATA     ; display free → send char (clears DOUT)

          Branch_if_[R5]=[R3] READ           ; if char == CR? (see note) loop for next
```

### Line-by-line meaning

- **`Move R2, #LOC`** — load the *start address* of the RAM buffer into R2. R2 is our
  **pointer**: it remembers where the next character goes.
- **`MoveByte R3, #CR`** — keep the Enter-key code handy so we can detect end of line.
- **`LoadByte R4, KBD_STATUS`** — we can't test the status in place (RISC), so copy it.
- **`And R4, R4, #2`** — this is a **bit mask**. `#2` in binary is `00000010`. ANDing keeps
  only bit 1 (KIN) and zeroes everything else:
  - KIN = 0 → R4 becomes `0`
  - KIN = 1 → R4 becomes `2` (non-zero)
- **`Branch_if_[R4]=0 READ`** — if R4 is 0 (no key), jump back and poll again.
- **`LoadByte R5, KBD_DATA`** — read the character; **side effect: hardware clears KIN.**
- **`StoreByte R5, (R2)`** — write the character into memory at the address held in R2.
- **`Add R2, R2, #1`** — move the pointer forward by one byte for the next character.
- The **ECHO** block repeats the same pattern for the display, masking with `#4`
  (`00000100`) to test **DOUT** (bit 2).
- **`StoreByte R5, DISP_DATA`** — character appears on screen; **side effect: DOUT → 0.**
- **Final branch** — compare the character we just handled against CR; if it isn't CR,
  loop back to read the next one. (The textbook's intent: keep going until Enter.)

> **Deep dive — `And R4, R4, #2` bit by bit:**
> ```
>   R4 (status) :  b7 b6 b5 b4 b3 b2 b1 b0
>   mask #2     :   0  0  0  0  0  0  1  0
>   result      :   0  0  0  0  0  0 b1  0   ← only KIN survives
> ```

---

## 7. Section 3.1.4 — The CISC-Style Program (Figure 3.5)

**Same task, CISC architecture.** The point of this section is to show that CISC does
*more work per instruction*, so the program is shorter.

Three CISC superpowers RISC does not have:

1. **`TestBit destination, #k`** — test one bit **directly in a memory location**,
   without loading it. It sets the **Z (Zero) flag**:
   - if bit *k* = 0 → **Z = 1**
   - if bit *k* = 1 → **Z = 0**
2. **Direct memory-to-memory move** — `MoveByte (R2), KBD_DATA` copies straight from the
   keyboard register into RAM, no intermediate CPU register.
3. **Autoincrement addressing `(R2)+`** — use the pointer, *then* increment it, in one
   instruction (replaces a separate `Add`).

```asm
          Move        R2, #LOC            ; pointer setup (same as RISC)

READ:     TestBit     KBD_STATUS, #1      ; test KIN directly in memory → sets Z
          Branch=0    READ                ; Branch when Z=1 (bit was 0) → keep waiting
          MoveByte    (R2), KBD_DATA      ; copy char straight into RAM (clears KIN)

ECHO:     TestBit     DISP_STATUS, #2     ; test DOUT directly → sets Z
          Branch=0    ECHO                ; wait until display ready
          MoveByte    DISP_DATA, (R2)     ; copy char from RAM to display (clears DOUT)

          CompareByte (R2)+, #CR          ; compare char to CR, THEN increment pointer
          Branch=0    READ                ; if not CR, loop for next character
```

### Why `TestBit KBD_STATUS, #1` matters

In RISC, checking the KIN flag took **3** instructions (`LoadByte`, `And`, `Branch`). In
CISC it takes **2** (`TestBit`, `Branch=0`) because the test happens *inside memory* and
leaves all registers untouched. It only updates the Z condition flag.

### RISC vs CISC side-by-side

| Task | RISC (Fig 3.4) | CISC (Fig 3.5) |
|------|----------------|----------------|
| Poll keyboard | LoadByte + And + Branch (3) | TestBit + Branch=0 (2) |
| Read & store | LoadByte + StoreByte + Add (3) | MoveByte (R2), KBD_DATA (1) |
| Store + advance pointer | StoreByte + Add (2) | autoincrement `(R2)+` (0 extra) |

**Takeaway:** CISC = fewer, more powerful instructions (shorter code) but each instruction
needs more internal micro-operations. RISC = many simple instructions.

> **Checkpoint:** What flag does `TestBit` set, and to what, when the tested bit is 0?
> *(It sets Z = 1.)*

---

## 8. Section 3.2 — Interrupts

Polling wastes the CPU. **Interrupts** fix this: instead of the CPU asking "ready?"
forever, the **device signals the CPU** the moment it becomes ready. The CPU does useful
work in the meantime.

### The subroutine analogy (and where it breaks)

An interrupt resembles a subroutine call: control jumps away, then returns. **But** a
subroutine is called *on purpose* by the program and expects certain registers to change.
An **interrupt can strike at any random moment** and has nothing to do with the running
program. Therefore the CPU must **save state** before servicing it, and **restore state**
afterwards, so the interrupted program never notices.

### The Interrupt-Service Routine (ISR)

The **ISR** (a.k.a. interrupt handler) is the code that runs in response to an interrupt.
Crucial facts:

- The ISR is **ordinary software** — a sequence of normal instructions (`LoadByte`,
  `StoreByte`, `Add`, …) ending in a special **`Return-from-interrupt`** instruction.
- It is **written by a developer / OS / device driver**, **not** built into the CPU.
- The **hardware** only provides the *mechanism* to jump to the ISR's address; the
  *content* at that address is the developer's code.

### What the hardware does automatically vs. what the ISR does

| Phase | Hardware (CPU) | Software (ISR) |
|-------|----------------|----------------|
| Trigger | Device asserts interrupt line | (earlier) set KIE=1 to allow it |
| Entry | Save **PC** and **PS**, disable interrupts, jump to ISR | — |
| Body | — | Save any registers it will use; read data; clear flags |
| Exit | Restore PC & PS on `Return-from-interrupt` | Restore its saved registers, then return |

### Interrupt latency and saving registers

> "Typically, the processor saves only the contents of the program counter and the
> processor status register."

The CPU saves **only the minimum** automatically:

- **PC (Program Counter)** — so it knows which instruction to resume at.
- **PS (Processor Status)** — so condition flags (Z, N, C, V) and the IE bit survive.

Saving *all* registers in hardware would be slow — the delay between the request and the
start of the ISR is called **interrupt latency**, and we want it short. So the ISR itself
is responsible for pushing/popping only the registers *it* touches.

**Three architectural strategies** for context saving:

1. **Minimal saving** (used in our examples) — hardware saves PC+PS; ISR saves what it
   uses. Fast, low overhead.
2. **Universal saving** — hardware auto-saves all registers R0–R31. Simple to program but
   high latency.
3. **Shadow registers** — the CPU has a *duplicate bank* of registers; on interrupt it
   instantly switches banks instead of copying to RAM. Near-zero overhead, but costs
   silicon area. (The chip designer decides whether these exist.)

> **Checkpoint:** Why does the CPU disable interrupts when it enters an ISR? *(So the
> still-active interrupt request from the device doesn't immediately re-trigger and cause
> an infinite loop.)*

---

## 9. Section 3.2.1 — Enabling & Disabling Interrupts

The programmer needs full control over *when* interrupts are allowed. Control exists at
**two ends**:

1. **Processor end** — the **IE** (Interrupt Enable) bit in the **PS** register.
   - IE = 1 → CPU accepts interrupt requests.
   - IE = 0 → CPU ignores (masks) all requests.
2. **Device end** — an interrupt-enable bit in the device's **control register** (e.g.
   **KIE** for the keyboard). The device may only raise requests when this is 1.

### The automatic entry sequence (single device)

When an enabled interrupt arrives:

1. Device raises the interrupt request.
2. CPU finishes the current instruction, saves **PC** and **PS**.
3. CPU **clears IE to 0** (disables further interrupts).
4. ISR runs; while servicing, the device is told its request was recognized, so it drops
   the request signal.
5. `Return-from-interrupt` restores PC and PS (which **sets IE back to 1**), and the
   interrupted program resumes.

### Why is KIE "always 1" in normal operation?

KIE is an **arming switch**. Once the driver sets KIE = 1, it stays 1 so the keyboard
keeps generating an interrupt for *every* keypress. Software deliberately sets it to 0
only when it wants to **ignore** the keyboard — e.g. after Enter is pressed and the full
line is being processed, or during a time-critical section.

---

## 10. Section 3.2.2 — Handling Multiple Devices

When many devices can interrupt, four questions arise:

1. **Which device requested the interrupt?**
2. **Where is that device's ISR?**
3. **Can one interrupt interrupt another?** (nesting)
4. **What if two arrive at once?** (simultaneous requests)

### 1 & 2 — Identifying the device

**Polling the IRQ bits:** the ISR checks each device's **IRQ** status bit; the first one
set to 1 is serviced. Simple, but slow (you interrogate devices that didn't ask).

**Vectored interrupts (the fast way):** the device **identifies itself** directly, either
via its own dedicated interrupt line or by sending a **vector code** over the bus. The CPU
uses that code to look up the ISR address in the **interrupt-vector table (IVT)**:

- The IVT is a reserved area of memory (usually at the lowest addresses, e.g. `0x0000`).
- Each entry is a 32-bit (4-byte) **interrupt vector** = the start address of one ISR.
- Lookup formula:
  ```
  ISR address = IVT base + (vector number × 4)
  ```
- The CPU loads that address straight into the PC and starts executing the ISR —
  **no polling needed.**

> **When does the device identify itself?** At **runtime, when it raises the request** —
> not at initialization. At boot, software merely *fills in* the IVT with ISR addresses.
> After initialization the IVT already holds every ISR's address; the device just supplies
> its index number when it actually needs service.

**Analogy:** Polling = doctor knocks on all 30 patient doors asking "did you call?".
Vectored = the wall panel shows "Room 12", doctor checks the directory and walks straight
there.

### 3 — Nesting & priority

Normally interrupts stay disabled during an ISR, so one ISR finishes before the next
starts. But some devices (e.g. a **real-time clock**) can't tolerate the delay. Solution:
assign each device a **priority level**. A higher-priority device may interrupt the ISR of
a lower-priority one. The processor's current priority lives in the PS register; it accepts
only requests **above** its own level.

> If nesting is allowed, each ISR must **save PC and PS onto the stack** *before*
> re-enabling interrupts (because the single IPS backup register would otherwise be
> overwritten — see §12).

### 4 — Simultaneous requests

Something must break the tie. With polling, priority = the order you poll. With vectored
interrupts, hardware **arbitration circuits** ensure only one device sends its vector at a
time (covered in Chapter 7).

---

## 11. Section 3.2.3 — Controlling I/O Device Behavior

Each device interface has a **control register** holding configuration bits. The most
important is the **interrupt-enable bit** (KIE for keyboard, DIE for display).

The keyboard interrupt logic:

```
  interrupt raised  ⇔  KIE = 1  AND  KIN = 1
  when it fires, hardware sets KIRQ = 1
```

So:
- **KIE** = software's permission switch (set it to arm the keyboard).
- **KIN** = hardware's "a key is waiting" flag.
- **KIRQ** = hardware's "I have an unserviced interrupt out" flag.

The display mirrors this with **DIE**, **DOUT**, **DIRQ**.

> Note the deliberate bit placement: KIN & KIE are both bit **1**; DOUT & DIE are both bit
> **2**. The authors chose this to make the example masks (`#2`, `#4`) clean.

---

## 12. Section 3.2.4 — Processor Control Registers

This is **Figure 3.7** — four special 32-bit registers *inside the processor* that manage
interrupts. They are **not** general-purpose registers and can only be touched by the
special **`MoveControl`** instruction.

| Register | Role | Key bits |
|----------|------|----------|
| **PS** (Processor Status) | current CPU state & flags | **IE** (bit 0) = global interrupt switch |
| **IPS** (Saved PS) | hardware backup of PS during an interrupt | mirrors PS |
| **IENABLE** | per-device enable mask | bit1=KBD, bit2=DISP, bit3=TIM, … |
| **IPENDING** | per-device "request active" flags | hardware sets the bit of any requesting device |

### How they work together

- **PS.IE** is the **master switch**. No interrupt is accepted unless IE = 1.
- **IPS**: when an interrupt is accepted, hardware **copies PS → IPS** automatically, then
  clears IE. On `Return-from-interrupt`, hardware copies **IPS → PS** to restore. Because
  there is only **one** IPS, nested interrupts must save it on the stack.
- **IENABLE** is a 32-bit mask: bit = 1 means "accept interrupts from the device wired to
  that bit." Up to 32 devices.
- **IPENDING** is read by software to see *who* is currently requesting, so it can pick the
  highest priority when several fire at once.

### The two-gate rule for an interrupt to fire

```
  BOTH must be true:
    1. PS.IE          = 1   (global switch on)
    2. IENABLE[device] = 1   (this device's switch on)
```

### Accessing control registers — `MoveControl`

Normal `Load`/`Store` can only name the 32 general-purpose registers (5-bit field), so
control registers need a dedicated instruction:

```asm
MoveControl R2, PS         ; read PS into general register R2
MoveControl IENABLE, R3    ; write R3's value into IENABLE
```

### How many control registers / how big?

- The **textbook model** shows **4** (PS, IPS, IENABLE, IPENDING).
- **Real CPUs** have dozens-to-hundreds (CR0–CR15, MSRs, etc.).
- In a **32-bit** CPU each is **32 bits = 4 bytes**; in a **64-bit** CPU, 8 bytes.

### Typical PS bit layout (RISC-style reference)

| Bit(s) | Symbol | Meaning |
|--------|--------|---------|
| 0 | **IE** | Interrupt Enable (master switch) |
| 1 | UM/MODE | User vs Supervisor mode |
| 2–3 | IPL | Interrupt Priority Level |
| 4–27 | — | reserved |
| 28 | **V** | Overflow flag |
| 29 | **C** | Carry flag |
| 30 | **Z** | Zero flag |
| 31 | **N** | Negative/Sign flag |

(Lower bits = control; upper bits = ALU condition codes set automatically by arithmetic.)

---

## 13. Section 3.2.5 — The Interrupt Program (Figure 3.8)

**Task (Example 3.2):** read a line from the keyboard using **interrupts**, but echo to
the display using **polling**. Stop at Carriage Return.

### Part A — The Interrupt-Service Routine (starts at ILOC)

```asm
ILOC:   Subtract         SP, SP, #8        ; (1) make room on stack for 2 words
        Store            R2, 4(SP)         ;     save caller's R2
        Store            R3, (SP)          ;     save caller's R3

        Load             R2, PNTR          ; (2) R2 = where to store next char
        LoadByte         R3, KBD_DATA      ;     read char (clears KIN & KIRQ in hw)
        StoreByte        R3, (R2)          ;     write char into buffer
        Add              R2, R2, #1        ;     advance pointer
        Store            R2, PNTR          ;     save updated pointer back to memory

ECHO:   LoadByte         R2, DISP_STATUS   ; (3) poll display (DOUT = bit 2)
        And              R2, R2, #4
        Branch_if_[R2]=0 ECHO              ;     wait until display free
        StoreByte        R3, DISP_DATA     ;     echo the character

        Move             R2, #CR           ; (4) load CR code
        Branch_if_[R3]=[R2] RTRN           ;     if char != CR → just return
        Move             R2, #1
        Store            R2, EOL           ;     char WAS CR → set End-Of-Line flag
        Clear            R2                ;     R2 = 0
        StoreByte        R2, KBD_CONT      ;     write 0 → KIE=0, disable kbd interrupts

RTRN:   Load             R3, (SP)          ; (5) restore saved registers
        Load             R2, 4(SP)
        Add              SP, SP, #8        ;     pop the stack frame
        Return-from-interrupt              ;     restore PC & PS, re-enable interrupts
```

#### Step-by-step

**(1) Save registers.** The hardware already saved PC & PS, but the ISR will clobber R2
and R3, so it pushes them onto the stack. `Subtract SP, SP, #8` reserves 8 bytes (two
4-byte words). The stack **grows downward**, so after subtracting:

```
  high mem                        (why 4(SP) and (SP)?)
    …                             SP+4  → R2 lives here  →  Store R2, 4(SP)
  [ R2 slot ]   ← SP + 4          SP+0  → R3 lives here  →  Store R3, (SP)
  [ R3 slot ]   ← SP (new top)
  low mem
```
Offsets must simply **match** between save and restore — that's why we restore with
`Load R3,(SP)` and `Load R2,4(SP)`.

**(2) Read & store the character.** `Load R2, PNTR` fetches the saved buffer pointer from
memory. `LoadByte R3, KBD_DATA` reads the key — **this read clears KIN and KIRQ in
hardware**, which drops the interrupt. Store it, bump the pointer, write the pointer back.

**(3) Echo via polling.** Even inside an interrupt-driven routine, the display here is
handled by polling: mask DOUT (`#4` = `00000100`, bit 2) and spin until it's free, then
`StoreByte R3, DISP_DATA`.

**(4) End-of-line check.** Compare the character to CR. If it's **not** CR, branch to RTRN
and return — interrupts stay enabled for the next keypress. If it **is** CR: set the `EOL`
memory flag to 1 (signals the Main program the line is done), then `Clear R2` and
`StoreByte R2, KBD_CONT` to write 0 → **KIE = 0**, disabling keyboard interrupts because no
more input is expected.

**(5) Restore & return.** Pop R3 and R2 back, release the stack frame, and
`Return-from-interrupt` — hardware restores PC & PS (which re-enables IE) and resumes Main.

> **`Clear R2`** sets every bit of R2 to 0. Here it is used to write 0 into KBD_CONT,
> clearing the KIE bit.

### Part B — The Main program (initialization, starts at START)

```asm
START:  Move        R2, #LINE
        Store       R2, PNTR          ; init buffer pointer to start of LINE

        Clear       R2
        Store       R2, EOL           ; EOL = 0  (line not finished yet)

        Move        R2, #2
        StoreByte   R2, KBD_CONT      ; write 2 → KIE = 1 (arm keyboard interrupts)

        MoveControl R2, IENABLE       ; read IENABLE
        Or          R2, R2, #2        ; set bit 1 (keyboard) without touching others
        MoveControl IENABLE, R2       ; write it back → CPU accepts kbd interrupts

        MoveControl R2, PS            ; read PS
        Or          R2, R2, #1        ; set bit 0 (IE) → master switch ON
        MoveControl PS, R2
        next instruction              ; Main now does other work; ISR fires on keypress
```

#### Step-by-step

1. **Pointer setup** — store the buffer start address `#LINE` into memory variable `PNTR`
   so the ISR knows where to put characters.
2. **Clear EOL** — mark the line as not-yet-complete.
3. **Arm the device** — `Move R2,#2` then `StoreByte R2, KBD_CONT` sets **KIE = 1**
   (bit 1). The keyboard may now raise interrupts.
4. **Enable in the processor** — read-modify-write `IENABLE` with `Or R2,R2,#2` to set the
   keyboard's bit **without disturbing other device bits**.
5. **Global enable** — read-modify-write `PS` with `Or R2,R2,#1` to set **IE = 1**. From
   now on, every keypress interrupts Main and runs the ISR.

#### Why `Or`, not `Move`?

`Or R2, R2, #1` forces **only bit 0** to 1 and leaves every other bit of PS untouched. A
plain `Move R2, #1` would **wipe out** all the other status flags. OR-with-a-mask is the
standard "set this bit, preserve the rest" idiom:

```
  rule:  x OR 0 = x (unchanged)      x OR 1 = 1 (forced on)

  PS      : 1000 0000 … 0001 0000
  #1 mask : 0000 0000 … 0000 0001
  result  : 1000 0000 … 0001 0001   ← only bit 0 turned on
```

The matching idiom for *clearing* a bit is `And` with a mask; for *testing* a bit, `And`
(RISC) or `TestBit` (CISC).

> **Checkpoint:** Trace the two gates that must be open for a keypress to actually
> interrupt the CPU in this program. *(KIE=1 set by `StoreByte R2,KBD_CONT`; the keyboard
> bit in IENABLE set by the `Or #2`; AND the global IE in PS set by the `Or #1`.)*

---

## 14. Instruction Reference Card

| Instruction | What it does |
|-------------|--------------|
| `Load R, addr` | Read a **32-bit word** from memory into register R |
| `LoadByte R, addr` | Read a **single byte** (8 bits) into the low 8 bits of R |
| `Store R, addr` | Write a 32-bit word from R to memory |
| `StoreByte R, addr` | Write the low byte of R to memory |
| `Move R, #val` | Put an immediate value (or address) into R |
| `MoveByte dst, src` | (CISC) copy one byte, memory-to-memory allowed |
| `Add R, R, #k` | R = R + k (also used to advance pointers) |
| `Subtract SP, SP, #k` | Grow the stack by k bytes (stack grows down) |
| `And R, R, #mask` | Bitwise AND — used to **isolate/test** specific bits |
| `Or R, R, #mask` | Bitwise OR — used to **set** specific bits, preserving others |
| `Clear R` | Set R to 0 |
| `TestBit dst, #k` | (CISC) test bit k in memory, set Z flag (Z=1 if bit=0) |
| `Compare dst, src` | Subtract to set flags; operands unchanged |
| `CompareByte (R)+, #v` | (CISC) compare byte then autoincrement pointer |
| `Branch_if_[R]=0 label` | Jump to label if R equals 0 |
| `Branch=0 label` | Jump if the Z flag is 1 |
| `MoveControl R, CREG` | Transfer between a general reg and a control reg |
| `Return-from-interrupt` | End ISR: restore PC & PS, re-enable interrupts |

### Load vs LoadByte (common exam trap)

| | `Load` (word) | `LoadByte` |
|--|--------------|------------|
| Size | 32 bits / 4 bytes | 8 bits / 1 byte |
| Use | integers, pointers, addresses | ASCII chars, 8-bit device registers |
| Alignment | must be multiple of 4 | any byte address |
| Why for I/O | would read 4 adjacent regs by mistake | reads exactly one char ✔ |

---

## 15. Glossary of Every Flag & Register

**Keyboard**
- `KBD_DATA` (0x4000) — 8-bit buffer, ASCII of pressed key.
- `KBD_STATUS` (0x4004) — contains KIN (bit1), KIRQ (bit0).
- `KBD_CONT` (0x4008) — contains KIE (bit1).
- **KIN** — set by HW when a key waits; cleared by HW when KBD_DATA is read.
- **KIRQ** — set by HW when an unserviced interrupt is outstanding.
- **KIE** — set by SW to allow keyboard interrupts.

**Display**
- `DISP_DATA` (0x4010) — 8-bit char to show.
- `DISP_STATUS` (0x4014) — contains DOUT (bit2), DIRQ (bit1).
- `DISP_CONT` (0x4018) — contains DIE (bit2).
- **DOUT** — 1 = display ready; cleared when DISP_DATA is written.
- **DIRQ** — display interrupt-request flag.
- **DIE** — set by SW to allow display interrupts.

**Processor control registers (Fig 3.7)**
- **PS** — processor status; holds IE (bit0) + condition flags N,Z,C,V.
- **IPS** — automatic single-slot backup of PS during an interrupt.
- **IENABLE** — 32-bit mask, one enable bit per device.
- **IPENDING** — 32-bit mask, one "requesting now" bit per device.

**Condition flags (in PS)**
- **N** Negative · **Z** Zero · **C** Carry · **V** Overflow · **IE** Interrupt Enable.

**Other**
- **PC** — Program Counter (address of next instruction).
- **SP** — Stack Pointer (top of the downward-growing stack).
- **ISR** — Interrupt-Service Routine (the handler code).
- **IVT** — Interrupt-Vector Table (addresses of all ISRs).
- **CR** — Carriage Return (Enter key) ASCII code.
- **EOL / PNTR / LINE / LOC** — memory variables the programs use.

---

## 16. Self-Test Questions

Try these without looking back. Answers in the sections cited.

1. What is memory-mapped I/O, and what is its main advantage? *(§2)*
2. A keyboard register holds one ASCII character. Which instruction reads it and why not
   the other one? *(§4, §14)*
3. Write the 3-step pseudo-sequence for polling the keyboard. *(§5)*
4. In `And R4, R4, #2`, what is `#2` doing and what are the two possible results? *(§6)*
5. Name the three CISC features that shorten the Figure 3.5 program. *(§7)*
6. What two things does the hardware save automatically on an interrupt, and why only
   those two? *(§8)*
7. What are the three context-saving strategies, and which has the lowest latency? *(§8)*
8. State the "two-gate rule" required for a device interrupt to be accepted. *(§12)*
9. Why does the ISR write 0 to KBD_CONT when it sees a CR? *(§13A)*
10. Why does the Main program use `Or R2,R2,#1` instead of `Move R2,#1` to set IE? *(§13B)*
11. When does a device identify itself under vectored interrupts — at boot or at runtime?
    *(§10)*
12. What is the formula to find an ISR address in the interrupt-vector table? *(§10)*

---

*End of study guide. Open this file in any Markdown viewer (VS Code, Obsidian, Typora,
GitHub) to read it with formatting, or export to PDF from there.*
