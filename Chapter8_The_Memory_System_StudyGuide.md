# Chapter 8 — The Memory System

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 267–332 (Sections 8.1 → 8.12)

> **Read Chapters 1 and 6 first.** Chapter 1 introduced the *memory hierarchy* idea;
> Chapter 6 showed how cache misses stall the pipeline. Chapter 8 is where the memory
> system is explained in full: the circuits, the cache, virtual memory, and disks.

---

## 0. How to Start Learning This Chapter (read this first)

Chapter 8 is long and spans two very different worlds: **circuits** (how a memory cell
works) and **systems** (cache + virtual memory policy). Don't read front-to-back blindly —
follow this path.

### Step 1 — Anchor to the founding tension
The entire chapter exists to resolve one impossibility: memory cannot be **fast, large,
and cheap** at the same time. The answer is a **hierarchy** — small/fast near the CPU,
large/slow/cheap far from it. Every section is either *a level of the hierarchy* or *a
trick to hide the slow levels*. Keep asking: *"which problem in the hierarchy is this
solving?"*

### Step 2 — Learn the vocabulary spine (do this before any detail)
The chapter hangs on a handful of words. Learn these first:

| Term | One-line meaning |
|------|------------------|
| **Access time** | Time from starting a transfer to completing it. |
| **Cache block / line** | A contiguous chunk of memory moved as a unit into the cache. |
| **Hit / Miss** | Requested item is / is not already in the cache. |
| **Tag** | High-order address bits stored with a cache block to identify it. |
| **Page** | A fixed-size block of the virtual address space. |
| **TLB** | A small cache of page-table entries inside the MMU. |

### Step 3 — Follow this section order (it's a dependency chain)
```
8.1 Basic Concepts        ← address space, access vs cycle time  (START HERE)
      │
8.2 Semiconductor RAM     ← SRAM / DRAM / SDRAM circuits
8.3 Read-Only Memories    ← ROM → PROM → EPROM → EEPROM → Flash
8.4 Direct Memory Access  ← block transfer without the CPU
      │
8.5 Memory Hierarchy      ← the big picture that ties it together
      │
8.6 Cache Memories        ← THE HEART: locality, mapping, replacement
   ├ 8.6.1 Mapping Functions   (direct / associative / set-associative)
   └ 8.6.2 Replacement Algorithms (LRU)
      │
8.7 Performance            ← hit rate, miss penalty, average access time
      │
8.8 Virtual Memory         ← pages, page table, TLB, page faults
8.9 Memory Management      ← user/system space, protection
      │
8.10 Secondary Storage     ← magnetic disks / optical / tape
```

### Step 4 — Prioritize for an exam
- **Must master (draw it / compute it yourself):** 8.6 cache mapping (direct vs
  associative vs set-associative, and the address field split), 8.7 average access time
  `t_avg = hC + (1 − h)M`, 8.8 virtual-address translation with the TLB.
- **Understand conceptually:** SRAM vs DRAM, why DRAM needs refresh, DMA sequence,
  write-through vs write-back.
- **Know the facts/comparisons:** the ROM family evolution, the hierarchy ordering, disk
  seek/rotational latency.

### Step 5 — Active-recall checklist
After each section, close the book and try to:
1. Draw the diagram from memory.
2. Say out loud the *sequence of events* (e.g., a cache miss, a DMA transfer, a page fault).
3. Explain the *trade-off* that section introduced (speed vs cost vs complexity).

---

