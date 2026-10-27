# Lecture 13 — "DMA ok… & Memory. Finally" · Slide-by-Slide Guide

**Source:** `lect13-memory.pdf` (TU Delft CSE11C Computer Organisation)
**Maps to:** Textbook **Chapter 8 — The Memory System** (pair with `Chapter8_The_Memory_System_StudyGuide.md` and `Chapter8_MindMaps.md`)
**Slides:** 32 (deck numbering skips a few — noted inline)

> **The through-line of the whole lecture**
> 1. **DMA** (slides 4–11): stop making the CPU move every byte — hand block transfers to an
>    independent **bus-master controller**, run CPU and DMA **in parallel**, and note that
>    **caches free the bus** so this works.
> 2. **Memory from scratch** (12–24): **one bit (SRAM vs DRAM) → a word → a 2-D row/column
>    array → a chip**, and how a chip's **shape** drives **pin cost** and byte-addressability.
> 3. **Interleaving** (27–31): split memory into **banks**; putting the **bank bits low**
>    makes consecutive addresses hit **parallel banks** for throughput — the same idea becomes
>    **RAID striping** on disks.

---

## Part A — Finishing I/O with DMA

### Slide 1 — Title
"DMA ok… & Memory. Finally (Chapter 8)." The "finally" is a running joke — the memory
lecture had been promised for a while. Two topics today: finish I/O with **DMA**, then build
**memory hardware from scratch**.

### Slide 2 — Previously: I/O organisation
Recap. Picture: **CPU**, **Memory**, and **I/O devices #1…#n** all on a shared **Bus**.
Key reminder: **memory-mapped I/O** — devices have addresses like memory, so you reach them
with ordinary load/store instructions. This is the world *before* DMA, where the
**CPU personally moves every byte**.

### Slide 3 — Today's agenda
- **A little more I/O** → use **DMA** to speed up data transfers.
- **Memory from scratch** → build it in layers: **cells → words → arrays → chips**.
That bottom-up path is the spine of the lecture.

### Slide 4 — Section header: NON-PROGRAMMED I/O
Divider. "Programmed I/O" = the CPU runs instructions to move each word (what you've seen so
far). "Non-programmed" = something *else* does the moving.

### Slide 5 — Non-programmed I/O
Core idea: **a separate active entity — not the CPU — does the I/O work.** You tell the device
*what* to copy and *where*; it handles the actual transport. Two flavors:
- **Direct Memory Access (DMA):** essentially one instruction, "MOVE/COPY this block."
- **Special I/O processors:** more powerful — they run their *own program*, not just a copy.

### Slide 6 — Why DMA? (part 1)
A **Compute routine** (instructions 1…M) is running. An **interrupt** fires at instruction *i*
to **read a character** (jump to handler → do work → `return`). This is normal interrupt-driven
I/O.

### Slide 7 — Why DMA? (part 2)
Same picture, punch-line question: **"What happens to the compute routine?"**
Answer: it is **suspended** every single time a character needs handling. Fine for one
character — but for a **big block** (disk → memory) the CPU gets interrupted constantly and
makes no real progress. That pain is why DMA exists.

### Slide 8 — Parallel processing to the rescue! (the DMA controller)
Solution: a **DMA controller** — an **independent entity, specialized in block-based transfer**,
sitting on the bus. Now CPU and DMA work **in parallel**. Two questions raised:
- **"Who has priority?"** on the bus → **bus arbitration**.
- Two bus-sharing strategies:
  - **Cycle stealing** — DMA grabs one bus cycle at a time, slipping between CPU accesses
    (CPU barely slows).
  - **Burst mode** — DMA seizes the bus and transfers the whole block at once (fast transfer,
    but CPU is locked out meanwhile).

### Slide 9 — CPU ↔ DMA interaction (video-playback example)
A timeline showing CPU and DMA running **side by side**:

| CPU does | DMA does |
|---|---|
| 1. Issue "transfer block N+1 from disk→memory" | 1. Receive the command |
| 2. Decode block N | 2. Transfer block N+1 (word by word over the bus) |
| 3. Display block N−1 | 3. Send an interrupt when done |
| 4. Handle the interrupt | |
| 5. Finish decoding block N | |

Lesson: while DMA fetches **block N+1**, the CPU **decodes N** and **displays N−1** — a software
**pipeline** with three blocks in flight. "Improve even further" → **double buffering / deeper
pipelining**.

