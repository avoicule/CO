# Lecture 14 — "Caching" · Slide-by-Slide Deep Guide

**Source:** `lect14-caching.pdf` (TU Delft CSE11C Computer Organisation)
**Backfilled with:** Textbook **Chapter 8 — The Memory System**, Hamacher et al. (6th ed.)
**Companions:** `Chapter8_The_Memory_System_StudyGuide.md`, `Chapter8_MindMaps.md`,
`Lecture13_Memory_SlideBySlide.md`
**Slides:** 37 (deck numbering skips a few — noted inline)

> **How to read this file.** Each slide has three parts:
> **What the slide shows** (literal content), **What it really means** (plain-English
> explanation), and **💡 My way to think about it** (an analogy/mental model). Where a slide
> only hints at a mechanism, I pull the detail from Chapter 8 and mark it **(book).**

> **The one-sentence story of the whole lecture:**
> *The CPU is far faster than main memory, so put a tiny-but-fast copy (the cache) close to
> the CPU; it works because programs reuse nearby/recent data (locality); the design choices
> are **where** a block may sit (mapping), **what** happens on reads/writes (policies), and
> **which** block to evict (replacement) — all judged by one number: the hit ratio.*

---

## PART 0 — Housekeeping / news (slides 1–6)

### Slide 1 — Title: "Caching (Chapter 8)"
**What it shows:** Course title slide.
**What it means:** Today's topic is the **cache** — the small fast memory between CPU and main
memory. This is the "smart layer" teased at the end of lecture 13.
**💡 My way to think about it:** Lecture 13 built the warehouse (main memory). Today we add the
**desk drawer** right next to you so you rarely have to walk to the warehouse.

### Slide 2 — "But first… a story"
**What it shows:** Agenda for a current-events aside: deadlines, AI/LLM, PHP, certificates,
GitLab.
**What it means:** A real-world security news segment (not exam material). Context: a week of
AI-assisted vulnerability discoveries.
**💡 My way to think about it:** Flavor/motivation, safe to skim. The exam content starts at
slide 7.

### Slide 3 — PHP vulnerability
**What it shows:** A decade-old "technical debt" bug in PHP, found by OpenAI with heavy compute,
disclosed early on social media before the patch shipped.
**What it means:** Example of **responsible disclosure gone wrong** — a fix was coordinated, then
leaked publicly two days early.
**💡 My way to think about it:** Security side-story. The lesson is about disclosure ethics, not
computer organisation.

### Slide 4 — Certificates
**What it shows:** "AI" used to find the private key of 8 intermediate CAs; fix = revoke the root
cert and reissue many certs; private keys are 115+ digits.
**What it means:** If a certificate authority's private key leaks, everything it signed becomes
untrustworthy, forcing mass revocation/replacement.
**💡 My way to think about it:** Not exam material; it's a "why cryptography key sizes matter"
anecdote.

### Slide 5 — "And then…" (GitLab + misc)
**What it shows:** A GitLab CVSS 10.0 RCE bug, a building fire, phone outages, and the TU
emergency number.
**What it means:** More current events; CVSS 10.0 = maximum-severity remote code execution.
**💡 My way to think about it:** Housekeeping. Skip for the exam.

### Slide 6 — "How does this affect me?"
**What it shows:** Update your toolchain/browsers; **Peer deadline extended by one day.**
**What it means:** Practical to-dos and a deadline change.
**💡 My way to think about it:** Admin only — but note the deadline extension.

---

## PART A — Why caches exist (slides 7–13)

### Slide 7 — Previously: DMA & memory organisation
**What it shows:** Recap diagram — CPU/Memory/DMA on a bus, plus the 32×32 array with the 5-bit
decoder and 32-to-8 MUX/DEMUX from lecture 13.
**What it means:** Quick bridge: you now know how raw memory is built and how DMA moves blocks.
**💡 My way to think about it:** "You built the warehouse and the loading dock. Now we make it
*feel* fast."

