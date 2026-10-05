# Chapter 3 — End-of-Chapter Problems: Worked Answers (3.1 – 3.26)

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Problems:** pages 126–128.

> **Honest note on these answers.** This textbook does **not** ship an official solutions
> manual inside the book, so the answers below are **my worked solutions**, written to match
> the book's exact conventions (register map Fig 3.3, timer Fig 3.14, seven-segment Fig
> 3.17, the lookup-table idiom, and the RISC/CISC instruction style from Figs 3.4, 3.5,
> 3.8, 3.12, 3.13, 3.18, 3.19).
>
> - **Conceptual problems** (3.1, 3.3, 3.4, 3.6, 3.7, 3.8, 3.11, 3.12) — these are
>   definitive; the reasoning is grounded directly in the chapter text.
> - **Analysis problem** (3.5) — full derivation shown; plug in your course's rounding.
> - **Programming problems** (3.2, 3.9, 3.10, 3.13–3.26) — these are *reference
>   implementations*. In assembly there are many correct variants; the logic and structure
>   are what matter. Treat them as a model, verify against your instructor's assembler
>   syntax, and adapt labels/addresses as needed.
>
> Difficulty tags from the book: [E]=Easy, [M]=Medium, [D]=Difficult.

**Reference register maps used throughout** (Figure 3.3 / 3.14):

| Register | Addr | Key bits |
|----------|------|----------|
| KBD_DATA | 0x4000 | 8-bit ASCII |
| KBD_STATUS | 0x4004 | KIN=bit1, KIRQ=bit0 |
| KBD_CONT | 0x4008 | KIE=bit1 |
| DISP_DATA | 0x4010 | 8-bit char |
| DISP_STATUS | 0x4014 | DOUT=bit2, DIRQ=bit1 |
| DISP_CONT | 0x4018 | DIE=bit2 |
| TIM_STATUS | 0x4020 | TON=bit2, ZERO=bit1, TIRQ=bit0 |
| TIM_CONT | 0x4024 | UP=bit3, FREE=bit2, RUN=bit1, TIE=bit0 |
| TIM_INIT | 0x4028 | initial count |
| TIM_COUNT | 0x402C | current count |

ASCII reminders: `'0'`=0x30 … `'9'`=0x39; `' '`(space)=0x20; CR=0x0D; NUL=0x00.

---

## 3.1 [E] Why clear the input status bit as soon as the data register is read?

**Answer.** The status flag (KIN) means "a *new, unread* character is waiting in
KBD_DATA." Clearing KIN automatically the moment the processor reads KBD_DATA prevents the
**same character from being read twice**.

- If KIN stayed 1 after the read, the polling loop (`wait until KIN=1`) would immediately
  see it still set and read KBD_DATA **again**, duplicating the character.
- Clearing it means KIN only goes back to 1 when the hardware places a *genuinely new*
  character in the register. This gives a clean one-flag-per-character handshake and keeps
  the software and hardware synchronized. It also lets the interface drop a pending
  interrupt request once the data has been consumed.

---

## 3.2 [E] Display 10 bytes from LOC in hex, two chars per byte, space-separated

**Answer (RISC-style).** Extend the Example 3.4 idea: for each of 10 bytes, output its high
nibble, its low nibble, then a space. Reuse the hex→ASCII `TABLE`.

```asm
        Move        R2, #LOC        ; R2 → source bytes
        Move        R3, #10         ; byte counter
BYTELOOP:
        LoadByte    R6, (R2)        ; R6 = current byte
        ; --- high nibble ---
        And         R5, R6, #0xF0   ; keep high 4 bits
        RotateR     R5, R5, #4      ; move them to the low position (value 0–15)
        LoadByte    R7, TABLE(R5)   ; ASCII of high nibble
        Call        PUTCHAR         ; display R7
        ; --- low nibble ---
        And         R5, R6, #0x0F   ; keep low 4 bits
        LoadByte    R7, TABLE(R5)
        Call        PUTCHAR
        ; --- separating space ---
        Move        R7, #0x20       ; ASCII space
        Call        PUTCHAR
        Add         R2, R2, #1      ; next byte
        Subtract    R3, R3, #1
        Branch_if_[R3]>0 BYTELOOP
        next instruction

; PUTCHAR: polls DOUT and sends the char in R7
PUTCHAR:
        LoadByte    R5, DISP_STATUS
        And         R5, R5, #4      ; DOUT = bit 2
        Branch_if_[R5]=0 PUTCHAR
        StoreByte   R7, DISP_DATA
        Return

        ORIGIN   0x1000
TABLE:  DATABYTE 0x30,0x31,0x32,0x33
        DATABYTE 0x34,0x35,0x36,0x37
        DATABYTE 0x38,0x39,0x41,0x42
        DATABYTE 0x43,0x44,0x45,0x46
```

