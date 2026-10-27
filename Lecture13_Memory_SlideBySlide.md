# Lecture 13 — "DMA ok… & Memory. Finally" · Slide-by-Slide Deep Guide

**Source:** `lect13-memory.pdf` (TU Delft CSE11C Computer Organisation)
**Backfilled with:** Textbook **Chapter 8 — The Memory System**, Hamacher et al. (6th ed.)
**Companions:** `Chapter8_The_Memory_System_StudyGuide.md`, `Chapter8_MindMaps.md`
**Slides:** 32 (deck numbering skips a few — noted inline)

> **How to read this file.** Each slide has three parts:
> **What the slide shows** (the literal content), **What it really means** (plain-English
> explanation), and **💡 My way to think about it** (an analogy or mental model to make it
> stick). Where the slide only hints at something, I pull the actual mechanism from the
> textbook and mark it **(book).**

> **The one-sentence story of the whole lecture:**
> *Memory is slow and the CPU is precious, so we (1) stop the CPU from babysitting data
> transfers (DMA), (2) understand how memory is physically built so we know why it's slow
> and what it costs (cells → chips), and (3) cheat the slowness by doing many memory
> accesses in parallel (interleaving / RAID).*

---

## PART A — Finishing I/O with DMA (slides 1–11)

### Slide 1 — Title: "DMA ok… & Memory. Finally"
**What it shows:** Course title slide, Chapter 8.
**What it means:** Two topics — close out I/O with **DMA**, then build **memory from scratch**.
**💡 My way to think about it:** This lecture sits on a *seam*. The first third still belongs
to the I/O world (how data gets *into* memory); the rest is about memory *itself*. Keep that
seam in mind — slide 11 (caches free the bus) is the hinge that connects the two halves.

### Slide 2 — Previously: I/O organisation
**What it shows:** CPU, Memory, and I/O devices #1…#n on a shared **Bus**; label
"memory-mapped I/O."
**What it means:** Everything hangs off one shared set of wires. With **memory-mapped I/O**,
device registers live at memory addresses, so `Load`/`Store` reach a disk controller the same
way they reach RAM. Up to now, **the CPU executes an instruction for every single word** that
moves.
**💡 My way to think about it:** The bus is a single-lane bridge and the CPU is the only driver.
Every byte that crosses the bridge is the CPU personally making a trip. That's fine for a
postcard; it's absurd for moving house. DMA is about hiring a moving truck.

### Slide 3 — Today's agenda
**What it shows:** "A little more I/O (DMA)" + "Memory from scratch: cells → words → arrays →
chips."
**What it means:** The memory half is deliberately **bottom-up**: one bit, then a word (row of
bits), then a 2-D array, then a packaged chip, then many chips, then banks.
**💡 My way to think about it:** It's LEGO. Slide 15 is a single stud; slide 24 is a finished
wall. If you ever feel lost later, ask "which LEGO level am I at — bit, word, array, or chip?"

### Slide 4 — Section header: NON-PROGRAMMED I/O
**What it shows:** Just a divider.
**What it means:** *Programmed* I/O = the CPU runs a program to move each word (polling or
interrupt-driven, from earlier lectures). *Non-programmed* = a different piece of hardware does
the moving, and the CPU only supervises.
**💡 My way to think about it:** "Programmed" = you washing every dish by hand. "Non-programmed"
= you loading the dishwasher and walking away. Same dishes, radically different use of *your*
time.

### Slide 5 — Non-programmed I/O
**What it shows:** A separate active entity (not the CPU) does the I/O. Two kinds: **DMA**
(1 instruction: MOVE/COPY) and **special I/O processors** (run their own program, more
versatile).
**What it means:** DMA is the minimal version — "copy this block from here to there, tell me
when done." An I/O processor is a little computer that can make decisions mid-transfer (format
conversion, following linked lists of buffers, etc.).
**💡 My way to think about it:** DMA is a courier with one order slip. An I/O processor is a
personal assistant who can read a whole to-do list and improvise. Most desktop hardware uses
the courier (DMA); mainframes historically used the assistant (channel processors).

