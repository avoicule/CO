# Chapter 7 — Input/Output Organization

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 227–263 (Sections 7.1 → 7.7)

> **Read Chapter 3 first.** Chapter 3 was the *programmer's* view ("how do I write code to
> talk to a device?"). Chapter 7 is the *hardware* view ("what wires and circuits make
> that possible?"). Every concept here is the machinery underneath Chapter 3.

---

## 0. How to Start Learning This Chapter (read this first)

Chapter 7 is bigger and more hardware-heavy than Chapter 3. Don't read it front-to-back
blindly — follow this learning path:

### Step 1 — Anchor to what you already know (Ch.3)
You already know: devices have DATA/STATUS/CONTROL registers, memory-mapped I/O, polling,
interrupts. Chapter 7 answers **"how is this physically wired and timed?"** Keep asking
yourself: *"which Chapter 3 idea is this explaining the hardware for?"*

### Step 2 — Learn the vocabulary spine (do this before any detail)
The whole chapter hangs on **six words**. Learn these first and 70% of the chapter unlocks:

| Term | One-line meaning |
|------|------------------|
| **Bus** | Shared set of wires (address + data + control) connecting everything. |
| **Master** | The device that *starts* a transfer (usually the CPU). |
| **Slave** | The device that is *addressed* and responds. |
| **Protocol** | The agreed rules for who puts what on the bus and when. |
| **Synchronous** | Timing driven by a shared **clock**. |
| **Asynchronous** | Timing driven by a **handshake** (request/acknowledge). |

### Step 3 — Follow this section order (it's a dependency chain)
```
7.1 Bus Structure        ← what a bus physically is  (START HERE)
      │
7.2 Bus Operation        ← the heart of the chapter
   ├ 7.2.1 Synchronous    (clock-based timing)
   ├ 7.2.2 Asynchronous   (handshake timing)
   └ 7.2.3 Electrical     (tri-state drivers — short, read last of 7.2)
      │
7.3 Arbitration          ← who gets the bus when several want it
      │
7.4 Interface Circuits   ← parallel vs serial ports (ties back to Ch.3 registers)
      │
7.5 Interconnection Standards  ← USB / FireWire / PCI / PCIe  (breadth, not depth)
```

### Step 4 — Prioritize for an exam
- **Must master (draw the timing diagrams yourself):** 7.2.1 synchronous (incl.
  multiple-cycle), 7.2.2 asynchronous handshake, 7.3 arbitration.
- **Understand conceptually:** 7.1 bus lines, 7.4 parallel vs serial, master/slave.
- **Know the comparisons/facts:** 7.5 standards — focus on *why each exists* and the
  isochronous/asynchronous data distinction, not memorizing every speed number.

### Step 5 — Active-recall checklist
After each section, close the book and try to:
1. Draw the diagram from memory.
2. Say out loud the *sequence of events* in order.
3. Explain the *trade-off* that section introduced.

If you can do those three, move on. If not, re-read just that section.

---