Output looks like: `3A 05 FF 10 ...` (10 byte-pairs, each separated by a space). If your
assembler lacks `RotateR`, substitute a logical shift-right by 4.

---

## 3.3 [E] Difference between a subroutine and an interrupt-service routine (ISR)

**Answer.**

| | Subroutine | Interrupt-Service Routine |
|--|-----------|---------------------------|
| **How invoked** | *Explicitly* by the program (a `Call`), at a point the programmer chose. | *Asynchronously* by a hardware event, at an unpredictable moment. |
| **Relationship to current code** | Performs a function the caller *wants*; register changes are *anticipated*. | May be *unrelated* to the interrupted program; it must not corrupt it. |
| **Context saving** | Normal calling convention; the compiler/programmer knows what to save. | Hardware auto-saves PC & PS; the ISR must save/restore *any* extra registers it touches. |
| **Return** | `Return` — restores PC. | `Return-from-interrupt` — restores PC **and** PS (re-enabling interrupts). |
| **Timing** | Deterministic. | Can occur between any two instructions. |

Core idea: a subroutine is a *planned* detour; an ISR is an *unplanned* one triggered by
the outside world, so it carries extra responsibility to leave the interrupted program
exactly as it found it.

---

## 3.4 [E] Why `And ...,#2` in Fig 3.4 but `TestBit ...,#1` in Fig 3.5 for the same KIN flag?

**Answer.** They look different but test the **same bit (KIN = bit 1)**; the difference is
how each instruction *names* a bit.

- **`And R4, R4, #2`** (RISC) uses a **bit mask**. To select bit position 1 you need a mask
  with a 1 in position 1, i.e. the *value* `2` (`00000010`). The operand is "the number
  whose set bit marks the position."
- **`TestBit KBD_STATUS, #1`** (CISC) takes a **bit index**. `#1` literally means "bit
  number 1." The operand is "the position, counted from 0."

So `#2` (mask for bit 1) and `#1` (index of bit 1) refer to the identical physical flag;
the instructions just use different conventions — a mask value vs. a position number.

---

## 3.5 [D] Polling vs interrupt for 20 terminals — timing analysis

Given: 20 terminals; max rate `c` chars/sec/terminal; average rate `rc` (r ≤ 1);
POLL (all 20 devices) = 800 ns; one interrupt = 200 ns. c = 100 chars/s.

### Routines (sketch)

```asm
; (a) POLL — called every T seconds by PROG
POLL:   Move R2, #1              ; terminal index n = 1..20
PLOOP:  LoadByte R4, STATUS(R2)  ; status of terminal n
        And R4, R4, #KIN_MASK
        Branch_if_[R4]=0 SKIP
        LoadByte R5, DATA(R2)    ; read char (clears its KIN)
        Load R6, PNTR(R2)        ; that terminal's buffer pointer
        StoreByte R5, (R6)
        Add R6, R6, #1
        Store R6, PNTR(R2)
SKIP:   Add R2, R2, #1
        Branch_if_[R2]<=20 PLOOP
        Return

; (b) INTERRUPT — fires when ANY terminal has a char
INTERRUPT:
        ; find first terminal with KIN=1, transfer its char, update its pointer
        ; (same body as the loop above, but stops after servicing the first ready one)
        Return-from-interrupt
```

### Max T for method (a) so no characters are lost

