# Chapter 1 — Basic Structure of Computers · Mind Maps

**Companion to:** `Chapter1_Basic_Structure_StudyGuide.md`

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
2. [Computer Types](#2-computer-types)
3. [The Five Functional Units](#3-the-five-functional-units)
4. [The Fetch-Execute Cycle (flow)](#4-the-fetch-execute-cycle)
5. [The Memory Hierarchy](#5-the-memory-hierarchy)
6. [Signed-Number Systems](#6-signed-number-systems)
7. [2's-Complement Add and Subtract (flow)](#7-2s-complement-add-and-subtract)
8. [Performance and Parallelism](#8-performance-and-parallelism)
9. [The Four Generations](#9-the-four-generations)

---

## 1. Master Map — The Whole Chapter

```mermaid
mindmap
  root((Ch.1<br/>Basic<br/>Structure))
    Computer Types 1.1
      Embedded
      Personal
        Desktop
        Workstation
        Portable or Notebook
      Servers and Enterprise
      Supercomputers and Grid
      Cloud computing trend
    Functional Units 1.2
      Input
      Memory
      ALU
      Output
      Control
      Processor = ALU plus control
    Operational Concepts 1.3
      Load Add Store
      Fetch execute cycle
      PC and IR
      Interrupts
    Numbers 1.4
      Unsigned integers
      Sign and magnitude
      1s complement
      2s complement
      Overflow
      Floating point
    Characters 1.5
      ASCII 7-bit
      BCD
    Performance 1.6
      Technology VLSI
      Parallelism
    History 1.7
      Four generations
```

**ASCII fallback:**
```
Ch.1 BASIC STRUCTURE
├── COMPUTER TYPES (1.1)
│   ├── Embedded · Personal (Desktop/Workstation/Portable) · Servers · Super+Grid
│   └── Cloud computing (emerging access trend)
├── FUNCTIONAL UNITS (1.2): Input · Memory · ALU · Output · Control
│   └── Processor = ALU + main control circuits
├── OPERATIONAL CONCEPTS (1.3): Load/Add/Store · fetch-execute · PC & IR · interrupts
├── NUMBERS (1.4): unsigned · sign-mag · 1s-comp · 2s-comp · overflow · floating point
├── CHARACTERS (1.5): ASCII 7-bit · BCD
├── PERFORMANCE (1.6): VLSI technology · parallelism
└── HISTORY (1.7): four generations
```

---

## 2. Computer Types

```mermaid
mindmap
  root((Computer<br/>Types))
    Embedded
      Inside a larger device
      Monitor and control a process
      Appliances vehicles telecom
      Often invisible to user
    Personal
      Desktop - general needs
      Workstation - engineering and science
      Portable or Notebook - battery mobile
    Servers and Enterprise
      Shared by many users
      Accessed over a network
      Host large databases
    Supercomputers and Grid
      Highest performance
      Most expensive and largest
      Super - weather and simulation
      Grid - many PCs over a network
    Cloud computing
      Distributed servers over Internet
      Pay as you use utility
```

**ASCII fallback:**
```
COMPUTER TYPES
├── EMBEDDED        : inside a larger device, control a process, often invisible
├── PERSONAL        : Desktop(general) · Workstation(eng/sci) · Portable(battery/mobile)
├── SERVERS+ENTERPRISE : shared by many users over a network, host large databases
├── SUPER + GRID    : highest performance; Super=weather/simulation; Grid=many PCs networked
└── CLOUD COMPUTING : distributed servers over Internet, pay-as-you-use utility
```

---

## 3. The Five Functional Units

```mermaid
mindmap
  root((Functional<br/>Units))
    Input
      Keyboard most common
      Mouse touchpad joystick
      Microphone and camera
      Internet from other computers
    Memory
      Primary - fast holds running programs
      Secondary - permanent large slow
      Word and word length
      Address starts at 0
      RAM fixed access time
      Cache small fast on chip
    ALU
      Add subtract multiply divide
      Compare and logic
      Operands in registers
    Output
      Printer mechanical and slow
      Display can also be input
    Control
      Nerve center
      Sends timing signals
      Distributed control lines
    Processor
      ALU plus main control
    I-O unit
      Input and output together
```

**ASCII fallback:**
```
FUNCTIONAL UNITS
├── INPUT   : keyboard(most common) · mouse/touchpad/joystick · mic/camera · Internet
├── MEMORY  : primary(fast, running programs) · secondary(permanent, large, slow)
│             word & word length · address from 0 · RAM(fixed access) · cache(small fast on-chip)
├── ALU     : add/sub/mul/div · compare · logic · operands held in registers
├── OUTPUT  : printer(mechanical, slow) · display(can also be input)
└── CONTROL : nerve center · timing signals · distributed control lines
Grouping: PROCESSOR = ALU + main control ;  I/O UNIT = input + output together
```

---

## 4. The Fetch-Execute Cycle

A **flow** map — the order of events running one instruction (Section 1.3, Example 1.1).

```mermaid
flowchart TD
    A["PC holds address of next instruction"] --> B["Send PC to memory with Read"]
    B --> C["Fetched word loaded into IR"]
    C --> D["Control unit decodes the instruction"]
    D --> E["Increment PC to point to next instruction"]
    E --> F{"Needs a memory operand?"}
    F -->|Yes| G["Send operand address, Read into a register"]
    F -->|No| H["ALU operates on register operands"]
    G --> H
    H --> I{"Store result to memory?"}
    I -->|Yes| J["Send address and data with Write"]
    I -->|No| K["Keep result in register"]
    J --> L["Fetch next instruction"]
    K --> L
    L --> A
```

**ASCII fallback:**
```
FETCH-EXECUTE CYCLE
 1. PC holds address of next instruction
 2. Send PC to memory with a Read signal
 3. Fetched word loaded into IR
 4. Control unit decodes the instruction
 5. Increment PC -> points to next instruction
 6. Need a memory operand?
       Yes -> send operand address, Read it into a register
       No  -> skip
 7. ALU operates on the register operands
 8. Store result to memory?
       Yes -> send address + data with a Write signal
       No  -> keep result in a register
 9. Loop back to fetch the next instruction
```

---

## 5. The Memory Hierarchy

```mermaid
mindmap
  root((Memory<br/>Hierarchy))
    Registers
      Inside the processor
      One word each
      Fastest access
    Cache
      Small fast RAM
      On the processor chip
      Starts empty fills on use
      Speeds up loops
    Primary main memory
      Semiconductor cells
      Organized in words
      RAM fixed access time
      Holds running programs
    Secondary storage
      Permanent and large
      Slower and cheaper
      Magnetic disk
      Optical disk DVD or CD
      Flash memory
```

**ASCII fallback:**
```
MEMORY HIERARCHY  (fastest/smallest at top)
├── REGISTERS : inside processor, one word each, fastest
├── CACHE     : small fast RAM on chip, starts empty, speeds up loops
├── PRIMARY   : semiconductor cells in words, RAM fixed access, holds running programs
└── SECONDARY : permanent, large, slow, cheap - magnetic disk · optical DVD or CD · flash
```

---

## 6. Signed-Number Systems

```mermaid
mindmap
  root((Signed<br/>Numbers))
    Common rule
      Leftmost bit 0 positive 1 negative
      Positives identical in all three
    Sign and magnitude
      Flip only the sign bit
      Two zeros plus and minus
      Easiest to read worst to add
    1s complement
      Flip every bit
      Subtract from 2 power n minus 1
      Two zeros
      Carry out needs correction
    2s complement
      1s complement then add 1
      Subtract from 2 power n
      Only one zero
      One extra negative value
      Best for add and subtract
      Used in modern computers
```

**ASCII fallback:**
```
SIGNED NUMBERS  (leftmost bit: 0=positive, 1=negative; positives identical in all three)
├── SIGN-AND-MAGNITUDE : flip only the sign bit; two zeros; easy read, worst arithmetic
├── 1s COMPLEMENT      : flip every bit (= subtract from 2^n - 1); two zeros; carry needs fix
└── 2s COMPLEMENT      : 1s-complement + 1 (= subtract from 2^n); one zero; one extra negative;
                         best for add/subtract; used in modern computers
```

---

## 7. 2's-Complement Add and Subtract

A **flow** map — the rules and the overflow test.

```mermaid
flowchart TD
    S{"Operation?"} -->|Add X plus Y| A["Add the n-bit representations"]
    S -->|Subtract X minus Y| B["Form 2s-complement of Y"]
    B --> A
    A --> C["Ignore the carry-out of the MSB"]
    C --> D{"Both summands same sign?"}
    D -->|No| OK["No overflow possible - result valid"]
    D -->|Yes| E{"Sum sign differs from summands?"}
    E -->|No| OK
    E -->|Yes| OV["OVERFLOW - result out of range"]
    style OK fill:#e0ffe0,stroke:#0a0
    style OV fill:#ffe0e0,stroke:#c00
```

**ASCII fallback:**
```
2's-COMPLEMENT ADD and SUBTRACT
  ADD X+Y        -> add the n-bit representations
  SUBTRACT X-Y   -> form 2's-complement of Y, THEN add it to X
  then: IGNORE the carry-out of the most significant bit

OVERFLOW TEST (addition):
  both summands same sign?
     No  -> no overflow possible, result valid
     Yes -> sum's sign differs from summands?
               No  -> valid
               Yes -> OVERFLOW (result out of representable range)
```

---

## 8. Performance and Parallelism

```mermaid
mindmap
  root((Performance<br/>1.6))
    Measured by
      How fast programs execute
    Affected by
      Instruction set design
      Hardware and software
      Operating system
      Implementation technology
      Compiler
    Technology
      VLSI single chip
      Smaller transistors switch faster
      More transistors per chip
    Parallelism
      Pipelining
        Overlap instruction steps
      Multicore
        Many cores on one chip
      Multiprocessor
        Shared memory
      Multicomputer
        Message passing
```

**ASCII fallback:**
```
PERFORMANCE (1.6)
├── MEASURED BY : how fast programs execute
├── AFFECTED BY : instruction set · hardware · software · OS · technology · compiler
├── TECHNOLOGY  : VLSI on one chip; smaller transistors switch faster; more per chip
└── PARALLELISM : pipelining(overlap steps) · multicore(cores/chip)
                  · multiprocessor(shared memory) · multicomputer(message passing)
```

---

## 9. The Four Generations

```mermaid
mindmap
  root((Four<br/>Generations))
    First 1945-1955
      Vacuum tubes
      Stored program concept
      Assembly language
      Mercury delay line then core
    Second 1955-1965
      Transistors from Bell Labs
      Magnetic core and disk
      Fortran and compilers
      IBM rises
    Third 1965-1975
      Integrated circuits
      Microprogramming and pipelining
      Operating systems
      Cache and virtual memory
      IBM System 360 and DEC PDP
    Fourth 1975-present
      VLSI
      Microprocessor on one chip
      Multicore and cache on chip
      FPGAs for embedded
      Notebooks phones cloud
```

**ASCII fallback:**
```
FOUR GENERATIONS
├── FIRST  1945-1955 : vacuum tubes · stored-program concept · assembly · delay-line/core
├── SECOND 1955-1965 : transistors(Bell Labs) · core+disk · Fortran+compilers · IBM rises
├── THIRD  1965-1975 : integrated circuits · microprogramming/pipelining · OS
│                      · cache(seems faster) + virtual memory(seems larger) · S/360, PDP
└── FOURTH 1975-now  : VLSI · microprocessor on one chip · multicore+cache · FPGAs
                       · notebooks, phones, cloud
```

---

*End of mind maps. Pair this with the main study guide for full detail on each node.*