### Slide 6 — Why DMA? (part 1)
**What it shows:** A compute routine (instructions 1…M); an **interrupt** at instruction *i*
jumps to a "read character" handler, which runs and `return`s.
**What it means:** This is the *normal* interrupt-driven I/O you already know. One character
arrives → interrupt → handle it → resume computing.
**💡 My way to think about it:** A phone call interrupting your work. One call is a minor blip.
Hold that thought — the next slide asks what happens when the phone *won't stop ringing*.

### Slide 7 — Why DMA? (part 2)
**What it shows:** Same diagram + the question **"What happens to the compute routine?"**
**What it means:** For a **large block** (e.g., a disk sector of thousands of words), you'd take
an interrupt *per word*. Each interrupt costs: save registers, run the handler, restore
registers, resume. The compute routine is **suspended over and over** and barely advances. The
overhead dwarfs the actual data movement.
**💡 My way to think about it:** Imagine writing an essay but your phone rings once per *letter*
you need to type. You'll never finish the paragraph. The fix isn't a faster phone — it's to let
someone else take all the calls. That "someone else" is the DMA controller.
**(book):** program-controlled transfer needs several instructions *per word* (move, increment
address, decrement count, test) — the exact overhead DMA removes.

### Slide 8 — Parallel processing to the rescue! (the DMA controller)
**What it shows:** A **DMA controller** on the bus — independent, specialized in **block-based**
transfer. Questions: "Who has priority?" and the strategies **cycle stealing** vs **burst
mode**.
**What it means:** The controller is a second bus master. The CPU hands it a job and keeps
computing; the controller moves the block on its own. Because both now want the one bus, you
need **arbitration** (a referee deciding who drives the bus each cycle):
- **Cycle stealing** — DMA takes *one* bus cycle whenever the CPU isn't using it (or briefly
  pauses the CPU). Transfer is slower but the CPU hardly notices.
- **Burst mode** — DMA grabs the bus and moves the *whole* block uninterrupted. Transfer is
  fast, but the CPU is stalled from the bus the whole time.
**💡 My way to think about it:** Shared kitchen, one counter. **Cycle stealing** = you chop a
vegetable whenever your roommate steps away — nobody's blocked for long, but your cooking is
slow. **Burst mode** = you take over the counter for ten minutes straight — you finish fast, but
your roommate waits. Same trade-off DMA makes with the bus.

### Slide 9 — CPU ↔ DMA interaction (video-playback example)
**What it shows:** Parallel timeline. CPU: issue transfer N+1 → decode N → display N−1 → handle
interrupt → finish N. DMA: receive command → transfer N+1 word-by-word → interrupt when done.
**What it means:** Three blocks are "in flight" at once — one being **fetched** (by DMA), one
being **decoded** (by CPU), one being **displayed**. This is a **pipeline**, just like the
instruction pipeline from Chapter 6, but at the granularity of *video frames/blocks*.
**💡 My way to think about it:** A restaurant kitchen. While the waiter brings dish N+1 from the
pantry, the chef cooks dish N, and the customer eats dish N−1. Nobody waits for the full
round-trip. The "improve further" hint = **double/triple buffering**: keep enough blocks staged
so no stage ever starves.

### Slide 10 — The DMA controller as an "intelligent" I/O device
**What it shows:** Three memory-mapped registers:
```
0x400000  [ IRQ | IE | … | R/W | DONE ]   ← status & control flags
0x400004  [ START ADDRESS ]                ← where in memory the block goes
0x400008  [ WORD COUNT ]                   ← how many words to move
```
Notes: accessed like a normal I/O device; signals completion via **DONE** and/or **interrupt**;
**acts as a bus master** when transferring.
**What it means:** You "program" a DMA transfer by three stores: write the start address, write
the word count, write a control word (direction R/W, interrupt-enable IE). Then it runs. While
running, it **drives the address and control lines itself** — that phrase "bus master" is the
whole point: the controller temporarily *becomes the CPU* as far as the bus is concerned.
- **IE** = raise an interrupt when finished? **IRQ** = "I am requesting an interrupt now."
  **DONE** = "block finished." **R/W** = direction (memory→device or device→memory).
- "Anything missing?" → the **device-side source** (which disk, which sector). The slide shows
  only the memory side.