A terminal at the **maximum** rate produces a new character every `1/c` seconds. Its data
register holds only **one** character, so POLL must visit it before the *next* character
overwrites it. Therefore:

> **T_max = 1/c.**  For c = 100 → **T_max = 10 ms.**

(If any terminal could run faster than being polled once per 1/c s, its single-byte buffer
would be overwritten and a character lost.)

### Equivalent for method (b)

Interrupts respond essentially immediately (within one interrupt latency), so a character is
collected the moment it arrives, as long as the aggregate interrupt load doesn't saturate
the CPU. The "equivalent limit" is throughput: the system must finish servicing interrupts
faster than they arrive. Max aggregate char rate = `20 × c`; each interrupt costs 200 ns, so
required service time per second = `20c × 200 ns`. For c = 100: `2000 × 200 ns = 400 µs/s` =
0.04 % — far below saturation, so **no loss** at any realistic r. The binding constraint is
simply that interrupt latency ≪ 1/c (10 ms), which is easily met.

### Percentage of time servicing terminals

**Method (a), polling every T = 1/c:** POLL runs once per 10 ms and costs 800 ns each time,
*regardless of r* (it checks all 20 every time):

> fraction_a = 800 ns / 10 ms = **0.008 %**… but to *guarantee* no loss you poll at the
> max rate independent of r, so **method (a) overhead ≈ 0.008 % for all r** (it does the
> same work whether terminals are busy or idle).

Wait — more precisely, POLL cost is fixed per invocation and you must invoke every 1/c
seconds: overhead = 800 ns × c = 800 ns × 100 = 80 µs/s = **0.008 %**, constant in r.

**Method (b), interrupt-driven:** work is proportional to the *actual* characters arriving.
Chars/sec across all terminals = `20 × r × c`; each costs 200 ns:

> fraction_b = 20 · r · c · 200 ns

For c = 100: fraction_b = 20 · r · 100 · 200 ns = `r × 400 µs/s` = `r × 0.04 %`.

| r | Method (a) overhead | Method (b) overhead |
|---|--------------------:|--------------------:|
| 0.01 | 0.008 % | 0.0004 % |
| 0.1  | 0.008 % | 0.004 % |
| 0.5  | 0.008 % | 0.02 % |
| 1.0  | 0.008 % | 0.04 % |

**Interpretation.** Interrupts win decisively when terminals are mostly idle (low r):
overhead scales with real traffic. Polling's cost is **fixed** (you pay to check everyone
even when nothing happened). Only as r → 1 (everyone typing at full speed) do the two
converge, and even then interrupt overhead (0.04 %) exceeds polling (0.008 %) because of
the per-character 200 ns cost vs. one batched 800 ns poll of all 20. **Takeaway:** polling
is efficient under heavy uniform load; interrupts are efficient under bursty/light load.

---

## 3.6 [E] Why set the PS interrupt-enable bit *last* in START? Does earlier order matter?

**Answer.** Setting **IE in PS last** is deliberate. The PS.IE bit is the **global master
switch**. If it were turned on *before* the rest of the initialization (buffer pointer PNTR,
EOL flag, device KIE, IENABLE), then a keystroke arriving mid-setup could fire the ISR while
the data structures it relies on (e.g. PNTR) are not yet valid → crash or corrupt data. By
enabling global interrupts **only after everything else is ready**, you guarantee the ISR
never runs against half-initialized state.

**Do earlier operations' order matter?** Among the *earlier* steps, order is largely
irrelevant **because interrupts are still globally disabled** — nothing can preempt the
setup. You can initialize PNTR, EOL, KIE, and IENABLE in any order; none takes effect in a
way that triggers the ISR until PS.IE is finally set. (The one constraint: PS.IE must be
strictly last.)

---

## 3.7 [E] "Only one request handled per entry into ILOC" — true or false?

**Answer: True (for the Figure 3.9 single-device keyboard ISR).** On entering ILOC the
processor clears IE (interrupts disabled during the ISR). The ISR services **one**
character (reads KBD_DATA once, which clears KIN/KIRQ for that one keypress) and then
executes Return-from-interrupt, which re-enables interrupts. If other requests are pending,
they cause a **new, separate entry** into the ISR afterward — one entry handles one request.

