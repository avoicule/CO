# Chapter 3 — Worked Example 3.4: Display a 32-bit Pattern as 8 Hex Digits

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Location:** Example 3.4, page 120 (Figures 3.12 RISC & 3.13 CISC)
**Prereq:** the keyboard/display register map from Figure 3.3 (see the main Ch.3 guide).

---

## 1. The Problem (in plain words)

> Memory location **BINARY** holds a 32-bit pattern. Display it as **eight hexadecimal
> digits** on the display device from Figure 3.3.

Why eight digits? A 32-bit number = **8 groups of 4 bits**, and every 4 bits = exactly one
hex digit (`0000`–`1111` → `0`–`F`). So 32 bits → 8 hex characters.

**Example:** if BINARY = `1010 0011 ... 1111` then you want to print `A3...F` — eight
characters, one per 4-bit nibble, left-to-right (high-order digit first).

But there's a catch: the display doesn't understand "the number 10 means A." A display
shows **ASCII characters**. So we must first **translate each 4-bit value into the ASCII
code of its hex character**, then send those ASCII bytes to the display.

---

## 2. The Strategy (three stages)

The solution breaks into three conceptual stages:

```
  BINARY (32-bit)                                                 Display
  ┌───────────────┐   STAGE A        ┌──────────┐   STAGE C      ┌────────┐
  │ 1010 0011 ... │ ─ chop into ───▶ │ HEX buf: │ ─ poll DOUT ─▶ │ A 3 .. │
  │               │   4-bit nibbles  │ 8 ASCII  │   send each    │        │
  └───────────────┘        │         │ bytes    │   byte         └────────┘
                     STAGE B│         └──────────┘
                     table-lookup each nibble → its ASCII code
```

- **Stage A — Extract** each 4-bit nibble, high-order first.
- **Stage B — Convert** each nibble (0–15) to the ASCII code of its hex character, using a
  **lookup table**.
- **Stage C — Display** the 8 resulting ASCII bytes using the polling loop from Chapter 3.

### Why a lookup table?

A nibble can be 0–15. We need its ASCII code:

| Nibble | Hex char | ASCII (hex) |
|-------:|:--------:|:-----------:|
| 0–9 | `'0'`–`'9'` | `0x30`–`0x39` |
| 10–15 | `'A'`–`'F'` | `0x41`–`0x46` |

Notice the ASCII codes are **not contiguous**: after `'9'` (0x39) the next is `'A'` (0x41) —
there's a gap (0x3A–0x40 are `:;<=>?@`). So you *can't* just add a constant. The clean
trick is a **16-entry table** `TABLE` where entry *k* holds the ASCII code for hex digit
*k*. Then "convert nibble R5" becomes simply "load the byte at `TABLE + R5`." This is the
**table-lookup approach**.

```
TABLE:  0x30 0x31 0x32 0x33 0x34 0x35 0x36 0x37   ; '0'..'7'
        0x38 0x39 0x41 0x42 0x43 0x44 0x45 0x46   ; '8','9','A'..'F'
         ^index 0                        ^index 15
```

---

## 3. The RISC Solution (Figure 3.12), line by line

```asm
          Load             R2, BINARY        ; R2 = the 32-bit number to display
          Move             R3, #8            ; R3 = digit counter (8 digits to do)
          Move             R4, #HEX          ; R4 = pointer to the HEX output buffer

LOOP:     RotateL          R2, R2, #4        ; rotate LEFT by 4 → high nibble comes to the bottom
          And              R5, R2, #0xF      ; R5 = bottom 4 bits only (one nibble, value 0–15)
          LoadByte         R6, TABLE(R5)     ; R6 = ASCII code = byte at (TABLE + R5)
          StoreByte        R6, (R4)          ; store that ASCII byte into HEX buffer
          Subtract         R3, R3, #1        ; one fewer digit to go
          Add              R4, R4, #1        ; advance HEX pointer to next byte
          Branch_if_[R3]>0 LOOP             ; repeat until all 8 nibbles converted

DISPLAY:  Move             R3, #8            ; reset counter: 8 characters to send
          Move             R4, #HEX          ; reset pointer to start of HEX buffer
DLOOP:    LoadByte         R5, DISP_STATUS   ; read display status
          And              R5, R5, #4        ; isolate DOUT (bit 2, mask 0b100)
          Branch_if_[R5]=0 DLOOP            ; wait while display busy (DOUT = 0)
          LoadByte         R6, (R4)          ; get next ASCII char from HEX buffer
          StoreByte        R6, DISP_DATA     ; send it to the display (clears DOUT)
          Subtract         R3, R3, #1        ; one fewer char to send
          Add              R4, R4, #1        ; advance buffer pointer
          Branch_if_[R3]>0 DLOOP            ; loop until all 8 sent
          next instruction

          ORIGIN   1000                      ; place the following at address 1000
HEX:      RESERVE  8                         ; 8 empty bytes for the ASCII digits
TABLE:    DATABYTE 0x30,0x31,0x32,0x33       ; ASCII '0'..'3'
          DATABYTE 0x34,0x35,0x36,0x37       ; ASCII '4'..'7'
          DATABYTE 0x38,0x39,0x41,0x42       ; ASCII '8','9','A','B'
          DATABYTE 0x43,0x44,0x45,0x46       ; ASCII 'C'..'F'
```