**💡 My way to think about it:** It's a vending machine for data transfers. You insert three
coins (address, count, control) and walk away; it dings (DONE/interrupt) when your snack is
ready. The subtle part is "bus master" — picture the controller putting on the CPU's hat and
steering the bus while the CPU looks away.
**(book):** Figure 8.12 shows exactly these registers (status/control with IRQ, Done, IE, R/W;
plus starting address and word count).

### Slide 11 (shown as 14) — DMA works better with caches
**What it shows:** Two cases. **Without cache:** every instruction fetched from memory → bus
"mostly occupied" ☹. **With cache (C$):** bus "free (best case)" ☺. Diagram adds a cache between
CPU and memory.
**What it means:** Here's the hinge between the two halves of the lecture. DMA needs the bus, but
so does the CPU *for every instruction fetch*. If the CPU is constantly fetching from main
memory, there's no free bus time for DMA. A **cache** satisfies most of the CPU's fetches
locally, so the **bus sits idle a lot of the time** — exactly the spare capacity DMA wants.
**💡 My way to think about it:** The bus is the single-lane bridge again. Without a cache the CPU
is driving across it nonstop, so the moving truck (DMA) can never merge on. Give the CPU a
pantry in its own house (the cache), and it stops crossing the bridge for every little thing —
now the truck has the bridge to itself. This is *why* the lecture pivots to memory next: to make
the CPU fast, you need good memory (cache), and good memory is what the rest of the lecture
builds.

