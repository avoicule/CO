# Chapter 4 — Software · Mind Maps

**Companion to:** `Chapter4_Software_StudyGuide.md`

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
2. [The Toolchain Pipeline](#2-the-toolchain-pipeline)
3. [The Two-Pass Assembler](#3-the-two-pass-assembler)
4. [The Linker and Libraries](#4-the-linker-and-libraries)
5. [The Compiler and Optimization](#5-the-compiler-and-optimization)
6. [The Debugger — Trace Mode and Breakpoints](#6-the-debugger--trace-mode-and-breakpoints)
7. [Assembly and C Interaction](#7-assembly-and-c-interaction)
8. [The Operating System](#8-the-operating-system)
9. [Multitasking — Process States and Time Slicing](#9-multitasking--process-states-and-time-slicing)

---

## 1. Master Map — The Whole Chapter

```mermaid
mindmap
  root((Ch.4<br/>Software))
    Assembly process 4.1
      Text editor makes source
      Assembler makes object
      Symbol table maps names
      Two-pass 4.1.1
        Pass 1 build table
        Pass 2 substitute
    Loading 4.2
      Loader copies to memory
      Header has length and address
      Branch to START
    Linker 4.3
      Combine object files
      Resolve external names
      ORIGIN or linker chooses
    Libraries 4.4
      Archiver builds library
      Linker extracts routines
    Compiler 4.5
      High-level to assembly
      Manages stack frames
      Optimizations 4.5.1
      Mixed languages 4.5.2
    Debugger 4.6
      Trace mode
      Breakpoints
    High-level I-O 4.7
      Pointers to I-O
      volatile matters
    Assembly and C 4.8
      asm directive
      MoveControl for control regs
      interrupt keyword
    Operating system 4.9
      Boot-strapping 4.9.1
      Managing programs 4.9.2
      Interrupts in OS 4.9.3
```

**ASCII fallback:**
```
Ch.4 SOFTWARE
├── ASSEMBLY PROCESS (4.1)
│   ├── text editor → source; assembler → object program
│   ├── symbol table maps names to values
│   └── two-pass (4.1.1): pass1 build table, pass2 substitute
├── LOADING (4.2) — loader copies to memory; header=length+address; branch to START
├── LINKER (4.3) — combine object files, resolve external names, ORIGIN or linker chooses
├── LIBRARIES (4.4) — archiver builds library; linker extracts needed routines
├── COMPILER (4.5) — high-level→assembly, manages stack frames
│   ├── optimizations (4.5.1)
│   └── mixed languages (4.5.2)
├── DEBUGGER (4.6) — trace mode · breakpoints
├── HIGH-LEVEL I/O (4.7) — pointers to I/O registers; volatile matters
├── ASSEMBLY+C (4.8) — asm directive, MoveControl, interrupt keyword
└── OPERATING SYSTEM (4.9)
    ├── boot-strapping (4.9.1)
    ├── managing programs (4.9.2)
    └── interrupts in OS (4.9.3)
```

---

## 2. The Toolchain Pipeline

A **flow** map — how source becomes a running program.

```mermaid
flowchart TD
    HL["High-level source C"] --> C[Compiler]
    C --> ASM["Assembly file"]
    ASMSRC["Assembly source"] --> ASM
    ASM --> A[Assembler]
    A --> OBJ["Object files"]
    LIB["Library files"] --> L[Linker]
    OBJ --> L
    L --> PROG["Object program on disk"]
    PROG --> LD[Loader]
    LD --> MEM["Program in memory"]
    MEM --> RUN["Execution starts at START"]

    style C fill:#e0e8ff,stroke:#36c
    style A fill:#e0e8ff,stroke:#36c
    style L fill:#fff0d0,stroke:#c90
    style LD fill:#e0ffe0,stroke:#0a0
```

**ASCII fallback:**
```
TOOLCHAIN PIPELINE
  High-level source (C) ──► COMPILER ──► assembly file ──┐
                                                         ├─► ASSEMBLER ─► object files ─┐
  Assembly source ────────────────────────────────────────┘                           │
                                           Library files ─────────────────────────────┤
                                                                                       ▼
                                                                                    LINKER
                                                                                       ▼
                                                                        Object program on disk
                                                                                       ▼
                                                                                    LOADER
                                                                                       ▼
                                                      Program in memory → execution starts at START
```

---

## 3. The Two-Pass Assembler

```mermaid
mindmap
  root((Two-Pass<br/>Assembler))
    Problem
      Forward reference
      Name used before defined
      Forward branch offset unknown
    Pass 1
      Build symbol table
      EQU record name and value
      Label value from position
      Sum sizes of earlier instructions
    Pass 2
      Scan again
      Look up each name
      Substitute numeric value
    Result
      Complete object program
      All names resolved
    Symbol table
      Names to values
      EQU constants
      Address labels
```

**ASCII fallback:**
```
TWO-PASS ASSEMBLER
├── PROBLEM: forward reference — name used before defined (forward branch offset unknown)
├── PASS 1: build symbol table
│     EQU → record name and value
│     label → value from position = sum of sizes of all earlier instructions
├── PASS 2: scan again, look up each name, substitute numeric value
└── RESULT: complete object program, all names resolved
SYMBOL TABLE = names → values (EQU constants and address labels)
```

---

## 4. The Linker and Libraries

```mermaid
mindmap
  root((Linker<br/>and<br/>Libraries))
    Why linker
      Call subroutines by others
      Many separate source files
      Assemble each separately
    External references
      Labels defined elsewhere
      Assembler builds a list
      List stored in object file
      Exported names shared out
    Linker job
      Combine object files
      Build memory map
      Assign absolute addresses
      Substitute final addresses
      Resolve all references
    Address choice
      ORIGIN fixes addresses
      Or linker chooses freely
      Avoid overlap and vectors
    Libraries 4.4
      Archiver builds library
      Reusable subroutines
      Linker extracts needed ones
```

**ASCII fallback:**
```
LINKER AND LIBRARIES
├── WHY: call subroutines by others in many separate files; assemble each separately
├── EXTERNAL REFERENCES
│     labels defined elsewhere; assembler lists them in the object file
│     exported names are shared out for others to use
├── LINKER JOB
│     combine object files → build memory map → assign absolute addresses
│     substitute final addresses → resolve all external references
├── ADDRESS CHOICE: ORIGIN fixes addresses, OR linker chooses (avoid overlap and vectors)
└── LIBRARIES (4.4): archiver builds library of reusable subroutines; linker extracts needed ones
```

---

## 5. The Compiler and Optimization

```mermaid
mindmap
  root((Compiler<br/>4.5))
    Job
      High-level to assembly
      Invokes the assembler
      Needs no machine details
    Benefit
      Manages stack frames
      Shorter development
      Easier to maintain
    Multiple files
      Declare external names
      Check data types
      Linker combines all
    Optimizations 4.5.1
      Reorder instructions
      Optimizing compiler
      Loop counter in register
        Load before loop
        No Load or Store inside
        Store after loop
    Mixed languages 4.5.2
      Assembly subroutines for speed
      C can call assembly
      Assembly can call C
```

**ASCII fallback:**
```
COMPILER (4.5)
├── JOB: high-level → assembly, then invokes the assembler; no machine details needed
├── BENEFIT: manages stack frames, shorter development, easier maintenance
├── MULTIPLE FILES: declare external names → type checking; linker combines all
├── OPTIMIZATIONS (4.5.1): reorder instructions = optimizing compiler
│     loop counter in register → Load before loop, none inside, Store after loop
└── MIXED LANGUAGES (4.5.2): hand-crafted assembly for speed; C↔assembly can call each other
```

---

## 6. The Debugger — Trace Mode and Breakpoints

A **decision/comparison** flow.

```mermaid
flowchart TD
    START["Program gives wrong results"] --> D[Use debugger]
    D --> Q{"How often to stop?"}
    Q -->|After every instruction| T[Trace mode]
    Q -->|Only at chosen points| B[Breakpoints]

    T --> T1["Interrupt after each instruction"]
    T1 --> T2["Debugger ISR takes control"]
    T2 --> T3["Inspect registers and memory"]
    T3 --> T4["Slow but complete"]

    B --> B1["Trap replaces instruction i"]
    B1 --> B2["Runs full speed until hit"]
    B2 --> B3["Debugger activated by Software-interrupt"]
    B3 --> B4["Reinstall by restoring i then re-arming"]

    style T fill:#ffe0e0,stroke:#c00
    style B fill:#e0ffe0,stroke:#0a0
```

**ASCII fallback:**
```
DEBUGGER (4.6)  — program gives wrong results, so stop and inspect
            How often to stop?
            │                        │
   After every instruction      Only at chosen points
            │                        │
       TRACE MODE               BREAKPOINTS
   interrupt after each         Trap replaces instruction i
   debugger ISR controls        runs full speed until hit
   inspect regs and memory      Software-interrupt activates debugger
   slow but complete            reinstall: restore i, then re-arm
                                  via trace mode or temp breakpoint at i+1
```

---

## 7. Assembly and C Interaction

```mermaid
flowchart TD
    NEED["Need processor control registers"] --> NOPTR["Pointers cannot reach them"]
    NOPTR --> REASON["Control regs have no address"]
    REASON --> ASM["Use asm directive to embed assembly"]
    ASM --> MC["asm MoveControl PS R2"]
    MC --> SAVE["Save R2 on stack first then restore"]

    ISR["ISR must be a C function"] --> SUB["Compiler ends it with Return-from-subroutine"]
    SUB --> PROB["Plain asm Return-from-interrupt leaves dead restore code"]
    PROB --> FIX{"Two correct fixes"}
    FIX -->|Keyword| K["interrupt keyword swaps in Return-from-interrupt"]
    FIX -->|Assembly handler| H["Save link register call C then restore"]

    style ASM fill:#e0e8ff,stroke:#36c
    style FIX fill:#fff0d0,stroke:#c90
```

**ASCII fallback:**
```
ASSEMBLY AND C INTERACTION (4.8)
ACCESS CONTROL REGISTERS
  need PS and IENABLE → pointers cannot reach them (no address)
  → use asm directive to embed assembly, e.g. asm("MoveControl PS, R2")
  → save R2 on stack first, restore after (compiler may be using it)

ISR IN C
  ISR must be a C function → compiler ends it with Return-from-subroutine
  plain asm("Return-from-interrupt") leaves dead restore code (regs/SP not restored!)
  TWO CORRECT FIXES:
    1. interrupt keyword → compiler swaps in Return-from-interrupt (not all compilers)
    2. assembly handler → save link register, call C subroutine, restore, Return-from-interrupt
```

---

## 8. The Operating System

```mermaid
mindmap
  root((Operating<br/>System<br/>4.9))
    What it is
      Coordinates all activity
      Resident routines in memory
      Utility programs on disk
    Manages resources
      Processor
      Memory and disk space
      Input and output
    Enables tools
      Editor compiler assembler linker
      Loader is part of OS
    Boot-strapping 4.9.1
      First instruction fixed location
      Must be non-volatile memory
      Small program loads more OS
      Loads loader and command handler
    Uses interrupts 4.9.3
      Programs ask OS for I-O
      Software interrupt enters OS
      Hardware interrupt signals done
      Software-interrupt ends program
```

**ASCII fallback:**
```
OPERATING SYSTEM (4.9)
├── WHAT: coordinates all activity; resident routines in memory + utilities on disk
├── MANAGES: processor · memory and disk space · input and output
├── ENABLES TOOLS: editor, compiler, assembler, linker; loader is part of OS
├── BOOT-STRAPPING (4.9.1)
│     first instruction at fixed location in NON-VOLATILE memory
│     small program loads progressively more OS → loader + command handler
└── USES INTERRUPTS (4.9.3)
      programs ask OS for I/O via software interrupt
      hardware interrupt signals I/O done; Software-interrupt ends a program
```

---

## 9. Multitasking — Process States and Time Slicing

A **state/flow** map of process states and the context switch.

```mermaid
flowchart LR
    RUN["Running"] -->|Time slice ends - timer| RBL["Runnable"]
    RBL -->|Scheduler selects| RUN
    RUN -->|Requests I-O| BLK["Blocked"]
    BLK -->|I-O done END=1| RBL

    subgraph SW["Context switch by SCHEDULER"]
      S1["Save state of current process"]
      S2["Select another Runnable process"]
      S3["Restore its state"]
      S4["Return-from-interrupt"]
    end

    style RUN fill:#e0ffe0,stroke:#0a0
    style RBL fill:#e0e8ff,stroke:#36c
    style BLK fill:#ffe0e0,stroke:#c00
```

**ASCII fallback:**
```
MULTITASKING — PROCESS STATES (time slicing: each program runs for τ, set by hardware timer)
   RUNNING  --time slice ends (timer)-->  RUNNABLE
   RUNNABLE --scheduler selects-------->  RUNNING
   RUNNING  --requests I/O------------->  BLOCKED
   BLOCKED  --I/O done, END=1---------->  RUNNABLE

CONTEXT SWITCH (SCHEDULER):
   1. save state of current process (regs, PC, PS)
   2. select another Runnable process
   3. restore its saved state
   4. Return-from-interrupt
OS ROUTINES: OSINIT · OSSERVICES · SCHEDULER · IOINIT · IODATA · KBDINIT · KBDDATA
```

---

*End of mind maps. Pair this with the main study guide for full detail on each node.*