Caveat: a more general handler could *loop* internally over IPENDING to service several
devices per entry; but the Fig 3.9 structure as written handles exactly one request per
invocation, so for that program the statement is **true**.

---

## 3.8 [E] Check for zero divisor in the user program vs. let a divide-by-zero exception occur

**Answer — trade-offs both ways.**

*In favor of checking in the user program (explicit guard before each divide):*
- **Faster in the common case**: a single compare+branch is far cheaper than taking an
  exception (context save, kernel entry, handler, return).
- **Local control**: the program can respond gracefully in context (substitute a default,
  skip, warn) without OS involvement.
- **Deterministic**: no dependence on OS exception policy.

*In favor of letting the exception fire:*
- **Less code / no clutter**: you don't repeat a guard before every division.
- **Centralized handling**: the OS handles *all* divide-by-zeros uniformly, including ones
  you forgot to guard — a safety net.
- **No overhead when divisors are (almost) never zero**: you pay nothing on the normal path;
  the cost is only incurred on the rare actual error.

**Bottom line:** guard explicitly when zero divisors are *plausible/frequent* and you want
graceful local recovery; rely on the exception when they're *rare* and you'd rather keep the
hot path clean and lean on the OS as a backstop.

---

## 3.9 [M] Display a 16-bit BINARY pattern as a string of 0s and 1s (RISC)

**Answer.** 16 bits → 16 characters, each `'0'` or `'1'`. Peel bits from the **top** using
rotate-left-by-1, mask the lowest bit, convert to ASCII by **adding 0x30** (`'0'`), display.

```asm
        Load        R2, BINARY      ; the 16-bit pattern (in low 16 bits)
        Move        R3, #16         ; bit counter
BLOOP:  RotateL     R2, R2, #1      ; bring next-highest bit to position 0
        And         R5, R2, #1      ; R5 = that bit (0 or 1)
        Add         R5, R5, #0x30   ; convert to ASCII '0' or '1'
        ; --- display R5 (poll DOUT) ---
WAIT:   LoadByte    R6, DISP_STATUS
        And         R6, R6, #4      ; DOUT = bit 2
        Branch_if_[R6]=0 WAIT
        StoreByte   R5, DISP_DATA
        Subtract    R3, R3, #1
        Branch_if_[R3]>0 BLOOP
        next instruction
```

Note: because bits are only `0`/`1`, we skip the lookup table and just `Add #0x30` (`'0'` and
`'1'` *are* contiguous in ASCII, unlike the hex-letter case). Rotate-left-by-1 sixteen times
emits the bits most-significant-first.

---

## 3.10 [M] CISC-style version of 3.9

```asm
        Move        R2, BINARY
        Move        R3, #16
BLOOP:  RotateL     R2, #1
        Move        R5, R2
        And         R5, #1
        Add         R5, #0x30       ; ASCII '0'/'1'
WAIT:   TestBit     DISP_STATUS, #2 ; DOUT bit 2
        Branch=0    WAIT
        MoveByte    DISP_DATA, R5   ; send char
        Subtract    R3, #1
        Branch>0    BLOOP
        next instruction
```

CISC shortens it with `TestBit` (direct status test) and `MoveByte` to the memory-mapped
DISP_DATA.

---

## 3.11 [E] Modify Fig 3.18 (RISC) if TABLE address is 0x10100

**Answer.** In Fig 3.18 the table is reached by `LoadByte R5, TABLE(R2)` with `ORIGIN
0x1000`. If TABLE now lives at **0x10100**, the index addressing `TABLE(R2)` still works
*provided the assembler can encode a 0x10100 displacement*. On a RISC machine the index
offset field is limited, so you must **load the base address into a register** and index
from there:

```asm
        Move        R6, #0x10100    ; load full table base (may need OrHigh/Or for 32-bit)
        Add         R6, R6, R2      ; R6 = TABLE + digit
        LoadByte    R5, (R6)        ; get the 7-segment pattern
        StoreByte   R5, SEVEN
```

