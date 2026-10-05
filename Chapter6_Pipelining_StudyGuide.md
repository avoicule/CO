# Chapter 6 — Pipelining

**Textbook:** Computer Organization and Embedded Systems (6th ed.), Hamacher et al.
**Pages covered:** 193–226 (Sections 6.1 → 6.11)

> How to use this guide: read it top to bottom. Each section builds on the previous one.
> Terms in **bold** are the ones you must be able to define. Timing diagrams and code
> blocks come straight from the textbook, explained stage-by-stage. The "Checkpoint"
> boxes are what you should be able to answer before moving on.

---

## Table of Contents

1. [The Big Picture — Why Pipelining Exists](#1-the-big-picture)
2. [Section 6.1 — Basic Concept, The Ideal Case](#2-section-61--basic-concept-the-ideal-case)
3. [Section 6.2 — Pipeline Organization & Interstage Buffers](#3-section-62--pipeline-organization--interstage-buffers)
4. [Section 6.3 — Pipelining Issues (Hazards)](#4-section-63--pipelining-issues-hazards)
5. [Section 6.4 — Data Dependencies](#5-section-64--data-dependencies)
6. [Section 6.4.1 — Operand Forwarding](#6-section-641--operand-forwarding)
7. [Section 6.4.2 — Handling Data Dependencies in Software](#7-section-642--handling-data-dependencies-in-software)
8. [Section 6.5 — Memory Delays](#8-section-65--memory-delays)
9. [Section 6.6 — Branch Delays](#9-section-66--branch-delays)
10. [Section 6.7 — Resource Limitations (Structural Hazards)](#10-section-67--resource-limitations-structural-hazards)
11. [Section 6.8 — Performance Evaluation](#11-section-68--performance-evaluation)
12. [Section 6.9 — Superscalar Operation](#12-section-69--superscalar-operation)
13. [Section 6.10 — Pipelining in CISC Processors](#13-section-610--pipelining-in-cisc-processors)
14. [Instruction & Stage Reference Card](#14-instruction--stage-reference-card)
15. [Glossary of Every Term](#15-glossary-of-every-term)
16. [Self-Test Questions](#16-self-test-questions)

---

## 1. The Big Picture

A processor that executes instructions **one at a time** (Chapter 5) wastes most of its
hardware most of the time. While one instruction is in the Compute stage, the Fetch logic,
the memory unit, and the register-write logic all sit idle. **Pipelining** fixes this waste.

The central idea is **overlapping execution**: start a new instruction before the previous
one has finished, so that at any instant each piece of hardware is busy with a *different*
instruction.

| Approach | What the hardware does | Throughput |
|----------|------------------------|------------|
| Sequential (Ch. 5) | One instruction occupies the whole datapath for 5 cycles | 1 instruction / 5 cycles |
| Pipelined (Ch. 6) | Five instructions occupy five stages at once | ideally 1 instruction / cycle |

**Analogy (the automobile assembly line):** The textbook's own analogy. One station
prepares the chassis, the next adds the body, the next installs the engine, and so on.
While one crew installs an engine on car 1, another crew fits a body on car 2, and a third
prepares the chassis for car 3. Any single car still takes hours or days to build, but a
finished car rolls off the end **every few minutes**. Pipelining does the same for
instructions: each instruction still takes 5 cycles end-to-end, but one *completes* every
cycle.

Everything else in the chapter is about the gap between the **ideal case** (one instruction
finishing per cycle) and **reality**, where **hazards** force the pipeline to pause.

> **Checkpoint:** Does pipelining make a single instruction execute faster? *(No. Each
> instruction still takes the same number of cycles. Pipelining raises throughput — how
> many instructions finish per second — not the latency of one instruction.)*

---

## 2. Section 6.1 — Basic Concept, The Ideal Case

The Chapter 5 processor uses a **five-stage** organization. Pipelining reuses those same
five stages but runs a different instruction in each one simultaneously. The stages are:

| # | Stage | What happens |
|---|-------|--------------|
| 1 | **Fetch** | Use the PC to read the instruction from memory |
| 2 | **Decode** | Decode the instruction and read its operands from the register file |
| 3 | **Compute** | Perform the arithmetic or logic operation in the ALU |
| 4 | **Memory** | Access memory (for Load/Store instructions) |
| 5 | **Write** | Write the result back into the register file |

The ideal overlap (**Figure 6.1**): instruction `Ij` is fetched in cycle 1 and then moves
through the remaining stages in the following cycles. In cycle 2, `Ij+1` is fetched while
`Ij` is in Decode. In cycle 3, `Ij+2` is fetched, `Ij+1` is in Decode, and `Ij` is in
Compute.

```
Clock cycle    1       2       3       4       5       6       7
Ij           Fetch   Decode  Compute Memory  Write
Ij+1                 Fetch   Decode  Compute Memory  Write
Ij+2                         Fetch   Decode  Compute Memory  Write
```

**Key observation:** any one instruction takes **five cycles** to complete, but once the
pipeline is full, instructions **complete at the rate of one per cycle**.

> **Checkpoint:** In the ideal pipeline, how many instructions are "in flight" at once
> after the pipeline fills? *(Five — one in each of the five stages.)*

---

## 3. Section 6.2 — Pipeline Organization & Interstage Buffers

**Figure 6.2** shows how the five-stage datapath is pipelined. The PC fetches a new
instruction in the first stage; as more instructions are fetched, execution proceeds
through successive stages. **At any given time, each stage is processing a different
instruction.**

The problem: information an instruction needs (register addresses, immediate data, the
operation to perform, control-signal settings) must travel *with* that instruction as it
moves from stage to stage. This information is held in **interstage buffers** — registers
placed *between* the stages. They include RA, RB, RM, RY, and RZ from Figure 5.8, the IR
and PC-Temp registers, plus additional storage.

| Buffer | Sits between | What it carries |
|--------|--------------|-----------------|
| **B1** | Fetch → Decode | The newly-fetched instruction |
| **B2** | Decode → Compute | Two operands read from the register file, source/destination register identifiers, the immediate value, the incremented PC (return address), and the control-signal settings from the decoder |
| **B3** | Compute → Memory | The ALU result (data to write, or an address for the Memory stage); the data to be written on a Store; the incremented PC |
| **B4** | Memory → Write | The value to write into the register file (ALU result, memory-read result, or incremented PC) |

The control-signal settings decided by the decoder **move through the pipeline inside the
buffers** so that each later stage knows what to do: which ALU operation to run, which
memory operation to perform, and whether to write the register file.

> **Deep dive — why buffers are mandatory:** Without interstage buffers, the signals for
> instruction `Ij+1` in Decode would collide with the signals for `Ij` in Compute, because
> both share the same wires. The buffers latch each instruction's state at the end of every
> cycle, giving each stage a private, stable copy of exactly what it needs.

> **Checkpoint:** Where do the control signals that tell the Memory and Write stages what
> to do come from? *(They are produced by the instruction decoder in the Decode stage and
> carried forward through buffers B2, B3, and B4.)*

---

## 4. Section 6.3 — Pipelining Issues (Hazards)

The ideal of Figure 6.1 cannot always hold. Sometimes a new instruction **cannot** enter
the pipeline every cycle.

Consider two instructions `Ij` and `Ij+1`, where the **destination** register of `Ij` is a
**source** register of `Ij+1`. The result of `Ij` is not written to the register file until
cycle 5, but `Ij+1` needs to read that source operand in cycle 3. If execution proceeded as
in Figure 6.1, `Ij+1` would read the **old** value and compute a wrong result. To be
correct, `Ij+1` must wait until the new value is written — it cannot read its operand until
cycle 6, so it is **stalled in the Decode stage for three cycles**. While `Ij+1` is stalled,
`Ij+2` and all later instructions are delayed too.

> **Definition — Hazard:** *Any condition that causes the pipeline to stall is called a
> hazard.* The example above is a **data hazard** (a source operand is not available when
> needed). Other hazards arise from **memory delays**, **branch instructions**, and
> **resource limitations**.

The three hazard families covered in this chapter:

| Hazard type | Cause | Covered in |
|-------------|-------|-----------|
| **Data hazard** | An operand isn't ready because a prior instruction hasn't written it yet | §6.4, §6.5 |
| **Control (instruction) hazard** | A branch changes the instruction flow, so wrongly-fetched instructions must be discarded | §6.6 |
| **Structural hazard** | Two instructions need the same hardware resource in the same cycle | §6.7 |

> **Checkpoint:** Name the three families of hazards. *(Data hazards, control/branch
> hazards, and structural/resource hazards.)*

---

## 5. Section 6.4 — Data Dependencies

A **data dependency** exists when one instruction carries data to a later instruction
through a register. Example (**Figure 6.3**):

```asm
Add       R2, R3, #100      ; R2 = R3 + 100   (R2 is the destination)
Subtract  R9, R2, #30       ; R9 = R2 - 30    (R2 is a source → dependency)
```

Register R2 carries data from the Add to the Subtract. In the pipeline, the Subtract is
**stalled for three cycles**, delaying its read of R2 until cycle 6, when the new value is
available.

```
Clock cycle        1   2   3   4   5   6   7   8   9
Add R2,R3,#100     F   D   C   M   W
Subtract R9,R2,#30     F   -   -   -   D   C   M   W
```

**How the stall is created (the mechanics):**

1. In **cycle 3**, the control circuit decodes the Subtract and detects the dependency by
   **comparing** the Subtract's source-register identifier (held in buffer B1) with the
   Add's destination-register identifier (held in buffer B2).
2. The Subtract is held in buffer **B1 during cycles 3–5** while the Add proceeds through
   the remaining stages.
3. In cycles 3–5, as the Add moves ahead, control signals are set in B2 for an implicit
   **NOP (No-operation)** instruction — one that modifies neither memory nor the register
   file.
4. Each NOP creates one clock cycle of idle time, called a **bubble**, that passes through
   the Compute, Memory, and Write stages to the end of the pipeline.

> **Definition — Bubble:** The idle clock cycle introduced by an implicit NOP as it travels
> down the pipeline. Three stall cycles = three bubbles.

> **Checkpoint:** How does the hardware *detect* the dependency in Figure 6.3? *(It compares
> the source-register identifier of the Subtract in B1 against the destination-register
> identifier of the Add in B2.)*

---

## 6. Section 6.4.1 — Operand Forwarding

Stalling is wasteful, and often unnecessary. Look again at the Add/Subtract pair: the new
value of R2 is **actually available at the end of cycle 3**, when the ALU finishes the Add.
That value is loaded into register **RZ** (part of interstage buffer B3). We don't need to
wait for it to be written back to the register file in cycle 5.

**Operand forwarding** (a.k.a. data forwarding) routes the value directly from RZ to where
it is needed — the ALU input — in cycle 4, instead of stalling (**Figure 6.4**):

```
Clock cycle        1   2   3   4   5   6
Add R2,R3,#100     F   D   C   M   W
Subtract R9,R2,#30     F   D   C   M   W
                           ↑
            ALU result of cycle 3 forwarded into ALU input of cycle 4
```

**The datapath change (Figure 6.5):** a new multiplexer **MuxA** is inserted before ALU
input InA, and the existing **MuxB** is given an extra input. Each multiplexer can now select
either a value read from the register file in the normal way, **or** the value sitting in
register RZ.

**Forwarding from RY as well.** Forwarding can also pull from register **RY**, to cover a
dependency separated by one more instruction:

```asm
Add       R2, R3, #100
Or        R4, R5, R6        ; an unrelated instruction in between
Subtract  R9, R2, #30       ; still depends on R2
```

When the Subtract is in Compute, the Or is in Memory (no operation), and the Add is in
Write. The new R2 value is now in register **RY**. Forwarding it from RY to ALU input InA
avoids the stall. MuxA and MuxB each gain another input for the RY value.

> **Deep dive — why RZ and RY both matter:** RZ holds the result **one cycle** after Compute;
> RY holds it **two cycles** after Compute. Together they cover a dependency where the
> producing instruction is one *or* two positions ahead of the consumer, which is exactly the
> window during which the result exists in the pipeline but hasn't reached the register file.

> **Checkpoint:** Which register holds the ALU result that gets forwarded in Figure 6.4, and
> to where? *(Register RZ, forwarded to the ALU input in the next cycle.)*

---

## 7. Section 6.4.2 — Handling Data Dependencies in Software

Instead of building forwarding or stall-detection into the hardware, the task can be left to
the **compiler**. When the compiler sees a data dependency between successive instructions
`Ij` and `Ij+1`, it inserts **three explicit NOP instructions** between them (**Figure 6.6a**):

```asm
Add       R2, R3, #100
NOP
NOP
NOP
Subtract  R9, R2, #30
```

The three NOPs introduce exactly the delay needed for `Ij+1` to read the new value **after**
it has been written to the register file. Their effect on execution time (**Figure 6.6b**)
is identical to the three-cycle hardware stall of Figure 6.3.

**Trade-offs:**

| | Hardware stall / forwarding | Software NOPs |
|--|-----------------------------|---------------|
| Hardware complexity | Higher (detection + forwarding paths) | Lower (simpler pipeline) |
| Code size | Unchanged | **Larger** (NOPs added) |
| Execution time | Reduced with forwarding | **Not reduced** (NOPs still cost cycles) |

The compiler can do better than blindly inserting NOPs: it can **reorder instructions** to
move genuinely useful work into the NOP slots. In doing so it must respect the data
dependencies between instructions, which limit how freely the slots can be filled.

> **Checkpoint:** Why is the software-NOP approach less attractive than forwarding, despite
> simplifying the hardware? *(Code size grows and execution time is not reduced — the NOPs
> still burn cycles, whereas forwarding removes the stall entirely.)*

---

## 8. Section 6.5 — Memory Delays

Memory accesses are a second source of stalls.

**Cache-miss stall (Figure 6.7).** A Load instruction may need more than one clock cycle to
get its operand if the data is **not in the cache** — a **cache miss**. A real memory access
may take **ten or more cycles** (the figure shows three for simplicity). A cache miss delays
**all subsequent instructions**. The same kind of delay happens on a cache miss while
**fetching** an instruction.

**Load-use dependency stall (Figure 6.8).** A subtler stall happens even on a **cache hit**,
when an instruction depends on data a Load just read:

```asm
Load      R2, (R3)          ; read memory into R2 (1 cycle, cache hit)
Subtract  R9, R2, #30       ; needs R2
```

Here forwarding **cannot** work the same way as in Figure 6.4, because the data read from
the cache is not available until it is loaded into register **RY at the beginning of cycle
5**. So the Subtract must be **stalled for one cycle** to delay its ALU operation; then the
memory operand, now in RY, is forwarded to the ALU input in cycle 5.

```
Clock cycle        1   2   3   4   5   6   7
Load R2,(R3)       F   D   C   M   W
Subtract R9,R2,#30     F   D   -   C   M   W
                                 ↑ one-cycle stall, then forward RY
```

**The compiler's role.** The compiler can **eliminate** this one-cycle stall by reordering
instructions to place a **useful instruction between** the Load and the dependent
instruction — filling the bubble that would otherwise form. If no useful instruction can be
found, the hardware inserts the one-cycle stall automatically; if the hardware doesn't handle
dependencies at all, the compiler must insert an explicit NOP.

> **Checkpoint:** Why can't a Load-use dependency be forwarded with zero stall like a
> Compute-use dependency? *(The loaded data isn't ready at the end of Compute; it only
> arrives in RY at the start of cycle 5, one cycle too late, forcing a single-cycle stall.)*

---

## 9. Section 6.6 — Branch Delays

Branch instructions change the sequence of execution — but the processor must first *execute*
the branch to learn **whether** and **where** to branch. Meanwhile the pipeline keeps
fetching the next sequential instructions, which may turn out to be wrong.

### 6.6.1 — Unconditional Branches

For an unconditional branch `Ij` whose target is `Ik` (**Figure 6.9**): the branch is fetched
in cycle 1, decoded in cycle 2, and the **target address is computed in cycle 3**. So `Ik`
can only be fetched in cycle 4. But in cycles 2 and 3 the pipeline already fetched `Ij+1` and
`Ij+2` (the instructions sitting right after the branch). Those must be **discarded**. The
result is a **two-cycle branch penalty**.

**Why this matters:** Branches are about **20 percent** of the *dynamic instruction count*
(the number of instruction *executions*, counting loop repetitions). With a two-cycle
penalty, the execution time of a program could rise by as much as **40 percent**.

**The fix — compute the target earlier (Figure 6.10).** Determine the target address and
update the PC in the **Decode stage** instead of the Compute stage. Then `Ik` is fetched one
cycle earlier, and only one instruction (`Ij+1`) is fetched incorrectly — a **one-cycle
penalty**. The hardware change: a **second adder in the Decode stage** computes a branch
target for every instruction; when the decoder confirms the instruction is a branch, the
target is already available to fetch from next cycle.

### 6.6.2 — Conditional Branches

```asm
Branch_if_[R5]=[R6]  LOOP
```

For a conditional branch the **branch condition must be tested as early as possible**. The
**comparator** that tests the condition is also moved into the **Decode stage**, so the
branch decision and the target address are determined **at the same time**. The comparator
uses the values from outputs A and B of the register file directly. This gives a **common
one-cycle penalty for all branch instructions**.

### 6.6.3 — The Branch Delay Slot

The instruction location **immediately after a branch** is always fetched, regardless of the
branch outcome. This location is called the **branch delay slot**.

Rather than conditionally discard whatever is in the delay slot, the pipeline is arranged to
**always execute** it. The compiler finds a useful instruction — typically **one of the
instructions that preceded the branch** — and moves it into the slot, provided data
dependencies are preserved. This is called **delayed branching**: branching effectively takes
place one instruction later than where the branch appears.

**Figure 6.11 example:**

```asm
; (a) original
Add               R7, R8, R9
Branch_if_[R3]=0  TARGET
Ij+1
...
TARGET: Ik
```

```asm
; (b) Add moved into the delay slot — always executed
Branch_if_[R3]=0  TARGET
Add               R7, R8, R9     ; delay slot: executed whether or not branch taken
Ij+1
...
TARGET: Ik
```

If a useful instruction is found, there is **no penalty**. If no instruction can be moved
(because of data dependencies), a **NOP** goes in the slot and there is a one-cycle penalty
either way. Experimental data: the compiler can usefully fill the delay slot in **70 percent
or more** of cases.

### 6.6.4 — Branch Prediction

Even deciding the branch in cycle 2, the instruction fetched in cycle 2 may still have to be
discarded. The decision to fetch *that* instruction was made in **cycle 1**, when the PC was
incremented while the branch itself was being fetched. To cut the penalty further, the
processor must **anticipate** that an instruction being fetched is a branch and **predict** its
outcome, all in cycle 1.

**Static branch prediction.** Use the same guess every time:

- Simplest: **assume not-taken**, keep fetching sequentially. Correct → no penalty;
  wrong → full penalty. If branches were random this gives **50 percent** accuracy.
- Better: a **backward branch** (end of a loop) is usually taken → predict **taken**; a
  **forward branch** (start of a loop) is often not taken → predict **not-taken**. The
  processor can decide from the **sign of the branch offset**, or from a **prediction bit**
  in the instruction encoding set by the compiler.

**Dynamic branch prediction.** Use the branch's **actual past behavior**. The hardware keeps
track of branch decisions each time the instruction executes.

- **Two-state algorithm (Figure 6.12a):** states **LT** (likely taken) and **LNT** (likely
  not taken). Uses only the single most recent outcome. Works well inside loops, but
  **mispredicts twice per loop** — on the first pass and the last pass.
- **Four-state algorithm (Figure 6.12b):** states **ST** (strongly taken), **LT** (likely
  taken), **LNT** (likely not taken), **SNT** (strongly not taken). Predict **taken** if ST
  or LT, else **not taken**. Keeping more history reduces loop mispredictions to **only one
  per loop** (the last pass).

**Branch target buffer (BTB).** To predict in **cycle 1**, the processor stores branch
history in a small, fast memory — the **branch target buffer** — organized as a lookup table
keyed by instruction address. Each entry holds:

- the address of the branch instruction
- one or two **state bits** for the prediction algorithm
- the **branch target address**

Every fetch, the processor checks the BTB for the current instruction address. A hit means
"this is a branch"; the processor reads the state bits to predict taken/not-taken **and** gets
the target address — **all while the branch is still being fetched in cycle 1**. In cycle 2
it fetches using the prediction; it still verifies the real decision and target, discarding and
re-fetching in cycle 3 only on a misprediction. Because a BTB for *all* branches would be
too large and slow to search, the table is limited — typically about **1024 entries** — holding
only the most recently executed branches.

> **Checkpoint:** Why must branch prediction happen in cycle 1 rather than cycle 2? *(The
> decision of which instruction to fetch in cycle 2 is made in cycle 1 when the PC is
> incremented; to fetch the right instruction in cycle 2 the prediction and target must
> already be known, which the branch target buffer provides.)*

---

## 10. Section 6.7 — Resource Limitations (Structural Hazards)

A **structural hazard** occurs when two instructions need the **same hardware resource in the
same clock cycle**; one must be stalled so the other can use it. Adding hardware prevents it.

**The classic example — a single cache.** If one cache serves both the Fetch stage and the
Memory stage and allows only one access per cycle, the two stages cannot both proceed when a
Load or Store sits in the Memory stage. Fetch (which accesses the cache every cycle) must
stall for one cycle. If **25 percent** of instructions are Load/Store, these stalls increase
execution time by **25 percent**.

**The fix:** use **separate caches for instructions and data**, so the Fetch and Memory
stages can access memory simultaneously without stalling.

> **Checkpoint:** How does splitting the cache into an instruction cache and a data cache
> remove the structural hazard? *(Fetch uses the instruction cache while Memory uses the data
> cache, so both accesses happen in the same cycle without competing for one port.)*

---

## 11. Section 6.8 — Performance Evaluation

**The basic performance equation** (non-pipelined):

```
T = (N × S) / R
```

- **T** = execution time
- **N** = dynamic instruction count
- **S** = average clock cycles to fetch and execute one instruction
- **R** = clock rate (cycles per second)

**Instruction throughput** = instructions executed per second.

- Non-pipelined: `Pnp = R / S`. The Chapter 5 processor uses five cycles per instruction, so
  with no cache misses **S = 5**.
- Ideal pipelined: a new instruction enters every cycle, so **S = 1** and `Pp = R`. An
  **n-stage pipeline can potentially increase throughput n times**.

This raises two questions: how much of the potential gain is realized in practice, and what
is a good value for *n*? Any stall or discarded instruction drops throughput below ideal.

### 6.8.1 — Effects of Stalls and Penalties (quantitative)

Each stall source adds an increment to S above the ideal value of 1. The example assumes the
ALU delay dictates the cycle time; if that delay is 2 ns then R = 500 MHz and ideal
throughput `Pp = 500 MIPS`.

**Load-use stalls.** With hardware forwarding, the only remaining data-dependency stall is a
Load immediately followed by a dependent instruction (one-cycle stall, §6.5):

```
δstall = (fraction of Loads) × (fraction of those followed by a dependent instr) × 1
δstall = 0.25 × 0.40 × 1 = 0.10        → T rises 10%, Pp = R / 1.1 = 0.91R
```

**Branch misprediction penalties.** With a one-cycle penalty, 20% branches, 90% prediction
accuracy (so 10% mispredict):

```
δbranch_penalty = 0.20 × 0.10 × 1 = 0.02
```

**Cache misses.** With a per-miss penalty `pm`, instruction-fetch miss fraction `mi`, Load/
Store fraction `d`, and data-miss fraction `md`:

```
δmiss = (mi + d × md) × pm
δmiss = (0.05 + 0.30 × 0.10) × 10 = 0.8
```

The three increments are **independent and additive**:

```
S = 1 + δstall + δbranch_penalty + δmiss
```

**Takeaway:** In the worked example, the cache-miss contribution (0.8) dwarfs the
data-dependency stall (0.10) and the branch penalty (0.02). **Cache misses are often the
dominant factor.**

### 6.8.2 — Number of Pipeline Stages

More stages (larger *n*) means higher *potential* throughput, but:

- More instructions in flight → **more potential dependencies** → more stalls.
- A longer pipeline may push the branch decision to a later stage → **larger branch
  penalty**.
- So the throughput gain from increasing *n* **diminishes**, and a deeper pipeline may not
  be worth the cost.

The **ALU delay** is the key floor on cycle time: the clock is usually chosen so one ALU
operation completes in one cycle, and other operations (like cache access) are divided into
steps of roughly that same length. A **pipelined ALU** allows even shorter cycles. Some
recent processors use **twenty or more stages** to aggressively shorten the cycle, reaching
clock rates of several GHz.

> **Checkpoint:** In the worked example, which single factor hurts throughput most, and by
> how much does it raise S? *(Cache misses, raising S by δmiss = 0.8 — far more than the
> 0.10 data-stall and 0.02 branch-penalty terms.)*

---

## 12. Section 6.9 — Superscalar Operation

A single pipeline tops out at **one instruction per cycle**. A **superscalar** processor
breaks that ceiling by using **multiple execution units**, each possibly pipelined, so that
several instructions **start execution in the same cycle** in different units. This is called
**multiple-issue**, and it gives throughput of **more than one instruction per cycle**.

**Organization (Figure 6.13):**

- A richer **fetch unit** fetches two or more instructions per cycle, ahead of need, into an
  **instruction queue**.
- A **dispatch unit** takes instructions from the front of the queue, decodes them, and sends
  them to the appropriate execution units.
- The example has two execution units: an **arithmetic unit** (one cycle, simple) and a
  **Load/Store unit** (a two-stage pipeline, because Index-mode addressing needs an address
  calculation before each memory access).

**Register-file implications.** Dispatching an arithmetic instruction and a Load/Store in the
same cycle means both must read operands at once — the register file needs **four output
ports** instead of two. Two instructions completing together means it needs **two input
ports** instead of one. If two instructions would write the **same destination register** in
the same cycle, dispatch is arranged to avoid it; otherwise one is stalled so results are
written in **program order**.

**Example (Figure 6.14):**

```asm
Add       R2, R3, #100      ; arithmetic unit
Load      R5, 16(R6)        ; Load/Store unit
Subtract  R7, R8, R9        ; arithmetic unit
Store     R10, 24(R11)      ; Load/Store unit
```

The fetch unit grabs two instructions per cycle; they are decoded and their source registers
read next cycle; then they are dispatched to the two units. Arithmetic ops initiate every
cycle; the two-stage Load/Store unit overlaps one instruction's address calculation with the
previous one's memory access. Two results can be written in the same cycle because their
destination registers differ.

### 6.9.1 — Branches and Data Dependencies

A superscalar processor must still enforce correct sequencing.

- **Branches:** The fetch unit must determine the decision and target for each branch.
  Stalling until an earlier result is known kills throughput, so it uses **branch
  prediction** combined with **speculative execution** — fetching, dispatching, and possibly
  executing instructions beyond an unconfirmed prediction, **labeled speculative** so they
  (and their results) can be discarded if the prediction was wrong. Extra hardware tracks
  speculative instructions and ensures correct re-fetch on a misprediction.
- **Data dependencies:** A simple option is to dispatch dependent instructions **in sequence
  to the same unit**. But dependents may go to different units (e.g. a Load result needed by
  an Add). Since units run independently, a mechanism is needed to make a dependent
  instruction **wait for its operands**. Dispatched instructions are buffered in
  **reservation stations** holding their info and operands. Each unit **broadcasts** its
  results, tagged with a register identifier, to all reservation stations; a matching tag
  copies the result in, and an instruction begins only when it has **all** its operands.

In a multiple-issue processor the harm from stalls is even greater than in single-issue, so
the compiler should **interleave arithmetic and memory instructions** to keep both units
busy.

### 6.9.2 — Out-of-Order Execution

Instructions in Figure 6.14 are dispatched in program order but may **complete out of order**
(e.g. the Subtract may finish before a slow Load). If there is no dependency between a pair of
instructions, the completion order does not matter.

**But exceptions create a complication.** If the Load triggers an exception (say an illegal
unaligned access) *after* the later Subtract has already modified its destination register,
program state is **inconsistent** — this is an **imprecise exception**.

**Precise exceptions** (the preferred alternative) require that results are **written to their
destinations strictly in program order**. The Subtract's write to R7 must wait until the
Load's write to R5 is done; its result is buffered in a **temporary register** meanwhile. If
an exception occurs, all subsequent instructions and their buffered results are discarded.
Precise exceptions are easier for **external interrupts**: the dispatch unit stops reading new
instructions, discards those still queued, lets pending instructions finish, and then the
processor is in a consistent state for interrupt processing.

### 6.9.3 — Execution Completion

To go fast, an execution unit should run **any** instruction whose operands are ready (out of
order), yet instructions must **complete in program order** for precise exceptions. The
resolution:

- Execute out of order, writing results into **temporary registers**.
- Later transfer those results to the **permanent registers** in correct program order — the
  **commitment step** (after which an instruction's effect cannot be reversed).
- **Register renaming:** a temporary register assigned to an instruction's result takes on the
  role of the permanent register it holds, and its contents are forwarded to any later
  instruction referring to that permanent register.
- A **commitment unit** guarantees in-order commitment using a **reorder buffer** — a queue
  that instructions enter strictly in program order at dispatch. When an instruction reaches
  the head and has completed, its results move to the permanent registers and it is
  **retired**; its temporary registers are released. Thus instructions **complete out of
  order but retire in program order**.

### 6.9.4 — Dispatch Operation

Before dispatching, the dispatch unit must ensure **all needed resources are available**: a
free temporary register, space in the target unit's reservation station, and a slot in the
reorder buffer. Only then is the instruction dispatched.

**Out-of-order dispatch risks deadlock.** A **deadlock** arises when unit B can't finish
until unit A finishes, while B holds a resource A needs — neither can proceed. Example: with
only **one temporary register**, dispatching the Subtract before the Load reserves that
register for the Subtract; the Load can't dispatch (it needs the same register), which won't
free until the Subtract retires — but the Subtract can't retire before the Load. Deadlock.

Preventing deadlocks makes out-of-order dispatch complex and slow. **In-order dispatch**
avoids it: program order is enforced at **dispatch** and again at **retirement**, while
execution between those two points may proceed out of order, subject only to
interdependencies.

**Number of execution units.** Beyond the one-arithmetic + one-Load/Store example, modern
superscalar processors often add **two integer arithmetic units**, a separate
**floating-point unit** (with its own register file), and often a **vector unit** (two to
eight parallel operations, possibly its own register file). A single Load/Store unit usually
serves all of them. To keep many units busy, processors may fetch and dispatch **four or more
instructions** per cycle.

> **Checkpoint:** How can a processor allow out-of-order execution yet still provide precise
> exceptions? *(Execute out of order into temporary registers, then commit/retire results to
> permanent registers in program order using a reorder buffer; on an exception, discard the
> buffered results of later instructions.)*

---

## 13. Section 6.10 — Pipelining in CISC Processors

**Why RISC pipelines easily.** RISC instruction sets suit the five-stage pipeline: all
instructions are **one word**, operand fields sit in the same position across instructions,
**no instruction needs more than one memory operand**, only **Load/Store** access memory
(typically with indexed addressing), and all other instructions use **register operands**.

**Why CISC complicates pipelining:**

- **Variable instruction size** → multi-word instructions take several cycles to fetch and
  complicate decoding, operand access, and dispatch-queue management in a superscalar
  processor.
- **Side effects from complex addressing** (e.g. Autoincrement/Autodecrement). `Move R5,(R8)+`
  affects **both** R5 (destination) **and** R8 (autoincremented source). A later dependency on
  R8 must be handled just like a destination dependency — stall or forward, or in a
  superscalar processor, temporary registers and register renaming.
- **Condition codes as side effects.** In
  ```asm
  Compare   R7, R8
  Branch>0  TARGET
  ```
  the Compare sets condition flags as a side effect, and the Branch depends on them. A
  condition-code register fits easily in a simple pipeline (one ALU op per cycle) but in a
  superscalar processor with multiple ALUs doing two or more operations per cycle, these
  dependencies again need **temporary registers and register renaming**.
- **Multiple memory operands.** In
  ```asm
  Move  (R2), (R3)      ; two memory accesses
  Move  (R4), R5        ; one memory access
  ```
  the first Move needs two memory operand accesses, requiring hardware to **stall** the second
  Move (or the Load/Store unit's internal pipeline in a superscalar design) until the first
  completes.

These complications were **a main reason for developing RISC**. Still, CISC instruction sets
(which predate widespread pipelining) have been pipelined — e.g. **ColdFire** (embedded) and
**Intel** (general-purpose) processors.

### 6.10.1 — Pipelining in ColdFire Processors

Versions **V1/V2** use **two pipelines in series** with a **FIFO buffer** between them: a
two-stage instruction-fetch pipeline prefetches into the buffer, which feeds a two-stage
execution pipeline. Register-only or register-to-memory instructions make **one pass** through
the execution stages; memory-to-register or memory-to-memory instructions make **two passes**.
Later versions enhance this: **V4** extends fetch to four stages (with branch prediction) and
execution to five stages (early stages for address calculation, later stages for arithmetic/
logic), enabling a **limited form of superscalar** processing. **V5** adds a second execution
pipeline for **true superscalar** processing.

### 6.10.2 — Pipelining in Intel Processors

Intel's **Core 2** and **Core i7** use a **multiple-issue width of four** and a **14-stage
pipeline**, with branch prediction, register renaming, and out-of-order execution. CISC
instructions are **dynamically converted by hardware into simpler RISC-style
micro-operations**, which are issued to the execution units — preserving code compatibility
while enabling aggressive RISC-style techniques. Sometimes micro-operations are **fused** into
macro-operations (e.g. a compare followed by a branch is fused into a single
compare-and-branch) for more efficient handling.

> **Checkpoint:** How do modern Intel processors reconcile CISC compatibility with RISC-style
> performance techniques? *(Hardware dynamically translates CISC instructions into simpler
> RISC-like micro-operations — sometimes fusing related ones — then runs those on execution
> units that use pipelining, out-of-order execution, and register renaming.)*

---

## 14. Instruction & Stage Reference Card

### The five pipeline stages

| Abbr. | Stage | Role |
|-------|-------|------|
| **F** | Fetch | Read instruction from memory using the PC |
| **D** | Decode | Decode instruction and read operands from the register file |
| **C** | Compute | Perform the ALU (arithmetic/logic) operation |
| **M** | Memory | Access memory (Load/Store) |
| **W** | Write | Write the result into the register file |

### Interstage buffers

| Buffer | Between | Carries |
|--------|---------|---------|
| B1 | F → D | fetched instruction |
| B2 | D → C | operands, register IDs, immediate, incremented PC, control signals |
| B3 | C → M | ALU result (RZ) / address / store data / incremented PC |
| B4 | M → W | value to write back (ALU result, memory result, or PC) |

### Hazards and their cures

| Hazard | Symptom | Cure(s) |
|--------|---------|---------|
| Data dependency (Compute-use) | Operand not yet written | Operand forwarding from RZ/RY; else stall or software NOPs |
| Data dependency (Load-use) | Loaded data arrives late | One-cycle stall then forward from RY; compiler reordering |
| Memory delay (cache miss) | 10+ cycle stall | Caching; cannot be removed, only reduced |
| Control / branch | Wrong instructions fetched after a branch | Decide branch in Decode; delayed branching; branch prediction + BTB; speculative execution |
| Structural / resource | Two stages need one resource | Add hardware; separate instruction and data caches |

### Performance increments (added to ideal S = 1)

| Term | Formula | Example value |
|------|---------|---------------|
| `δstall` | Loads × dependent-fraction × 1 | 0.25 × 0.40 = 0.10 |
| `δbranch_penalty` | branches × misprediction-rate × 1 | 0.20 × 0.10 = 0.02 |
| `δmiss` | (mi + d × md) × pm | (0.05 + 0.30×0.10) × 10 = 0.8 |
| **S total** | 1 + δstall + δbranch_penalty + δmiss | — |

---

## 15. Glossary of Every Term

**Pipelining concepts**
- **Pipelining** — overlapping the execution of successive instructions to raise throughput.
- **Throughput** — instructions completed per second. Ideal pipelined = R.
- **Latency** — cycles for one instruction end-to-end (5 here); unchanged by pipelining.
- **Interstage buffer (B1–B4)** — register between pipeline stages carrying an instruction's
  state and control signals forward.
- **Stage (F, D, C, M, W)** — Fetch, Decode, Compute, Memory, Write.

**Hazards**
- **Hazard** — any condition that causes the pipeline to stall.
- **Data hazard / data dependency** — a source operand isn't available because a prior
  instruction hasn't written it yet.
- **Control (branch) hazard** — a branch alters flow, forcing wrongly-fetched instructions to
  be discarded.
- **Structural (resource) hazard** — two instructions need the same resource in one cycle.
- **Stall** — pausing the pipeline until a hazard clears.
- **Bubble** — the idle clock cycle created by an implicit NOP travelling down the pipeline.
- **NOP** — No-operation instruction; modifies neither memory nor the register file.

**Data-hazard cures**
- **Operand forwarding (data forwarding)** — routing a result directly from RZ or RY to an ALU
  input instead of waiting for register-file write-back.
- **MuxA / MuxB** — multiplexers added before the ALU inputs to select forwarded values.
- **RZ / RY** — interstage result registers; RZ holds the ALU result one cycle later, RY two
  cycles later.
- **Load-use dependency** — a dependency on data a preceding Load just read; needs a one-cycle
  stall even on a cache hit.

**Memory**
- **Cache miss** — requested instruction/data not in cache; costs ten or more cycles.

**Branches**
- **Branch penalty** — cycles lost to discarded instructions after a branch (two cycles if
  resolved in Compute, one if resolved in Decode).
- **Dynamic instruction count** — number of instruction *executions*, counting loop repeats;
  branches ≈ 20%.
- **Branch delay slot** — the location right after a branch, always fetched.
- **Delayed branching** — always executing the delay-slot instruction; the compiler fills it
  usefully ~70% of the time.
- **Static branch prediction** — fixed guess (e.g. assume not-taken; backward = taken, forward
  = not-taken).
- **Dynamic branch prediction** — guess based on observed history.
- **LT / LNT / ST / SNT** — Likely Taken, Likely Not Taken, Strongly Taken, Strongly Not Taken
  prediction states.
- **Branch target buffer (BTB)** — small fast table (≈1024 entries) keyed by branch address,
  holding state bits and target address, enabling prediction in cycle 1.

**Performance**
- **Basic performance equation** — T = (N × S) / R.
- **S** — average cycles per instruction. **N** — dynamic instruction count. **R** — clock
  rate.
- **MIPS** — million instructions per second.
- **δstall / δbranch_penalty / δmiss** — increments added to ideal S from Load-use stalls,
  branch mispredictions, and cache misses.

**Superscalar**
- **Superscalar processor** — uses multiple execution units for throughput above one
  instruction/cycle.
- **Multiple-issue** — starting several instructions in the same cycle in different units.
- **Fetch unit / dispatch unit** — fetch instructions into the queue / decode and send them to
  execution units.
- **Instruction queue** — buffer of prefetched instructions.
- **Reservation station** — buffer at an execution unit holding a dispatched instruction and
  its operands until all are ready.
- **Speculative execution** — executing past an unconfirmed branch prediction, labeled so it
  can be discarded.
- **Out-of-order execution** — completing instructions in an order different from program
  order.
- **Imprecise vs precise exceptions** — inconsistent state after an exception vs. results
  written strictly in program order.
- **Temporary register / commitment step** — holds a result until it is committed to a
  permanent register in program order.
- **Register renaming** — a temporary register assuming the role of a permanent register,
  forwarding its value to later references.
- **Commitment unit / reorder buffer** — ensure in-order retirement; instructions complete out
  of order but retire in program order.
- **Retired** — committed and removed from the reorder buffer; its resources freed.
- **Deadlock** — a cyclic wait where two units each hold a resource the other needs.

**CISC pipelining**
- **Side effect** — a location other than the destination operand is also changed (e.g.
  Autoincrement on R8, or condition-code flags).
- **Micro-operation** — a simple RISC-style step a CISC instruction is converted into.
- **Macro-operation (fusion)** — re-combining related micro-operations (e.g.
  compare-and-branch).
- **ColdFire / Intel Core 2 / Core i7** — example CISC-style processors with pipelining
  (14-stage, 4-wide multiple-issue for Intel).

---

## 16. Self-Test Questions

Try these without looking back. Answers in the sections cited.

1. Name the five pipeline stages in order and say what each does. *(§2)*
2. What are interstage buffers, and what does buffer B2 carry? *(§3)*
3. Define "hazard" and name the three families of hazards. *(§4)*
4. In the Add/Subtract example, how does the hardware detect the data dependency, and how many
   cycles is the Subtract stalled? *(§5)*
5. What is a bubble, and what creates it? *(§5)*
6. What is operand forwarding, which registers can it forward from, and what datapath change
   does it require? *(§6)*
7. Why does the software-NOP approach increase code size without reducing execution time?
   *(§7)*
8. Why does a Load-use dependency still cost one cycle even with forwarding and a cache hit?
   *(§8)*
9. What is the branch penalty when the target is computed in the Compute stage vs the Decode
   stage, and why? *(§9)*
10. What is the branch delay slot and how does delayed branching exploit it? *(§9)*
11. Compare the two-state and four-state dynamic prediction algorithms for a loop. How many
    mispredictions does each incur? *(§9)*
12. What three things does a branch target buffer entry hold, and why does prediction have to
    happen in cycle 1? *(§9)*
13. Give the single-cache structural hazard example and its fix. *(§10)*
14. Write the basic performance equation and compute S for the worked example with all three
    δ terms. Which term dominates? *(§11)*
15. What is multiple-issue, and what register-file changes does the two-unit superscalar
    processor require? *(§12)*
16. Explain how out-of-order execution and precise exceptions are reconciled using temporary
    registers, register renaming, and a reorder buffer. *(§12)*
17. Give two reasons CISC instruction sets complicate pipelining, and explain how Intel
    processors cope. *(§13)*

---

*End of study guide. Open this file in any Markdown viewer (VS Code, Obsidian, Typora,
GitHub) to read it with formatting, or export to PDF from there.*
