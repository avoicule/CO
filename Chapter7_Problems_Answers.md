# Chapter 7 — End-of-Chapter Problems: Worked Answers (7.1 – 7.21)

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Problems:** pages 263–265.

> **Honest note.** No official solutions manual ships in the book — these are **my worked
> solutions**, grounded in the chapter text and the worked Examples 7.1 (timing calc) and
> 7.2 (arbiter state diagram). Confidence by type:
> - **Conceptual** (7.1, 7.4, 7.5, 7.6, 7.17, 7.19, 7.20): definitive, from the text.
> - **Quantitative** (7.2, 7.7, 7.8, 7.9): full arithmetic shown — these have exact numeric
>   answers; recheck the figure parameters your instructor uses.
> - **Design / diagram** (7.3, 7.10–7.16, 7.18, 7.21): described precisely in words + logic;
>   the actual circuit/timing drawing is yours to render, but the structure is complete.
>
> **Key reminder about the figures** (this edition):
> - **Figure 7.4** = single-cycle synchronous transfer (address in the first clock phase,
>   slave data in the second phase — the one Example 7.1 analyzes).
> - **Figure 7.5** = multiple-cycle synchronous transfer with the **Slave-ready** ack.
> - **Figure 7.6** = asynchronous **full-handshake** (Master-ready / Slave-ready).
> - **Figure 7.9 / Example 7.2** = 3-request priority arbiter (R1 highest).

---

## 7.1 [E] Why clear the input status bit as soon as the data register is read?

**Answer.** The status bit means "*new, unread* data is in the register." Auto-clearing it
on read prevents the processor from **reading the same datum twice**: if it stayed set, the
polling loop (`wait until status=1`) would see it still 1 and re-read stale data. Clearing
guarantees the bit only returns to 1 when the hardware delivers a *genuinely new* value,
keeping hardware and software synchronized (one flag = one fresh datum). It also lets a
pending interrupt request be dropped once the data is consumed. *(Same principle as Ch.3
Problem 3.1, now at the bus-hardware level.)*

---

## 7.2 [E] Addresses a device responds to (16 lines, base 0x7CA4, decoder ignores A8, A9)

**Answer.** The decoder ignores address lines **A8 and A9**, so those two bits are "don't
care" — the device responds to *every* combination of A9A8 while all other bits match
0x7CA4.

0x7CA4 in binary (A15…A0):
```
0111 1100 1010 0100
          ^^-- bits 9 and 8 are the two bits just left of the low byte
```
Bits A9,A8 of 0x7CA4: looking at nibble `A` = `1010`, bit9=1, bit8=0. The device ignores
them, so A9A8 ∈ {00, 01, 10, 11}. That changes the value by `A9·0x200 + A8·0x100`.

Base with A9A8 forced to 00: 0x7CA4 − (0x200) = **0x7AA4** (since the base had A9=1,A8=0 =
0x200). The four responding addresses (A9A8 = 00, 01, 10, 11):

| A9 A8 | Added | Address |
|-------|-------|---------|
| 0 0 | +0x000 | **0x7AA4** |
| 0 1 | +0x100 | **0x7BA4** |
| 1 0 | +0x200 | **0x7CA4** (the given one) |
| 1 1 | +0x300 | **0x7DA4** |

**The device responds to: 0x7AA4, 0x7BA4, 0x7CA4, 0x7DA4.** (Four addresses, because two
ignored lines = 2² aliases.)

---

## 7.3 [M] Priority encoder: 7 request lines INTR1..INTR7 → 3-bit code of highest active

**Answer.** INTR7 is highest priority, INTR1 lowest. The encoder outputs a 3-bit number
equal to the **index of the highest-numbered asserted line** (ignoring all lower ones).