If the immediate 0x10100 doesn't fit one instruction, build it with the two-instruction
`OrHigh`/`Or` idiom from Section 2.9. Also change `ORIGIN 0x1000` → `ORIGIN 0x10100`.

---

## 3.12 [E] Modify Fig 3.19 (CISC) if TABLE address is 0x10100

**Answer.** CISC addressing modes carry larger displacements, so often you can simply keep
`MoveByte SEVEN, TABLE(R2)` and just change the directive `ORIGIN 0x1000` → `ORIGIN
0x10100` (the assembler fills the new absolute TABLE address into the indexed operand). If
the particular CISC encoding can't hold a 0x10100 displacement, fall back to loading the
base into a register as in 3.11:

```asm
        Move        R6, #0x10100
        Add         R6, R6, R2
        MoveByte    SEVEN, (R6)
```

---

## 3.13 [M] Flash digits 0,1,…,9,0,… one per second on a 7-segment display (RISC)

**Answer.** Use the timer (Fig 3.14) to generate a 1-second interrupt; an ISR advances the
digit and writes its 7-segment pattern (from the Fig 3.18 TABLE) to SEVEN. 1 s at 100 MHz =
`100,000,000` counts = `0x05F5E100`.

```asm
SEVEN   EQU 0x4030
; --- Interrupt handler: fires every 1 s ---
TISR:   Subtract    SP, SP, #4
        Store       R2, (SP)
        LoadByte    R2, TIM_STATUS       ; clear TIRQ/ZERO
        Load        R3, DIGIT            ; current digit (0..9)
        LoadByte    R4, STABLE(R3)       ; 7-seg pattern for that digit
        StoreByte   R4, SEVEN            ; display it
        Add         R3, R3, #1           ; next digit
        Move        R5, #10
        Branch_if_[R3]<[R5] NOWRAP
        Move        R3, #0               ; wrap 10 → 0
NOWRAP: Store       R3, DIGIT
        Load        R2, (SP)
        Add         SP, SP, #4
        Return-from-interrupt

; --- Main: program the timer, enable its interrupt ---
START:  Move        R2, #0               ; start at digit 0
        Store       R2, DIGIT
        OrHigh      R2, R0, #0x05F5       ; initial count = 100,000,000
        Or          R2, R2, #0xE100
        Store       R2, TIM_INIT
        Move        R2, #7               ; FREE=1,RUN=1,TIE=1 (bits3?) → free-run+interrupt
        StoreByte   R2, TIM_CONT
        MoveControl R2, IENABLE
        Or          R2, R2, #8           ; enable timer (bit 3) in IENABLE
        MoveControl IENABLE, R2
        MoveControl R2, PS
        Or          R2, R2, #1           ; global IE
        MoveControl PS, R2
LOOP:   Branch      LOOP                 ; idle; ISR does the work

        ORIGIN 0x1000
STABLE: DATABYTE 0x7E,0x30,0x6D,0x79     ; 7-seg patterns 0..3  (from Fig 3.18)
        DATABYTE 0x33,0x5B,0x5F,0x70     ; 4..7
        DATABYTE 0x7F,0x7B               ; 8,9
```

> On TIM_CONT: set FREE (auto-reload), RUN (count), TIE (interrupt enable). The exact mask
> depends on the Fig 3.14 bit positions (UP=3,FREE=2,RUN=1,TIE=0); `#7` sets FREE+RUN+TIE
> and leaves UP=0 (count down), matching Example 3.5's convention.

---

## 3.14 [M] CISC-style version of 3.13

Same logic; CISC collapses the ISR using memory operands, autoincrement, and `MoveByte`:

```asm
TISR:   Move        -(SP), R2
        MoveByte    R2, TIM_STATUS       ; clear flags
        Move        R3, DIGIT
        MoveByte    SEVEN, STABLE(R3)    ; look up + display in one move
        Add         R3, #1
        CompareByte R3, #10
        Branch<     NOWRAP
        Move        R3, #0
NOWRAP: Move        DIGIT, R3
        Move        R2, (SP)+
        Return-from-interrupt

START:  Move        DIGIT, #0
        Move        TIM_INIT, #0x05F5E100
        MoveByte    TIM_CONT, #7
        MoveControl R2, IENABLE
        Or          R2, #8
        MoveControl IENABLE, R2
        MoveControl R2, PS
        Or          R2, #1
        MoveControl PS, R2
LOOP:   Branch      LOOP
        ORIGIN 0x1000
STABLE: DATABYTE 0x7E,0x30,0x6D,0x79,0x33,0x5B,0x5F,0x70,0x7F,0x7B
```