### Slide 8 — Today: Caching
**What it shows:** The bus diagram now with a **C$ (cache)** between CPU and Memory. Three
sub-topics: **structure, policies, performance.**
**What it means:** The roadmap for the lecture: how a cache is *built* (structure/mapping), how
it *behaves* (read/write policies, replacement), and how we *measure* it (hit ratio, average
access time).
**💡 My way to think about it:** The three questions are **Where does data go? What happens on
access? How good is it?** Everything in the lecture answers one of these.

### Slide 9 — The processor–memory speed gap
**What it shows:** CPU speed doubles every ~2 years; DRAM speed doubles every ~7 years → the
**gap grows ~2× every 2 years**. Mentions the "power wall."
**What it means:** This is *the* reason caches exist. The CPU keeps getting faster much quicker
than main memory does, so without help the CPU would spend most of its time **stalled waiting for
memory**. "What does this mean for CPU operation?" → the CPU is increasingly **starved** of data.
**💡 My way to think about it:** A race car (CPU) and a bicycle (DRAM) that both get faster each
year — but the car improves way faster. Every year the car spends more time parked waiting for
the bike to deliver fuel. The cache is a **fuel can in the car** so it rarely waits.

### Slide 10 — The memory hierarchy
**What it shows:** The pyramid: **L1 (L1D/L1I) → L2 → L3 → Main Memory (L4) → Disks**. Going
**up** = faster + higher cost/bit + smaller; going **down** = bigger + cheaper. Plus an I/O cache.
**What it means:** No single memory is fast, big, and cheap, so we **stack levels**. Each level
is a fast buffer for the slower, larger one below. L1 is split into **instruction (L1I)** and
**data (L1D)** caches (so a fetch and a load don't collide — ties to pipelining §6.7).
- "Downsides of more components?" → more cost, power, complexity, and coherence problems.
- "How do we solve the speed gap?" → the hierarchy/caches. "Downside of this solution?" →
  complexity + the fact that a miss is now *more* expensive relative to a hit.
**💡 My way to think about it:** Your workspace. **Registers** = what's in your hands; **L1** =
your desk; **L2/L3** = a shelf behind you; **main memory** = a filing cabinet across the room;
**disk** = the basement archive. You keep what you use most within arm's reach.

### Slide 11 — "Let's quote some (old) numbers"
**What it shows:** A table of typical access times/sizes per level (Thiebaut, 2013); asks what's
wrong/changed/missing.
**What it means:** Concrete feel for the *orders of magnitude* — registers ≈ sub-ns, L1 ≈ 1 ns,
main memory ≈ tens of ns, disk ≈ millions of ns. The "what's changed" question = the numbers age
fast (and SSDs now sit between RAM and spinning disk).
**💡 My way to think about it:** Don't memorize the exact figures; memorize that **each level
down is roughly 10×–100× slower**. A miss that reaches disk is catastrophically slower than an L1
hit.

### Slide 12 — How the cache works (read & write overview)
**What it shows:**
- **READ:** miss → copy block into cache then read (possibly *read-through*); hit → read from
  cache.
- **WRITE:** miss → write to main memory; hit → write to cache, then either **store-through**
  (also write memory now) or set the **dirty bit** and write later.
**What it means:** The four cases of cache access. Key policy terms:
- **Read-through / load-through:** forward the requested word to the CPU as soon as it arrives,
  without waiting for the whole block (reduces miss penalty).
- **Write-through (store-through):** update cache *and* memory immediately — simple, but extra
  memory traffic.
- **Write-back (dirty bit):** update only the cache now; mark the block **dirty**; write it to
  memory later, when it's evicted — fewer memory writes, more common. **(book)**
**💡 My way to think about it:** Editing a document. **Write-through** = you save to the cloud
after every keystroke (safe, slow). **Write-back** = you edit locally and only upload when you
close the file (fast, but you must remember it's "dirty" / unsaved).

### Slide 13 — Why do caches work? Locality of reference
**What it shows:** Two kinds of locality:
- **Spatial:** we use data *close together* (e.g., array elements).
- **Temporal:** we reuse data we used *recently* (e.g., many TAs reading the same queue requests).
**What it means:** A cache would be useless if accesses were random. They're not — programs
cluster in space and time. **Spatial** locality justifies fetching a whole **block** (grab the
neighbors too). **Temporal** locality justifies **keeping** recently used blocks around.
**💡 My way to think about it:** **Spatial** = when you read one sentence, you'll probably read
the next (so bring the whole paragraph). **Temporal** = the word you just looked up in the
dictionary, you'll likely need again soon (so keep it on the desk). These two habits are the
entire reason caching pays off.

---

## PART B — Cache structure & the access algorithm (slides 14–20)

### Slide 14 — Performance model for an L1 cache
**What it shows:** Parameters and the formula:
```
hit ratio      = h          miss ratio = 1 − h
cache time     = c          memory time = m
Average access time = c + (1 − h)·m
```
**What it means:** This is the exam formula. Every access first checks the cache (costs **c**).
With probability **(1 − h)** it misses and must also pay the memory access **m**. So:
`t_avg = c + (1−h)·m`. The parameters depend on the **application/input**, the **cache policy**,
etc.
> **Note on the formula's shape:** this version *always* pays `c` (you always probe the cache),
> then adds `m` only on a miss. The textbook sometimes writes `t_avg = h·c + (1−h)·(c+m)`, which
> simplifies to the same `c + (1−h)·m`. Use the lecture's form.
**💡 My way to think about it:** You always open the desk drawer (c). Most of the time the file is
there (hit). Occasionally it isn't and you also trek to the filing cabinet (+m). The higher the
hit ratio h, the rarer that trek — so t_avg creeps toward just c. **High h is everything.**

### Slide 15 (deck 17) — Cache organisation: design goals
**What it shows:** The cache is **transparent** to the CPU/programmer; it stores **data** plus
**administration** (valid/in-out, clean/dirty); it is **block-based** to amortize overhead and
make lookups efficient.
**What it means:**
- **Transparent** = the program uses normal addresses and never "sees" the cache; the hardware
  silently intercepts. You don't write code to "use the cache."
- **Administration** = besides the data, each cache slot stores bookkeeping: a **tag** (which
  memory block is here), a **valid bit** (is this slot meaningful?), a **dirty bit** (was it
  modified?).
- **Block-based** = store data in blocks, not single bytes, so one tag covers many bytes
  (less overhead) and spatial locality is exploited.
**💡 My way to think about it:** A library book returned to a shelf. The **data** is the book's
text; the **administration** is the spine label (tag), a "shelved?" flag (valid), and a "someone
scribbled in it" sticky note (dirty). Transparent = you ask the librarian by title and never care
which shelf it's on.
> Deck jumps 14 → 17 (slides 15–16 of the original aren't in this PDF).

### Slide 16 (18) — Memory blocks
**What it shows:** A diagram: memory is divided into **blocks**, each block = several **words**;
the cache holds whole blocks.
**What it means:** The **block (line)** is the unit of transfer between memory and cache. When you
miss on one word, you pull in its *entire* block (its neighbors), banking on spatial locality.
**💡 My way to think about it:** You don't photocopy one line of a page — you copy the whole page
(block). Next time you need a nearby line, it's already on your desk.

### Slide 17 (20) — The cache access algorithm (write-back + write-allocate)
**What it shows:** Step list to access word *w* in block *B*:
1. Is block B in the cache?
2. If **MISS**: fetch B from memory → compute where it goes in the cache → is that spot free? →
   if not, **evict** the resident block → write B into that cache slot.
3. Access *w* in the cache.
**What it means:** This is the full miss-handling path for a **write-back, write-allocate** cache:
on *any* miss (read or write), you **bring the block into the cache first** (write-allocate), then
operate on it there. "Compute where it goes" = the **mapping function** (next section). "Evict"
= the **replacement algorithm** (last section). If the evicted block is **dirty**, it must be
written back to memory first.
**💡 My way to think about it:** To work on a file (B): check your desk; if it's not there, fetch
it from the cabinet, find a spot on the desk, and if the desk is full, first put away an old file
(and if you'd scribbled on it, re-file the updated version) — then work on your file at the desk.

---

## PART C — Cache mapping functions (slides 18–28)

### Slide 18 (21) — Section header: CACHE MAPPING FUNCTIONS
**What it shows:** Divider.
**What it means:** The central design question: **given a memory block, which cache slot(s) may
hold it?** Three answers coming: direct, fully associative, set-associative.

### Slide 19 (22) — Where to place blocks?
**What it shows:** The cache is smaller than memory, so **many memory blocks map to the same cache
slot**. Mapping can be **static (direct)**, **dynamic (fully associative)**, or **mixed (x-way set
associative)**. Hit ratio depends on mapping + locality.
**What it means:** Because the cache can't hold everything, blocks must *share* slots, and the
mapping rule decides the sharing. More freedom in placement → fewer forced collisions → higher
potential hit ratio, but harder/slower lookup. This is the core trade-off of the whole section.
**💡 My way to think about it:** Parking. **Direct** = assigned spots (your plate determines your
spot — instant to find, but two cars assigned the same spot fight). **Associative** = park
anywhere (flexible, but to find your car you scan the whole lot). **Set-associative** = assigned
to a small *zone*, any spot within it (compromise).

### Slide 20 (23) — The library analogy
**What it shows:** Mapping: Main memory → Library; Cache → bookcase at home; Block → book; Byte →
line in a book.
**What it means:** The lecture's running metaphor. A **word "address"** becomes "Author
Langendoen, line 6027": the **author** behaves like the block identifier, the **line** like the
byte offset within the block.
**💡 My way to think about it:** Your home bookcase (cache) is tiny vs the library (memory). The
mapping rules below are just *"which shelf at home may a given library book go on?"*

### Slide 21 (24) — Direct-Mapped Cache (analogy)
**What it shows:** Books A…Z; each author maps to a fixed bookcase slot (tag identifies the
author). Fast lookup, **not flexible**, prone to **thrashing** — e.g. authors 'Koen' and
'Langendoen' map to the same slot, so they can't both be cached at once.
**What it means:** **Direct mapping = each memory block has exactly ONE possible cache slot**
(`slot = block number mod number-of-slots`). Lookup is a single comparison (fast), but two hot
blocks that map to the same slot keep **evicting each other** — that repeated eviction of
still-needed data is **thrashing**.
**💡 My way to think about it:** One assigned shelf per author initial. Super fast to find, but if
you're actively reading two authors that share a shelf, you're forever swapping them in and out —
exhausting and slow (thrashing).

### Slide 22 (25) — Fully Associative Cache (analogy)
**What it shows:** Any book can go **anywhere** in the bookcase; to find one you must **check all
labels in parallel**. Slow lookup, **very flexible**, high potential hit ratio — 'Koen' and
'Langendoen' can both be cached simultaneously.
**What it means:** **Fully associative = a block may sit in ANY slot.** No forced collisions, so
the best hit ratio — but to check for a hit you compare the tag against **every** slot at once
(expensive hardware: one comparator per slot). The address has **no block/set field — just tag +
byte offset.**
**💡 My way to think about it:** Put any book on any shelf. Nothing ever forces two books to
clash, but finding a book means scanning every shelf simultaneously — flexible but costly.

### Slide 23 (26) — Direct-Mapped: the real address split
**What it shows:** Example — 16-bit address, 16-byte blocks (**4 byte bits**), 128 cache blocks
(**7 block bits**):
```
 tag (5) | block (7) | byte (4)      (5 + 7 + 4 = 16)
```
**What it means:** The address is sliced into three fields:
- **byte (4 bits):** which byte within the 16-byte block.
- **block (7 bits):** which of the 128 cache slots this block must go to (the "mod 128").
- **tag (5 bits):** which of the 2⁵ = 32 memory blocks that share this slot is actually present —
  compared against the stored tag to decide hit/miss.
**💡 My way to think about it:** Address = `[tag | slot | offset]`. The **slot** bits *point
directly* at one shelf (no searching); the **tag** bits confirm "is it the right book or an
impostor sharing this shelf?"; the **offset** picks the line.

### Slide 24 (27) — Direct-Mapped diagram + pros/cons
**What it shows:** Memory blocks 0,128,256,… all map to cache slot 0 (and 1,129,257,… to slot 1,
etc.); each cache slot stores a **tag + the block's words**. Questions: pros/cons? when is hit
ratio lowest?
**What it means:** Confirms the "mod" collision pattern: every 128th memory block competes for one
slot. **Pros:** simplest, fastest lookup (one comparison), cheap hardware, trivial replacement
(only one place to go). **Cons:** thrashing when hot blocks collide. **Hit ratio is lowest** when
a program repeatedly accesses two+ blocks that map to the **same slot** (e.g., striding through
arrays spaced exactly one cache-size apart).
**💡 My way to think about it:** The pigeonhole with assigned holes — great until two pigeons are
assigned the same hole and keep kicking each other out.

### Slide 25 (28) — Fully Associative: the real address split
**What it shows:** Example — 16-bit address, 16-byte blocks (**4 byte bits**), 4K memory blocks
(**12 bits**):
```
 tag (12) | byte (4)      (12 + 4 = 16)
```
**What it means:** With full freedom there's **no slot/set field**. The tag must identify the
block among **all** 4K memory blocks → 12 tag bits. On access, all slots' tags are compared in
parallel.
**💡 My way to think about it:** Since a book can be anywhere, its label must be its *full*
identity (12-bit tag), and you check every shelf's label at once.

### Slide 26 (29) — Fully Associative diagram + pros/cons
**What it shows:** Any memory block can land in any cache slot; each slot stores a tag + words.
Questions: pros/cons? when is hit ratio lowest?
**What it means:** **Pros:** best flexibility → highest hit ratio, no thrashing from mapping
conflicts. **Cons:** expensive (a comparator per slot), slower/more power for the parallel search,
and needs a real **replacement algorithm** (any slot is a candidate to evict). **Hit ratio is
lowest** only when the **working set simply exceeds the cache capacity** (capacity misses) — never
from conflicts.
**💡 My way to think about it:** Maximum freedom, maximum search cost. You only ever miss because
the bookcase is genuinely too small, not because of silly assigned-shelf clashes.

### Slide 27 (30) — Set-Associative: the idea
**What it shows:** Goal: **control the trade-off** between performance and flexibility. Idea:
**partly direct, partly associative** — group blocks into **sets** (direct-mapped *to a set*),
then do a **parallel search within the set** (associative *inside the set*).
**What it means:** The best-of-both compromise. A block is *forced* to one **set** (like direct
mapping, cheap to locate the set) but may occupy **any slot within that set** (like associative,
reduces conflicts). A **k-way** cache has **k slots per set**, so you only compare **k** tags, not
all of them.
**💡 My way to think about it:** Assigned to a small **zone** of the parking lot, park in any spot
within your zone. Finding your car = scan just your zone (k spots), not the whole lot — far less
conflict than one assigned spot, far cheaper than scanning everything.

### Slide 28 (31) — Set-Associative: address split vs the extremes
**What it shows:** Side-by-side for the 16-bit, 16-byte-block example:
```
Fully associative:  tag(12)           | byte(4)
2-way set assoc.:   tag(6) | set(6)    | byte(4)
Direct mapped:      tag(5) | block(7)  | byte(4)
```
Question: "how many sets?"
**What it means:** Set-associative sits **between** the two extremes, and you can see it in the
field sizes. As you add ways (more slots per set), the **set field shrinks** and the **tag field
grows** — moving from "direct" (big index, small tag) toward "fully associative" (no index, huge
tag). For 2-way here: 128 blocks ÷ 2 = **64 sets** → 6 set bits; tag = 16 − 6 − 4 = 6.
**💡 My way to think about it:** The three rows are one continuous dial. Turn it toward fewer ways
→ more "index" bits (direct). Turn it toward more ways → more "tag" bits (associative).
Set-associative is wherever you stop the dial.

---

## PART C′ — Set-associative detail & edge cases (slides 29–30)

### Slide 29 (32) — Set-Associative diagram
**What it shows:** A 2-way example: **128 blocks, 64 sets** (2 blocks per set); each set has 2
tagged slots; memory blocks map to a set, then either slot.
**What it means:** Concretely: `set = block number mod (number of sets)`; within the chosen set,
the block may occupy either slot, and both slots' tags are compared in parallel. More ways →
fewer conflict misses but more comparators and a bigger tag.
**💡 My way to think about it:** 64 two-car garages. Your block is assigned a garage (set) but can
take either bay. Two clashing blocks can now coexist (two bays) instead of evicting each other —
thrashing largely solved, cost still modest.

### Slide 30 (36) — Question time: the extremes of x-way
**What it shows:** What is an **x-way** cache when:
1. **x = 1** → ?
2. **x = |blocks in cache|** → ?
3. Most common in practice: **8-way**.
**What it means:** This nails down that set-associativity is a *spectrum*:
- **x = 1** (one slot per set) = **direct-mapped** (each block has exactly one place).
- **x = all blocks** (one single set containing everything) = **fully associative** (a block can
  be anywhere).
- Real CPUs usually pick something in between — **8-way** is a common sweet spot (most of the
  hit-ratio benefit, affordable search).
**💡 My way to think about it:** 1-way = assigned spots; all-ways = park anywhere; 8-way = zones
of 8 — the practical middle that industry settled on.
> Deck jumps 32 → 36 (slides 33–35 of the original aren't in this PDF).

---

## PART D — Replacement algorithms (slides 31–37)

### Slide 31 (38) — Section header: CACHE REPLACEMENT ALGORITHMS
**What it shows:** Divider.
**What it means:** When a set/cache is full and you must bring in a new block, **which resident
block do you evict?** (Only matters for associative and set-associative — direct mapping has no
choice.)
**💡 My way to think about it:** The desk is full; which file do you put away to make room for the
new one? Ideally the one you're least likely to need next.

### Slide 32 (39) — Least Recently Used (LRU)
**What it shows:** Keep an **age counter** per block. For a **2^x-way** cache you need an
**x-bit** counter per block. Algorithm:
- **Hit:** reset the hit block's counter to 0 (youngest); increment the counters that were lower.
- **Miss, set full:** evict the block with the **highest** counter (oldest), reset its counter;
  increment the others.
- **Miss, set not full:** place in an empty slot; increment the others.
**What it means:** **LRU evicts the block unused for the longest time** — the best practical match
to temporal locality. The counters act as an ordering: **0 = youngest (just used), highest =
oldest (evict me next)**. Every access ages the blocks that were "younger-than-or-equal" so the
ordering stays consistent. A k-way set needs enough bits to rank k blocks (x bits for 2^x ways).
**💡 My way to think about it:** A stack of papers where you always put the one you just touched
on **top**. The paper at the **bottom** (highest age = oldest) is the one you toss when you need
room. "Reset to 0" = "put on top"; "increment lower counters" = "everything above it slides
down."

### Slide 33 (40) — LRU Example 1: a cache **hit** (4 blocks/set, x=2)
**What it shows:** Ages before → after on a hit to the block aged `10`:
```
 01 → 10   (increased: became older)
 00 → 01   (increased: became older)
 10 → 00   HIT → now youngest (top)
 11 → 11   (unchanged: already older)
```
**What it means:** The **hit** block is reset to `00` (youngest). Blocks that were **younger than
it** (ages `01`, `00`) get **incremented** (they're now relatively older). Blocks that were
**already older** (age `11`) stay put — their position relative to the hit block doesn't change.
**💡 My way to think about it:** You re-read a file, so it goes back on top (00). The files that
were above it slide down one. Files already below it don't move.

### Slide 34 (41) — LRU Example 2: a **miss**, set **full** (x=2)
**What it shows:**
```
 01 → 10   (increased)
 00 → 01   (increased)
 10 → 11   (increased)
 11 → 00   MISS: this was oldest → EVICTED, new block placed here → youngest
```
**What it means:** The **oldest** block (age `11`, highest) is the victim: evict it, put the new
block in that slot, and reset it to `00` (youngest). **All** other blocks get incremented (they
all just got one step older relative to the brand-new block).
**💡 My way to think about it:** Desk full → toss the bottom (oldest) file, drop the new file on
top (00), and every remaining file slides down one.

### Slide 35 (42) — LRU Example 3: a **miss**, set **not full** (x=2)
**What it shows:** Two slots are **EMPTY**:
```
 01 → 10   (increased)
 00 → 01   (increased)
 EMPTY (11) → 00   new block placed in empty spot → youngest
 EMPTY (11) → 11   still empty (unchanged)
```
**What it means:** No eviction needed — just drop the new block into an **empty** slot and make it
youngest (`00`); increment the occupied ones; leave the remaining empties alone.
**💡 My way to think about it:** Desk has free space → just place the new file on top; nothing has
to be thrown away.

### Slide 36 (43) — Other replacement algorithms
**What it shows:** Alternatives to LRU:
- **FIFO** — evict the **oldest-inserted** block (First-In-First-Out), regardless of recent use.
- **LFU** — evict the **Least-Frequently Used** block (fewest accesses).
- **Random** — evict a random block.
Prompts: how? why? when?
**What it means:** LRU is effective but costs counters and updates. The alternatives trade
accuracy for simplicity: **FIFO** ignores reuse (can evict a hot block that happened to arrive
early); **LFU** tracks frequency but can keep stale "once-popular" blocks; **Random** is almost
free and surprisingly decent, used when LRU hardware is too expensive. **(book: LRU is the usual
choice; FIFO/random are cheaper approximations.)**
**💡 My way to think about it:** LRU = "toss what I haven't touched longest" (smart, bookkeeping).
FIFO = "toss whatever's been here longest" (even if I use it daily). LFU = "toss what I use least
often." Random = "grab any file and toss it" (cheap, no records).

### Slide 37 (44) — Next: Virtual Memory
**What it shows:** Teaser for the next lecture — **virtual memory.**
**What it means:** The next level of the hierarchy illusion: letting each program believe it has a
huge, private memory, with pages swapped between RAM and disk (the page table + TLB are
*literally a cache for address translations* — the same ideas you learned today).
**💡 My way to think about it:** Caching taught you "fast small copy of a slow big thing." Virtual
memory applies the *same trick* one level down — RAM becomes a "cache" for the disk, and the TLB
is a cache for the page table.

---

## Big-picture connections
- **The speed gap (slide 9) is the "why."** Everything else is engineering around it.
- **Locality (slide 13) is the "why it works."** Spatial → fetch whole blocks; temporal → keep
  recent blocks + use LRU.
- **The three design axes:** *mapping* (where a block may go: direct ↔ set ↔ associative),
  *policies* (read/write: write-through vs write-back, write-allocate), *replacement* (who to
  evict: LRU/FIFO/LFU/random). All are judged by **one scoreboard: the hit ratio h**, which drives
  `t_avg = c + (1−h)·m`.
- **Direct ↔ fully associative is one spectrum**, and **set-associative is the dial between them**
  (slides 28 & 30): x=1 is direct, x=all is fully associative, x=8 is the common sweet spot.

## Quick self-check (close the file and answer)
1. Why do caches exist at all — what trend makes them necessary? *(slide 9)*
2. Define spatial vs temporal locality, and say which cache design decision each one justifies.
   *(slide 13)*
3. Write the average-access-time formula and explain each term. *(slide 14)*
4. Write-through vs write-back: what does each do on a write hit, and what is the dirty bit for?
   *(slide 12)*
5. For a 16-bit address, 16-byte blocks, 128 cache blocks: give the address-field split for
   **direct**, **fully associative**, and **2-way set-associative**. *(slides 23, 25, 28)*
6. What is **thrashing**, which mapping suffers from it, and why? *(slide 21/24)*
7. In an x-way set-associative cache, what do **x = 1** and **x = (all blocks)** correspond to?
   *(slide 30)*
8. State the LRU rule for: a hit, a miss with a full set, and a miss with a non-full set.
   *(slides 32–35)*
9. How many age-counter bits per block does a 2^x-way LRU cache need, and why? *(slide 32)*
10. Name two alternatives to LRU and one reason you'd pick each over LRU. *(slide 36)*

---

*End of deep slide-by-slide guide. Pair with `Chapter8_The_Memory_System_StudyGuide.md`,
`Chapter8_MindMaps.md`, and `Lecture13_Memory_SlideBySlide.md`.*
