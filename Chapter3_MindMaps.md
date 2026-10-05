# Chapter 3 — Basic Input/Output · Mind Maps

**Companion to:** `Chapter3_Basic_Input_Output_StudyGuide.md`

> **How to view these:** The diagrams below use **Mermaid**, which renders as real
> pictures in VS Code (with a Markdown Mermaid extension), Obsidian, Typora, GitHub, and
> GitLab. If you open this file somewhere that *doesn't* render Mermaid, every diagram
> also has a plain-text **ASCII** version right underneath so nothing is lost.
>
> To export as an image/PDF: open in Obsidian or Typora → Export, or paste a single
> ```mermaid``` block into https://mermaid.live and download PNG/SVG.

---

## Table of Contents
1. [Master Map — The Whole Chapter](#1-master-map--the-whole-chapter)
2. [Memory-Mapped I/O](#2-memory-mapped-io)
3. [The Device Interface & Register Map](#3-the-device-interface--register-map)
4. [Polling vs Interrupts (decision)](#4-polling-vs-interrupts)
5. [The Interrupt Lifecycle (flow)](#5-the-interrupt-lifecycle)
6. [Processor Control Registers & the Two-Gate Rule](#6-processor-control-registers--the-two-gate-rule)
7. [The Keyboard Flag Logic (KIE · KIN · KIRQ)](#7-the-keyboard-flag-logic)
8. [RISC vs CISC](#8-risc-vs-cisc)
9. [Context Saving Strategies](#9-context-saving-strategies)

---

## 1. Master Map — The Whole Chapter

```mermaid
mindmap
  root((Ch.3<br/>Basic I/O))
    Why I/O
      Speed mismatch
        Keyboard ~ few/sec
        Display ~ thousands/sec
        CPU ~ billions/sec
      Need synchronization
    Accessing devices 3.1
      Memory-mapped I/O
        Devices look like memory
        Use Load / Store
        I/O registers = flip-flops
      Port-mapped I/O
        Special In / Out
        Separate address space
      Device interface
        DATA register
        STATUS register
        CONTROL register
    Program-controlled I/O 3.1
      Polling
        Spin on status flag
        Wastes CPU
      RISC program Fig 3.4
      CISC program Fig 3.5
    Interrupts 3.2
      Device alerts CPU
      ISR = handler
      Enable/disable 3.2.1
      Multiple devices 3.2.2
        Polling IRQ bits
        Vectored + IVT
        Nesting + priority
      Device control 3.2.3
      Control registers 3.2.4
        PS IPS IENABLE IPENDING
      Interrupt program Fig 3.8
```

**ASCII fallback:**
```
Ch.3 BASIC I/O
├── WHY I/O
│   ├── Speed mismatch (kbd few/s · display thousands/s · CPU billions/s)
│   └── Need synchronization
├── ACCESSING DEVICES (3.1)
│   ├── Memory-mapped I/O → devices look like memory, use Load/Store
│   ├── Port-mapped I/O   → special In/Out, separate space
│   └── Device interface  → DATA · STATUS · CONTROL registers
├── PROGRAM-CONTROLLED I/O (3.1)  [Polling]
│   ├── Spin on a status flag (wastes CPU)
│   ├── RISC program (Fig 3.4)
│   └── CISC program (Fig 3.5)
└── INTERRUPTS (3.2)
    ├── Device alerts CPU; ISR handles it
    ├── Enable/Disable (3.2.1) — IE bit
    ├── Multiple devices (3.2.2) — polling IRQ · vectored+IVT · nesting/priority
    ├── Device control (3.2.3) — KIE/KIN/KIRQ
    ├── Control registers (3.2.4) — PS·IPS·IENABLE·IPENDING
    └── Interrupt program (Fig 3.8)
```

---

## 2. Memory-Mapped I/O

```mermaid
mindmap
  root((Memory-<br/>Mapped I/O))
    Core idea
      Devices get real addresses
      Share CPU address space
      Steal addresses from RAM
    Consequence
      Any memory instruction works
      Load R2, DATAIN
      Store R2, DATAOUT
    Implemented as
      Flip-flops
        1 bit each
        8 = one byte register
        32 = one word register
      Called I/O registers
    Postman analogy
      RAM = mailboxes 1-900
      Device = mailboxes 901-910
      Same delivery routine
    Alternative
      Port-mapped I/O
      In / Out instructions
      x86 legacy
```

**ASCII fallback:**
```
MEMORY-MAPPED I/O
├── CORE IDEA: devices get real addresses, stolen from RAM's space
├── CONSEQUENCE: any memory instruction works (Load R2,DATAIN / Store R2,DATAOUT)
├── IMPLEMENTED AS: flip-flops (1 bit) → grouped into I/O registers (8b=byte, 32b=word)
├── ANALOGY: RAM=mailboxes 1-900, devices=901-910, same postman routine
└── ALTERNATIVE: port-mapped I/O (In/Out, separate space, x86 legacy)
```

---

## 3. The Device Interface & Register Map

```mermaid
mindmap
  root((Device<br/>Interface))
    Keyboard 0x4000 base
      KBD_DATA 0x4000
        8-bit ASCII of key
      KBD_STATUS 0x4004
        KIN bit1 - key waiting
        KIRQ bit0 - IRQ raised
      KBD_CONT 0x4008
        KIE bit1 - allow IRQ
    Display 0x4010 base
      DISP_DATA 0x4010
        8-bit char to show
      DISP_STATUS 0x4014
        DOUT bit2 - ready
        DIRQ bit1 - IRQ raised
      DISP_CONT 0x4018
        DIE bit2 - allow IRQ
    Three register types
      DATA - the byte
      STATUS - ready?
      CONTROL - configure
    Why +4 spacing
      Word-aligned
      32-bit words = 4 bytes
```

**ASCII fallback:**
```
DEVICE INTERFACE  (3 register types: DATA=the byte · STATUS=ready? · CONTROL=configure)
├── KEYBOARD
│   ├── KBD_DATA   0x4000 : 8-bit ASCII
│   ├── KBD_STATUS 0x4004 : KIN(bit1 key waiting) · KIRQ(bit0 irq raised)
│   └── KBD_CONT   0x4008 : KIE(bit1 allow irq)
├── DISPLAY
│   ├── DISP_DATA   0x4010 : 8-bit char
│   ├── DISP_STATUS 0x4014 : DOUT(bit2 ready) · DIRQ(bit1 irq raised)
│   └── DISP_CONT   0x4018 : DIE(bit2 allow irq)
└── +4 spacing keeps everything word-aligned (32-bit word = 4 bytes)
```

---

## 4. Polling vs Interrupts

A **decision/comparison** map — when to use which.

```mermaid
flowchart TD
    A[Need to transfer I/O data] --> B{Can device<br/>raise interrupts?}
    B -->|No HW support| P[POLLING only]
    B -->|Yes| C{Event frequent &<br/>predictable?}
    C -->|Yes, fast tight loop| P
    C -->|No, rare/slow event<br/>e.g. keyboard| I[INTERRUPTS]
    C -->|Multitasking OS| I

    P --> P1[CPU spins on status flag]
    P1 --> P2[Simple to code]
    P1 --> P3[Wastes CPU cycles]

    I --> I1[Device signals CPU when ready]
    I1 --> I2[CPU free to do other work]
    I1 --> I3[Needs ISR + enable bits + save/restore]

    style P fill:#ffe0e0,stroke:#c00
    style I fill:#e0ffe0,stroke:#0a0
```

**ASCII fallback:**
```
                 Need I/O transfer
                        │
             Can device raise interrupts?
                 │                 │
                No                Yes
                 │                 │
             POLLING        Event rare/slow? (keyboard, OS multitask)
                 │             │                        │
   spin on flag  │            No (fast tight loop)     Yes
   simple        │             │                        │
   WASTES CPU    │          POLLING                 INTERRUPTS
                              (same box)        device signals CPU,
                                                CPU free meanwhile,
                                                needs ISR+enable+save/restore

RULE: choice is a SOFTWARE decision (if HW supports interrupts at all).
```

---

## 5. The Interrupt Lifecycle

A **sequence/flow** map — the exact order of events for one keypress (Fig 3.8).

```mermaid
sequenceDiagram
    participant U as User
    participant KB as Keyboard HW
    participant CPU as CPU Hardware
    participant ISR as ISR (software)

    Note over CPU: Init: KIE=1, IENABLE[KBD]=1, PS.IE=1
    U->>KB: press key 'A'
    KB->>KB: ASCII → KBD_DATA, set KIN=1
    KB->>KB: KIE AND KIN → set KIRQ=1, assert line
    KB->>CPU: interrupt request
    CPU->>CPU: finish current instruction
    CPU->>CPU: save PC & PS→IPS, clear IE
    CPU->>ISR: jump to ILOC
    ISR->>ISR: push R2,R3 on stack
    ISR->>KB: LoadByte KBD_DATA  (clears KIN & KIRQ)
    ISR->>ISR: store char, bump pointer
    ISR->>ISR: poll DOUT, echo to display
    ISR->>ISR: if CR → set EOL, KIE=0
    ISR->>ISR: pop R2,R3
    ISR->>CPU: Return-from-interrupt
    CPU->>CPU: restore PC & PS (IE=1 again)
    Note over CPU: resume Main program
```

**ASCII fallback:**
```
INTERRUPT LIFECYCLE (one keypress)
 0. INIT (Main): KIE=1 · IENABLE[KBD]=1 · PS.IE=1
 1. User presses 'A'
 2. Keyboard: ASCII→KBD_DATA, KIN=1
 3. Keyboard: (KIE AND KIN) → KIRQ=1, assert interrupt line
 4. CPU: finish current instruction
 5. CPU: save PC; copy PS→IPS; clear IE (disable further interrupts)
 6. CPU: jump to ISR at ILOC
 7. ISR: push R2,R3 on stack
 8. ISR: LoadByte KBD_DATA  →  HW auto-clears KIN & KIRQ (drops the request)
 9. ISR: store char in buffer, increment pointer
10. ISR: poll DOUT, echo char to display
11. ISR: if char==CR → set EOL=1, write KIE=0
12. ISR: pop R2,R3
13. ISR: Return-from-interrupt
14. CPU: restore PC & PS (IE=1 again) → resume Main
```

---

## 6. Processor Control Registers & the Two-Gate Rule

```mermaid
mindmap
  root((Control<br/>Registers<br/>Fig 3.7))
    PS Processor Status
      IE bit0 = global switch
      N Z C V condition flags
      Accessed by MoveControl only
    IPS Saved PS
      HW backup of PS on entry
      Restored on return
      Only ONE - nesting needs stack
    IENABLE
      32-bit per-device mask
      bit1 KBD bit2 DISP bit3 TIM
      1 = accept that device
    IPENDING
      32-bit per-device flags
      HW sets requesting device
      SW reads to pick priority
    TWO-GATE RULE
      Gate 1 PS.IE = 1
      Gate 2 IENABLE device = 1
      BOTH needed to fire
```

**ASCII fallback:**
```
CONTROL REGISTERS (Fig 3.7)  — all 32-bit, reached only by MoveControl
├── PS       : IE(bit0 global switch) + condition flags N,Z,C,V
├── IPS      : HW backup of PS on entry; restored on return; ONLY ONE (nesting→stack)
├── IENABLE  : per-device mask (bit1 KBD, bit2 DISP, bit3 TIM); 1=accept
└── IPENDING : per-device "requesting now" flags; SW reads to choose priority

TWO-GATE RULE (both must be 1 for an interrupt to fire):
   [ PS.IE = 1 ]  AND  [ IENABLE[device] = 1 ]
```

---

## 7. The Keyboard Flag Logic

How **KIE**, **KIN**, **KIRQ** interact — who sets what.

```mermaid
flowchart LR
    SW[Software sets<br/>KIE = 1<br/>arming switch] --> AND
    KEY[Key pressed →<br/>HW sets KIN = 1] --> AND
    AND{KIE AND KIN}
    AND -->|both 1| IRQ[HW sets KIRQ = 1<br/>raise interrupt line]
    READ[ISR reads KBD_DATA] --> CLR[HW clears KIN = 0]
    CLR --> DROP[condition false →<br/>HW clears KIRQ = 0<br/>drop request]

    style SW fill:#e0e8ff
    style KEY fill:#fff0d0
    style IRQ fill:#ffe0e0
    style DROP fill:#e0ffe0
```

**ASCII fallback:**
```
KEYBOARD FLAG LOGIC   (who controls each bit)
  KIE  = SOFTWARE  (arming switch: 1 = allow interrupts)
  KIN  = HARDWARE  (1 = a key is waiting in KBD_DATA)
  KIRQ = HARDWARE  (1 = unserviced interrupt outstanding)

  trigger:   KIE=1  AND  KIN=1   →   HW sets KIRQ=1, asserts interrupt line
  clearing:  ISR reads KBD_DATA  →   HW clears KIN=0
                                 →   (KIE AND KIN) now false → HW clears KIRQ=0
```

---

## 8. RISC vs CISC

```mermaid
mindmap
  root((RISC vs<br/>CISC))
    RISC
      Load/Store philosophy
      Cannot touch memory in ALU ops
      Must Load → operate → Store
      Poll kbd = 3 instr
        LoadByte And Branch
      Needs separate Add for pointer
      More instructions, each simple
    CISC
      Operate directly on memory
      TestBit dst #k - sets Z flag
        Z=1 if bit=0
      Memory-to-memory MoveByte
      Autoincrement R2+
      Poll kbd = 2 instr
        TestBit Branch=0
      Fewer instr, each more complex
    Trade-off
      RISC simpler HW faster per instr
      CISC shorter code more microops
```

**ASCII fallback:**
```
RISC vs CISC
┌───────────────────────────────┬────────────────────────────────────┐
│ RISC (Load/Store)              │ CISC (operate on memory)           │
├───────────────────────────────┼────────────────────────────────────┤
│ cannot test/add in memory      │ TestBit dst,#k (sets Z, Z=1 if 0)  │
│ Load → operate → Store         │ MoveByte memory→memory             │
│ poll kbd = 3 instr             │ autoincrement (R2)+                │
│ (LoadByte, And, Branch)        │ poll kbd = 2 instr (TestBit,Br=0)  │
│ separate Add for pointer       │ pointer bump folded in             │
│ many simple instructions       │ few powerful instructions          │
└───────────────────────────────┴────────────────────────────────────┘
Trade-off: RISC = simpler HW, fast per instruction.
           CISC = shorter code, but each instruction = more micro-ops.
```

---

## 9. Context Saving Strategies

```mermaid
mindmap
  root((Context<br/>Saving))
    Minimal saving
      HW saves PC + PS only
      ISR pushes regs it uses
      Low overhead
      Used in Fig 3.8
    Universal saving
      HW auto-saves R0..R31
      Easy to program
      High latency
    Shadow registers
      Duplicate register bank
      Instant bank switch
      Near-zero overhead
      Costs silicon area
    Who decides
      HW: chip architect builds it
      SW: driver/compiler uses it
```

**ASCII fallback:**
```
CONTEXT SAVING STRATEGIES  (balance speed vs complexity)
├── MINIMAL     : HW saves PC+PS; ISR pushes only regs it uses. Low overhead. (Fig 3.8)
├── UNIVERSAL   : HW auto-saves R0..R31. Easy to code, HIGH latency.
└── SHADOW REGS : duplicate bank, instant switch, near-zero overhead, costs silicon.
Decision: HW architect builds the mechanism; SW driver/compiler chooses how to use it.
```

---

*End of mind maps. Pair this with the main study guide for full detail on each node.*