### Slide 10 — The DMA controller as an "intelligent" I/O device
Programmer's view — **three memory-mapped registers**:
```
0x400000  [ IRQ | IE | … | R/W | DONE ]   ← status & control
0x400004  [ START ADDR ]                   ← where in memory
0x400008  [ WORDCOUNT ]                    ← how many words
```
- Programmed like any memory-mapped device.
- **DONE** / an **interrupt** signals completion; **IE** enables the interrupt; **R/W** sets
  direction.
- Crucially it **acts as a bus master** — drives address and control lines itself (like the
  CPU), which is how it moves data without the CPU.
- "Anything missing?" → you also need the **device/source address** (e.g., which disk sector).

> Deck jumps 10 → 14 here (slides 11–13, extra DMA detail, aren't in this deck).

### Slide 11 (shown as 14) — DMA works better with caches
- **Without a cache:** every instruction fetch goes to memory → the **bus is almost always
  busy** → DMA rarely gets a turn (the sad face).
- **With a cache (C$):** most fetches are served from the cache → the **bus is often free** →
  DMA can use it (the happy face).

So caching not only speeds the CPU, it **frees the bus** so CPU and DMA don't fight over it.
This is the bridge into the memory half of the lecture.

---

## Part B — Memory from Scratch

### Slide 12 (15) — Section header: MEMORY ORGANISATION
Divider. From here it's pure memory hardware, built bottom-up.

### Slide 13 (16) — Memory organisation intuition
"It's just like a big register file!" Mental model: memory is a huge array of word-sized
registers. Two conventions that make hardware simpler/faster:
- **Keep memory aligned.**
- **Work with complete words** internally.
"We can optimise for this!" — alignment is what enables the row/column tricks later.

### Slide 14 (17) — 16×8 memory organization
First concrete example: **16 words × 8 bits each**. We'll zoom into a single bit, then rebuild
up to this.

### Slide 15 (18) — One bit in memory: selecting it
A single storage cell stores value **B** and its complement **1−B** on two lines. A **word
line** selects the cell for read/write. "HIGH" marks which side holds the stored value. This
is the atom of memory.

### Slide 16 (19) — One bit: writing
To **write**, force the two sides: one line **HIGH**, the other **LOW**, flipping the cell to
the desired state. Writing = driving the bit lines hard enough to overpower the cell.

### Slide 17 (20) — One bit holds its value → SRAM
Disconnect the word line and the cell **keeps its value**, essentially **without consuming
power** (`*` = tiny leakage aside). This self-holding cell is **SRAM (Static RAM)** — "static"
because it holds state on its own (built from a latch/flip-flop, no refresh needed).

### Slide 18 (21) — "Less is more?" → DRAM
Contrast. An SRAM cell needs ~6 transistors (lots of area). **DRAM (Dynamic RAM)** stores a bit
as **charge on a tiny capacitor** → far fewer components → **denser and cheaper**. Catch:
**charge leaks**, so DRAM needs **periodic refresh**. The trade-off:
- **SRAM** → fast, expensive → **caches**.
- **DRAM** → dense, cheap, needs refresh → **main memory**.

### Slide 19 (22) — 16×8: one word
Back to the 16×8 memory, highlighting **one 8-bit word** — a horizontal row of 8 bit-cells all
selected together by one word line.

### Slide 20 (23) — 16×8: all 16 words
The full array: **16 of those 8-bit words** stacked = the whole 16×8 memory. (cells → word →
array)

### Slide 21 (24) — 16×8: the three line groups
The array with its interface wires — the classic trio:
- **Address lines** — pick *which* word.
- **Data lines** — carry the 8 bits in/out.
- **Control lines** — R/W, chip-select, timing.
Same address/data/control pattern seen on the bus and in I/O, now at chip level.

### Slide 22 (25) — 1024-bit memory as 128×8: split into rows & columns
Scale up: **1024 bits = 128 words × 8 bits**, physically laid out as a **32×32 array** (a
square is area-efficient). Access is **two-stage**:
- **5-bit row address** → **5-bit decoder** picks one of 32 rows (word lines W0…W31).
- **2-bit column address** → **32-to-8 MUX/DEMUX** picks which 8 bits of that row.
- Total **7 address bits** (5 row + 2 column) in the **MAR**, plus **R/W** and **CS**.

**"Why split into rows/columns?"** → a flat 128-way decoder is huge; a square array with two
small decoders uses far fewer gates/wires. (Real DRAM does exactly this with **RAS/CAS**.)

### Slide 23 (26) — Same 1024 bits as 1024×1
Same capacity, different shape: **1024 words × 1 bit**. Still a 32×32 array, but:
- **5-bit row + 5-bit column = 10 address bits**.
- Column mux is **32-to-1** (one data bit out).
Same silicon, different **aspect ratio** → different pin needs (next slide).

### Slide 24 (27) — Cost in pins: 128×8 vs 1024×1
Organization affects **pin count**, a real chip cost:

| | 128×8 | 1024×1 |
|---|---|---|
| Address pins | 7 | 10 |
| Data pins | 8 | 1 |
| R/W + CS | 2 | 2 |
| Power + ground | 2 | 2 |
| **Total** | **19 pins** | **15 pins** |

Takeaway: a **narrow (×1) organization needs more address pins but far fewer data pins** → fewer
pins overall. That's why wide words are built from **many ×1 chips in parallel**.

### Slide 25 (29) — Address lines vs. byte addressability
Hardware reads/writes a **full 32-bit word line at once**, but programs address **by byte**.
- **"Convert address → line?"** → **drop the low 2 bits** (word address = byte address ÷ 4);
  those 2 bits select the byte *within* the word.
- **"Unaligned access?"** → an access straddling two words needs **two memory accesses** (or is
  disallowed) — which is why alignment (slide 13) matters.

> Slide 28 is skipped in the deck (25 → 29).

### Slide 26 (30) — Larger memory chips using Chip-Select (CS)
**"Why compose using multiple chips?"** — one chip isn't big/wide enough, so you tile many.
**CS (chip-select)** is the trick: high-order address bits are decoded to **enable exactly one
chip**, while lower bits address *within* each chip. **"What's weird here?"** → the chips' data
pins are **wired together on a shared bus**, and CS ensures only one chip **drives** them at a
time (others sit in high-impedance / tri-state).

---

## Part C — Performance: Interleaved Memory

### Slide 27 (31) — Section header: INTERLEAVED MEMORY
Divider into the last topic: **interleaving** — spread memory across **banks** to access several
in parallel.

### Slide 28 (32) — Memory banks: flat layout
Memory split into **n banks**. The address is cut into **k bits = which bank** and **m bits =
address within the bank**. In the **flat layout** the **bank bits are the HIGH bits**, so a
whole contiguous region lives in **one bank**.
- Downside: **consecutive addresses served by the same memory** → sequential access hammers one
  bank, no parallelism.
- "What values for k and m?" → k = log₂(#banks), m = log₂(bank size).

### Slide 29 (33) — Memory banks: interleaved layout
Flip the fields: **bank bits become the LOW bits**, within-bank address is the high bits. Now
**consecutive addresses go to consecutive banks** (addr 0→bank0, 1→bank1, 2→bank2, …).
- Benefit: sequential access hits a different bank each step, so banks run **in parallel** →
  **higher throughput**. While bank 0 still serves word 0, bank 1 already serves word 1.

### Slide 30 (34) — Interleaving at the word (cache-block) level
Refinement: the address splits into **three** fields — **(address in bank) | (bank) | (w
bits)**. The low **w bits** stay grouped — that group is exactly a **cache block**. So you
interleave **whole blocks** across banks: consecutive *blocks* land on consecutive banks. This
matches how caches fetch (a block at a time) while keeping parallel-bank throughput.

### Slide 31 (35) — Secondary storage: striping & RAID
Same interleaving idea one level down — on **disks**. **RAID (Redundant Array of Independent
Disks)** stripes data across multiple disks for:
- **Performance** — read/write several disks in parallel (disk-level interleaving).
- **Reliability** — redundancy (mirroring/parity) so data survives a disk failure.
The "?" is the **tension** between the two (more redundancy costs capacity/performance).

### Slide 32 (36) — Next time
Teaser:
- **Caches** — "make the CPU faster (but sometimes slower!)" and "make exam questions harder"
  (joke).
- **Virtual Memory.**

---

## Quick self-check (close the file and answer)
1. Why does moving a large block with interrupt-driven I/O starve the compute routine, and how
   does DMA fix it?
2. What are the three DMA controller registers, and what does "acts as a bus master" mean?
3. Cycle stealing vs burst mode — what does each do to the CPU during a transfer?
4. Why does caching help DMA (hint: the bus)?
5. SRAM vs DRAM: what stores the bit, which needs refresh, and which is used for cache vs main
   memory?
6. Why lay a memory out as a square row/column array instead of one flat decoder?
7. Why does a 1024×1 chip need fewer pins than a 128×8 chip of the same capacity?
8. To turn a byte address into a 32-bit word-line address, what do you do with the low 2 bits?
9. Flat vs interleaved banks: which address bits pick the bank in each, and which gives higher
   sequential throughput?
10. How is RAID striping the same idea as memory interleaving, and what second goal does RAID
    add?

---

*End of slide-by-slide guide. Pair with the Chapter 8 study guide and mind maps for full detail.*
