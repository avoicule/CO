# Chapter 7 — Input/Output Organization · Mind Maps

**Companion to:** `Chapter7_Input_Output_Organization_StudyGuide.md`

> View with any Mermaid-capable tool (VS Code + Mermaid extension, Obsidian, Typora,
> GitHub). Each diagram also has a plain-text ASCII fallback. Export a single ```mermaid```
> block to PNG/SVG at https://mermaid.live.

---

## Table of Contents
1. [How to Start Learning (the path)](#1-how-to-start-learning--the-path)
2. [Master Map — The Whole Chapter](#2-master-map--the-whole-chapter)
3. [Bus Structure](#3-bus-structure)
4. [Synchronous Bus (timing)](#4-synchronous-bus)
5. [Asynchronous Handshake (flow)](#5-asynchronous-handshake)
6. [Synchronous vs Asynchronous](#6-synchronous-vs-asynchronous)
7. [Arbitration](#7-arbitration)
8. [Interface Circuits](#8-interface-circuits)
9. [Interconnection Standards](#9-interconnection-standards)

---

## 1. How to Start Learning — the path

```mermaid
flowchart TD
    A[START: you know Ch.3<br/>programmer's view] --> B[Step 1: anchor<br/>Ch.7 = the HARDWARE<br/>under Ch.3 ideas]
    B --> C[Step 2: learn 6 words<br/>bus · master · slave ·<br/>protocol · sync · async]
    C --> D[7.1 Bus Structure<br/>what a bus IS]
    D --> E[7.2 Bus Operation<br/>THE CORE]
    E --> E1[7.2.1 Synchronous<br/>clock timing]
    E --> E2[7.2.2 Asynchronous<br/>handshake timing]
    E --> E3[7.2.3 Electrical<br/>tri-state - read last]
    E1 --> F[7.3 Arbitration<br/>who gets the bus]
    E2 --> F
    F --> G[7.4 Interface Circuits<br/>parallel vs serial]
    G --> H[7.5 Standards<br/>USB/FireWire/PCI/PCIe<br/>breadth not depth]
    H --> I[Active recall:<br/>redraw diagram · say sequence · state trade-off]

    style A fill:#e1d5e7,stroke:#9673a6
    style E fill:#f8cecc,stroke:#b85450
    style I fill:#d5e8d4,stroke:#82b366
```

**ASCII fallback:**
```
HOW TO START
START (you know Ch.3 programmer's view)
  └─ Step 1: anchor — Ch.7 is the HARDWARE under Ch.3 ideas
      └─ Step 2: learn 6 words (bus·master·slave·protocol·sync·async)
          └─ 7.1 Bus Structure (what a bus is)
              └─ 7.2 Bus Operation  ← THE CORE
                   ├─ 7.2.1 Synchronous (clock)
                   ├─ 7.2.2 Asynchronous (handshake)
                   └─ 7.2.3 Electrical (tri-state, read last)
                        └─ 7.3 Arbitration (who gets the bus)
                             └─ 7.4 Interface Circuits (parallel vs serial)
                                  └─ 7.5 Standards (USB/FireWire/PCI/PCIe — breadth)
                                       └─ ACTIVE RECALL: redraw · say sequence · state trade-off
```

---

## 2. Master Map — The Whole Chapter

```mermaid
mindmap
  root((Ch.7 I/O<br/>Organization))
    7.1 Bus Structure
      Shared wires
      Address lines
      Data lines
      Control lines
      One pair at a time
      Address decoder picks device
    7.2 Bus Operation
      Protocol = rules
      R/W line
      Master vs Slave
      7.2.1 Synchronous clock
        t0 addr t1 data t2 latch
        Multiple-cycle + Slave-ready
      7.2.2 Asynchronous handshake
        Master-ready
        Slave-ready
        Skew
        Full handshake
      7.2.3 Electrical
        Bus driver
        Tri-state gate
    7.3 Arbitration
      Arbiter + priority
      Bus-request / Bus-grant
      Round-robin
    7.4 Interface Circuits
      Port parallel vs serial
      Six interface jobs
    7.5 Standards
      USB tree polling
      FireWire daisy peer-to-peer
      PCI bridge plug-and-play
      PCIe point-to-point
      SATA SAS SCSI storage
```

**ASCII fallback:**
```
Ch.7 I/O ORGANIZATION
├── 7.1 BUS STRUCTURE: shared wires (address+data+control), 1 pair at a time, address decoder
├── 7.2 BUS OPERATION
│   ├── protocol=rules · R/W line · master vs slave
│   ├── 7.2.1 Synchronous (clock): t0 addr → t1 data → t2 latch; multiple-cycle + Slave-ready
│   ├── 7.2.2 Asynchronous (handshake): Master-ready/Slave-ready, skew, full handshake
│   └── 7.2.3 Electrical: bus driver, tri-state gate (high-Z)
├── 7.3 ARBITRATION: arbiter + priority, Bus-request/Bus-grant, round-robin
├── 7.4 INTERFACE CIRCUITS: port parallel vs serial; six interface jobs
└── 7.5 STANDARDS: USB(tree,polling) · FireWire(daisy,peer) · PCI(bridge,PnP) · PCIe · SATA/SAS/SCSI
```

---

## 3. Bus Structure

```mermaid
mindmap
  root((Bus<br/>7.1))
    Three line groups
      Address - which device/register
      Data - the bits
      Control - R/W, timing, status
    Rule
      Only ONE source-dest pair at a time
    Addressing a device
      Master puts address on bus
      ALL decoders examine it
      Matching device responds
      Others ignore
    Enables memory-mapped I/O
      Load R2 DATAIN
      Store R2 DATAOUT
    Interface circuit =
      decoder + registers + control
```

**ASCII fallback:**
```
BUS STRUCTURE (7.1)
├── THREE LINE GROUPS: Address(which) · Data(bits) · Control(R/W,timing,status)
├── RULE: only ONE source→dest pair at a time
├── ADDRESSING: master puts address → ALL decoders check → matching device responds
├── ENABLES memory-mapped I/O: Load R2,DATAIN / Store R2,DATAOUT
└── INTERFACE CIRCUIT = address decoder + data/status/control registers + control logic
```

---

## 4. Synchronous Bus

A **timing** map — the three instants of a read.

```mermaid
flowchart LR
    T0["t0<br/>master puts<br/>ADDRESS + READ cmd"] --> T1["t1<br/>slave puts<br/>DATA on bus"]
    T1 --> T2["t2 (end of cycle)<br/>master LATCHES<br/>data into register"]
    T2 --> N["Limits:<br/>• 1 transfer / cycle → clock = slowest device<br/>• no proof device responded"]
    N --> M["FIX: Multiple-cycle + Slave-ready<br/>• adapts duration per device<br/>• enables error detect / abort"]

    style T0 fill:#dae8fc,stroke:#6c8ebf
    style T1 fill:#dae8fc,stroke:#6c8ebf
    style T2 fill:#dae8fc,stroke:#6c8ebf
    style N fill:#f8cecc,stroke:#b85450
    style M fill:#d5e8d4,stroke:#82b366
```

**ASCII fallback:**
```
SYNCHRONOUS BUS (shared clock)
  t0 → master puts ADDRESS + READ command
  t1 → slave puts DATA on bus
  t2 → master LATCHES data (end of cycle)
  constraints: pulse width > propagation delay + decode time; t2-t1 > prop + setup time

  LIMITS: 1 transfer/cycle → clock forced to slowest device; no proof of response
  FIX   : Multiple-cycle transfer + Slave-ready ack
          → duration adapts per device · error detect (abort if no response)
```

---

## 5. Asynchronous Handshake

A **sequence/flow** map — the 6 instants (Figure 7.6, input).

```mermaid
sequenceDiagram
    participant M as Master
    participant Bus
    participant S as Slave
    Note over M,S: NO clock — timing by handshake
    M->>Bus: t0 place address + command (all devices decode)
    M->>S: t1 assert Master-ready (delay covers SKEW)
    S->>Bus: t2 place data + assert Slave-ready
    S->>M: t3 Slave-ready arrives → master latches data, drops Master-ready
    M->>Bus: t4 remove address/command (delay covers skew)
    S->>Bus: t5 sees Master-ready low → remove data + drop Slave-ready (DONE)
```

**ASCII fallback:**
```
ASYNCHRONOUS HANDSHAKE (no clock; input, Fig 7.6)
 t0  master puts ADDRESS + COMMAND (all devices decode)
 t1  master asserts MASTER-READY   (delay t1-t0 covers bus SKEW)
 t2  slave puts DATA + asserts SLAVE-READY
 t3  Slave-ready reaches master → master LATCHES data, drops Master-ready
 t4  master removes address/command (delay covers skew)
 t5  slave sees Master-ready low → removes data + drops Slave-ready → DONE
 Fully interlocked = each change responds to the other = highest reliability.
```

---

## 6. Synchronous vs Asynchronous

```mermaid
mindmap
  root((Sync vs<br/>Async))
    Synchronous
      Shared CLOCK
      1 round-trip per transfer
      FASTER
      Hard clock distribution
      Needs Slave-ready for errors
      Most high-speed buses today
      Hook - marching band to drumbeat
    Asynchronous
      HANDSHAKE
      2 round-trips 4 delays
      SLOWER
      No clock to distribute
      Error detect built-in interlocked
      Adapts to any device speed
      Hook - a conversation
```

**ASCII fallback:**
```
SYNC vs ASYNC
┌───────────────────────────────┬────────────────────────────────────┐
│ SYNCHRONOUS (clock)            │ ASYNCHRONOUS (handshake)           │
├───────────────────────────────┼────────────────────────────────────┤
│ 1 round-trip/transfer → FASTER │ 2 round-trips (4 delays) → SLOWER  │
│ clock distribution is HARD     │ no clock needed                    │
│ needs Slave-ready for errors   │ error-detect built in (interlocked)│
│ used by most high-speed buses  │ adapts to any device speed         │
│ hook: marching band to drum    │ hook: a two-way conversation       │
└───────────────────────────────┴────────────────────────────────────┘
```

---

## 7. Arbitration

```mermaid
flowchart TD
    R["Several devices want to be BUS MASTER"] --> ARB{Arbiter<br/>by PRIORITY}
    ARB --> G["Grant to highest-priority requester"]
    G --> EX["Example (1=highest):<br/>M2 requests → BG2 granted<br/>then M1 & M3 both request<br/>M2 done → BG1 FIRST (higher prio)<br/>then BG3"]
    EX --> K["KEY: priority beats arrival order.<br/>No urgency? → round-robin (fair)."]
    R2["Each master: Bus-request (BRn) + Bus-grant (BGn)"] --> ARB

    style ARB fill:#fff2cc,stroke:#d6b656
    style K fill:#d5e8d4,stroke:#82b366
```

**ASCII fallback:**
```
ARBITRATION (7.3)
Several devices want to be BUS MASTER → ARBITER decides by PRIORITY
Each master has: Bus-request (BRn) + Bus-grant (BGn)
EXAMPLE (1=highest): M2 requests→BG2; then M1&M3 request; M2 done→BG1 FIRST→then BG3
KEY: priority beats arrival order. No urgency → round-robin (fair rotation).
```

---

## 8. Interface Circuits

```mermaid
mindmap
  root((Interface<br/>7.4))
    Two sides
      Bus side - address data control
      Device side - the PORT
    Port types
      Parallel - many bits at once
      Serial - one bit at a time
      Conversion inside interface
      CPU sees them the same
    Six jobs
      Data register
      Status register
      Control register
      Address decoding
      Timing signals
      Format conversion
    Ties to Ch.3
      Parallel input = KBD_DATA KBD_STATUS KIN
```

**ASCII fallback:**
```
INTERFACE CIRCUITS (7.4)
├── TWO SIDES: bus side (addr/data/ctrl)  |  device side = the PORT
├── PORT TYPES: parallel (many bits at once) vs serial (one bit); conversion inside; CPU sees same
├── SIX JOBS: data reg · status reg · control reg · address decode · timing · format conversion
└── TIES TO Ch.3: the parallel input interface = the KBD_DATA/KBD_STATUS/KIN hardware
```

---

## 9. Interconnection Standards

```mermaid
mindmap
  root((Standards<br/>7.5))
    Data nature
      Asynchronous data
        irregular low-rate
        e.g. keystroke
      Isochronous data
        steady equal intervals
        e.g. audio 44.1kHz
        timing beats correctness
    USB
      Tree hubs + root hub
      Serial, plug-and-play, hot-plug
      POLLING only - no collisions
      7-bit USB address
      Differential signaling
    FireWire 1394
      Daisy chain
      Peer-to-peer no host
      Audio/video
    PCI
      Motherboard via BRIDGE
      Pioneered plug-and-play
      Shared addr/data lines, bursts
      Initiator/Target IRDY TRDY
    PCIe
      Point-to-point serial lanes
      Modern PCI replacement
    Storage
      SATA SAS SCSI
```

**ASCII fallback:**
```
INTERCONNECTION STANDARDS (7.5)
├── DATA NATURE:
│    • Asynchronous data = irregular/low-rate (keystroke)
│    • Isochronous data  = steady equal intervals (audio 44.1kHz); timing > correctness
├── USB      : tree (hubs+root), serial, plug&play, hot-plug, POLLING-only, 7-bit addr, differential
├── FireWire : daisy chain, PEER-TO-PEER (no host), audio/video (IEEE 1394)
├── PCI      : motherboard via BRIDGE, pioneered plug&play, shared addr/data lines, bursts (initiator/target)
├── PCIe     : point-to-point serial lanes, modern PCI replacement
└── STORAGE  : SATA / SAS / SCSI
```

---

*End of mind maps. Pair with the study guide for full detail.*