## Table of Contents
1. [Section 7.1 — Bus Structure](#1-section-71--bus-structure)
2. [Section 7.2 — Bus Operation (overview)](#2-section-72--bus-operation-overview)
3. [Section 7.2.1 — Synchronous Bus](#3-section-721--synchronous-bus)
4. [Multiple-Cycle Data Transfer](#4-multiple-cycle-data-transfer)
5. [Section 7.2.2 — Asynchronous Bus (Handshake)](#5-section-722--asynchronous-bus-handshake)
6. [Synchronous vs Asynchronous — the big comparison](#6-synchronous-vs-asynchronous)
7. [Section 7.2.3 — Electrical Considerations (tri-state)](#7-section-723--electrical-considerations)
8. [Section 7.3 — Arbitration](#8-section-73--arbitration)
9. [Section 7.4 — Interface Circuits (Parallel vs Serial)](#9-section-74--interface-circuits)
10. [Section 7.5 — Interconnection Standards](#10-section-75--interconnection-standards)
11. [Glossary](#11-glossary)
12. [Self-Test Questions](#12-self-test-questions)

---

## 1. Section 7.1 — Bus Structure

A **bus** is the simplest interconnection network: a shared bundle of wires that every
unit (processor, memory, I/O devices) taps into. **Key constraint: only one
source→destination pair can use the bus at a time.**

The bus is **three groups of lines**:

| Line group | Carries |
|------------|---------|
| **Address lines** | *Which* device/register the transfer targets. |
| **Data lines** | The actual bits being moved. |
| **Control lines** | Commands (R/W), timing, status signals. |

### How a transfer is targeted (address decoding)

1. The processor (master) places an address on the **address lines**.
2. **Every** device's **address decoder** examines it.
3. The one device whose address matches **responds**; all others ignore it.
4. The master uses control lines to say Read or Write; data flows on the data lines.

This is the hardware behind **memory-mapped I/O** from Chapter 3: because device registers
have addresses, `Load R2, DATAIN` / `Store R2, DATAOUT` reach them like memory.

> The address decoder + data/status registers + control circuitry together form the
> device's **interface circuit** (expanded in §7.4).

> **Checkpoint:** What are the three line groups, and what does the address decoder do?

---

## 2. Section 7.2 — Bus Operation (overview)

A **bus protocol** is the rulebook: when a device may put data on the bus, when it may
read data off, etc. Implemented via control signals.

Two foundational concepts:

- **R/W line** — one control line: `1` = Read, `0` = Write. Other control lines indicate
  the data size (byte / halfword / word).
- **Master & Slave** — the **master** initiates the transfer (issues Read/Write; normally
  the processor). The **slave** is the device the master addresses.

Timing of transfers is either **synchronous** (clock) or **asynchronous** (handshake) —
the two big subsections that follow.

---

## 3. Section 7.2.1 — Synchronous Bus

**Idea:** all devices share one **bus clock** line. Timing is measured in clock cycles — a
metronome everyone marches to.

### Input (Read) transfer — the three key instants

Study **Figure 7.3**. During one clock cycle:

```
  t0 ───────────── t1 ───────────── t2
  │                │                │
  master puts      slave puts       master
  address +        requested        loads data
  Read command     data on bus      into its register
  on the bus
```

- **t0** — master places address + Read command on the bus.
- **t1** — the addressed slave has decoded the address and places data on the data lines.
- **t2** — (end of cycle) master latches the data into a register.

### The physics that sets the clock speed

The clock period can't be arbitrary — it must respect real delays:

- **Propagation delay** — signals take time to travel the length of the bus wires.
- The pulse width `t1 − t0` must exceed the max propagation delay **and** give devices
  time to decode the address.
- `t2 − t1` must exceed propagation time **plus** the register's **setup time**.

> **Figure 7.4 (realistic view):** signals don't appear instantly. The master sees them at
> `tAM`, the slave at `tAS`, data returns at `tDM`, etc. Different devices see the same
> transition at *different* times — that's the whole timing headache of synchronous buses.

> **Checkpoint:** Name the three instants t0/t1/t2 and what happens at each. Why can't the
> clock period be shorter than the bus propagation delay?

---

## 4. Multiple-Cycle Data Transfer

**Problem with the simple scheme:** a transfer must finish in **one** clock cycle, so the
cycle has to be stretched to fit the **slowest** device → *everything* runs slow. Also, the
master has no proof the device actually responded (undetected errors).

**Solution:** let a transfer span **several clock cycles**, and add a **Slave-ready**
acknowledgment signal (Figure 7.5):

```
 cycle 1        cycle 2         cycle 3            cycle 4
 master sends   slave starts    slave puts data    master can
 addr+command   accessing data  + asserts          start a new
                                 Slave-ready;       transfer
                                 master latches
```

- **Slave-ready** = "the data I was asked for is now on the bus."
- Fast devices respond in an early cycle; slow devices take more cycles — the duration
  *adapts per device* instead of forcing one worst-case speed.
- If a device never responds, the master waits a max number of cycles, then **aborts**
  (catches bad addresses / malfunctions).

> **This is the key upgrade:** the acknowledgment both (a) adapts timing per device and
> (b) enables error detection.

---

## 5. Section 7.2.2 — Asynchronous Bus (Handshake)

**No clock at all.** Timing comes from a **full handshake** — two interlocked control
lines:

- **Master-ready** — asserted by the master: "address/command are on the bus."
- **Slave-ready** — asserted by the slave: "I've done the operation."

### The input handshake — 6 instants (Figure 7.6)

```
 t0  master puts address + command on bus (all devices start decoding)
 t1  master asserts Master-ready  (delay t1−t0 covers bus SKEW)
 t2  slave has decoded, puts data on bus, asserts Slave-ready
 t3  Slave-ready reaches master → master latches data, drops Master-ready
 t4  master removes address/command (delay covers skew)
 t5  slave sees Master-ready go low → removes data + drops Slave-ready  → DONE
```

### Two concepts you must understand here

- **Skew** — two signals sent together arrive at *different* times because bus lines have
  different propagation speeds. The deliberate delay `t1 − t0` guarantees Master-ready
  never arrives *before* the address it refers to.
- **Fully interlocked / full handshake** — every signal change happens *only in response*
  to the other side's change. This gives the **highest reliability** (each step is
  confirmed) at the cost of speed.

> Output transfer (Figure 7.7) is the mirror image: master puts data out *with* the
> address; slave latches it on Master-ready and confirms with Slave-ready.

---

## 6. Synchronous vs Asynchronous

This comparison is the single most exam-worthy takeaway of §7.2.

| | **Synchronous** | **Asynchronous** |
|--|-----------------|------------------|
| Timing source | shared **clock** | **handshake** (Master-ready/Slave-ready) |
| Round-trips per transfer | **one** | **two** (4 end-to-end delays) |
| Speed | faster | slower (waits on each handshake step) |
| Clock distribution | hard — clock edges must reach all devices together | not needed |
| Handles varying device speeds | via multiple-cycle + Slave-ready | automatically, naturally |
| Reliability / error detect | needs Slave-ready added | built-in (interlocked) |
| Used by | **most high-speed buses today** | simpler timing design |

**Memory hook:** Synchronous = *marching band to a drumbeat* (fast, but everyone must hear
the same beat). Asynchronous = *a conversation* (each person waits for the other to finish;
reliable, but slower).

---

## 7. Section 7.2.3 — Electrical Considerations

Short but important. **Only one device may drive the bus at a time** — otherwise two
devices fighting over a line corrupt the data.

- A gate that puts data on the bus is a **bus driver**.
- All non-sending devices must turn their drivers **off**.
- The mechanism: a **tri-state gate** — it has three output states:
  1. drive `1`
  2. drive `0`
  3. **high-impedance (Z)** — effectively *disconnected*, doesn't affect the bus.

So "turning a driver off" = putting its tri-state gate into high-impedance.

---

## 8. Section 7.3 — Arbitration

**Problem:** more than one device may want to be **bus master** at the same time (e.g. a
disk doing a direct memory transfer). Who goes first?

**Solution:** an **arbiter circuit** decides, based on **priority**.

### The mechanism (Figure 7.8)

- Each master has a **Bus-request** line (BR1, BR2, …) and a **Bus-grant** line (BG1, BG2, …).
- A master raises its BR; if it's the only/highest-priority request, the arbiter raises the
  matching BG → that master may use the bus.
- When done, the master drops BR; the arbiter drops BG.

### Priority example (Figure 7.9, three masters, 1 = highest)

```
1. Master 2 requests (BR2) — no competition → arbiter grants BG2.
2. While M2 is busy, BOTH master 1 and master 3 request.
3. M2 finishes (drops BR2).
4. Arbiter grants BG1 FIRST (master 1 has higher priority) — even though
   master 3 asked earlier.
5. M1 finishes → arbiter then grants BG3 to master 3.
```

**Key insight:** priority beats arrival order. If no urgency, a **round-robin** scheme can
be used for fairness instead.

> **Checkpoint:** In the example, master 3 requested *before* master 1 but was served
> *after*. Why? *(Master 1 has higher priority; the arbiter grants by priority, not order
> of arrival.)*

---

## 9. Section 7.4 — Interface Circuits

The **interface** connects a device to the bus. One side = bus (address/data/control); the
other side = the connection to the device, called a **port**.

### Parallel vs Serial port

| | **Parallel port** | **Serial port** |
|--|-------------------|-----------------|
| Data movement | **multiple bits at once** | **one bit at a time** |
| Example use | 8-bit keyboard/display interface | long-distance / few-wire links |
| Conversion | — | parallel↔serial conversion happens *inside* the interface |

To the processor, **both look the same**; the interface hides the difference.

### The six jobs of any I/O interface (recap from Ch.3, formalized)

1. Provide a **data register** for temporary storage.
2. Provide a **status register** the processor can read.
3. Provide a **control register** governing device behavior.
4. Contain **address-decoding** circuitry (recognize when it's addressed).
5. Generate required **timing signals**.
6. Perform **format conversion** if needed (e.g. parallel↔serial).

The **parallel input interface** example (Figure 7.10) is literally the hardware for the
`KBD_DATA` / `KBD_STATUS` / `KIN` registers you learned in Chapter 3 — the circle closes.

---

## 10. Section 7.5 — Interconnection Standards

This section is **breadth, not depth.** For each standard, learn *why it exists* and its
*one defining trait*. Don't drown in speed numbers.

### First, two data-nature terms (they explain the designs)

- **Asynchronous data** — produced at *unpredictable* times, low rate (e.g. a keystroke:
  ~10 bytes/s). Must be delivered promptly but timing between events varies.
- **Isochronous data** — a steady stream at *equal* time intervals, synchronized to a
  sampling clock (e.g. digitized audio at 44.1 kHz). **Consistent timing matters more than
  perfect correctness** — an occasional dropped sample is just a click.

### The standards

| Standard | Topology | Defining trait |
|----------|----------|----------------|
| **USB** | **tree** (hubs + root hub) | Most common. Plug-and-play, hot-pluggable, serial, **polling-only** (devices speak only when polled → no collisions → cheap hubs). Supports isochronous via a Start-of-Frame marker each ms. |
| **FireWire** (IEEE 1394) | **daisy chain** | Differential serial. **Peer-to-peer**: devices transfer data directly *without* the host. Great for audio/video. |
| **PCI** | motherboard bus via a **bridge** | Processor-independent; devices appear as if on the processor bus. **Pioneered plug-and-play.** Shares address/data lines to cut cost; burst transfers. initiator/target + IRDY#/TRDY#/DEVSEL#/FRAME# signals. |
| **PCI Express (PCIe)** | point-to-point serial lanes | Modern replacement for PCI's shared bus. |
| **SATA / SAS / SCSI** | — | Storage-device interfaces (disks). |

### USB essentials worth knowing

- **Why polling?** If devices spoke whenever they wanted, two messages could collide at a
  hub. USB forbids this: a device transmits **only in response to a host poll** → hubs stay
  simple and cheap.
- **Plug-and-play:** on connection a device starts at address 0; the host reads its
  capability info and assigns a unique **7-bit USB address** (local to the USB tree, not the
  CPU address space).
- **Differential signaling** (High-Speed USB): data sent as the *voltage difference* between
  two twisted wires → noise hits both wires equally and cancels → faster, lower voltage.
  (Contrast: **single-ended** = signal relative to ground, noise-prone.)

### PCI bus transaction (Figure 7.19 — for depth if needed)

Initiator asserts **FRAME#** + address + command → target asserts **DEVSEL#** ("that's me")
→ **IRDY#/TRDY#** coordinate each word of a **burst** → FRAME# deasserts on the
second-to-last word. The `#` suffix means "asserted when low."

---

## 11. Glossary

- **Bus** — shared address/data/control lines; one transfer pair at a time.
- **Bus protocol** — rules governing bus use.
- **Master / Slave** — initiator of a transfer / addressed responder.
- **Address decoder** — per-device circuit that checks if an address is "mine."
- **Synchronous bus** — timing from a shared clock.
- **Asynchronous bus** — timing from a handshake.
- **Slave-ready** — slave's acknowledgment that data is on the bus.
- **Master-ready** — master's signal that address/command are ready.
- **Full handshake / interlocked** — each signal change responds to the other's.
- **Skew** — simultaneously-sent signals arriving at different times.
- **Propagation delay** — time for a signal to travel the bus.
- **Setup/hold time** — how long data must be stable before/after a clock edge to latch.
- **Multiple-cycle transfer** — a transfer spanning several clock cycles (adapts to device speed).
- **Bus driver** — gate that puts data on the bus.
- **Tri-state gate** — gate with a high-impedance "disconnected" state.
- **Arbiter / arbitration** — circuit/process deciding which master gets the bus.
- **Bus-request / Bus-grant** — the request/grant line pair per master.
- **Round-robin** — fair, rotating arbitration when no priority urgency.
- **Port (parallel/serial)** — device side of the interface; many bits at once vs one at a time.
- **Asynchronous data** — irregular, low-rate (keystrokes).
- **Isochronous data** — steady, equal-interval stream (audio/video); timing > correctness.
- **Plug-and-play** — auto-detect + auto-configure a connected device.
- **Hot-pluggable** — connect/disconnect while powered on.
- **Differential vs single-ended signaling** — voltage between two wires vs relative to ground.
- **Bridge** — controller linking the processor bus to the PCI bus.
- **Initiator / Target** — PCI terms for master / slave.

---

## 12. Self-Test Questions

1. What is the single most important constraint on a shared bus? *(§1)*
2. What does an address decoder do, and how many devices respond to a given address? *(§1)*
3. Define master and slave. Which is normally the processor? *(§2)*
4. On a synchronous read, what happens at t0, t1, t2? *(§3)*
5. Why must the clock period exceed the bus propagation delay? *(§3)*
6. What two problems does the multiple-cycle scheme (with Slave-ready) solve? *(§4)*
7. Name the two handshake signals and the order they're asserted/deasserted. *(§5)*
8. What is bus skew, and which deliberate delay guards against it? *(§5)*
9. Give three differences between synchronous and asynchronous buses. *(§6)*
10. What are the three states of a tri-state gate? *(§7)*
11. In the 3-master arbitration example, why is master 1 served before master 3? *(§8)*
12. Parallel vs serial port — where does the conversion happen? *(§9)*
13. Distinguish asynchronous data from isochronous data with an example of each. *(§10)*
14. Why does USB operate strictly on polling? *(§10)*
15. What does differential signaling do that single-ended cannot? *(§10)*

---

*End of study guide. Pair with `Chapter7_MindMaps.md` and `Chapter7_MindMaps.drawio`.*
