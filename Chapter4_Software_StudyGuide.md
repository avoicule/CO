# Chapter 4 — Software

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 129–150 (Sections 4.1 → 4.10)

> How to use this guide: read it top to bottom. Each section builds on the previous one.
> Terms in **bold** are the ones you must be able to define. Code blocks are the exact
> instructions from the textbook, explained line-by-line. The "Checkpoint" boxes are
> what you should be able to answer before moving on.

---

## Table of Contents

1. [The Big Picture — The Toolchain](#1-the-big-picture)
2. [Section 4.1 — The Assembly Process](#2-section-41--the-assembly-process)
3. [Section 4.1.1 — The Two-Pass Assembler](#3-section-411--the-two-pass-assembler)
4. [Section 4.2 — Loading and Executing Object Programs](#4-section-42--loading-and-executing-object-programs)
5. [Section 4.3 — The Linker](#5-section-43--the-linker)
6. [Section 4.4 — Libraries](#6-section-44--libraries)
7. [Section 4.5 — The Compiler](#7-section-45--the-compiler)
8. [Section 4.5.1 — Compiler Optimizations](#8-section-451--compiler-optimizations)
9. [Section 4.5.2 — Combining Programs in Different Languages](#9-section-452--combining-programs-in-different-languages)
10. [Section 4.6 — The Debugger](#10-section-46--the-debugger)
11. [Section 4.7 — Using a High-Level Language for I/O Tasks](#11-section-47--using-a-high-level-language-for-io-tasks)
12. [Section 4.8 — Interaction between Assembly Language and C](#12-section-48--interaction-between-assembly-language-and-c)
13. [Section 4.9 — The Operating System](#13-section-49--the-operating-system)
14. [Section 4.9.1 — The Boot-strapping Process](#14-section-491--the-boot-strapping-process)
15. [Section 4.9.2 — Managing Execution of Application Programs](#15-section-492--managing-execution-of-application-programs)
16. [Section 4.9.3 — Use of Interrupts in Operating Systems](#16-section-493--use-of-interrupts-in-operating-systems)
17. [Utility Program Reference Card](#17-utility-program-reference-card)
18. [Glossary](#18-glossary)
19. [Self-Test Questions](#19-self-test-questions)

---

## 1. The Big Picture

Chapter 2 showed how to write programs in **assembly language**; Chapter 3 showed how to
do I/O. This chapter answers a different question: **what software do you need to turn a
program you typed into something the machine actually runs?**

A program never goes straight from your fingertips to execution. It passes through a chain
of **utility programs**, each doing one job:

| Utility | Input | Output | Job |
|---------|-------|--------|-----|
| **Text editor** | keystrokes | source file | let you type and save the program |
| **Compiler** | high-level source (C) | assembly-language file | translate C → assembly |
| **Assembler** | assembly source | object file | translate assembly → machine code |
| **Linker** | several object files + libraries | one object program | stitch pieces together, resolve references |
| **Loader** | object program on disk | program in memory | copy into memory, start it |
| **Debugger** | running object program | — | pause execution, inspect state, find bugs |

Overarching all of this sits the **operating system (OS)**, which coordinates every resource
(processor, memory, disk, I/O) and ties the whole toolchain together.

The central theme of the chapter: **a symbolic program a human can read must be
progressively translated and assembled into binary a machine can execute, and the OS
manages that program while it runs.**

> **Checkpoint:** In what order do the compiler, assembler, and linker run for a C
> program? *(Compiler → assembler → linker: C is translated to assembly, assembly to an
> object file, and object files are combined into the final object program.)*

---

## 2. Section 4.1 — The Assembly Process

A **source program** is written in symbolic assembly language — mnemonics a human
understands. But the computer executes only **machine-language code** (binary). The
**assembler** is the utility that performs this translation; the activity is called
**assembling a program**.

Step by step, before the assembler even runs:

1. The programmer uses a **text editor** to type statements and save them in a **file**.
2. The file is a sequence of binary-encoded alphanumeric characters, identified by a
   user-chosen **name**, normally stored on a **secondary storage device** such as a
   magnetic disk.

Then the assembler takes over. It:

- Translates the source program into an **object program** made of **machine
  instructions**.
- Converts the assembly-language representation of **data** into binary patterns that
  become part of the object program.
- Loads the source file from disk into memory, translates it, and **stores the object
  program in a separate file on the disk**.

### What the assembler recognizes

- **Mnemonics** representing OP codes — the assembler generates the binary encoding of
  the OP code and the other instruction fields.
- **Syntax rules** governing addressing modes for operands.
- **Directives** that specify numbers/characters and that allocate memory space for data
  areas.
- **EQU (equate) directives** — let the programmer define **names that represent
  constants**; those names can then be used as operands.
- **Address labels** — names marking branch targets, subroutine entry points, or data
  locations. A label's value is based on **its position relative to the beginning of the
  assembled program**.

### The symbol table

As the assembler scans the source program, it records every name and its value in a
**symbol table**. Each time a name appears, it is **replaced with its value** from the table.

**Analogy (the translator with a glossary):** imagine translating a manuscript that uses
nicknames. You keep a glossary (symbol table) mapping each nickname to a real name. Every
time a nickname appears, you look it up and substitute. The only trouble comes when a
nickname is *used* on page 2 but not *defined* until page 40 — which is exactly the
problem the next section solves.

> **Checkpoint:** What is stored in the symbol table and why? *(Every name — EQU constants
> and address labels — paired with its numeric value, so the assembler can substitute the
> value wherever the name appears.)*

---

## 3. Section 4.1.1 — The Two-Pass Assembler

**The problem — forward references.** A name may be used as an operand *before* its value
is defined. The classic case is a **forward branch** to a label that appears later in the
program. As in Section 2.5.2, the branch **offset** is calculated from the target's
address — but with a forward branch the assembler does not yet know that address, because
the label is not in the symbol table yet.

**The solution — scan the program twice:**

| Pass | What happens |
|------|--------------|
| **Pass 1** | Build the symbol table. For **EQU** directives, record each name and its defined value. For **address labels**, compute each name's value from its position — found by **summing the sizes of all machine instructions processed before the label's definition**. At the end of pass 1, every name has a numeric value. |
| **Pass 2** | Scan again; look up each name in the completed symbol table and substitute its numeric value. |

A **two-pass assembler** therefore produces a **complete object program** — no name is
left unresolved, because pass 1 guaranteed all values are known before pass 2 uses them.

> **Deep dive — why summing instruction sizes gives the address:**
> Each machine instruction occupies a known number of bytes. If the program starts at a
> known origin and you add up the byte-sizes of every instruction before a label, you get
> that label's offset from the start — hence its address. This is purely bookkeeping, and
> it is exactly why pass 1 can resolve forward references that pass 2 then plugs in.

> **Checkpoint:** Why can't a single-pass assembler always resolve a forward branch?
> *(The target label's address is unknown when the branch is first encountered; its value
> is only recorded later. A first full pass records all values before the second pass
> substitutes them.)*

---

## 4. Section 4.2 — Loading and Executing Object Programs

The assembler leaves the object program **in a file on disk**. To run it, the program must
be brought into memory and started. The **loader** is the utility that does this.

### What the loader does, in order

1. The **loader is invoked** when the user enters a command to execute an object file.
2. The user command **specifies the name of the object file**, so the loader can find it
   on the disk.
3. The loader **transfers the object program from disk into a specified place in memory.**
   To do this it must know the program's **length** and the **memory address** where it
   will be loaded.
4. That information lives in a **header** the assembler places at the front of the object
   file, preceding the instructions and data.
5. Once loaded, the loader **starts execution by branching to the first instruction.** The
   programmer marks that instruction with a special label such as **START**, and the
   assembler puts START's value in the header.

### Entering the command

- **Typing** the command at the keyboard, or
- Using a **graphical user interface (GUI)** — the user selects the object file with a
  mouse, and the GUI software passes the file's disk location to the loader.

### Termination

When a program finishes, its execution must be **terminated in a well-defined manner** so
that:

- the memory it occupied can be **recovered**, and
- the user can enter a **new command** to run another program.

These termination duties are normally handled by the **operating system** (Section 4.9).

> **Checkpoint:** What two facts must the loader know to place a program in memory, and
> where does it get them? *(The program's length and its load address — both read from the
> header the assembler wrote at the front of the object file.)*

---

## 5. Section 4.3 — The Linker

So far we assumed one source file → one object program. In practice a programmer often
wants to call **subroutines written by other programmers**, scattered across many source
files. Gathering them all into one giant source file is neither convenient nor practical.

**The common procedure:** assemble each source file **separately**. But then each output
file is **not a complete object program** — it may contain **external references**: address
labels defined in *other* source files.

### How external references are tracked

- When the assembler processes a source file, it **identifies external references** and
  builds a **list** of these names and the instructions that refer to them. That list is
  **included in the object file**.
- Labels that *other* files may reference must be **exported**. The programmer indicates
  which labels to export; the assembler includes the **exported names** in each object
  file, along with the list of external names used and the instructions referring to them.

### What the linker does

The **linker** combines several object files into one object program by **resolving
references to external names**:

1. It reads each object file plus the **known sizes** of the machine-language programs.
2. It builds a **memory map** of the final combined object file.
3. It assigns each piece its **final location in memory**, which determines the **absolute
   address** of every exported label.
4. It **substitutes those final addresses** into the specific instructions that contain
   external references.
5. When every external reference is resolved, the **final object program is complete.**

### ORIGIN directives vs. letting the linker choose

- The programmer **may fix addresses explicitly** using directives such as **ORIGIN** in
  the source file. Then the programmer must **ensure object files do not overlap** in
  memory.
- The **more flexible approach** is *not* to use ORIGIN, giving the linker freedom to
  choose the starting address. The linker then ensures object files do not overlap with
  each other **or with special locations** such as **interrupt vectors**.

> **Checkpoint:** What information must an object file carry so the linker can do its job?
> *(The list of external names it references with the instructions that use them, and the
> relative positions of the labels it exports.)*

---

## 6. Section 4.4 — Libraries

Subroutines written for one program are often useful for others. So it is common to collect
object files of such subroutines into a **library file** on disk.

- A utility called an **archiver** creates the library file. The library includes the
  information the linker needs to **resolve references to external names** in programs that
  call library routines.
- When invoking the linker, the programmer **specifies the desired library files.** The
  linker **extracts only the relevant object files** from the library and includes them in
  the final object program.

> **Checkpoint:** Does the linker include an entire library in your program? *(No — it
> extracts only the relevant object files that your program actually references.)*

---

## 7. Section 4.5 — The Compiler

Assembly-language programming requires **machine-specific knowledge** that varies from one
computer to another. A **high-level language** such as C, C++, or Java does not.

But before a high-level program can run it must be translated **first into assembly
language, then into machine language.** The **compiler** performs the first step:

1. The programmer prepares a high-level **source file** on disk.
2. The compiler **generates assembly-language instructions and directives** into an output
   file.
3. The compiler then **invokes the assembler** to assemble that file into an object file.

### Multiple files

A high-level program is often **partitioned into multiple files**, grouping related
subroutines. In each file, the names of **external subroutines and data variables** defined
elsewhere must be **declared** — this lets the compiler **check data types and detect
errors**. For each source file the compiler produces an assembly file, then invokes the
assembler to make an object file; finally the **linker** combines all object files
(including library routines) into the final object program.

### Why high-level languages are a win

The compiler **automates tedious tasks** the assembly programmer must do by hand. The
textbook's headline example: when generating assembly for subroutines, **the compiler
performs all tasks related to managing stack frames.**

> **Checkpoint:** The compiler's output is not machine code directly — what is it, and
> what runs next? *(It is assembly language; the compiler then invokes the assembler to
> turn that into an object file.)*

---

## 8. Section 4.5.1 — Compiler Optimizations

A **straightforward** translation from high-level to assembly may not be the most
**efficient** in execution time or size. A compiler that improves the code — for example by
**reordering instructions** — is called an **optimizing compiler**.

### The loop-counter example

Because much execution time is spent in **loops**, compilers optimize loops heavily.
Consider a loop counter kept in a **memory variable**:

- **Straightforward version:** the counter is read and written every pass, so **Load, Add,
  Store** instructions sit inside the loop.
- **Optimized version:** the compiler recognizes the counter can live in a **register**
  for the loop's duration. Then:
  - a single **Load** before the loop places the initial value in the register,
  - the **Load and Store are no longer needed inside the loop**,
  - a single **Store** after the loop records the final value.

```text
  Straightforward (inside loop):     Optimized:
      Load   counter                     Load counter   ; once, before loop
      Add    ...                     LOOP:
      Store  counter                     Add ...        ; register only
      ... (every pass)                   ... (every pass)
                                     END:
                                         Store counter  ; once, after loop
```

Removing memory traffic from the hot path of a loop is one of the biggest speedups a
compiler can deliver.

> **Checkpoint:** Why does keeping the loop counter in a register speed up the loop?
> *(It eliminates the per-pass Load and Store to memory; only register arithmetic remains
> inside the loop.)*

---

## 9. Section 4.5.2 — Combining Programs in Different Languages

The linker can combine object files from **high-level source** and **assembly source**
together.

Why mix them?

- The programmer may hand-craft **assembly subroutines for high performance** and call them
  from a high-level program.
- Equally, an **assembly program can call high-level subroutines**.

**Figure 4.1** in the text illustrates the complete flow: high-level source files go
through the **compiler**, assembly source files go through the **assembler**, both produce
**object files**, and those plus **library files** feed the **linker**, which emits the
final **object program**.

```text
   High-level source ──► Compiler ──► (assembly) ──┐
                                                    ├─► Assembler ──► Object files ──┐
   Assembly source ─────────────────────────────────┘                               │
                                              Library files ──────────────────────────┤
                                                                                      ▼
                                                                                   Linker
                                                                                      ▼
                                                                              Object program
```

> **Checkpoint:** Can an assembly subroutine and a C function end up in the same executable?
> *(Yes — the assembler and compiler each produce object files that the linker combines
> into one object program.)*

---

## 10. Section 4.6 — The Debugger

An object program is generated **successfully** only when there are **no syntax errors or
unknown names** — those are caught and reported by the assembler, compiler, or linker, and
the programmer fixes the source.

But a program that assembles cleanly can still produce **incorrect results** at run time
due to **programming errors (bugs)** that are hard to isolate. The **debugger** helps: it
lets the programmer **stop execution at points of interest** and **examine processor
registers and memory locations**, comparing computed values against expected ones to locate
the error, then fix the source.

To support debugging, processors provide **special modes and special interrupts**. Two key
facilities:

### Trace mode

- In **trace mode**, an **interrupt occurs after *every* instruction.**
- Each such interrupt invokes an **interrupt-service routine in the debugger**, which takes
  control and lets the user inspect registers and memory.
- When the user resumes, a **Return-from-interrupt** runs the next instruction, after which
  the debugger is activated **again** by another interrupt.
- The trace-mode interrupt is **automatically disabled when the debugger is entered** and
  **re-enabled on return** to the object program.

### Breakpoints

Breakpoints are also interrupt-based, but the program is interrupted **only at specific
points** the programmer chooses. The advantage: **execution runs at full speed until the
breakpoint is hit.**

Implementation uses a special **Trap** (also called **Software-interrupt**) instruction,
which produces the same actions as a hardware-interrupt request. To set a breakpoint just
before instruction *i*:

1. The debugger **saves instruction *i*** in a temporary location and **replaces it with a
   Software-interrupt instruction.**
2. The user resumes; the debugger executes **Return-from-interrupt.**
3. Instructions run normally until the **Software-interrupt** is reached, which **activates
   the debugger again** so the user can inspect state.

### Reinstalling a breakpoint (the tricky part)

When the user resumes, the debugger must both execute instruction *i* **and** re-arm the
same breakpoint:

1. **Restore instruction *i*** to its original location — it will be the first instruction
   executed on resume.
2. Arrange a **second interrupt after *i* executes**, by either:
   - **enabling trace mode** (if available), or
   - placing a **temporary breakpoint at instruction *i + 1*.**
3. After *i* executes, the second interrupt fires. The debugger then **restores instruction
   *i + 1*, reinstalls the breakpoint at *i*,** and resumes the program.

> **Checkpoint:** What is the practical advantage of a breakpoint over trace mode? *(With a
> breakpoint the program runs at full speed until the chosen point; trace mode interrupts
> after every single instruction, which is far slower.)*

---

## 11. Section 4.7 — Using a High-Level Language for I/O Tasks

Using a high-level language is **preferable in most applications** — shorter development
time, easier to generate and maintain. This section shows a **C** program doing a polling
I/O task equivalent to an assembly one.

**Task:** poll the keyboard, read 8-bit characters, and send them to the display as the user
types (using the memory-mapped interfaces from Figure 3.3).

### The C program (Figure 4.3)

```c
/* Define register addresses. */
#define KBD_DATA    (volatile char *) 0x4000
#define KBD_STATUS  (volatile char *) 0x4004
#define DISP_DATA   (volatile char *) 0x4010
#define DISP_STATUS (volatile char *) 0x4014

void main() {
    char ch;
    while (1) {                                 /* Infinite loop. */
        while ((*KBD_STATUS & 0x2) == 0);       /* Wait for a new character. */
        ch = *KBD_DATA;                          /* Read char from keyboard. */
        while ((*DISP_STATUS & 0x4) == 0);      /* Wait for display ready. */
        *DISP_DATA = ch;                         /* Send char to display. */
    }
}
```

### Line-by-line meaning

- **The `#define` pointers** associate address constants with symbolic names — serving the
  same purpose as **EQU** statements in assembly. Each cast like `(volatile char *) 0x4000`
  tells the compiler the pointer's value **is the address** of a memory-mapped I/O location
  and that its contents are **one byte** (matching the 8-bit I/O registers of Figure 3.3).
- **`*KBD_STATUS & 0x2`** reads the status register and masks **bit b1** (the KIN flag).
  The `while (... == 0);` spins until a key is waiting.
- **`ch = *KBD_DATA;`** reads the character.
- **`*DISP_STATUS & 0x4`** masks **bit b2** (DOUT) and waits until the display is free.
- **`*DISP_DATA = ch;`** writes the character to the display.

### Why `volatile` is essential

`KBD_STATUS` and `DISP_STATUS` are only **read**, never written, by the program. An
**optimizing compiler may delete statements that appear to have no effect** — including
reads of a location that is never written. But these registers **change under external
influences** (the hardware), so the program must tell the compiler not to optimize them
away. Declaring the pointer **`volatile`** does exactly that: the compiler **will not
remove** statements involving volatile variables.

> **Deep dive — `volatile` and the cache:**
> On a machine with a **cache** (a small fast memory holding copies of main memory), data
> from memory-mapped I/O registers **must not be cached**, because those registers change
> externally. References to them should **bypass the cache** and hit the real registers.
> Some compilers give `volatile` this second meaning too: not only prevent unwanted
> optimizations, but also **generate memory-access instructions that bypass the cache.**

> **Checkpoint:** Why must `KBD_STATUS` be declared `volatile`? *(The program only reads it
> and never writes it, so an optimizer would otherwise remove the polling reads; `volatile`
> forbids that because the register changes externally — and may also force cache bypass.)*

---

## 12. Section 4.8 — Interaction between Assembly Language and C

Sometimes a program must access **processor control registers** — for example when
**initializing an interrupt-service routine**. A compiler **cannot** generate instructions
that touch control registers from a plain high-level statement. So the compiler lets you
**embed assembly-language instructions directly** in the high-level program.

### The task

Transfer characters from keyboard to display, using **interrupts** to receive keypresses.
To keep it simple, the ISR sends each received character to the display **without polling**
(assuming input is slow enough).

Initialization must:

- Configure the interface (Figure 3.3) to raise an interrupt when **KIN = 1**, by setting
  **KIE = 1** in the **KBD_CONT** register.
- Enable interrupts in the processor by setting **IE = 1** in the **PS** register and the
  **KBD** bit in the **IENABLE** control register (Figure 3.7).

This section assumes a **single interrupt vector, IVECT, at address 0x20** for all
interrupts, initialized with the ISR's address.

### Embedding assembly in C — the `asm` directive

The pointer trick from Section 4.7 **cannot** reach IENABLE and PS, because those **control
registers do not have memory addresses.** Instead you embed assembly:

```c
asm ("MoveControl PS, R2");
```

This inserts the quoted instruction verbatim into the compiled code. Because the compiler
may already be using **R2**, you must **save R2 on the stack before using it** and restore
it afterward (compilers also offer more sophisticated register-management methods).

### The interrupt-service routine as a C function (Figure 4.5)

C requires the ISR to be written as a **function** — but the compiler implements all C
functions as subroutines ending with **Return-from-subroutine**:

```c
void intserv() {
    *DISP_DATA = *KBD_DATA;   /* Transfer a character. */
}
```

Compiler-generated code for `intserv` (I/O addresses fit in 16 bits, so **Absolute
addressing with R0 = 0** is used):

```asm
<save registers>
LoadByte    R2, 0x4000(R0)
StoreByte   R2, 0x4010(R0)
<restore registers>
Return-from-subroutine
```

### The problem — an ISR needs Return-from-interrupt

An ISR must end with **Return-from-interrupt** (to restore PC and PS to their values at the
time of the interrupt). You could insert it:

```c
asm ("Return-from-interrupt");
```

giving:

```asm
<save registers>
LoadByte    R2, 0x4000(R0)
StoreByte   R2, 0x4010(R0)
Return-from-interrupt
<restore registers>          ; never executed — dead code after the return!
Return-from-subroutine
```

But the compiler **still appends** the register-restore code and Return-from-subroutine,
which now **never execute** — so registers (and critically the **stack pointer**) are
**not restored**. Because interrupts can occur anywhere, failing to restore a modified
register corrupts later execution, and failing to restore the **stack pointer corrupts the
stack frames** of nested subroutines.

### Two correct approaches

| Approach | How it works | Trade-off |
|----------|--------------|-----------|
| **Special `interrupt` keyword** | A C compiler recognizes `interrupt void intserv() {...}` and substitutes **Return-from-interrupt** for Return-from-subroutine, still saving/restoring registers properly. | Cleanest — but **not all C compilers provide it.** |
| **Assembly handler + linker** | Write the handler in assembly, **save the link register first** (the interrupt may follow a subroutine call), then call a C subroutine to do the work; on return, **restore the link register** and run Return-from-interrupt. | No special keyword needed in the high-level file. |

### The final C program (Figure 4.6)

Uses the **`interrupt` keyword** approach so the whole program fits in one C file. Note the
pointer **types**: I/O register pointers are **`char`** (they point to 8-bit registers);
**IVECT is `unsigned int`** because it points to a **4-byte interrupt vector**.

```c
#define IVECT       (volatile unsigned int *) 0x20
#define KBD_DATA    (volatile char *) 0x4000
#define KBD_CONT    (volatile char *) 0x4008
#define DISP_DATA   (volatile char *) 0x4010
#define DISP_STATUS (volatile char *) 0x4014

interrupt void intserv();                 /* Forward declaration. */

void main() {
    *KBD_CONT = 0x2;                      /* Enable keyboard interrupts (KIE=1). */
    *IVECT = (unsigned int) &intserv;     /* Set interrupt vector. */
    asm ("Subtract SP, SP, #4");          /* Save register R2. */
    asm ("Store R2, (SP)");
    asm ("Move R2, #0x2");
    asm ("MoveControl IENABLE, R2");      /* Processor recognizes kbd interrupts. */
    asm ("Move R2, #0x1");
    asm ("MoveControl PS, R2");           /* Enable interrupts in processor (IE=1). */
    asm ("Load R2, (SP)");                /* Restore register R2. */
    asm ("Add SP, SP, #4");
    while (1) { }                          /* Continuous loop. */
}

interrupt void intserv() {                /* Keyword → treat as interrupt routine. */
    *DISP_DATA = *KBD_DATA;               /* Transfer a character. */
    /* Compiler inserts Return-from-interrupt at end of function. */
}
```

> **Checkpoint:** Why can't a pointer reach the IENABLE and PS registers the way one reaches
> KBD_DATA? *(Memory-mapped I/O registers have memory addresses; processor control
> registers do not, so they must be accessed with embedded assembly `MoveControl`
> instructions.)*

---

## 13. Section 4.9 — The Operating System

Every task in this chapter is **facilitated by the operating system (OS)** — the key
software component responsible for **coordinating all activities** in a computer.

The OS consists of:

- **Essential routines that always reside in memory**, and
- Various **utility programs stored on disk**, loaded and executed when needed.

What the OS manages: the **processing, memory, and I/O resources** during program
execution. It **interprets user commands, assigns memory and disk space, moves information
between memory and disk, and handles I/O**. It makes the editor, compiler, assembler, and
linker usable. The **loader is normally part of the OS**, invoked when the user runs an
application program.

> **Checkpoint:** Name three categories of resource the OS manages. *(Processing/processor,
> memory, and input/output resources.)*

---

## 14. Section 4.9.1 — The Boot-strapping Process

The OS is large and complex, and all of it — **including the memory-resident portion** — is
normally stored on disk. **Boot-strapping** is the process that loads the memory-resident
portion into memory so it can begin executing and take control.

The sequence:

1. When the computer is **turned on**, the processor **fetches the first instruction from a
   predetermined location.**
2. That location must be in a **permanent (non-volatile) portion of memory** that retains
   its contents when powered off.
3. A **small program** there enables the processor to **transfer progressively larger parts
   of the OS from disk** into the non-permanent memory.
4. Each program in the sequence transfers **more of the OS** and performs necessary
   **initialization of memory and I/O devices.**
5. Ultimately the **loader and the command-processing portion** of the OS are in memory,
   enabling the OS to accept commands to load and run application programs.

> **Checkpoint:** Why must the very first boot instruction live in non-volatile memory?
> *(Because volatile memory loses its contents at power-off; the first instruction must be
> present the instant the machine turns on, before any OS is loaded.)*

---

## 15. Section 4.9.2 — Managing Execution of Application Programs

### Running one program

Consider a computer with a processor, keyboard, display, disk, and printer. To run a program:

1. The user enters a command; the **loader transfers the file into memory** and execution
   starts.
2. Suppose the program must **read a data file from disk, compute on it, and print results.**
3. When it needs the data file, it **requests the OS** to transfer the file from disk to
   memory. The OS does so, then **passes control back** to the program.
4. The program computes; when ready to print, it **again requests the OS**, and an OS
   routine prints the results.

Execution control thus **passes back and forth** between the application program and OS
routines, which **share the processor.** The text's **time-line (Figure 4.7)** shows this:

```text
 t0───t1 : loader transfers object program disk → memory
 t1      : OS passes control to the program (it runs until it needs disk data)
 t2───t3 : OS transfers the required data from disk
 t4───t5 : OS prints the results from memory
```

### Running several programs — multitasking

Resources are used **more efficiently** with several programs. Notice the disk and processor
are **idle during most of t4–t5** (while printing). If the user can start another program
during that idle time, the OS can **load and run it while the printer prints** — giving
**concurrent processing** of the two programs when they don't compete for the same resource.

Managing this concurrent execution to make best use of all resources is called
**multiprogramming** or **multitasking**: the processor executes several programs in an
**interleaved time order**, overlapped with work done by different I/O devices.

> **Checkpoint:** What makes multitasking able to improve efficiency? *(While one program
> waits on a slow resource such as the printer or disk, the otherwise-idle processor can run
> another program, overlapping computation with I/O.)*

---

## 16. Section 4.9.3 — Use of Interrupts in Operating Systems

The OS makes **extensive use of interrupts** to perform I/O and to control programs:
assigning priorities, switching between programs, terminating programs, implementing
security/protection, and coordinating I/O.

Key principles:

- The OS **incorporates the interrupt-service routines** for every device capable of
  raising interrupts.
- **Application programs do not perform I/O directly.** When a program needs I/O, it points
  to the data and **asks the OS**, usually via a **library subroutine that raises a software
  interrupt** to enter the OS.
- The OS **suspends** the requesting program, **initiates the I/O**, and when the I/O
  completes (signaled by a **hardware interrupt**) it lets the suspended program **resume.**
  Control passes back and forth using **software interrupts.**

To offer many services, a processor may have **several Software-interrupt instructions**
(each with its own vector), **or** a single one with an **immediate operand** selecting the
service.

**Termination:** executing an appropriate Software-interrupt at the end of a program tells
the OS to take control and finish termination. Using the **header** info (starting location
and length), the OS **recovers the program's memory space** for reuse.

### Time slicing

A common multitasking technique is **time slicing**: each program runs for a short period
**τ (a time slice)**, then another runs for its slice, and so on. τ is set by a
continuously running **hardware timer** that generates an interrupt every τ seconds.

### Process states

A **process** = a program plus the information describing its current execution state. A
process is in one of **three states**:

| State | Meaning |
|-------|---------|
| **Running** | Currently being executed. |
| **Runnable** | Ready and waiting to be selected for execution. |
| **Blocked** | Not ready to resume — e.g. waiting for an I/O operation it requested. |

### The OS routines (Figure 4.8)

| Routine | Role |
|---------|------|
| **OSINIT** | Initialization: sets the interrupt-vector locations to the starting addresses of the ISRs (e.g. **timer → SCHEDULER**, **software → OSSERVICES**, **I/O → IODATA**). |
| **OSSERVICES** | Examines the stack/registers to determine the requested operation, then calls the appropriate routine. |
| **SCHEDULER** | Saves the state of the current process, selects another **Runnable** process, restores its state, and does Return-from-interrupt. |
| **IOINIT** | Sets requesting process to **Blocked**, initializes buffer pointer and counter, calls the **device driver** to initialize it and enable interrupts, returns. |
| **IODATA** | Polls devices to find the interrupt source, calls the right driver; if **END = 1**, sets the I/O-blocked process back to **Runnable**; returns from interrupt. |
| **KBDINIT / KBDDATA** | The **keyboard device driver**: KBDINIT enables interrupts; KBDDATA checks status, transfers a character, and if it is a Carriage Return sets **End = 1** and disables interrupts. |

### A context switch, step by step

Suppose program **A** is Running during a time slice:

1. At the slice's end, the **timer interrupts** A and starts **SCHEDULER.**
2. SCHEDULER **saves all of A's state** — registers, including the **program counter**
   (where to resume) and the **processor status register** (program state).
3. SCHEDULER **selects a Runnable program B**, restores B's saved state (including PC and
   PS), and executes **Return-from-interrupt.**
4. B runs for τ seconds, then the timer interrupts again and another **context switch**
   occurs.

### An I/O request, step by step

Suppose A needs to read a line from the keyboard:

1. Instead of doing I/O itself, A **passes info via the stack or registers** (operation,
   device, buffer address) and raises a **software interrupt.**
2. The vector points to **OSSERVICES**, which inspects the info and calls **IOINIT.**
3. IOINIT sets A to **Blocked**, prepares pointers/counts, and calls the keyboard driver
   **KBDINIT**, which enables interrupts in the interface and returns.
4. Back in OSSERVICES, **SCHEDULER** picks another Runnable program (not A — it is Blocked).
   Its Return-from-interrupt **re-enables processor interrupts** (via the restored PS).
5. When a key is pressed, the keyboard interrupt vector points to **IODATA**, which **polls**
   to find the source and calls **KBDDATA** to transfer one character. On a Carriage Return,
   KBDDATA sets **END = 1**, so IODATA changes A from **Blocked → Runnable** for a future
   slice.

**Device driver** = a self-contained module encapsulating all software for a particular I/O
device; it can be easily **added to or deleted from** the OS.

> **Checkpoint:** What are the three process states, and which transition does a completed
> keyboard read trigger? *(Running, Runnable, Blocked; completing the requested I/O moves the
> process from Blocked to Runnable.)*

---

## 17. Utility Program Reference Card

| Utility | Reads | Produces | Core job |
|---------|-------|----------|----------|
| **Text editor** | keystrokes | source file on disk | create/save source |
| **Assembler** | assembly source | object file (+ symbol table, external/exported lists, header) | assembly → machine code; two passes resolve forward refs |
| **Loader** | object file + header | program in memory, PC set to START | copy to memory and start |
| **Linker** | object files + libraries | one complete object program | resolve external references, assign absolute addresses |
| **Archiver** | object files | library file | bundle reusable subroutines |
| **Compiler** | high-level source (C) | assembly file, then invokes assembler | high-level → assembly, manages stack frames, may optimize |
| **Debugger** | running object program | — | pause via trace mode / breakpoints, inspect state |
| **Operating system** | user commands + interrupts | coordinated execution | manage processor, memory, I/O; multitasking via time slicing |

### Debugger mechanisms

| Mechanism | How it stops the program | Speed | Implementation |
|-----------|--------------------------|-------|----------------|
| **Trace mode** | interrupt after **every** instruction | slow | special processor mode; auto-disabled in debugger, re-enabled on return |
| **Breakpoint** | interrupt only at **chosen** points | full speed until the point | **Trap / Software-interrupt** replaces the target instruction |

---

## 18. Glossary

**Toolchain utilities**
- **Text editor** — utility to type and save a source program file.
- **Assembler** — translates assembly source into an object program of machine
  instructions and binary data.
- **Two-pass assembler** — scans the source twice; pass 1 builds the symbol table (resolving
  forward references), pass 2 substitutes values.
- **Loader** — transfers an object program from disk into memory and starts it; usually part
  of the OS.
- **Linker** — combines separate object files and libraries into one object program,
  resolving external references.
- **Archiver** — creates a library file from object files.
- **Compiler** — translates a high-level language into assembly, then invokes the assembler.
- **Optimizing compiler** — a compiler that improves efficiency, e.g. by reordering
  instructions or keeping loop counters in registers.
- **Debugger** — utility to stop a running program and inspect registers and memory to find
  bugs.

**Files and structures**
- **Source program / source file** — the symbolic program as written by the programmer.
- **Object program / object file** — machine instructions and binary data produced by the
  assembler (may contain unresolved external references until linked).
- **Header** — info at the front of an object file giving the program's length, load address,
  and START address.
- **Symbol table** — assembler's map of names (EQU constants and labels) to numeric values.
- **Library file** — a collection of object files of reusable subroutines.
- **Memory map** — the linker's plan of where each object file sits in memory.

**Names and references**
- **EQU directive** — defines a name representing a constant.
- **Address label** — a name marking a branch target, subroutine entry, or data location;
  valued by position.
- **ORIGIN directive** — fixes addresses explicitly in a source file.
- **External reference / external name** — a label defined in another source file.
- **Exported name** — a label a source file makes available to others.
- **Forward reference** — use of a name before it is defined (e.g. a forward branch).

**High-level ↔ low-level interaction**
- **volatile** — C qualifier telling the compiler not to optimize away accesses (and often to
  bypass the cache) because the location changes externally.
- **asm directive** — inserts a verbatim assembly instruction into compiled C code.
- **MoveControl** — instruction to access processor control registers (PS, IENABLE), which
  have no memory address.
- **interrupt keyword** — a C compiler feature that makes a function end with
  Return-from-interrupt.
- **Return-from-interrupt / Return-from-subroutine** — instructions ending an ISR vs. an
  ordinary function.

**Debugging**
- **Trace mode** — processor mode causing an interrupt after every instruction.
- **Breakpoint** — an interrupt placed at a chosen instruction via a Trap/Software-interrupt.
- **Trap / Software-interrupt** — instruction producing the same actions as a
  hardware-interrupt request.

**Operating system**
- **Operating system (OS)** — software coordinating all computer activities and resources.
- **Boot-strapping** — process of loading the memory-resident OS from disk at power-on.
- **Multiprogramming / multitasking** — concurrent interleaved execution of several programs.
- **Time slice (τ)** — the fixed period each program runs, timed by a hardware timer.
- **Process** — a program plus its current execution-state information.
- **Running / Runnable / Blocked** — the three process states.
- **Context switch** — saving one process's state and restoring another's.
- **Device driver** — self-contained OS module handling one I/O device.
- **OSINIT, OSSERVICES, SCHEDULER, IOINIT, IODATA, KBDINIT, KBDDATA** — the example OS
  routines of Figure 4.8.

---

## 19. Self-Test Questions

Try these without looking back. Answers in the sections cited.

1. List the toolchain utilities a C program passes through, in order, from typing to
   execution. *(§1, §7)*
2. What does the assembler store in the symbol table, and what does it do with it? *(§2)*
3. Why does a forward branch force a two-pass assembler, and what does each pass do? *(§3)*
4. What two facts must the loader know to place a program, and where are they stored? *(§4)*
5. What is an external reference, and how does the linker resolve it? *(§5)*
6. What is the difference between using ORIGIN directives and letting the linker choose
   addresses? *(§5)*
7. What tool builds a library, and does the linker include the whole library? *(§6)*
8. The compiler automates a tedious assembly task highlighted in the text — which one? *(§7)*
9. Explain the loop-counter optimization an optimizing compiler performs. *(§8)*
10. Why must a C pointer to KBD_STATUS be declared `volatile`? *(§11)*
11. Why can't a pointer access the PS or IENABLE registers, and what is used instead? *(§12)*
12. What goes wrong if you just insert `asm("Return-from-interrupt")` into a normal C
    function used as an ISR? *(§12)*
13. Name the two correct ways to support an ISR written in a high-level language. *(§12)*
14. Compare trace mode and breakpoints — how does each stop the program, and which runs at
    full speed? *(§10)*
15. What is boot-strapping, and why must the first instruction be in non-volatile memory?
    *(§14)*
16. Define the three process states and give the transition caused by completing a requested
    I/O. *(§16)*

---

*End of study guide. Open this file in any Markdown viewer (VS Code, Obsidian, Typora,
GitHub) to read it with formatting, or export to PDF from there.*