---

## 3.15 [D] Flash 00,01,…,98,99,00,… one number per second on TWO 7-segment displays (RISC)

**Answer.** Two displays: tens digit → SEVEN_H (say 0x4030), units digit → SEVEN_L (0x4034).
Keep a counter 0–99; each second split it into tens/units, display both.

```asm
SEVEN_H EQU 0x4030          ; tens
SEVEN_L EQU 0x4034          ; units
TISR:   Subtract SP,SP,#4
        Store    R2,(SP)
        LoadByte R2, TIM_STATUS          ; clear flags
        Load     R3, COUNT               ; 0..99
        ; split into tens (R4) and units (R5)
        Move     R6, #10
        Divide   R4, R3, R6              ; R4 = R3 / 10  (tens)   [or repeated subtraction]
        Multiply R7, R4, R6
        Subtract R5, R3, R7              ; R5 = R3 - 10*tens (units)
        LoadByte R8, STABLE(R4)
        StoreByte R8, SEVEN_H
        LoadByte R8, STABLE(R5)
        StoreByte R8, SEVEN_L
        Add      R3, R3, #1
        Move     R6, #100
        Branch_if_[R3]<[R6] NW
        Move     R3, #0
NW:     Store    R3, COUNT
        Load     R2,(SP)
        Add      SP,SP,#4
        Return-from-interrupt
; Main: identical timer setup to 3.13 (1-second interrupt, STABLE as before)
```

If your ISA lacks `Divide`/`Multiply`, compute tens by repeated subtraction of 10 (count how
many times you can subtract 10 before going negative). The timer setup block is identical to
Problem 3.13.

---

## 3.16 [D] CISC-style version of 3.15

Same algorithm; use CISC memory operands and `MoveByte SEVEN_x, STABLE(Rn)`; replace
Divide/Multiply with a repeated-subtraction loop if needed. Timer init as in 3.14.

---

## 3.17 [D] Wall-clock HH:MM on four 7-segment displays (RISC)

**Answer.** Maintain seconds→minutes→hours counters in memory, driven by a 1-second timer
interrupt. Four displays: H_tens, H_units, M_tens, M_units.

```asm
; memory: SEC, MIN, HOUR (bytes)
TISR:   ; (save regs; clear TIM_STATUS)
        Load R3, SEC
        Add  R3, R3, #1
        Move R6, #60
        Branch_if_[R3]<[R6] WR_SEC       ; <60 → just store seconds
        Move R3, #0                      ; sec wrap
        Load R4, MIN
        Add  R4, R4, #1
        Branch_if_[R4]<[R6] WR_MIN       ; <60 → store minutes
        Move R4, #0                      ; min wrap
        Load R5, HOUR
        Add  R5, R5, #1
        Move R7, #24
        Branch_if_[R5]<[R7] WR_HOUR
        Move R5, #0                      ; hour wrap at 24
WR_HOUR:Store R5, HOUR
WR_MIN: Store R4, MIN
WR_SEC: Store R3, SEC
        ; --- refresh the 4 displays from HOUR and MIN (split each into tens/units,
        ;     look up STABLE, StoreByte to the 4 SEVEN_x addresses) ---
        ; (restore regs) Return-from-interrupt
; Main: timer 1-second interrupt setup as in 3.13
```

Structure: a **cascade of mod-counters** (60 s → 60 min → 24 h). Each second the ISR bumps
seconds; on overflow it cascades to minutes, then hours, with wraps at 60/60/24. Display
refresh = the two-digit split from Problem 3.15 applied to HOUR and MIN.

---

## 3.18 [D] CISC-style version of 3.17

