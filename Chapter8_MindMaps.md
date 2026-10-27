# Chapter 8 — The Memory System · Mind Maps

**Companion to:** `Chapter8_The_Memory_System_StudyGuide.md`

> View with any Mermaid-capable tool (VS Code + Mermaid extension, Obsidian, Typora,
> GitHub, GitLab). Each diagram also has a plain-text ASCII fallback. Export a single
> ```mermaid``` block to PNG/SVG at https://mermaid.live.

---

## Table of Contents
1. [How to Start Learning (the path)](#1-how-to-start-learning--the-path)
2. [Master Map — The Whole Chapter](#2-master-map--the-whole-chapter)
3. [Basic Concepts & the Memory Hierarchy](#3-basic-concepts--the-memory-hierarchy)
4. [Semiconductor RAM — SRAM vs DRAM vs SDRAM](#4-semiconductor-ram)
5. [Read-Only Memories (ROM family)](#5-read-only-memories)
6. [Direct Memory Access (flow)](#6-direct-memory-access)
7. [Cache — Hit/Miss & Write Policies (decision)](#7-cache--hitmiss--write-policies)
8. [Cache Mapping Functions](#8-cache-mapping-functions)
9. [Cache Performance — Average Access Time](#9-cache-performance)
10. [Virtual Memory & Address Translation (flow)](#10-virtual-memory--address-translation)
11. [Secondary Storage](#11-secondary-storage)

---

## 1. How to Start Learning — the path

```mermaid
flowchart TD
    A[START: you know Ch.1<br/>memory hierarchy idea] --> B[Step 1: anchor the GOAL<br/>fast + large + cheap<br/>is impossible → hierarchy]
    B --> C[Step 2: learn 6 words<br/>access time · cache block ·<br/>hit/miss · tag · page · TLB]
    C --> D[8.1 Basic Concepts<br/>address space · access vs cycle time]
    D --> E[8.2 Semiconductor RAM<br/>SRAM · DRAM · SDRAM]
    E --> F[8.3 ROM family<br/>ROM→PROM→EPROM→EEPROM→Flash]
    F --> G[8.4 DMA<br/>block transfer w/o the CPU]
    G --> H[8.5 Memory Hierarchy<br/>the big picture]
    H --> I[8.6 Cache  ← THE CORE<br/>locality · mapping · replacement]
    I --> J[8.7 Performance<br/>hit rate · miss penalty · t_avg]
    J --> K[8.8 Virtual Memory<br/>pages · page table · TLB · faults]
    K --> L[8.9 Mem Management<br/>user/supervisor · protection]
    L --> M[8.10 Secondary Storage<br/>disks · optical · tape]
    M --> N[Active recall:<br/>redraw diagram · say sequence · state trade-off]

    style A fill:#e1d5e7,stroke:#9673a6
    style I fill:#f8cecc,stroke:#b85450
    style N fill:#d5e8d4,stroke:#82b366
```

**ASCII fallback:**
```
HOW TO START
START (you know Ch.1 memory-hierarchy idea)
  └─ Step 1: anchor the GOAL — fast+large+cheap is impossible → hierarchy solves it
      └─ Step 2: learn 6 words (access time · cache block · hit/miss · tag · page · TLB)
          └─ 8.1 Basic Concepts (address space, access vs cycle time)
              └─ 8.2 Semiconductor RAM (SRAM · DRAM · SDRAM)
                  └─ 8.3 ROM family (ROM→PROM→EPROM→EEPROM→Flash)
                      └─ 8.4 DMA (block transfer without the CPU)
                          └─ 8.5 Memory Hierarchy (big picture)
                              └─ 8.6 Cache  ← THE CORE (locality, mapping, replacement)
                                  └─ 8.7 Performance (hit rate, miss penalty, t_avg)
                                      └─ 8.8 Virtual Memory (pages, page table, TLB, faults)
                                          └─ 8.9 Mem Management (user/supervisor, protection)
                                              └─ 8.10 Secondary Storage (disks, optical, tape)
                                                  └─ ACTIVE RECALL: redraw · say sequence · state trade-off
```

---

## 2. Master Map — The Whole Chapter

```mermaid
mindmap
  root((Ch.8 The<br/>Memory System))
    8.1 Basic Concepts
      Address space from address width
      Access time vs cycle time
      RAM = uniform access time
      Block transfers
    8.2 Semiconductor RAM
      Internal organization cells + word/bit lines
      SRAM latch fast volatile costly
      DRAM capacitor dense cheap needs refresh
      SDRAM clocked burst
      DDR two transfers per clock
    8.3 Read-Only Memories
      ROM mask programmed
      PROM fuse once
      EPROM UV erase
      EEPROM electrical erase
      Flash block erase - cards + drives
    8.4 Direct Memory Access
      DMA controller does transfer
      Registers addr + count + status
      CPU sets it up then interrupt at end
      Cycle stealing vs burst
    8.5 Memory Hierarchy
      Registers → cache → main → disk
      Faster+smaller+costlier at top
    8.6 Cache Memories
      Locality temporal + spatial
      Hit vs miss
      Write-through vs write-back
      8.6.1 Mapping direct/assoc/set-assoc
      8.6.2 Replacement LRU
    8.7 Performance
      Hit rate h / miss penalty M
      t_avg = hC + (1-h)M
      Bigger block up to a point
      Load-through
    8.8 Virtual Memory
      Virtual vs physical address
      Page + page frame
      Page table + base register
      TLB = cache for page table
      Page fault → OS fetches from disk
    8.9 Memory Management
      System vs user space
      Supervisor vs user mode
      Protection + privileged instr
      Shared pages
    8.10 Secondary Storage
      Magnetic hard disks
      Optical CD/DVD
      Magnetic tape
```

**ASCII fallback:**
```
Ch.8 THE MEMORY SYSTEM
├── 8.1 BASIC CONCEPTS: address space (from addr width), access vs cycle time, RAM=uniform, block transfers
├── 8.2 SEMICONDUCTOR RAM: cells + word/bit lines
│      SRAM (latch, fast, volatile, costly) · DRAM (capacitor, dense, cheap, needs REFRESH)
│      SDRAM (clocked, burst) · DDR (2 transfers/clock)
├── 8.3 ROM FAMILY: ROM(mask) → PROM(fuse,once) → EPROM(UV erase) → EEPROM(elec erase) → FLASH(block erase; cards+drives)
├── 8.4 DMA: controller does the transfer; regs = start addr + word count + status; CPU sets up, interrupt at end; cycle-steal vs burst
├── 8.5 MEMORY HIERARCHY: registers → cache → main → disk (faster/smaller/costlier at top)
├── 8.6 CACHE: locality (temporal+spatial), hit/miss, write-through vs write-back
│      ├── 8.6.1 Mapping: direct / associative / set-associative
│      └── 8.6.2 Replacement: LRU (and others)
├── 8.7 PERFORMANCE: hit rate h, miss penalty M; t_avg = hC + (1-h)M; bigger block (to a point); load-through
├── 8.8 VIRTUAL MEMORY: virtual vs physical addr, page/page-frame, page table + base reg, TLB (cache for page table), page fault→OS fetch
├── 8.9 MEM MANAGEMENT: system vs user space, supervisor vs user mode, protection + privileged instrs, shared pages
└── 8.10 SECONDARY STORAGE: magnetic hard disks · optical CD/DVD · magnetic tape
```

---

## 3. Basic Concepts & the Memory Hierarchy

The chapter's founding tension: you cannot have **fast + large + cheap** all at once.

```mermaid
flowchart TD
    G["GOAL: memory that is<br/>FAST + LARGE + CHEAP"] --> P["PROBLEM: impossible<br/>all three at once"]
    P --> S["SOLUTION: a HIERARCHY<br/>— each level trades off"]
    S --> H

    subgraph H["Memory Hierarchy (top = fast/small/costly)"]
      R[Registers<br/>fastest, tiny] --> C[Cache SRAM<br/>very fast, small]
      C --> MM[Main memory DRAM<br/>slower, large]
      MM --> D[Secondary storage disk<br/>slowest, huge, cheap]
    end

    H --> T["Illusion delivered:<br/>speed of cache + size of disk"]

    style G fill:#dae8fc,stroke:#6c8ebf
    style P fill:#f8cecc,stroke:#b85450
    style S fill:#d5e8d4,stroke:#82b366
    style T fill:#d5e8d4,stroke:#82b366
```

**ASCII fallback:**
```
BASIC CONCEPTS + HIERARCHY (8.1, 8.5)
 GOAL: fast + large + cheap  →  PROBLEM: impossible at once  →  SOLUTION: a HIERARCHY

 KEY TERMS
  • Address space  = set of addressable locations (k-bit address → 2^k locations)
  • Access time    = init → complete of ONE transfer
  • Cycle time     = min delay between two successive operations (slightly > access time)
  • RAM            = access time same for any location (vs serial disk/tape)

 HIERARCHY (top = faster, smaller, costlier per bit)
   Registers  →  Cache (SRAM)  →  Main memory (DRAM)  →  Secondary storage (disk)
 ILLUSION delivered to CPU: access time of cache + capacity of disk
```

---

## 4. Semiconductor RAM

```mermaid
mindmap
  root((RAM<br/>8.2))
    SRAM static
      Stores bit in a latch two inverters
      Holds value while powered
      Volatile loses on power off
      Very fast few ns
      More transistors → costly, low density
      Used for CACHE
    DRAM dynamic
      Stores bit as charge on a capacitor
      Charge leaks → needs REFRESH
      One transistor → dense + cheap
      Used for MAIN MEMORY
      Asynchronous DRAM RAS/CAS
    SDRAM synchronous
      Operation synced to a CLOCK
      Built-in refresh + addr latches
      Burst read auto-increment column
      133 MHz early → >1 GHz today
    DDR SDRAM
      Transfers on BOTH clock edges
      Double data rate
    Rambus
      Competing proprietary tech
```

**ASCII fallback:**
```
SEMICONDUCTOR RAM (8.2)
├── SRAM (static): bit held in a LATCH (2 inverters); volatile; VERY FAST (few ns);
│       many transistors → costly, low density → used for CACHE
├── DRAM (dynamic): bit = CHARGE on a capacitor; leaks → needs periodic REFRESH;
│       1 transistor/cell → dense + cheap → used for MAIN MEMORY; async uses RAS/CAS
├── SDRAM (synchronous): clocked; built-in refresh + address latches; BURST read
│       (auto-increment column); ~133 MHz early → >1 GHz today
├── DDR SDRAM: transfers on BOTH clock edges → double data rate
└── Rambus: competing proprietary technology
MEMORY HOOK: Static = sits still (latch) · Dynamic = drains (capacitor, refresh)
```

---

## 5. Read-Only Memories

An **evolution** map — each ROM type fixes the previous one's limitation.

```mermaid
flowchart LR
    ROM["ROM<br/>written at MANUFACTURE<br/>(mask)"] --> PROM["PROM<br/>user writes ONCE<br/>(blow fuses)"]
    PROM --> EPROM["EPROM<br/>erase with UV light<br/>reprogrammable"]
    EPROM --> EEPROM["EEPROM<br/>erase ELECTRICALLY<br/>byte-level, in-circuit"]
    EEPROM --> FLASH["FLASH<br/>erase by BLOCK<br/>high density, cheap"]
    FLASH --> USE["Flash cards (memory keys)<br/>+ Flash drives (SSD, no moving parts)"]

    style ROM fill:#dae8fc,stroke:#6c8ebf
    style FLASH fill:#d5e8d4,stroke:#82b366
    style USE fill:#fff2cc,stroke:#d6b656
```

**ASCII fallback:**
```
READ-ONLY MEMORIES (8.3) — nonvolatile; evolution of "how do we (re)write it?"
  ROM     → written at MANUFACTURE (mask programmed)
  PROM    → user programs ONCE (blow fuses)
  EPROM   → erase with UV light, reprogram (whole chip)
  EEPROM  → erase ELECTRICALLY, byte-level, in-circuit
  FLASH   → erase by BLOCK (sector); high density + cheap
            └─ Flash CARDS (memory keys / USB) and Flash DRIVES (SSD; solid-state, no moving parts)
```

---

## 6. Direct Memory Access

A **sequence/flow** map — how a block moves without the CPU babysitting it.

```mermaid
sequenceDiagram
    participant CPU as Processor (OS)
    participant DMA as DMA controller
    participant MEM as Main memory
    participant IO as I/O device (disk)
    CPU->>DMA: 1. write START ADDRESS, WORD COUNT, direction (R/W)
    Note over CPU: CPU is now FREE to run other work
    loop for each word in the block
        IO->>DMA: data ready
        DMA->>MEM: 2. put address + control, transfer word
        DMA->>DMA: 3. increment address, decrement count
    end
    DMA->>CPU: 4. block done → raise INTERRUPT (if IE set)
```

**ASCII fallback:**
```
DIRECT MEMORY ACCESS (8.4) — move a BLOCK directly between I/O device and memory
 WHY: program-controlled transfer = huge CPU overhead per word (poll/interrupt + address + count)
 DMA CONTROLLER REGISTERS: (1) starting address  (2) word count  (3) status/control
      status bits: R/W (direction) · IE (interrupt-enable) · Done · IRQ
 SEQUENCE
   1. CPU (OS) writes start addr + word count + direction → then is FREE
   2. DMA controller supplies address + control signals, transfers each word
   3. increments address, keeps track of word count
   4. when whole block done → sets Done, raises INTERRUPT
 SHARING THE BUS: cycle stealing (one word at a time) vs burst/block mode
```

---

## 7. Cache — Hit/Miss & Write Policies

A **decision** map — what happens on every access and how writes propagate.

```mermaid
flowchart TD
    A[CPU issues address] --> B{In cache?<br/>compare TAG}
    B -->|Yes = HIT| RW{Read or Write?}
    B -->|No = MISS| MISS[Bring whole BLOCK<br/>from main memory]
    RW -->|Read| RH[Serve from cache<br/>main memory untouched]
    RW -->|Write| WP{Write policy}
    WP -->|Write-through| WT[Update cache AND memory<br/>simpler, more writes]
    WP -->|Write-back| WB[Update cache only,<br/>set DIRTY bit; write to<br/>memory on eviction]
    MISS --> LT[Load-through / early restart:<br/>forward needed word first]

    style RH fill:#d5e8d4,stroke:#82b366
    style WT fill:#dae8fc,stroke:#6c8ebf
    style WB fill:#dae8fc,stroke:#6c8ebf
    style MISS fill:#f8cecc,stroke:#b85450
```

**ASCII fallback:**
```
CACHE OPERATION (8.6) — built on LOCALITY OF REFERENCE
  • Temporal locality: a recently used item is likely used again soon
  • Spatial  locality: items near a used item are likely used soon → fetch a BLOCK (line)

 ON EACH ACCESS: compare TAG →
   HIT  → Read: serve from cache (memory untouched)
          Write: write-through (cache + memory, simpler, more writes)
                 write-back    (cache only + DIRTY bit; memory updated on eviction) ← common
   MISS → copy the whole BLOCK from main memory into cache, then serve
          load-through/early restart: forward the requested word first (less waiting)
 Separate I-cache and D-cache avoid structural stalls (ties to Ch.6 §6.7).
```

---

## 8. Cache Mapping Functions

Running example: cache = 128 blocks × 16 words; main memory = 64K words = 4K blocks; 16-bit address.

```mermaid
mindmap
  root((Mapping<br/>8.6.1))
    Direct mapping
      block j → cache block j mod 128
      Address = TAG 5 + BLOCK 7 + WORD 4
      Simplest, trivial replacement
      Contention even when not full
    Associative mapping
      block → ANY cache position
      Address = TAG 12 + WORD 4
      Must search ALL tags in parallel
      Most flexible, most expensive
      Needs replacement algorithm
    Set-associative mapping
      Blocks grouped into SETS
      block → any line of ONE set
      Address = TAG + SET + WORD
      k-way = k blocks per set
      Compromise: less contention,
      smaller associative search
    Extremes
      1 block per set = direct
      128 per set = fully associative
```

**ASCII fallback:**
```
MAPPING FUNCTIONS (8.6.1)  [example: 128 cache blocks, 16 words/block, 64K main = 4K blocks, 16-bit addr]

 DIRECT         : block j → cache block (j mod 128)
                  address = TAG(5) | BLOCK(7) | WORD(4)
                  + simplest, replacement trivial   − contention even when cache not full

 ASSOCIATIVE    : block → ANY cache position
                  address = TAG(12) | WORD(4)
                  + most flexible  − must search ALL tags in parallel (costly); needs replacement algo

 SET-ASSOCIATIVE: lines grouped into SETS; block → any line of ONE set
                  address = TAG | SET | WORD ; k-way = k blocks/set
                  COMPROMISE: less contention than direct, cheaper search than associative

 EXTREMES: 1 block/set = direct mapping · 128 blocks/set = fully associative
 PERFORMANCE RANK: associative > set-associative > direct (but set-assoc = best practical)
```

---

## 9. Cache Performance

```mermaid
flowchart TD
    FORM["Average access time<br/>t_avg = h·C + (1 − h)·M"] --> H["h = hit rate (want > 0.9)"]
    FORM --> C["C = cache access time"]
    FORM --> M["M = miss penalty<br/>time to fetch block from memory"]
    H --> IMP["Improve hit rate:<br/>bigger cache (costs $) ·<br/>larger block (spatial locality)"]
    M --> RED["Reduce miss penalty:<br/>load-through / early restart"]
    IMP --> WARN["Block too LARGE → wasted fetches<br/>+ longer transfer → bigger M"]
    WARN --> SWEET["Sweet spot: 16–128 bytes/block"]

    style FORM fill:#fff2cc,stroke:#d6b656
    style SWEET fill:#d5e8d4,stroke:#82b366
    style WARN fill:#f8cecc,stroke:#b85450
```

**ASCII fallback:**
```
CACHE PERFORMANCE (8.7)
  AVERAGE ACCESS TIME:  t_avg = h*C + (1 - h)*M
     h = hit rate (high hit rates > 0.9 essential) · C = cache access time · M = miss penalty
  MISS PENALTY (1-level example): M = τ + 10τ + 7τ + τ = 19τ  (initial access + first word + 7 words + forward)

  IMPROVE HIT RATE: larger cache (↑cost) · larger block (exploit spatial locality)
  REDUCE MISS PENALTY: load-through / early restart (resume as soon as needed word arrives)

  BLOCK SIZE TRADE-OFF: too small → poor spatial use; too large → wasted fetches + bigger M
       → popular range 16–128 bytes per block
```

---

## 10. Virtual Memory & Address Translation

A **flow** map — turning a virtual address into a physical one, and what a page fault triggers.

```mermaid
flowchart TD
    VA["Virtual address<br/>= VIRTUAL PAGE # + OFFSET"] --> TLB{In TLB?<br/>cache of page table}
    TLB -->|Hit| PA["Physical address<br/>= PAGE FRAME + OFFSET"]
    TLB -->|Miss| PT["Look up PAGE TABLE in memory<br/>(base reg + page #)"]
    PT --> VAL{Valid bit set?<br/>page in memory?}
    VAL -->|Yes| UPD[Update TLB] --> PA
    VAL -->|No = PAGE FAULT| OS["OS exception:<br/>fetch page from DISK<br/>(may run another program)"]
    OS --> REPL["If memory full → replace a page<br/>(LRU-like); write back if DIRTY"]
    REPL --> UPD

    style PA fill:#d5e8d4,stroke:#82b366
    style OS fill:#f8cecc,stroke:#b85450
    style TLB fill:#fff2cc,stroke:#d6b656
```

**ASCII fallback:**
```
VIRTUAL MEMORY + ADDRESS TRANSLATION (8.8)
 IDEA: only ACTIVE pages live in main memory; the rest stay on DISK → program sees memory larger than physical RAM
 UNITS: virtual address = VIRTUAL PAGE # + OFFSET ; a page-sized slot in RAM = PAGE FRAME

 PAGE TABLE: one entry per page → page frame + control bits (valid, modified/dirty, access rights)
   located via PAGE TABLE BASE REGISTER + virtual page number
 TLB: small associative cache of the most-recent page-table entries (inside the MMU)

 TRANSLATION
   virtual addr → check TLB
     • TLB hit  → physical addr = page frame + offset
     • TLB miss → read page table in memory → update TLB
         • valid? → translate
         • NOT valid = PAGE FAULT → OS exception → load page from disk
             (if RAM full → replace a page LRU-style; write back first if DIRTY)
 NOTE: write-BACK only (disk too slow for write-through)
```

---

## 11. Secondary Storage

```mermaid
mindmap
  root((Secondary<br/>Storage 8.10))
    Magnetic hard disks
      Platters + tracks + sectors
      Read/write head on arm
      Seek time + rotational latency
      Huge capacity, low cost/bit
    Optical disks
      CD / DVD / Blu-ray
      Laser reads pits/lands
      Removable, archival
    Magnetic tape
      Sequential access
      Backup / archive
      Lowest cost/bit, slowest
```

**ASCII fallback:**
```
SECONDARY STORAGE (8.10) — nonvolatile, bottom of hierarchy
├── MAGNETIC HARD DISKS: platters/tracks/sectors; head on arm; SEEK time + ROTATIONAL latency;
│       huge capacity, lowest cost/bit among online storage
├── OPTICAL DISKS: CD / DVD / Blu-ray; laser reads pits & lands; removable, good for archival
└── MAGNETIC TAPE: SEQUENTIAL access; backup/archive; lowest cost/bit, slowest access
```

---

*End of mind maps. Pair with the study guide for full detail.*