## Table of Contents
1. [Section 8.1 — Basic Concepts](#1-section-81--basic-concepts)
2. [Section 8.2 — Semiconductor RAM Memories](#2-section-82--semiconductor-ram-memories)
3. [Section 8.3 — Read-Only Memories](#3-section-83--read-only-memories)
4. [Section 8.4 — Direct Memory Access (DMA)](#4-section-84--direct-memory-access-dma)
5. [Section 8.5 — Memory Hierarchy](#5-section-85--memory-hierarchy)
6. [Section 8.6 — Cache Memories](#6-section-86--cache-memories)
7. [Section 8.6.1 — Mapping Functions](#7-section-861--mapping-functions)
8. [Section 8.6.2 — Replacement Algorithms](#8-section-862--replacement-algorithms)
9. [Section 8.7 — Performance Considerations](#9-section-87--performance-considerations)
10. [Section 8.8 — Virtual Memory](#10-section-88--virtual-memory)
11. [Section 8.9 — Memory Management Requirements](#11-section-89--memory-management-requirements)
12. [Section 8.10 — Secondary Storage](#12-section-810--secondary-storage)
13. [Glossary](#13-glossary)
14. [Self-Test Questions](#14-self-test-questions)

---

## 1. Section 8.1 — Basic Concepts

The **maximum memory size** is set by the **addressing scheme**: a processor that
generates *k*-bit addresses can address up to **2^k** locations (the **address space**).

| Address width | Address space |
|---------------|---------------|
| 16-bit | 2¹⁶ = 64K locations |
| 32-bit | 2³² = 4G locations |
| 64-bit | 2⁶⁴ ≈ 16E locations |

In a **byte-addressable** machine with 32-bit addresses, the high-order 30 bits select the
word and the low-order 2 bits select the byte within the word.

The processor–memory connection uses **address, data, and control lines** (Figure 8.1).
The control lines carry the Read/Write command and byte/word size, plus timing. The
memory signals completion with **MFC** (Memory Function Completed); the processor then
advances to its next step.

**Two speed measures:**
- **Access time** — time from initiating a word transfer to completing it.
- **Cycle time** — minimum delay between two *successive* operations (slightly longer than
  access time).

A memory is a **random-access memory (RAM)** if access time is the **same for every
location**, regardless of address. This is the opposite of serial devices (disk, tape),
whose access time depends on position.

**Block transfers:** data move between main memory↔cache and main memory↔disk not one
word at a time but in **contiguous blocks** of tens to thousands of words. The ability to
read/write blocks at high speed is a critical performance parameter.

> **Checkpoint:** What determines the maximum memory size, and what's the difference
> between access time and cycle time?

---

## 2. Section 8.2 — Semiconductor RAM Memories

Memory chips are a grid of **cells** connected by **word lines** (select a row) and **bit
lines** (carry the data). Two families:

### Static RAM (SRAM)
- Each cell stores a bit in a **latch** (two cross-coupled inverters / transistors).
- Holds its value **as long as power is applied** → called *static*.
- **Volatile:** loses contents when power is removed.
- **Very fast** (access times of a few nanoseconds); low power in CMOS.
- Many transistors per cell → **expensive, low density**.
- **Use:** cache memory.

### Dynamic RAM (DRAM)
- Each cell stores a bit as **charge on a tiny capacitor** (just one transistor + capacitor).
- Charge **leaks away** → the cell must be **refreshed** periodically (e.g., every row
  within ~64 ms).
- Very **dense and cheap** → **use:** main memory.
- **Asynchronous DRAM** uses **RAS** (row address strobe) and **CAS** (column address
  strobe) to latch a row then a column.

### Synchronous DRAM (SDRAM)
- DRAM whose operation is **synchronized to a clock**.
- Built-in **refresh circuitry** and address/data registers.
- **Burst mode:** give a starting address, then the chip **auto-increments** the column and
  streams consecutive words — fast block transfers.
- Early SDRAMs ran at ~133 MHz; modern ones exceed 1 GHz.

### Double-Data-Rate SDRAM (DDR)
- Transfers data on **both the rising and falling edges** of the clock → double the data
  rate without raising the clock frequency.
- **Rambus** is a competing (proprietary) high-bandwidth technology.

> **Memory hook:** *Static* sits still (latch, no refresh). *Dynamic* drains (capacitor,
> needs refresh).

> **Checkpoint:** Why does DRAM need refresh but SRAM doesn't? Why is SRAM used for cache
> and DRAM for main memory?

---

## 3. Section 8.3 — Read-Only Memories

All **nonvolatile** — they keep contents with power off. Useful for boot code / firmware.
The family is an **evolution of "how can we (re)write it?"**

| Type | How it's written | Erasable? |
|------|------------------|-----------|
| **ROM** | At **manufacture** (mask-programmed) | No |
| **PROM** | By the user **once** (blow fuses) | No |
| **EPROM** | Electrically programmed | Yes, by **UV light** (whole chip) |
| **EEPROM** | Electrically programmed | Yes, **electrically**, byte-level, in-circuit |
| **Flash** | Electrically programmed | Yes, **by block/sector** |

**Flash memory** gives high density at low cost and is the basis of:
- **Flash cards** (a.k.a. memory keys / USB sticks) — chips on a small card with a standard
  interface.
- **Flash drives (SSDs)** — emulate hard disks; **solid-state, no moving parts** → faster
  access, shock-resistant, lower power (but historically lower capacity and higher cost/bit
  than magnetic disks).

> **Checkpoint:** What distinguishes EPROM, EEPROM, and Flash in how they're erased?

---

## 4. Section 8.4 — Direct Memory Access (DMA)

**Problem:** program-controlled I/O (Chapter 3) moves one word at a time, and every word
costs several instructions (poll/interrupt, move data, increment address, decrement count)
— huge overhead for a large block.

**Solution — DMA:** a **DMA controller** transfers a whole block **directly** between an
I/O device and main memory **without the CPU doing each word**. It performs the work the
CPU would otherwise do: supplies the memory address, generates control signals,
increments the address, and tracks the count.

**DMA controller registers** (Figure 8.12):
1. **Starting address**
2. **Word count**
3. **Status and control**, including:
   - **R/W** bit — direction of transfer
   - **IE** (bit 30) — interrupt-enable
   - **Done** — set when the block is finished
   - **IRQ** — set when the controller has requested an interrupt

**Sequence:**
1. The CPU (an OS routine) writes the **start address, word count, and direction** to the
   controller — then is free to do other work.
2. The controller transfers each word, supplying addresses and control signals.
3. It increments the address and counts down the words.
4. When the whole block is done, it sets **Done** and raises an **interrupt**.

**Bus sharing:** because both the CPU and the DMA controller want the memory bus, the DMA
transfer uses either **cycle stealing** (grab one bus cycle at a time between CPU accesses)
or **burst/block mode** (hold the bus for the whole block).

> **Checkpoint:** What three things does the CPU give the DMA controller to start a
> transfer, and how does the CPU learn the transfer finished?

---

## 5. Section 8.5 — Memory Hierarchy

The hierarchy is the answer to the fast/large/cheap impossibility. From top (fastest,
smallest, most expensive per bit) to bottom (slowest, largest, cheapest):

```
Processor registers      ← fastest, tiny
      ↓
Cache (SRAM, often on-chip, multi-level L1/L2/L3)
      ↓
Main memory (DRAM/SDRAM)
      ↓
Secondary storage (magnetic disk, flash SSD)
```

Each level acts as a fast **buffer** for the larger, slower level below it. Because of
**locality of reference**, a small fast level can satisfy most requests, so the CPU
*perceives* the speed of the top level with the capacity of the bottom level.

> **Checkpoint:** State the hierarchy levels in order and the property (locality) that
> makes it work.

---

## 6. Section 8.6 — Cache Memories

A **cache** is a small, fast memory placed between the processor and main memory to make
main memory *appear* much faster. Its effectiveness relies on **locality of reference**:
- **Temporal locality:** a recently used item is likely to be used again soon → bring it
  into the cache.
- **Spatial locality:** items near a used item are likely to be used soon → bring in a
  whole **block (line)**, not just one word.

The correspondence between memory blocks and cache positions is the **mapping function**
(§8.6.1). When the cache is full, a **replacement algorithm** (§8.6.2) picks the victim.

### Hits
- **Read hit:** served from the cache; main memory is **not** involved.
- **Write hit:** two policies —
  - **Write-through:** update **both** cache and memory. Simpler, but causes extra memory
    writes.
  - **Write-back (copy-back):** update **only the cache** and set a **dirty/modified bit**;
    memory is updated **later**, when the block is evicted. Most common, exploits fast block
    transfers.

### Misses
- **Read miss:** copy the whole block from memory into the cache, then forward the word.
  **Load-through / early restart** forwards the requested word *first* to reduce waiting.
- **Write miss:** write-through → write straight to memory; write-back → bring the block in,
  then overwrite in the cache.

Many processors use **separate instruction and data caches** so a fetch and a data access
can proceed in parallel, avoiding the structural stall from Chapter 6 (§6.7).

> **Checkpoint:** Explain temporal vs spatial locality, and write-through vs write-back.

---

## 7. Section 8.6.1 — Mapping Functions

**Running example (from the book):** cache = **128 blocks** of **16 words** each (2K words
total); main memory = **64K words** = **4K blocks** of 16 words; **16-bit** address.
So the address splits into a **Word** field (4 bits, 16 words/block) plus fields that
locate the block.

### Direct Mapping
- Memory block *j* maps to **cache block (j mod 128)**.
- Address fields: **Tag (5) | Block (7) | Word (4)**.
- **Replacement is trivial** — each memory block has exactly one possible cache slot.
- **Weakness:** **contention** — blocks 1, 129, 257… all fight for cache block 1, even when
  the cache isn't full.

### Associative Mapping
- A memory block can go in **any** cache position.
- Address fields: **Tag (12) | Word (4)**.
- To find a block you must **compare its tag against every block's tag in parallel**
  (an **associative search**).
- **Most flexible**, best cache utilization — but **most expensive**, and needs a
  replacement algorithm.

### Set-Associative Mapping
- A compromise: cache lines are grouped into **sets**; a memory block maps to **one
  specific set** but can occupy **any line within that set**.
- Address fields: **Tag | Set | Word**.
- A **k-way set-associative** cache has **k blocks per set**. (Example: 64 sets of 2 blocks
  → 6-bit set field, a **two-way** search.)
- **Extremes:** 1 block/set = **direct mapping**; 128 blocks/set = **fully associative**.

**Performance (from the book's example):** associative performs best, set-associative is
next, direct is worst. But fully associative is expensive, so **set-associative is the best
practical compromise.**

> **Checkpoint:** For the running example, give the address-field split for direct and for
> associative mapping. Why does set-associative reduce contention?

---

## 8. Section 8.6.2 — Replacement Algorithms

When a miss occurs and the candidate set/cache is full, the controller must evict a block.
By locality, the block **least likely to be needed soon** should go.

- **LRU (Least Recently Used):** replace the block unused for the longest time. Best match
  to locality; implemented with small counters/age bits per block in a set.
- Other schemes: **FIFO**, **random** — cheaper but generally less effective.

Direct mapping needs **no** replacement algorithm (only one possible slot). Associative and
set-associative mapping **do**.

> **Checkpoint:** Why does direct mapping not need a replacement algorithm?

---

## 9. Section 8.7 — Performance Considerations

The payoff of the whole hierarchy is measured by how often requests hit the fast levels.

- **Hit rate (h):** fraction of accesses found in the cache. **Miss rate = 1 − h.**
  High-performance machines need **h well over 0.9**.
- **Miss penalty (M):** the extra time to bring a block from the slower level while the
  processor stalls.

**Average access time (one-level cache):**
```
t_avg = h·C + (1 − h)·M
```
where **C** = cache access time, **M** = miss penalty.

**Worked miss penalty (Example 8.1):** cache access = τ, main memory = 10τ, block = 8
words (first word 10τ, next 7 at 1τ each), plus τ to probe the cache and τ to forward the
word (no load-through):
```
M = τ + 10τ + 7τ + τ = 19τ
```
With 130 accesses per 100 instructions, instruction hit rate 0.95 and data hit rate 0.9,
the cache makes memory appear **~4.7× faster** (and ~7.3× if main memory were 20τ).

**Improving performance:**
- **Raise the hit rate:** larger cache (↑ cost) or **larger block** to exploit spatial
  locality — but only up to a point: blocks too large waste fetches and lengthen M.
  **Popular block sizes: 16–128 bytes.**
- **Reduce the miss penalty:** **load-through / early restart** — resume as soon as the
  needed word arrives instead of waiting for the whole block.

> **Checkpoint:** Write the average-access-time equation and explain why bigger blocks help
> only up to a point.

---

## 10. Section 8.8 — Virtual Memory

**Idea:** keep only the **active portions (pages)** of a program in main memory; the rest
stay on **disk**. The program sees a memory **much larger than physical RAM**. Movement
between disk and memory is **transparent** to the application. The **Memory Management Unit
(MMU)** performs the translation.

**Addresses and units:**
- A **virtual address** = **virtual page number** (high bits) + **offset** (low bits,
  within the page).
- A main-memory slot that holds one page is a **page frame**.

**Page table:** one entry per virtual page, giving the **page frame** (physical location)
plus **control bits**:
- **Valid** bit — is the page actually in memory?
- **Modified / dirty** bit — written to while resident? (decides write-back to disk)
- **Access-rights** bits — read-only vs read/write, etc.

The table is located via the **page table base register** + virtual page number. The table
can be large, so it lives in main memory.

**Translation Lookaside Buffer (TLB):** a small **associative (or set-associative) cache of
the most-recently-used page-table entries**, kept inside the MMU.
- **TLB hit:** physical address obtained immediately.
- **TLB miss:** read the entry from the page table in memory, update the TLB.
- The OS must **invalidate** TLB entries when it changes the page table (keep them
  consistent).

**Page fault:** access to a page **not in memory**. The MMU raises an **exception**; the OS
**loads the page from disk** (and may run another program during the long wait). If memory
is full, a **page is replaced** (LRU-like, using the page-table usage bits); a **dirty page
is written back to disk first**.

> **Important:** virtual memory uses **write-back only** — the disk is far too slow for
> write-through.

> **Checkpoint:** Trace a virtual address through TLB → page table → physical address, and
> describe what a page fault triggers.

---

## 11. Section 8.9 — Memory Management Requirements

Memory-management routines are part of the **operating system**.

- **System space vs user space:** OS routines live in a separate virtual address space
  (**system space**); each user program has its own **user space**, arranged by giving each
  a **separate page table**. Switching spaces = changing the **page table base register**.
- **Protection:** no program may corrupt another's data or code. Processors run in one of
  two modes:
  - **Supervisor mode** — for OS routines; can execute **privileged instructions** (e.g.,
    modifying the page table base register).
  - **User mode** — for applications; privileged instructions are **forbidden**, so a user
    program can't touch other users' or the system's page tables.
- **Shared pages:** the OS can make a page appear in two page tables so programs can share
  it, with per-table **access-rights** bits (e.g., one program read/write, another
  read-only).

> **Checkpoint:** How do supervisor/user modes and per-program page tables provide
> protection?

---

## 12. Section 8.10 — Secondary Storage

Nonvolatile storage at the bottom of the hierarchy: huge, cheap per bit, slow.

- **8.10.1 Magnetic hard disks:** rotating **platters** divided into **tracks** and
  **sectors**; a **read/write head** on a moving arm. Access time = **seek time** (move the
  arm to the track) + **rotational latency** (wait for the sector) + transfer time. Very
  high capacity, lowest online cost per bit.
- **8.10.2 Optical disks:** **CD / DVD / Blu-ray**; a **laser** reads **pits and lands**.
  Removable, good for distribution and archival.
- **8.10.3 Magnetic tape:** **sequential-access**; used for **backup and archive**; lowest
  cost per bit but slowest access.

> **Checkpoint:** What two delays dominate hard-disk access time, and how does tape differ
> in access pattern?

---

## 13. Glossary

| Term | Meaning |
|------|---------|
| **Address space** | Set of locations addressable by the processor (2^k for k-bit addresses). |
| **Access time** | Time from initiating a word transfer to its completion. |
| **Cycle time** | Minimum delay between two successive memory operations. |
| **RAM** | Random-access memory — uniform access time for all locations. |
| **SRAM** | Static RAM — latch-based, fast, volatile, costly; used for cache. |
| **DRAM** | Dynamic RAM — capacitor-based, dense, cheap, needs refresh; used for main memory. |
| **SDRAM / DDR** | Clocked DRAM; DDR transfers on both clock edges. |
| **Refresh** | Periodic rewrite of DRAM cells to replace leaked charge. |
| **ROM/PROM/EPROM/EEPROM/Flash** | Nonvolatile memories, varying in how they're (re)written/erased. |
| **DMA** | Direct Memory Access — block transfer managed by a controller, not the CPU. |
| **Cache block / line** | Contiguous group of words moved into the cache as a unit. |
| **Hit / Miss** | Requested item is / isn't in the cache. |
| **Tag** | High-order address bits stored to identify a cached block. |
| **Write-through / Write-back** | Update memory immediately / only on eviction (dirty bit). |
| **Direct / Associative / Set-associative** | Cache mapping schemes (one slot / any slot / any slot within a set). |
| **LRU** | Least-Recently-Used replacement algorithm. |
| **Hit rate (h) / Miss penalty (M)** | Fraction of hits / extra time on a miss. |
| **Virtual memory** | Keep active pages in RAM, rest on disk; RAM appears larger. |
| **Page / Page frame** | Fixed-size block of virtual space / its slot in physical memory. |
| **Page table** | Maps virtual pages to page frames + control bits. |
| **TLB** | Translation Lookaside Buffer — cache of page-table entries in the MMU. |
| **Page fault** | Access to a page not currently in main memory. |
| **MMU** | Memory Management Unit — performs address translation. |
| **Seek time / rotational latency** | Disk arm move time / wait for sector to rotate under head. |

---

## 14. Self-Test Questions

1. A processor generates 32-bit byte addresses. How many byte locations can it address,
   and which bits select the word vs the byte in a 32-bit-word, byte-addressable machine?
2. Why does a DRAM cell need refreshing while an SRAM cell does not? Which is used for cache
   and which for main memory, and why?
3. Put in order and explain: ROM, PROM, EPROM, EEPROM, Flash — by how each is erased/written.
4. List the three DMA controller registers and give the DMA transfer sequence from CPU
   setup to completion interrupt.
5. State the memory hierarchy from fastest to slowest and name the property that makes it
   effective.
6. Define temporal and spatial locality, and explain how each motivates a cache design
   decision.
7. Compare write-through and write-back: what does each do on a write hit, and which is more
   common?
8. For a cache of 128 blocks × 16 words and a 64K-word memory (16-bit address), give the
   address-field split for **direct** and for **associative** mapping. What are the fields
   for a two-way set-associative cache?
9. Compute the miss penalty M for Example 8.1 (cache τ, memory 10τ, 8-word block, no
   load-through) and write the average-access-time formula.
10. Trace a virtual address to a physical address through the TLB and page table. What
    happens on a TLB miss? On a page fault?
11. How do supervisor/user modes and separate per-program page tables enforce memory
    protection?
12. What two delays dominate magnetic-disk access time, and how does magnetic tape differ in
    access pattern?

---

*End of study guide. Pair this with `Chapter8_MindMaps.md` for the visual summaries.*