Same cascade logic; CISC does the mod-counters directly on memory operands
(`Add MIN, #1`, `CompareByte MIN, #60`, …) and uses `MoveByte SEVEN_x, STABLE(Rn)` for the
four displays. Timer init as in 3.14.

---

## 3.19 [M] Read the user's name, then display it backwards (RISC)

**Answer.** Three phases: (1) print a prompt, (2) read keystrokes into a buffer until CR,
remembering the length, (3) print a message, then walk the buffer **backwards** to the
display.

```asm
        ; --- Phase 1: print PROMPT (NUL-terminated) ---
        Move    R2, #PROMPT
        Call    PUTSTR
        ; --- Phase 2: read name into NAME until CR ---
        Move    R4, #NAME
READ:   LoadByte R5, KBD_STATUS
        And      R5, R5, #2          ; KIN bit 1
        Branch_if_[R5]=0 READ
        LoadByte R6, KBD_DATA        ; read char (clears KIN)
        Move     R7, #0x0D           ; CR?
        Branch_if_[R6]=[R7] DONEREAD
        StoreByte R6, (R4)           ; store char
        Add      R4, R4, #1
        Branch   READ
DONEREAD:
        ; R4 now points one past the last char; remember end
        ; --- Phase 3: print MSG then NAME reversed ---
        Move    R2, #MSG
        Call    PUTSTR
REV:    Subtract R4, R4, #1          ; step back
        Move     R8, #NAME
        Branch_if_[R4]<[R8] FIN      ; passed the start → finished
        LoadByte R7, (R4)
        Call     PUTCHAR             ; (poll DOUT, send R7)
        Branch   REV
FIN:    next instruction
; PUTSTR: send NUL-terminated string at R2.  PUTCHAR: poll DOUT then send R7.
```

Key idea: record where the name **ends**, then decrement the pointer from end back to
`NAME`, emitting each character — that reverses the order.

---

## 3.20 [M] CISC-style version of 3.19

Same three phases; CISC uses `TestBit KBD_STATUS,#1`, `MoveByte` with autoincrement for
reading (`MoveByte (R4)+, KBD_DATA`) and autodecrement `-(R4)` for the reverse walk, and
direct memory compares for the CR/NUL tests.

---

## 3.21 [M] Palindrome check of a user-entered word (RISC)

**Answer.** Read the word into a buffer (as in 3.19), set a pointer `L` at the start and `R`
at the last character, then compare inward; mismatch ⇒ not a palindrome.

```asm
        ; (prompt + read word into WORD until CR; R4 ends one past last char)
        Move    R_L, #WORD           ; left pointer
        Subtract R_R, R4, #1         ; right pointer (last char)
CHK:    Branch_if_[R_L]>=[R_R] YES   ; pointers crossed → palindrome
        LoadByte R6, (R_L)
        LoadByte R7, (R_R)
        Branch_if_[R6]≠[R7] NO       ; mismatch → not palindrome
        Add      R_L, R_L, #1
        Subtract R_R, R_R, #1
        Branch   CHK
YES:    Move    R2, #MSG_YES
        Call    PUTSTR
        Branch  FIN
NO:     Move    R2, #MSG_NO
        Call    PUTSTR
FIN:    next instruction
```

Classic two-pointer scan from both ends toward the middle.

---

## 3.22 [M] CISC-style version of 3.21

Same two-pointer algorithm; CISC can `CompareByte (R_L)+, (R_R)` style or load with
auto-increment/decrement and branch on the result; status tests via `TestBit`.

---

## 3.23 [D] Display a string centered on an 80-char line, enclosed in a box (RISC)

**Answer.** Steps:
1. **Length**: scan STRING to the NUL to get `len` (adapt the Example 2.1 strlen routine).
   If `len > 78`, set `len = 78` (truncate).
2. **Top border**: print `+`, then `len` `-` characters, then `+`, then CR.
3. **Middle**: compute left padding `pad = (80 - (len+2)) / 2` spaces for centering, print
   `pad` spaces, then `+`, the string (first `len` chars), `+`, CR. *(The box itself is
   `len+2` wide; center that within 80.)*
4. **Bottom border**: same as top.