Behavior table (x = don't care; output = binary index):

| Highest active | Y2 Y1 Y0 |
|----------------|----------|
| INTR7 | 1 1 1 |
| INTR6 (and INTR7=0) | 1 1 0 |
| INTR5 (7,6=0) | 1 0 1 |
| INTR4 | 1 0 0 |
| INTR3 | 0 1 1 |
| INTR2 | 0 1 0 |
| INTR1 | 0 0 1 |
| none | 0 0 0 |

Logic expressions (priority: a bit's term is gated by all higher lines being 0):
```
Y2 = INTR7 + INTR6 + INTR5 + INTR4
Y1 = INTR7 + INTR6 + ¬INTR5·¬INTR4·(INTR3 + INTR2)
Y0 = INTR7 + ¬INTR6·INTR5 + ¬INTR6·¬INTR5·¬INTR4·INTR3
          + ¬INTR6·¬INTR5·¬INTR4·¬INTR3·¬INTR2·INTR1
```
A standard 8-to-3 priority encoder (e.g. 74148-style) implements exactly this; add a "valid"
output (OR of all seven) to distinguish "code 000 = INTR1" from "no request." The clean
design: scan from INTR7 down; first asserted line wins and its index drives Y2Y1Y0.

---

## 7.4 [M] Fig 7.4 / 7.5 / 7.6 — what if the addressed device never responds (malfunction)?

**Answer, per protocol:**

- **Figure 7.4 (single-cycle synchronous, no ack):** The master **blindly assumes** data is
  on the bus at t2. With no device responding, it latches **garbage** (undefined bus
  levels). *Problem:* silent wrong data — **the error is undetected.** *Remedy:* none within
  this protocol; you must add a response signal (which is exactly why Fig 7.5 exists).

- **Figure 7.5 (multiple-cycle with Slave-ready):** The master **waits for Slave-ready**. If
  it never comes, the master waits a **predefined maximum number of clock cycles, then
  aborts** the transfer (flagging a bus-timeout error). *This protocol detects the fault.*

- **Figure 7.6 (asynchronous full-handshake):** The master waits for **Slave-ready** before
  proceeding. With no response it would **wait forever (hang)**. *Remedy:* add a **timeout
  (watchdog) timer** that, after a maximum interval, aborts the handshake and raises a
  bus-error, letting the master recover.

**Summary:** the acknowledgment-based protocols (7.5, 7.6) can *detect* a non-responding
device; the ack-less one (7.4) cannot. The remedy everywhere is a timeout/abort mechanism.

---

## 7.5 [E] Fig 7.5 — must the master hold the address until it gets a response?

**Answer.** **No, it is not necessary.** The address is only needed long enough for the
slave to **decode it and recognize itself**. After that the address lines can be freed (and
reused — e.g. PCI multiplexes address and data on the same lines).

**What the device side must add** if the master drives the address for only one cycle: the
slave must **latch the address into an internal register** when it first appears, and then
use that latched copy for the rest of the transaction (and, for multi-word/burst transfers,
increment it internally to walk successive locations). Without latching, the slave would
lose track of which location is being accessed once the master removes the address.

---

## 7.6 [E] Fig 7.6 as master–device distance grows; and Fig 7.4?

**Answer.**

- **Figure 7.6 (asynchronous):** Longer distance → longer propagation delay. The handshake
  **automatically stretches** to accommodate it: each edge (Master-ready, Slave-ready) is
  simply seen later, and the next action waits for it. The transfer **slows down but stays
  correct** — no redesign needed. This self-adjusting property is the key advantage of the
  asynchronous scheme. (The intervals t1−t0, t3−t2, etc., grow with distance.)

- **Figure 7.4 (synchronous, fixed clock):** The clock period is **fixed in advance**. If
  increased distance pushes propagation delay beyond what the fixed clock period allows, the
  **timing breaks** — data may not be valid when latched. To accommodate greater distance
  you must **slow the clock** (increase the period) so the worst-case delay still fits inside
  a cycle. The synchronous bus cannot self-adjust; the designer must budget for the longest
  distance up front.

---

## 7.7 [E] Synchronous bus (Fig 7.5): max clock speed & cycles per input

Parameters: bus-driver delay 2 ns; propagation 5–10 ns; address-decoder 6 ns; data-fetch
0–25 ns; setup 1.5 ns.

**(a) Maximum clock speed.** A clock period must be long enough for the longest single-cycle
activity. Use worst-case (maximum) delays. The two critical sub-operations:

- **Address out → decoded at slave:**
  driver (2) + max propagation (10) + decoder (6) = **18 ns**.
- **Data out → latched at master:**
  driver (2) + max propagation (10) + setup (1.5) = **13.5 ns**.

The clock period must cover the longer phase; the **cycle time ≥ 18 ns** (the address/decode
phase dominates). So:

> **f_max = 1 / 18 ns ≈ 55.5 MHz.**

**(b) Cycles per input operation.** The data fetch can take up to **25 ns**, which exceeds
one 18 ns clock cycle, so the slave can't always deliver data in the same cycle it decodes
the address. With the Fig 7.5 multiple-cycle scheme:
- Cycle 1: master sends address/command; slave decodes.
- Cycle 2: slave fetches data (needs up to 25 ns > one cycle, so it spans into the next).
- Cycle 3: slave places data + asserts Slave-ready; master latches.

> **≈ 3 clock cycles** to complete the input operation (address, fetch, data+ack). If the
> fetch were ≤ one cycle it could finish in 2.

*(Method mirrors Example 7.1; adjust if your course defines the critical path differently.)*

---

## 7.8 [M] Asynchronous bus (Fig 7.6): min & max time for one transfer (skew = 1 ns)

Same parameters as 7.7. The full handshake is **two round trips** (4 end-to-end crossings).
Walk the events t0→t5:

- **t0→t1** (master asserts Master-ready after allowing for skew): address decode must be
  covered; allow skew 1 ns → this interval ≥ skew + decode. Decoder = 6 ns.
- **t1→t2** (Master-ready travels to slave + slave puts data + Slave-ready): propagation +
  data fetch.
- **t2→t3** (Slave-ready travels back + setup).
- **t3→t4, t4→t5** (deassert phases, each a propagation + skew).

Count the delays. Each one-way crossing = driver (2) + propagation. The handshake needs
~**4 propagation crossings** plus the decode, data-fetch, setup, and skew allowances.

**Minimum** (use min propagation 5 ns, min fetch 0 ns):
```
≈ driver+prop (2+5) ×4 crossings  = 28
 + decoder 6 + fetch 0 + setup 1.5 + skew allowances (≈1×4)
 ≈ 28 + 6 + 0 + 1.5 + 4  ≈ 39.5 ns   (minimum ≈ ~40 ns)
```
**Maximum** (max propagation 10 ns, max fetch 25 ns):
```
≈ (2+10)×4 = 48
 + decoder 6 + fetch 25 + setup 1.5 + skew 4
 ≈ 48 + 6 + 25 + 1.5 + 4  ≈ 84.5 ns   (maximum ≈ ~85 ns)
```

> **Min ≈ 40 ns, Max ≈ 85 ns per transfer.** (Exact totals depend on precisely which
> crossings you charge driver delay to; the structure — 4 crossings + decode + fetch + setup
> + skew — is the point. Asynchronous is slower than synchronous here because of the two
> round-trips.)

---

## 7.9 [M] Pulsed (non-interlocked) handshake, 4 ns pulses, edge-triggered

**Answer.** Instead of waiting for the other party's level, each party emits a **fixed 4 ns
pulse**; the receiver acts on the **rising edge**. This removes the "wait for the other
signal to deassert" phases of the full handshake — it's a **two-crossing** exchange
(request pulse out, data+ack pulse back), not four.

Events: master pulses Master-ready → crosses to slave → slave decodes + fetches, pulses
Slave-ready with data → crosses back → master latches.

**Minimum** (min propagation 5, fetch 0):
```
driver(2)+prop(5) → decode(6) → fetch(0) → driver(2)+prop(5) → setup(1.5)
≈ 7 + 6 + 0 + 7 + 1.5 ≈ 21.5 ns   (plus pulse-width accounting ~4 ns) ≈ ~22–26 ns
```
**Maximum** (max propagation 10, fetch 25):
```
driver(2)+prop(10) → decode(6) → fetch(25) → driver(2)+prop(10) → setup(1.5)
≈ 12 + 6 + 25 + 12 + 1.5 ≈ 56.5 ns   ≈ ~57–60 ns
```

> **Min ≈ 22 ns, Max ≈ 57 ns.** Faster than the full handshake of 7.8 (fewer crossings),
> but **less robust**: fixed-width pulses assume the other side is fast enough to see each
> edge, so it can't automatically adapt to arbitrarily slow devices the way the full
> interlocked handshake does.

---

## 7.10 [M] Timing diagram with a shared **Busy** line

**Answer (describe the diagram).** New sequence per the problem: arbiter grants only when
**Busy is inactive**; the granted master **asserts Busy and drops its request**; the arbiter
then **drops the grant**; the master clears Busy when finished.

Draw signals BR1/BG1, BR2/BG2, BR3/BG3, and **Busy**. For the same request pattern as Fig
7.9 (M2 first; then M1 and M3 during M2's use; priority 1>2>3):

```
BR2  ▔▔█████▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁       (M2 requests, drops once it asserts Busy)
BG2  ▔▔▔██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁       (grant pulses, dropped after Busy asserted)
Busy ▔▔▔▔████▁▁▁████▁▁▁████▁▁▁▁       (asserted by whichever master holds the bus)
BR1  ▔▔▔▔███████▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁       (M1 requests during M2)
BG1  ▔▔▔▔▔▔▔▔██▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁       (granted after Busy clears, next by priority)
BR3  ▔▔▔▔███████████▁▁▁▁▁▁▁▁▁▁▁       (M3 requests during M2, served last)
BG3  ▔▔▔▔▔▔▔▔▔▔▔▔▔██▁▁▁▁▁▁▁▁▁▁▁
```
Key differences from Fig 7.9: (1) **grant is a short pulse** (dropped as soon as Busy goes
active, not held for the whole transfer); (2) **Busy** gates everything — a new grant only
issues while Busy is low; (3) request lines drop early (once the master takes Busy). Order
of service is still by priority: M2, then M1, then M3.

---

## 7.11 [M] Modify the Example 7.2 state diagram for the Busy-line protocol

**Answer.** In Example 7.2 (Fig 7.21), the arbiter stays in a grant state B/C/D until the
served device **drops its request**. With the Busy protocol, the trigger to leave a grant
state changes from "request dropped" to "**Busy deasserted**."

Modified machine:
- **State A (idle):** on one or more requests, go to the highest-priority grant state
  (B for R1, C for R2, D for R3) and assert that grant **while Busy is still inactive**.
- **Grant states B/C/D:** as soon as the master asserts **Busy** (and drops its request),
  the arbiter **deasserts the grant** but *remains committed* until **Busy = 0**.
- **Return to A** when **Busy becomes inactive** (device finished), *not* when the request
  line drops.

So every edge condition "request R_i deasserted → back to A" becomes "**Busy deasserted →
back to A**," and each grant is dropped on "Busy asserted" rather than held throughout.

---

## 7.12 [D] Add **preemption** to the arbiter

**(a) Protocol modification.** Introduce a **Preempt** (or "release-request") signal from
arbiter to the current master, plus a **Released** acknowledgment back. Flow:
1. A higher-priority request arrives while a lower-priority device holds the resource.
2. The arbiter asserts **Preempt** to the current device.
3. The device continues only until it reaches a **safe point**, then stops, drops Busy, and
   asserts **Released** (acknowledging a clean stop).
4. The arbiter now grants the resource to the high-priority device.
5. (Optionally) the preempted device re-asserts its request to be resumed later by priority.

This keeps termination **safe** — the device never stops mid-critical-operation; it chooses
the safe point.

**(b) State-diagram modification.** Add, to each grant state B/C/D, a transition that fires
when a **higher-priority request** is active:
- From the current grant state → a new **"Preempting" sub-state**: assert **Preempt**, wait.
- On **Released** (safe stop acknowledged) → go to the grant state of the higher-priority
  requester (assert its grant).
- Lower-priority or equal requests do **not** cause preemption (no transition) — only
  strictly higher priority does.
Normal (non-preempted) completion still returns to A when the device finishes.

---

## 7.13 [E] Rotating-priority arbiter: grant sequence for requests R3, R1, R4, R2

Setup: 4 lines; initial priority R1>R2>R3>R4. After a line is served it drops to **lowest**
and the **next** line becomes highest. Requests: R3 arrives first and is being serviced;
R1, R4, R2 arrive during that service.

Step through:
1. **R3 served first** (it arrived first, alone). After serving R3, priority rotates so the
   line *after* R3 becomes highest: new order **R4 > R1 > R2 > R3**.
2. Pending now: R1, R4, R2. Highest under new order is **R4** → **serve R4.** After R4, next
   becomes highest: order **R1 > R2 > R3 > R4**.
3. Pending: R1, R2. Highest is **R1** → **serve R1.** After R1: order **R2 > R3 > R4 > R1**.
4. Pending: R2. **Serve R2.**

> **Grant sequence: R3, R4, R1, R2.**

---

## 7.14 [E] Rotating vs fixed priority if one device requests repeatedly

**Answer.** With a **rotating-priority** scheme, a device that just got service drops to the
**lowest** priority, so even if it requests again immediately, every *other* waiting device
is served before it comes back around. This guarantees **fairness / no starvation** — every
requester is served within one full rotation.

With a **fixed-priority** scheme, a persistently requesting **high-priority** device can
**monopolize** the resource: each time it re-requests it wins again, and **lower-priority
devices starve** (never get served while the high-priority one keeps asking). Rotating
priority prevents this starvation at the cost of not always honoring an inherent importance
ranking.

---

## 7.15 [E] Address-decoder logic for 16-bit address 0xFA68

**Answer.** 0xFA68 in binary (A15…A0):
```
F    A    6    8
1111 1010 0110 1000
```
The decoder outputs 1 only when every line matches that pattern — AND together each line in
true form where the bit is 1 and complemented form where the bit is 0:

```
Select = A15·A14·A13·A12 · A11·¬A10·A9·¬A8 · ¬A7·A6·A5·¬A4 · A3·¬A2·¬A1·¬A0
```
(bits set to 1 → used uncomplemented; bits 0 → complemented). Equivalently, a 16-input AND
gate fed by the lines with inverters on the zero-bit positions
(A10, A8, A7, A4, A2, A1, A0).

---

## 7.16 [M] Interface for 8 sensor switches read as one byte (synchronous, Fig 7.4)

**Answer.** Build an **8-bit input port**:
1. **Tri-state buffer** (octal, e.g. 74244-style) with its 8 inputs wired to the 8 sensor
   switches (each switch pulled to a defined logic level — ON = 1 when the parameter exceeds
   its limit).
2. **Address decoder** that recognizes this port's assigned address (as in 7.15), producing
   a Select signal.
3. **Enable logic:** `Select AND R/W(=Read) AND (correct clock phase)` drives the tri-state
   buffer's output-enable, so it places all 8 switch states onto **data lines D7–D0**
   *simultaneously* during the data phase of the Fig 7.4 cycle.
4. Because Fig 7.4 is single-cycle and the switch states are static (always available), the
   port can respond within one clock cycle — no latch/fetch delay needed; the buffer just
   gates the live switch levels onto the bus when addressed and read.

Result: one `Load`/`LoadByte` from the port's address returns all eight switch states as a
single byte.

---

## 7.17 [E] Fig 7.4: slave must send data only in the **second** clock phase

**(a) Why not send sooner, and would the processor get wrong data?** The protocol reserves
the **first phase** for the address to propagate and be decoded by all devices. If a fast
slave drove data onto the bus **during the first phase**, its data could collide with the
address information still settling, and other devices might still be decoding. The master
only **samples at t2 (end of second phase)**, so *strictly for timing* the master would
still latch the right value **if** nothing else interfered — but driving early risks **bus
contention** (two sources on shared lines) and violates the single-driver rule. So the
master wouldn't necessarily latch wrong data, but you'd risk electrical conflict.

**(b) Other problems.** **Bus contention / driver conflict:** during the first phase the
address source (or address/data-shared lines) may still be driven; a slave driving data then
means **two devices fighting the bus**, causing invalid levels and possible driver damage,
plus wasted power. Reserving data to the second phase guarantees only one driver per phase.

---

## 7.18 [M] Generate Slave-ready for a memory needing 2 clock cycles (Fig 7.5)

**Answer.** The interface must assert **Slave-ready** only *after* the 2-cycle memory read
completes. Design a small **2-state (or counter) sequencer** clocked by the bus clock:

1. When the **address decoder** asserts Select (device addressed) and R/W = Read, start a
   **2-cycle counter** (or a 2-stage shift register / 2-state FSM).
2. **Cycle 1:** memory access begins; Slave-ready stays **low** (not ready).
3. **Cycle 2:** access completes; the sequencer now **asserts Slave-ready**, and the data
   buffer drives the data lines.
4. Slave-ready drops when Select deasserts (transfer done), resetting the sequencer.

Implementation: a D-flip-flop chain where Select propagates through two clocked stages;
`Slave-ready = output of the second stage`. This delays the ready signal by exactly the two
clock cycles the memory needs, matching the Fig 7.5 variable-duration scheme.

---

## 7.19 [E] PCI: how do DEVSEL# and TRDY# differ? (Fig 7.19)

**Answer.** Both are asserted by the **target** (the problem's "initiator" wording
notwithstanding — in Fig 7.19 these are the *target's* responses):

- **DEVSEL# (Device Select):** means **"I recognize my address — I am the target of this
  transaction."** It is asserted once, early, after the target decodes the address, and held
  for the duration. It answers *"does the addressed device exist / is it me?"*
- **TRDY# (Target Ready):** means **"I am ready to transfer *this* data word right now"**
  (send on a read, accept on a write). It can toggle **per word** during a burst — the
  target deasserts it to insert wait states when it isn't ready for the next word.

So **DEVSEL# = address recognition (once per transaction)**; **TRDY# = data-phase readiness
(can vary word-by-word)**. (IRDY# is the initiator's matching readiness signal.)

---

## 7.20 [E] PCI: target needs a 2-cycle delay between words 2 and 3

**Answer.** PCI handles this with **wait states** via TRDY#. After transferring word 2, the
target simply **deasserts TRDY#** for the two clock cycles it needs. While TRDY# is
deasserted (and IRDY# stays asserted), **no data is transferred** — the bus pauses but the
transaction stays open (FRAME# still asserted, DEVSEL# still asserted). When the target is
ready for word 3, it **re-asserts TRDY#** and word 3 transfers on the next clock. The burst
then continues normally for word 4. Either side (target via TRDY#, initiator via IRDY#) can
insert such pauses — this is PCI's built-in flow control.

---

## 7.21 [E] Timing diagram: transfer **three words to an output device** on PCI

**Answer (describe the diagram).** An output = **write** burst of 3 words. Signals: CLK,
FRAME#, AD, C/BE#, IRDY#, TRDY#, DEVSEL#. (`#` = active low.)

```
Cycle:     1       2       3       4       5
CLK     ‾|_|‾|_|‾|_|‾|_|‾|_
FRAME#  ‾‾\____________/‾‾‾        (asserted cycle1; deasserted during 2nd-last word)
AD      <ADDR><W1 ><W2 ><W3 >      (initiator drives address, then the 3 data words)
C/BE#   <CMD ><--byte enables--->  (write command in cyc1, then byte-enables)
IRDY#   ‾‾\________________/‾      (initiator ready to send each word)
DEVSEL# ‾‾‾‾\____________/‾        (target asserts after decoding its address)
TRDY#   ‾‾‾‾\____________/‾        (target ready to accept each word)
```

Sequence of events:
- **Cycle 1:** initiator asserts **FRAME#**, drives the **address** on AD and the **write
  command** on C/BE#.
- **Cycle 2:** initiator switches AD to **data (word 1)**, asserts **IRDY#**; target asserts
  **DEVSEL#** (recognized) and **TRDY#** (ready to accept). Word 1 transfers when IRDY# &
  TRDY# both low.
- **Cycles 3–4:** words 2 and 3 transfer, one per clock while IRDY# & TRDY# stay asserted.
- Initiator **deasserts FRAME#** during the second-to-last word (word 2's cycle) to signal
  the last word is coming.
- After **word 3**, the initiator deasserts IRDY#, the target deasserts TRDY# and DEVSEL#,
  and the bus is released.

For a *write*, the **initiator drives the data** (unlike the read in Fig 7.19 where the
target drives it), so there's no bus-turnaround cycle — data can start in cycle 2.

---

## Quick index by type

- **Conceptual (definitive):** 7.1, 7.4, 7.5, 7.6, 7.17, 7.19, 7.20.
- **Quantitative (exact numbers):** 7.2 (addresses), 7.7 (≈55 MHz, 3 cycles), 7.8 (≈40–85 ns),
  7.9 (≈22–57 ns).
- **Logic/encoder/decoder design:** 7.3 (priority encoder), 7.15 (address decoder),
  7.16 (8-switch port), 7.18 (Slave-ready sequencer).
- **Arbiter (state diagrams / sequences):** 7.10, 7.11, 7.12, 7.13 (R3,R4,R1,R2), 7.14.
- **PCI timing diagrams:** 7.20, 7.21.

> The quantitative answers (7.7–7.9) follow the Example 7.1 method (sum worst-case delays on
> the critical path). If your instructor charges driver delay or skew to different edges,
> the totals shift by a few ns — show the critical-path reasoning and you'll get full marks.