### Walking through the conversion loop (the clever part)

The loop runs **8 times**, once per hex digit. The star of the show is **`RotateL R2, R2, #4`**.

**Why rotate instead of shift?** A **rotate-left by 4** takes the top 4 bits and wraps them
around to the bottom 4 bits (nothing is lost — the bits circle around). After the rotate,
`And R5, R2, #0xF` grabs those bottom 4 bits.

Trace it (showing nibbles as hex, R2 = `D1 D2 D3 D4 D5 D6 D7 D8`, D1 = high-order):

| Iter | After `RotateL R2,#4` (R2 nibbles) | `And #0xF` → R5 extracts | Digit output |
|-----:|------------------------------------|--------------------------|:------------:|
| 1 | `D2 D3 D4 D5 D6 D7 D8 D1` | D1 | **D1** (high-order first ✔) |
| 2 | `D3 D4 D5 D6 D7 D8 D1 D2` | D2 | D2 |
| 3 | `D4 D5 D6 D7 D8 D1 D2 D3` | D3 | D3 |
| … | … | … | … |
| 8 | `D1 D2 D3 D4 D5 D6 D7 D8` (back to start) | D8 | D8 |

So rotating left by 4 **eight times** brings each nibble, in turn, down to the bottom —
**high-order digit first**, which is the natural reading order. After 8 rotations R2 is back
to its original value (a nice side effect, though we don't reuse it).

### `And R5, R2, #0xF` — the nibble mask

`0xF` = `0000...00001111`. ANDing keeps only the lowest 4 bits and zeroes the top 28:

```
  R2    : .... .... .... D1   (D1 is the bottom nibble right now)
  #0xF  : 0000 0000 0000 1111
  R5    : 0000 0000 0000 D1   ← just the nibble, value 0–15
```

### `LoadByte R6, TABLE(R5)` — the table lookup

`TABLE(R5)` is **indexed addressing**: effective address = `TABLE + R5`. Since R5 is the
nibble value (0–15), this reads the matching ASCII code straight out of the table. Example:
nibble = 10 → reads `TABLE+10` = `0x41` = ASCII `'A'`. This one instruction *is* the whole
decimal-vs-letter problem solved.

### The two counters/pointers

- **R3** = how many digits remain (starts at 8, `Subtract #1` each pass, loop while `>0`).
- **R4** = where in the `HEX` buffer to write next (`Add #1` each pass).

### Stage C — the DISPLAY loop

This is exactly the **polling output** pattern from Chapter 3's Figure 3.4:

1. Read `DISP_STATUS`, mask **DOUT** with `#4` (bit 2).
2. Spin while DOUT = 0 (display busy).
3. When ready, `StoreByte` the next char to `DISP_DATA` (writing clears DOUT).
4. Decrement R3, advance R4, loop until all 8 characters are shown.

### The data-definition directives at the bottom

- **`ORIGIN 1000`** — assemble the following at memory address 1000.
- **`HEX: RESERVE 8`** — reserve 8 bytes of scratch space (the output buffer).
- **`TABLE: DATABYTE ...`** — lay down the 16 constant ASCII codes in memory.

---

## 4. The CISC Solution (Figure 3.13) — same task, shorter

```asm
          Move             R2, BINARY        ; load the number
          Move             R3, #8            ; digit counter
          Move             R4, #HEX          ; pointer to HEX buffer
LOOP:     RotateL          R2, #4            ; rotate high nibble to the bottom
          Move             R5, R2
          And              R5, #0xF          ; extract the nibble into R5
          MoveByte         (R4)+, TABLE(R5)  ; TABLE lookup → store to HEX, auto-increment R4
          Subtract         R3, #1
          Branch>0         LOOP
DISPLAY:  Move             R3, #8
          Move             R4, #HEX
DLOOP:    TestBit          DISP_STATUS, #2   ; test DOUT (bit 2) directly in memory
          Branch=0         DLOOP             ; wait while display busy
          MoveByte         DISP_DATA, (R4)+  ; send char, auto-increment R4
          Subtract         R3, #1
          Branch>0         DLOOP
          next instruction
          ; (same ORIGIN / HEX / TABLE data as the RISC version)
```

### What CISC does more compactly

Same three CISC superpowers as in Example 3.4's sibling programs (and §3.1.4):

1. **`MoveByte (R4)+, TABLE(R5)`** — memory-to-memory move **plus autoincrement**. In one
   instruction it does what RISC needs three for (`LoadByte` into R6, `StoreByte` to buffer,
   `Add R4,#1`). The `(R4)+` writes to the buffer **and** bumps the pointer.
2. **`TestBit DISP_STATUS, #2`** — tests the DOUT flag *directly in the memory-mapped
   status register*, setting the Z flag; no `LoadByte` + `And` needed.
3. **No separate `Add` for the pointer** — the autoincrement `(R4)+` folds it in, so the
   loop drops the explicit `Add R4, R4, #1`.

Result: the conversion loop shrinks from ~6 instructions to ~5, and the display loop from
~6 to ~4 — the classic RISC-vs-CISC trade-off (fewer, more powerful instructions).

> Note one small RISC/CISC difference in the extract: the CISC version splits the mask into
> `Move R5, R2` then `And R5, #0xF` because its two-operand `And` writes the result into its
> first operand, whereas RISC's three-operand `And R5, R2, #0xF` reads R2 and writes R5 in
> one go.

---

## 5. Instruction Reference for this example

| Instruction | Meaning here |
|-------------|--------------|
| `Load R2, BINARY` | load the 32-bit word to be displayed |
| `Move R, #k` | put an immediate/address into R |
| `RotateL R2, R2, #4` | rotate bits left by 4 (top nibble wraps to bottom) |
| `And R5, R2, #0xF` | mask off everything but the low 4 bits (one nibble) |
| `LoadByte R6, TABLE(R5)` | indexed load: ASCII byte at address `TABLE+R5` |
| `StoreByte R6, (R4)` | write a byte to the address in R4 |
| `MoveByte (R4)+, src` | (CISC) store a byte, then auto-increment R4 |
| `TestBit DISP_STATUS,#2` | (CISC) test DOUT (bit 2) in memory, set Z flag |
| `Subtract R3, R3, #1` | decrement the digit/char counter |
| `Add R4, R4, #1` | advance the buffer pointer |
| `Branch_if_[R3]>0 LOOP` | loop while counter still positive |
| `ORIGIN / RESERVE / DATABYTE` | assembler directives: set address, reserve bytes, define constant bytes |

---

## 6. Key Takeaways (what this problem teaches)

1. **Devices speak ASCII, not numbers.** To "display a value" you must convert it to the
   ASCII codes of its printed characters first.
2. **Table lookup** elegantly handles non-contiguous mappings (the 0x39→0x41 gap between
   `'9'` and `'A'`).
3. **Rotate + mask** is the standard idiom to peel a number apart one nibble at a time,
   high-order first.
4. **Indexed addressing** `TABLE(R5)` turns "convert value k" into a single memory read.
5. The actual **output** reuses the exact **polling loop** (DOUT via `#4`) you already know
   from Figure 3.4 — nothing new there.
6. **CISC vs RISC**: autoincrement, memory-to-memory move, and direct `TestBit` collapse
   several RISC instructions into one each.

> **Self-check:** If BINARY = `0x2F` (i.e. `...0010 1111`), what two *trailing* hex chars
> get produced, and what are their ASCII codes? *(Nibbles 2 and F → chars `'2'` and `'F'` →
> ASCII `0x32` and `0x46`. All the higher nibbles are 0 → `'0'`, so the full output is
> `000000` then `2F` = "0000002F".)*

---

## 7. DEEP DIVE — the three things that usually confuse people

### 7.1 Why we process the HIGH nibble first — and why *rotate*, not shift

Hex is read left-to-right, high digit first. For `0x2A3F08C7` you must print `2` first,
then `A`, `3`, ... ending in `7`. So the program must peel off the **most significant**
nibble first.

Problem: a mask (`And #0xF`) can only grab the **bottom** 4 bits. So we must bring the top
nibble *down* to the bottom. That's what **`RotateL R2, R2, #4`** does — rotate the whole
32-bit register left by one nibble; bits falling off the left **wrap around** to the right.

```
Before:  [2][A][3][F][0][8][C][7]      [2] = top (most significant) nibble
                                        ...rotate left by 4 bits...
After:   [A][3][F][0][8][C][7][2]      [2] wrapped to the bottom → now maskable
          ^top                   ^bottom
```

Each pass: **rotate first** (next-highest nibble drops to the bottom), **then mask**. Since
we rotate before extracting, the first nibble extracted is the original top one → correct
high-order-first order.

**Rotate vs shift:** a *shift* left would push `2` off the end (lost forever) and feed in
zeros — destroying the number. A *rotate* preserves every bit (they circle around), so after
8 rotates R2 returns to its original value, having let each nibble visit the bottom exactly
once.

### 7.2 How `TABLE(R5)` turns a nibble into an ASCII code (indexed addressing)

`LoadByte R6, TABLE(R5)` computes an **effective address**:

```
effective address = TABLE + R5
```

`TABLE` = address where the 16 constant bytes start. `R5` = nibble value (0–15), used as an
**offset**:

```
Address      Byte    Char
TABLE + 0  → 0x30    '0'
TABLE + 1  → 0x31    '1'
TABLE + 2  → 0x32    '2'   ← R5=2 loads this
...
TABLE + 9  → 0x39    '9'
TABLE + 10 → 0x41    'A'   ← R5=10 loads this (the non-contiguous jump!)
...
TABLE + 15 → 0x46    'F'
```

One `LoadByte` does the whole conversion, including the awkward gap between `'9'` (0x39) and
`'A'` (0x41). The table *is* the gap-handling.

### 7.3 Full concrete trace — BINARY = 0x2A3F08C7

Setup: `R2 = 0x2A3F08C7`, `R3 = 8`, `R4 = HEX`.
Each pass: RotateL → And → LoadByte TABLE(R5) → StoreByte (R4) → R3-- → R4++.

| Pass | R2 after RotateL | R5 nibble | dec | R6 = TABLE(R5) | char | → HEX byte |
|-----:|------------------|:---------:|:---:|:--------------:|:----:|:----------:|
| 1 | `A3F08C72` | `0x2` | 2  | `0x32` | `'2'` | HEX[0] |
| 2 | `3F08C72A` | `0xA` | 10 | `0x41` | `'A'` | HEX[1] |
| 3 | `F08C72A3` | `0x3` | 3  | `0x33` | `'3'` | HEX[2] |
| 4 | `08C72A3F` | `0xF` | 15 | `0x46` | `'F'` | HEX[3] |
| 5 | `8C72A3F0` | `0x0` | 0  | `0x30` | `'0'` | HEX[4] |
| 6 | `C72A3F08` | `0x8` | 8  | `0x38` | `'8'` | HEX[5] |
| 7 | `72A3F08C` | `0xC` | 12 | `0x43` | `'C'` | HEX[6] |
| 8 | `2A3F08C7` | `0x7` | 7  | `0x37` | `'7'` | HEX[7] |

- The R5 column reads `2 A 3 F 0 8 C 7` — exactly the digits of `0x2A3F08C7` in order.
- After pass 8, R2 is back to `0x2A3F08C7` (8 × 4 bits = 32 = full circle).

Resulting HEX buffer:
```
HEX:  0x32 0x41 0x33 0x46 0x30 0x38 0x43 0x37
      '2'  'A'  '3'  'F'  '0'  '8'  'C'  '7'
```

### 7.4 The two loop variables, precisely

- **R3 — countdown:** 8→7→6→5→4→3→2→1→0. `Branch_if_[R3]>0` loops while positive →
  exactly 8 passes, then falls through.
- **R4 — write pointer:** HEX+0, HEX+1, …, HEX+7. `StoreByte R6,(R4)` writes one byte at the
  current pointer. One byte per char → that's why it's `StoreByte`, not word `Store`.

### 7.5 Stage C mask detail — why `#4` tests DOUT

From Figure 3.3, **DOUT is bit 2** of DISP_STATUS. `#4` = `00000100` (a 1 only in bit 2):

```
  DISP_STATUS : b7 b6 b5 b4 b3 b2 b1 b0
  #4 mask     :  0  0  0  0  0  1  0  0
  R5 result   :  0  0  0  0  0 b2  0  0   ← only DOUT survives
```

DOUT=0 → R5=0 → keep spinning (display busy). DOUT=1 → R5=4 (non-zero) → send char. Writing
`DISP_DATA` resets DOUT to 0, so the next pass waits correctly. Final screen output:
`2A3F08C7`.

### 7.6 What memory looks like (the directives)

```asm
        ORIGIN   1000            ; assemble the following at address 1000
HEX:    RESERVE  8               ; 8 blank bytes (1000–1007); label HEX = 1000
TABLE:  DATABYTE 0x30,0x31,0x32,0x33   ; constants placed right after HEX (1008+)
        DATABYTE 0x34,0x35,0x36,0x37
        DATABYTE 0x38,0x39,0x41,0x42
        DATABYTE 0x43,0x44,0x45,0x46
```

Order matters: table entry *k* must be the ASCII code for hex digit *k*, so `TABLE+R5` lands
on the right character.