```asm
        Move    R2, #STRING
        Call    STRLEN           ; R3 = len
        Move    R4, #78
        Branch_if_[R3]<=[R4] OK
        Move    R3, #78          ; truncate
OK:     ; pad = (80 - (len+2)) / 2
        Move    R5, #80
        Add     R6, R3, #2       ; box width = len+2
        Subtract R5, R5, R6
        ShiftR  R5, R5, #1       ; divide by 2 → R5 = pad
        Call    BORDER           ; print pad spaces, +, len '-', +, CR
        Call    PADSPACES        ; print R5 spaces
        Move    R7, #'+'
        Call    PUTCHAR
        Move    R2, #STRING      ; print len chars of the string
        Move    R8, R3
PS2:    Branch_if_[R8]=0 ENDMID
        LoadByte R7, (R2)
        Call    PUTCHAR
        Add     R2, R2, #1
        Subtract R8, R8, #1
        Branch  PS2
ENDMID: Move    R7, #'+'
        Call    PUTCHAR
        Call    PUTCR
        Call    BORDER
        next instruction
; BORDER prints pad spaces, '+', len copies of '-', '+', CR.
```

---

## 3.24 [D] CISC-style version of 3.23

Same algorithm; CISC uses memory-operand arithmetic for the padding/length math,
autoincrement for walking STRING, and `TestBit`/`MoveByte` for output. The centering formula
`pad = (80 - (len+2)) / 2` is unchanged.

---

## 3.25 [D] Display long ASCII text with word-wrap within 80-char lines (RISC)

**Answer.** Walk the text word by word (words separated by spaces, NUL ends the text). Keep
`col` = current column (0..80). For each word:
1. Measure the word length `w` (chars up to the next space or NUL).
2. If `col + 1(space) + w > 80` → emit CR, reset `col = 0` (start a new line); otherwise if
   not at column 0, emit a single space first.
3. Emit the word's characters; add `w` (and the space) to `col`.
4. Stop at NUL.

```asm
        Move    R2, #TEXT        ; text pointer
        Move    R9, #0           ; col = 0
WORD:   LoadByte R6, (R2)
        Branch_if_[R6]=0 FIN     ; NUL → done
        ; skip a leading space in the source, decide spacing
        ; measure word length w (scan ahead to space/NUL) → R3
        Call    MEASURE          ; R3 = w, R2 unchanged
        ; need a space before the word if col>0
        Add     R7, R9, R3
        Add     R7, R7, #1       ; col + w + space
        Move    R8, #80
        Branch_if_[R7]<=[R8] SAMELINE
        Call    PUTCR            ; wrap
        Move    R9, #0
        Branch  EMIT
SAMELINE:
        Branch_if_[R9]=0 EMIT    ; at col 0 → no leading space
        Move    R7, #0x20
        Call    PUTCHAR          ; one separating space
        Add     R9, R9, #1
EMIT:   ; print R3 chars of the word, advancing R2 and col
        ; (loop: LoadByte, PUTCHAR, Add R2,#1, Add R9,#1, Subtract R3,#1 until 0)
        ; skip the space in the source if present, then
        Branch  WORD
FIN:    next instruction
```

The core rule: **before printing a word, check if it fits on the remaining line; if not,
wrap to a new line first.**

---

## 3.26 [D] CISC-style version of 3.25

Same word-wrap logic; CISC uses memory-operand column arithmetic, autoincrement text walking
(`MoveByte DISP_DATA, (R2)+`), and `TestBit` for the display status. The fit test
`col + w + 1 ≤ 80` is identical.

---

## Quick index by type

- **Conceptual (definitive):** 3.1, 3.3, 3.4, 3.6, 3.7, 3.8, 3.11, 3.12.
- **Analysis (full derivation):** 3.5.
- **Programming — simple output:** 3.2, 3.9, 3.10.
- **Programming — timer/7-segment:** 3.13–3.18.
- **Programming — string handling:** 3.19–3.26.

> Reminder: the programming answers are reference models in the book's pseudo-assembly.
> Verify instruction names/addressing against your course's exact ISA and assembler, and
> adapt labels/addresses. The *algorithms and structure* are the gradable substance.