> Deck jumps 10 → 14 (slides 11–13 of the original aren't in this PDF).

---

## PART B — Memory from Scratch (slides 12–24)

### Slide 12 (15) — Section header: MEMORY ORGANISATION
**What it shows:** Divider.
**What it means:** We now forget I/O and ask: what *is* memory, physically?
**💡 My way to think about it:** Zoom all the way in. We're about to look at memory under a
microscope, one bit at a time, then zoom back out.

### Slide 13 (16) — Memory organisation intuition
**What it shows:** "It's just like a big register file!" + "keep memory aligned," "work with
complete words," "we can optimise for this."
**What it means:** Conceptually, memory = a gigantic array of word-sized storage slots, indexed
by address — like a register file with millions of entries. Two simplifying rules:
- **Aligned** — a 4-byte word sits at an address that's a multiple of 4.
- **Whole words** — hardware naturally reads/writes an entire word (row) at once, not individual
  bytes.
**Why it matters:** if you *guarantee* alignment, the hardware never has to fetch two rows to
assemble one word, which keeps the circuitry simple and fast. That guarantee is what makes the
row/column design on later slides work cleanly.
**💡 My way to think about it:** A library where every book is exactly one shelf wide and always
starts at the left edge of a shelf. You can grab any book in one reach. If books could start
mid-shelf and spill onto the next shelf (unaligned), every grab might need two reaches. Alignment
= "every book starts at a shelf edge."

### Slide 14 (17) — 16×8 memory organization
**What it shows:** A small memory: **16 words, 8 bits each**.
**What it means:** Our running toy example. 16 rows (words) × 8 columns (bits). We'll dissect one
cell, then rebuild.
**💡 My way to think about it:** A 16-row spreadsheet with 8 columns of 0/1. Each row is a byte;
the whole sheet is the memory. Everything from here is "how do we build and address this sheet in
silicon?"

### Slide 15 (18) — One bit in memory: selecting it
**What it shows:** A single cell storing **B** and its complement **1−B** on two lines; a **word
line** selects it; "HIGH" marks the stored side.
**What it means:** A memory bit is stored *differentially* — on two complementary lines (b and
b′). The **word line** is the "are you selected?" wire for this cell's whole row. When the word
line is off, the cell is isolated and just sits there holding its value.
**(book):** the SRAM cell is **two inverters cross-connected into a latch**, tapped by two switch
transistors (T1, T2) onto the bit lines. Word line **on** = close the switches = connect the
latch to the outside world.
**💡 My way to think about it:** A light switch wired as a flip-flop that remembers its last
position. The word line is a padlock: locked (off) = nobody can see or change it; unlocked (on) =
you can read which way it's flipped, or flip it.

### Slide 16 (19) — One bit: writing
**What it shows:** Writing B: one bit line forced **HIGH**, the other **LOW**.
**What it means:** To *write*, you don't gently ask the cell — you **overpower** it. The
sense/write circuit drives b high and b′ low (or vice-versa) harder than the little latch can
resist, so the latch flips to match, then stays there once the word line turns off.
**💡 My way to think about it:** Flipping a stiff see-saw. You can read which way it's tilted
without touching it (read), but to *change* it you have to push one side down hard (write). Once
pushed, it stays — that's memory.

### Slide 17 (20) — One bit holds its value → SRAM
**What it shows:** Disconnected cell keeps its value, "without consuming power*"; labeled **SRAM
(Static RAM)**.
**What it means:** The cross-coupled inverters feed each other, so the latch is self-sustaining —
no refresh, no clock. "Static" = holds state on its own as long as power is on. The `*` is
honesty: there's tiny leakage, and it's **volatile** — cut the power and it forgets.
**(book):** CMOS SRAM draws current *only when accessed*; otherwise no path from supply to
ground, so it's very low-power. Access times are a few nanoseconds → that's why SRAM is used for
caches.
**💡 My way to think about it:** A see-saw with two kids who each sit on the side the other
pushes up — they balance each other forever and you don't have to keep pushing. Fast and tidy,
but it takes two kids (6 transistors), so it's *expensive per bit*. Remember: **Static = Stays
by itself.**

### Slide 18 (21) — "Less is more?" → DRAM
**What it shows:** **DRAM (Dynamic RAM)**; "leakage current enforces periodic refresh." Questions
about other memory types and when to use each.
**What it means:** Shrink the cell to the extreme: **one transistor + one capacitor**. The bit is
just *charge* on the capacitor (charged = 1, empty = 0). Far smaller → **much denser and cheaper**
than SRAM. The catch: capacitors **leak**, so the value fades in tens of milliseconds and must be
**refreshed** (read-and-rewrite every row periodically). "Dynamic" = it would *decay* if you left
it alone.
**(book):** charge holds only tens of milliseconds; refresh happens whenever the cell is read or
rewritten, so a controller marches through all rows on a schedule.
**💡 My way to think about it:** SRAM is a see-saw (holds itself). DRAM is a **leaky bucket**:
cheap and you can fit millions of them, but you must keep topping each one up (refresh) or the
water drains and the bit is lost. Trade-off in one line: **SRAM = fast + costly → cache; DRAM =
dense + cheap + needs refresh → main memory.** ("Less is more": fewer transistors per cell →
more bits per chip.)

### Slide 19 (22) — 16×8: one word
**What it shows:** The 16×8 array with **one 8-bit word** highlighted.
**What it means:** Lay 8 of those single-bit cells side by side and connect them to **one shared
word line** → selecting that word line reads/writes all 8 bits (a whole byte) at once.
**💡 My way to think about it:** The word line is a row-wide master switch: flip it and all 8
cells in that row answer together. This is why hardware "works with complete words" (slide 13) —
a word line inherently grabs the entire row.

### Slide 20 (23) — 16×8: all 16 words
**What it shows:** The full 16×8 array — 16 word lines, each over a row of 8 cells.
**What it means:** 16 word lines (one per word) crossing 8 bit-line pairs (one per bit position).
Pick a word line → that byte appears on the bit lines.
**💡 My way to think about it:** A grid of streets. Word lines are the 16 horizontal streets; bit
lines are the 8 vertical ones. To fetch a byte you "turn on" exactly one horizontal street, and
read the 8 intersections along it. Addressing = choosing which horizontal street.

### Slide 21 (24) — 16×8: the three line groups
**What it shows:** The array wired to **Address lines**, **Data lines**, **Control lines**.
**What it means:** The same universal trio you met on the bus and in I/O, now at the chip:
- **Address** — which word (which word line to activate).
- **Data** — the actual bits in/out.
- **Control** — R/W (read or write), CS (chip-select / enable), timing.
**💡 My way to think about it:** Ordering at a counter: **Address** = your ticket number (who),
**Data** = the food handed over (what), **Control** = "serving now / pay here / takeaway or
eat-in" (how). Every storage/transfer unit in this course speaks this same three-part language.

### Slide 22 (25) — 1024-bit memory as 128×8: split into rows & columns
**What it shows:** 1024 bits arranged as **128 words × 8 bits**, built as a **32×32 array**.
A **5-bit row** → **5-bit decoder** → one of 32 rows; a **2-bit column** → **32-to-8 MUX/DEMUX**;
7 address bits total (in the MAR), plus R/W and CS. Question: "why split into rows/columns?"
**What it means:** You *could* decode 128 words with one giant 7-bit → 128-line decoder, but that
decoder is big and the array would be a tall thin strip (bad electrically). Instead, fold it into
a near-square **32×32** grid. Addressing becomes two cheap steps: the **row decoder** lights up
one of 32 word lines (that row's 32 bits all come out), then the **column mux** selects which 8
of those 32 bits you actually wanted.
**(book):** "a row address selects a row of cells, all accessed in parallel; the column address
picks which of them connect to the data lines." This is literally how DRAM's **RAS** (row
strobe) and **CAS** (column strobe) work.
**💡 My way to think about it:** Finding a seat in a cinema. A flat scheme = one unique number per
seat (huge list). The row/column scheme = "Row G, Seat 14" — two small lookups instead of one
enormous one. Fewer wires, smaller decoders, squarer (cheaper) chip. **That's why the split
exists: it turns one expensive decoder into two tiny ones.**

### Slide 23 (26) — Same 1024 bits as 1024×1
**What it shows:** Same 1024-bit capacity, now **1024 words × 1 bit**: still a 32×32 array, but
**5-bit row + 5-bit column = 10 address bits**, and a **32-to-1** mux (one data bit out).
**What it means:** Same silicon, different *shape*. A ×1 chip delivers a single bit per access, so
you need to address all the way down to the individual bit (10 bits), but you only need **one**
data wire.
**💡 My way to think about it:** Same 1024 lockers, two floor plans. 128×8 = 128 lockers each
holding 8 items (short address, wide payload). 1024×1 = 1024 lockers each holding 1 item (long
address, skinny payload). Next slide shows why that shape choice is really a *pin-count* choice.

### Slide 24 (27) — Cost in pins: 128×8 vs 1024×1
**What it shows:**
| | 128×8 | 1024×1 |
|---|---|---|
| Address pins | 7 | 10 |
| Data pins | 8 | 1 |
| R/W + CS | 2 | 2 |
| Power + ground | 2 | 2 |
| **Total** | **19** | **15** |
**What it means:** **Pins = packaging cost and board complexity**, so chip designers count them
carefully. Making the chip *narrow* (×1) costs 3 extra address pins but saves 7 data pins → net
cheaper. The industry trick: build a wide memory (say 8 bits) from **8 separate ×1 chips in
parallel**, each supplying one bit of every word. You get wide words *and* cheap, standardized
chips.
**💡 My way to think about it:** Shipping boxes. One fat box with 8 handles (8 data pins) vs eight
skinny boxes with 1 handle each. The skinny boxes need slightly more labeling (address pins) but
far fewer handles total — cheaper to manufacture and you can mix-and-match how many you stack.
This is exactly how a DIMM is many narrow DRAM chips working in lockstep.

### Slide 25 (29) — Address lines vs. byte addressability
**What it shows:** A ?×32 memory: hardware moves **32-bit word lines** at once, but programs
address **by byte**. Questions: "how to convert address → line?" and "how to handle unaligned
access?"
**What it means:** There's a mismatch of units. The memory array only knows *words* (rows); the
programmer thinks in *bytes*. Bridge it with the **low address bits**:
- A 32-bit word = 4 bytes, so the **low 2 bits** of a byte address select the byte *within* the
  word, and the **remaining high bits** are the word (row) address → i.e. **word address = byte
  address ÷ 4 = drop the low 2 bits**.
- **Unaligned access** (a 4-byte word starting at, say, byte 6) spans **two rows**, so it needs
  **two memory accesses** plus shifting/merging — slow, and many architectures simply forbid it.
That's the real-world payoff of the "keep aligned" rule from slide 13.
**💡 My way to think about it:** The memory sells eggs only by the carton of 4 (words), but you
asked for "egg #6." You compute: carton = 6 ÷ 4 = carton 1, egg = 6 mod 4 = position 2. Easy
*because* cartons are always full and start at multiples of 4. Ask for "4 eggs starting at #6" and
you must open *two* cartons (unaligned) — twice the work.

> Slide 28 is skipped in the deck (25 → 29).

### Slide 26 (30) — Larger memory chips using Chip-Select (CS)
**What it shows:** Composing a bigger memory from multiple chips; questions "why multiple chips?"
and "what is weird here?"
**What it means:** No single chip is big/wide enough, so you tile several. **Chip-Select (CS)** is
how you pick the right one: decode the **high-order address bits** to assert CS on **exactly one
chip** (that's the "which chip" decision), while the **low-order bits** address *within* each
chip (the "which word in the chip" decision).
- **"What's weird?"** → all the chips' **data pins are tied to the same shared data bus**. That
  looks like a short circuit — until you realize CS guarantees **only one chip drives the bus at
  a time**; the unselected chips put their outputs in **high-impedance (tri-state)**, effectively
  disconnecting. (This is the tri-state idea from the bus lecture.)
**💡 My way to think about it:** A conference call. Everyone's mic (data pins) is on the same line,
but there's a rule: only the person whose name is called (CS) may speak; everyone else mutes
(tri-state). Address high bits = who's called; address low bits = what they say. That's how you
make one big "memory" out of many small chips without them shouting over each other.

---

## PART C — Performance: Interleaved Memory (slides 27–31)

### Slide 27 (31) — Section header: INTERLEAVED MEMORY
**What it shows:** Divider, tagged "performance optimisation."
**What it means:** A single memory bank can only start one access at a time, and each access has
a long latency. Idea: use **several banks** so you can have **several accesses in flight at
once**.
**💡 My way to think about it:** One slow cashier vs several cashiers. You can't make one cashier
faster, but you can open more lanes and spread customers across them. Interleaving is "open more
lanes."

### Slide 28 (32) — Memory banks: flat layout
**What it shows:** Address split into **k bits = Bank** (high) + **m bits = Address in Bank**
(low). "Consecutive addresses served by the **same** memory." Question: "values for k and m?"
**What it means:** In the *flat* arrangement the **bank number is the high part** of the address.
So addresses 0,1,2,… all share the same high bits → they all live in **bank 0** until it fills,
then bank 1, etc. Consecutive accesses pound **one** bank, so you get **no parallelism** for
sequential access — you wait out each bank's full latency in turn.
- k = log₂(number of banks), m = log₂(words per bank).
**💡 My way to think about it:** A supermarket where aisle numbers are the *first* digit of the
product code — so everything you want for one recipe is jammed in a single aisle, and you queue
behind everyone else grabbing from that same aisle. Technically organized, terrible for throughput.

### Slide 29 (33) — Memory banks: interleaved layout
**What it shows:** Fields swapped — **m bits = Address in Bank** (high) + **k bits = Bank** (low).
"Consecutive addresses served by **consecutive** banks. Higher throughput (sequential access)."
**What it means:** Put the **bank number in the LOW bits**. Now address 0 → bank 0, address 1 →
bank 1, …, address n−1 → bank n−1, address n → bank 0 again. Sequential access **sprays across
all banks in rotation**, so while bank 0 is still finishing word 0, bank 1 is already working on
word 1, bank 2 on word 2… The banks overlap their latencies → big throughput win for the
streaming/sequential patterns that dominate real programs.
**💡 My way to think about it:** Deal a deck of cards to n players going around the circle
(low-bit = which player). Everyone gets busy almost immediately and in parallel, instead of
dumping the whole deck on one player (flat). **Flat = fill one bank then the next. Interleaved =
round-robin across banks.**

### Slide 30 (34) — Interleaving at the word (cache-block) level
**What it shows:** Address split into **three** fields: **(address in bank) | (bank) | (w bits)**;
the low **w bits** labelled "cache block."
**What it means:** Pure word-level interleaving would scatter the 4 words of one cache block
across 4 different banks — but caches fetch a **whole block** at a time, so you'd rather keep a
block's words together and interleave **whole blocks** across banks. So you peel off the low **w
bits** as the within-block offset (kept together), put the **bank** bits next, and the rest is the
address within the bank. Consecutive *blocks* then land on consecutive banks → you still get bank
parallelism, but aligned to how the cache actually moves data.
**💡 My way to think about it:** Deal cards *in small fans of 3* to each player instead of one
card each. Each player (bank) gets a tidy little hand (a cache block), and the next fan goes to
the next player. You keep the round-robin parallelism but hand out data in the chunks the cache
asked for.

### Slide 31 (35) — Secondary storage: striping & RAID
**What it shows:** "Interleaved layout (striping)" → **RAID — Redundant Array of Independent
Disks**, with two goals: **performance** and **reliability**, and a "?" between them.
**What it means:** The *same* interleaving idea, one level down the hierarchy, applied to
**disks**:
- **Striping for performance (RAID 0, book):** split one big file across several disks and
  read/write them **in parallel** — disk-level interleaving, higher bandwidth. But *more* disks
  = *more* chances one fails, so reliability actually drops.
- **Redundancy for reliability (RAID 1 and up, book):** keep copies (**mirroring**) or
  **parity** so the array survives a disk failure. Costs capacity and/or write speed.
The "?" is the **tension**: raw striping boosts speed but hurts reliability; redundancy restores
reliability at a cost. RAID levels are different points on that trade-off curve.
**💡 My way to think about it:** Interleaving-with-insurance. Spreading a file across disks is the
same "use many lanes" trick as memory banks (speed). Mirroring/parity is buying a spare tire
(reliability) — it costs you trunk space (capacity) but saves you when a disk blows out. RAID = a
menu of how much speed vs how much insurance you want.

### Slide 32 (36) — Next on Computer Organisation
**What it shows:** Teaser: **Caches** ("make the CPU faster — but sometimes slower! — and exam
questions harder 🙂") and **Virtual Memory**.
**What it means:** The natural next steps up the hierarchy. This lecture built the *raw* memory
and its bulk-transfer tricks; the next one adds the *smart* layer (cache) and the *illusion* layer
(virtual memory) on top.
**💡 My way to think about it:** You've now built the warehouse (main memory) and the loading
docks (DMA/interleaving). Next lecture adds the **desk drawer** right next to you (cache) so you
rarely walk to the warehouse, and a **catalog system** (virtual memory) that lets each program
pretend the warehouse is infinite and all its own.

---

## Big-picture connections (why these slides are in one lecture)
- **DMA ↔ caches (slide 11)** is the pivot: DMA needs a free bus; caches free the bus. You can't
  fully appreciate DMA without memory, or memory without DMA.
- **Cells → chips (slides 15–24)** explains *why memory is slow and what it costs*: physics
  (capacitor leak, latch size) and economics (pins). Everything above it (cache, interleaving,
  virtual memory) exists to *hide* that slowness.
- **Interleaving ↔ RAID (slides 27–31)** is the same idea — "parallel accesses across independent
  units" — appearing at two levels of the hierarchy (DRAM banks, then disks). Spot the pattern and
  you've learned it once instead of twice.

## Quick self-check (close the file and answer)
1. Why does moving a large block with interrupt-driven I/O starve the compute routine, and how
   does DMA fix it? *(slides 6–8)*
2. What are the three DMA controller registers, and what does "acts as a bus master" mean?
   *(slide 10)*
3. Cycle stealing vs burst mode — what does each do to the CPU during a transfer? *(slide 8)*
4. Why does caching help DMA? Describe it in terms of the bus. *(slide 11)*
5. SRAM vs DRAM: what physically stores the bit, which needs refresh and why, and which is used
   for cache vs main memory? *(slides 17–18)*
6. Why lay a memory out as a near-square row/column array instead of one flat decoder? *(slide 22)*
7. Why does a 1024×1 chip total fewer pins than a 128×8 chip of the same capacity, and how is that
   exploited to build wide memories? *(slide 24)*
8. To turn a byte address into a 32-bit word-line address, what do you do with the low 2 bits, and
   what makes an access "unaligned"? *(slide 25)*
9. Flat vs interleaved banks: which address bits pick the bank in each, and why does interleaving
   give higher sequential throughput? *(slides 28–29)*
10. How is RAID striping the same idea as memory interleaving, and what is the tension RAID has to
    balance? *(slide 31)*

---

*End of deep slide-by-slide guide. Pair with `Chapter8_The_Memory_System_StudyGuide.md` and
`Chapter8_MindMaps.md` for the full textbook treatment.*
