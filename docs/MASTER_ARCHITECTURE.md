# SEMFONIX PWM16 — Master Architecture

Status: LIVING DOCUMENT — this file is the permanent architectural source of
truth for the project. RTL must follow this document. If RTL and this
document ever disagree, this document wins unless a dated "Architectural
Decision Record" at the bottom says otherwise.

Scope of this project: **RTL + RTL verification + Yosys-clean synthesis
only.** No OpenLane/OpenROAD/PDK/floorplan/place/route/DRC/LVS/GDS work is
in scope, ever, for this repository.

---

## 1. Product Definition

SEMFONIX PWM16 is a synchronous-digital, ASIC-class, I²C-bus controlled
16-channel LED/PWM controller, functionally modeled on the NXP PCA9685
(see `docs/product/PCA9685_reference_notes.md` for the extracted reference
behavior) with additional SEMFONIX-specific low-cost enhancements:

- 16 independent PWM channels, 12-bit resolution (4096 steps), one shared
  free-running 12-bit timebase counter.
- Independent programmable ON (turn-on) time and OFF (turn-off) time per
  channel → programmable phase/delay + programmable duty cycle, exactly as
  in the PCA9685 LEDn_ON/LEDn_OFF model.
- Full-ON and full-OFF force bits per channel (bit 4 of the *_H byte pair),
  matching PCA9685 semantics, with OFF taking precedence over ON when both
  are set.
- Programmable prescaler for output PWM frequency (24 Hz .. ~1526 Hz range
  at a 25 MHz reference, i.e. prescale value 3..255), writable only while
  the internal oscillator is stopped (SLEEP=1), matching PCA9685.
- Shadow/active double-buffered register architecture: every channel's
  4-byte ON/OFF configuration is written into a shadow bank over I²C and
  only becomes the *active* PWM configuration at a well-defined atomic
  commit point, so channel outputs never glitch from a torn (partially
  updated) write. Commit policy is software-selectable per PCA9685
  MODE2.OCH: "commit on I²C STOP" (default) or "commit on ACK of the 4th
  byte of a channel's 4-register group" (OCH=1).
- Global "all channels" broadcast registers (ALL_LED_ON/ALL_LED_OFF) that
  write all 16 channels' shadow registers in one 4-register burst, same as
  PCA9685 registers 0xFA-0xFD.
- I²C-bus slave, up to Fast-mode Plus target (1 MHz), 7-bit hardware+soft
  address, LED All-Call address, 3 programmable Sub-Call addresses,
  auto-increment control-register pointer, general-call Software Reset.
- SEMFONIX extensions beyond PCA9685 (all "cheap" — no CPU/RAM/mul/div):
  - Per-channel **enable** bit (in addition to full-on/full-off), gating
    the output at the pad without touching the stored ON/OFF counts.
  - Per-channel **output polarity** bit (equivalent function to PCA9685's
    global INVRT but selectable per channel at zero extra counter cost —
    it only inverts a 1-bit mux at the output stage).
  - Per-channel **phase-offset enable**: since ON/OFF already encode an
    arbitrary phase, this is exposed architecturally as "channel phase =
    LEDn_ON value"; no extra hardware — documented here so verification
    treats it as a first-class feature.
  - **GROUP_UPDATE** register: a software-triggered atomic commit strobe,
    independent of the OCH/STOP mechanism, allowing the master to stage
    all 16 channels across multiple I²C transactions and then commit all
    of them in one register write (single flip of a `commit_pulse`).
  - **SYNC_UPDATE** input concept: the same shadow→active transfer used
    for I²C-driven commits can also be triggered by an external sync
    strobe at the top level (documented as an optional top-level input,
    `sync_update_i`, tied 0 if unused) so multiple SEMFONIX PWM16 devices
    can be phase-synchronized without extra I²C traffic. This reuses the
    identical commit pulse the GROUP_UPDATE register produces — no
    duplicated hardware.
  - **DEVICE_ID / REVISION_ID** read-only registers.
  - Defined, safe behavior for invalid/reserved register addresses (read
    as 0x00, writes ignored, still ACKed to keep the bus consistent with
    the PCA9685 "reserved, writes may cause unpredictable results"
    footnote replaced by a *safe*, deterministic no-op instead).
  - I²C bus-stuck recovery: an optional SCL low timeout counter that can
    force the state machine back to IDLE if SCL is held low longer than a
    timeout window (bus-hang protection). This is a small counter +
    comparator, not a general timeout/watchdog subsystem.

Explicitly **out of scope / not implemented** (per instructions): CPU, DMA,
large RAM, multiplier, divider, ADC, waveform memory, gamma LUT, analog
oscillator (a clean digital clock-source boundary is provided instead).

---

## 2. Functional Specification Summary

| Parameter | Value |
|---|---|
| PWM channels | 16 |
| PWM resolution | 12-bit (0..4095 counts) |
| PWM timebase | 1 shared free-running 12-bit counter, wraps 0..4095 |
| Output frequency range | ~24 Hz .. ~1526 Hz @ 25 MHz reference clock, via 8-bit prescaler (register value 3..255) |
| Prescale formula | `f_pwm = f_ref / (4096 * (PRESCALE + 1))` |
| I²C speed | Standard-mode / Fast-mode / Fast-mode Plus target, up to 1 MHz SCL |
| I²C addressing | 7-bit slave address (6 hw pins A0-A5, matching PCA9685 pin model), LED All-Call, 3x Sub-Call, General-Call SWRST |
| Register map | Compatible superset of PCA9685 register map (0x00-0x45 core + 0xFA-0xFE) plus SEMFONIX extension block at 0x50-0x5F |
| Reset | Single active-low async-assert / sync-deassert reset, `rst_n` |
| Clock | Single digital clock domain, `clk_ref` (reference oscillator, nominally 25 MHz equivalent) |

---

## 3. Complete Block Diagram

```
                 +-----------------------------------------------------+
                 |                  semfonix_pwm16_top                 |
                 |                                                     |
  scl_i/scl_o -->|   +-----------+     +----------------+              |
  sda_i/sda_o -->|-->| i2c_slave |---->| register_bank  |              |
  addr pins ---->|   | (i2c_rx/  |<----| (+ decode)     |              |
  oe_i --------->|   |  i2c_tx)  |     +----------------+              |
                 |   +-----------+           |    |                    |
                 |                            |    | shadow regs        |
                 |                            |    v                    |
                 |                     +-------------------+           |
                 |                     | shadow_active_ctrl|           |
                 |                     | (atomic commit FSM)|          |
                 |                     +-------------------+           |
                 |                            |                        |
                 |                            v active regs            |
                 |   +--------------+   +--------------------+         |
  clk_ref ------>|-->| prescaler /  |-->| pwm_engine         |-------> LED0..LED15
                 |   | pwm_counter  |   | (16 x pwm_channel) |
                 |   +--------------+   +--------------------+         |
                 |                                                     |
                 +-----------------------------------------------------+
```

Data flow (write path):
```
I2C SDA/SCL --> i2c_rx (bit/byte, protocol FSM)
             --> register_decode (control-register pointer, auto-increment)
             --> register_bank.shadow_regs[addr] <= wdata
             --> (on commit event) shadow_regs --> active_regs
             --> pwm_channel[n].on_active / off_active
             --> pwm_compare vs shared pwm_counter
             --> LEDn output stage (enable/polarity/OE mux)
```

Data flow (read path):
```
I2C SDA/SCL <-- i2c_tx <-- register_bank.active_or_shadow_regs[addr]
                          (reads always return the shadow/programmed value,
                           matching PCA9685 read-back semantics; PRE_SCALE,
                           MODE1/2, address registers are single-buffered)
```

Control flow: the I²C slave FSM only ever talks to `register_bank`. It has
no direct wires into `pwm_engine`. `pwm_engine` only ever reads
`active_regs`. The only cross-cutting control signal is the one-cycle
`commit_pulse` produced by `shadow_active_ctrl` (or `GROUP_UPDATE` /
`sync_update_i`), which is the single point where shadow data becomes
active data. This isolation is deliberate: it keeps the I²C timing domain
decoupled from the PWM output domain in terms of *logic dependency* (both
still run on `clk_ref`, single clock domain — see Section 6), and it keeps
`pwm_engine` free of any I²C-protocol awareness at all, which shrinks its
verification surface and lets it be swapped/optimized independently.

---

## 4. Module Hierarchy

```
rtl/top/semfonix_pwm16_top.sv
├── rtl/clock/clk_reset_sync.sv            (reset synchronizer, clock boundary doc)
├── rtl/i2c/i2c_slave.sv
│   ├── rtl/i2c/i2c_bus_sync.sv            (2-FF metastability sync for SDA/SCL)
│   ├── rtl/i2c/i2c_rx.sv                  (bit-level + byte-level protocol FSM, START/STOP/ACK detect)
│   └── rtl/i2c/i2c_tx.sv                  (shift-out for reads, open-drain SDA driver control)
├── rtl/registers/address_decode.sv         (slave/all-call/sub-addr/general-call compare)
├── rtl/registers/register_decode.sv        (control-register pointer, auto-increment, addr map decode)
├── rtl/registers/register_bank.sv          (shadow + single-buffered register storage)
├── rtl/control/shadow_active_ctrl.sv       (atomic commit FSM: STOP-commit / ACK-commit / GROUP_UPDATE / sync_update_i)
├── rtl/control/prescale_gate.sv            (SLEEP-gated PRE_SCALE write guard + oscillator enable)
├── rtl/pwm/pwm_counter.sv                  (shared free-running 12-bit timebase, prescale-clocked tick)
└── rtl/pwm/pwm_engine.sv                   (instantiates 16x pwm_channel, ALL_LED broadcast mux)
    └── rtl/pwm/pwm_channel.sv (x16)
        └── rtl/pwm/pwm_compare.sv          (shared comparator function, see Section 9 sharing analysis)
```

Unit-testable leaves (Level 1, built first): `pwm_compare`, `pwm_counter`,
`pwm_channel`.

---

## 5. Interface Definitions

### 5.1 Top-level port list (`semfonix_pwm16_top`)

```systemverilog
module semfonix_pwm16_top #(
  parameter int NUM_CHANNELS = 16,
  parameter int PWM_WIDTH    = 12
) (
  input  logic                       clk_ref,      // reference clock (nom. 25 MHz equiv.)
  input  logic                       rst_n,        // async assert, sync release, active low

  // I2C bus (open-drain style: *_o is drive-low request, tri-state modeled as _oe)
  input  logic                       scl_i,
  input  logic                       sda_i,
  output logic                       sda_o,
  output logic                       sda_oe,       // 1 = actively pulling SDA low
  output logic                       scl_o,        // reserved for clock stretching (unused v1, tie 1)
  output logic                       scl_oe,

  // hardware address pins (sampled combinationally / registered once at reset per PCA9685 model)
  input  logic [5:0]                 hw_addr_i,    // A5..A0

  // active-low output enable pin (PCA9685 OE)
  input  logic                       oe_n_i,

  // external clock input alternative to using clk_ref as the PWM reference
  // (architectural placeholder mirroring EXTCLK; tie 0 / unused bit selects internal)
  input  logic                       extclk_sel_i,

  // optional external synchronized-commit strobe (SEMFONIX extension)
  input  logic                       sync_update_i,

  // LED PWM outputs. Modeled the same way as the SDA pin (level + drive
  // enable) so open-drain and high-impedance output states (real states
  // on the reference part, Table 11 / Section 7.7) are represented
  // correctly at the digital/pad boundary instead of being silently
  // collapsed to a driven '0'. A pad cell interprets led_oe_o[n]=0 as
  // "release/high-Z that pad" and =1 as "drive led_o[n]." A user who only
  // needs digital-only simulation behavior may treat led_o directly as
  // the effective level whenever led_oe_o=1, and treat a released pad as
  // "externally pulled" (matching real open-drain LED wiring, Fig. 15).
  output logic [NUM_CHANNELS-1:0]    led_o,
  output logic [NUM_CHANNELS-1:0]    led_oe_o
);
```

### 5.2 Internal register-bus interface (I²C block <-> register_bank)

A minimal internal "regbus" struct-of-signals (not a standard AMBA bus —
kept deliberately simple since there is exactly one master, the I²C FSM):

```systemverilog
// request (from i2c_slave/register_decode to register_bank)
logic        rb_wr_en;      // write strobe, 1 cycle
logic        rb_rd_en;      // read strobe, 1 cycle (for read-side latch)
logic [7:0]  rb_addr;       // control-register pointer value (post auto-increment)
logic [7:0]  rb_wdata;
logic [7:0]  rb_rdata;      // combinational read data, valid same cycle as rb_rd_en

// commit control (from shadow_active_ctrl to register_bank)
logic        commit_pulse;  // 1 cycle: copy all shadow_regs -> active_regs atomically
logic        stop_event;    // from i2c_rx: I2C STOP condition detected this cycle
logic        ack4_event;    // from register_decode: 4th byte of a channel group ACKed
```

### 5.3 register_bank <-> pwm_engine interface

`register_bank` exposes the **active** register file as a flattened,
statically-indexed array (not a bus — this is internal point-to-point
wiring, appropriate for ASIC since PWM engine needs parallel read access to
all 16 channels every cycle):

```systemverilog
typedef struct packed {
  logic        full_on;
  logic        full_off;
  logic [11:0] on_count;
  logic [11:0] off_count;
  logic        enable;      // SEMFONIX extension
  logic        polarity;    // SEMFONIX extension
} pwm_chan_cfg_t;

pwm_chan_cfg_t active_cfg [NUM_CHANNELS];
logic [7:0]    active_prescale;
logic          active_sleep;
logic [1:0]    active_outne;
logic          active_outdrv;
logic          active_invrt;
```

---

## 6. Clock/Reset Strategy

- **Single synchronous clock domain.** `clk_ref` drives everything:
  I²C bit-sampling/oversampling, the register bank, the commit FSM, the
  PWM prescaler and PWM counter/comparators. This eliminates CDC
  verification burden and is appropriate because `clk_ref` (a 25 MHz-class
  reference) is far faster than both the I²C bus (≤1 MHz) and the PWM
  refresh rate (≤~1.5 kHz), giving ample oversampling margin (>=25x at
  Fm+ 1 MHz SCL, matching PCA9685's own 25 MHz internal oscillator vs 1 MHz
  Fm+ bus ratio).
- **Async SCL/SDA inputs are double-flopped** (`i2c_bus_sync.sv`) before
  any use, since they originate off-chip and are asynchronous to
  `clk_ref`. This is the only "CDC-like" structure in the design and it is
  a standard 2-FF synchronizer, not a real clock-domain crossing (single
  clock still).
- **Reset (`rst_n`)**: active-low, asynchronously asserted, synchronously
  released (standard reset-synchronizer cell `clk_reset_sync.sv`
  instantiated once at the top and fanned out as `rst_n_sync`). All
  sequential logic in the design uses this synchronized reset.
- **Reset values** (see Section 17) match PCA9685 power-on defaults where
  a PCA9685-equivalent register exists, and are chosen to be "all outputs
  off / all outputs safe" for SEMFONIX extension bits.
- **PWM reset**: `pwm_counter` resets to 0. All channel active registers
  reset to `full_off = 1` (LEDn full OFF default, matching PCA9685 default
  register 09h/0Dh/... = 0x10, i.e. bit4=1).
- **I²C reset**: `i2c_rx`/`i2c_tx` FSMs reset to IDLE, address registers
  reset to PCA9685 defaults (ALLCALLADR=0xE0, SUBADR1/2/3=0xE2/E4/E8,
  All-Call enabled, Sub-Calls disabled), matching MODE1 reset value 0x11
  (AI=0, SLEEP=1, ALLCALL=1... — see Section 17 exact bit table).
- **No analog oscillator in RTL.** `clk_ref` is treated as an already-
  generated digital reference. A clean boundary
  (`rtl/clock/clk_reset_sync.sv`) is the only clock-related RTL; a future
  technology-specific ring-oscillator/PLL macro can drive `clk_ref`
  without touching any other file. `extclk_sel_i` is carried through as an
  architectural placeholder (mux select) but both "clock sources" resolve
  to the same `clk_ref` pin at RTL level, since generating/selecting an
  actual second clock is analog/PLL work outside this project's scope. The
  MODE1.EXTCLK bit is implemented as a **status-only sticky bit** in the
  register bank (readable, settable via the documented set sequence) with
  no RTL effect on `clk_ref` itself — this preserves register-map/software
  compatibility without requiring real clock-muxing hardware that would
  reintroduce a second clock domain.

---

## 7. I²C Transaction Architecture

`i2c_slave` = `i2c_bus_sync` + `i2c_rx` (protocol FSM, receive path) +
`i2c_tx` (transmit/shift path) + `address_decode`.

### 7.1 Protocol FSM states (in `i2c_rx`)

```
IDLE -> (START detected) -> ADDR_BYTE -> ADDR_ACK ->
   [write path]  -> CTRL_BYTE -> CTRL_ACK -> DATA_BYTE -> DATA_ACK -> (loop DATA_BYTE on more bytes, or STOP/RESTART)
   [read path]   -> DATA_BYTE_TX -> DATA_ACK_RX -> (loop, master NACKs last byte) -> STOP/RESTART
   [general call] -> GC_BYTE -> GC_ACK -> SWRST_BYTE -> SWRST_ACK -> STOP -> pulse internal soft-reset
```

- START/repeated-START/STOP are detected as edge conditions on the
  synchronized SDA/SCL (SDA falling while SCL high = START; SDA rising
  while SCL high = STOP), exactly per Section 8.1.1 of the reference
  datasheet.
- The **first data byte after the control-register byte is the register
  pointer** (matches PCA9685 "Control register" concept, Fig. 6 of the
  reference). Auto-increment (AI, MODE1 bit 5) is honored: `register_decode`
  increments the internal pointer after each byte, using the documented
  wrap points (69 -> 0, 250..254 -> 0 boundary from the reference register
  summary table). This wrap logic is deliberately table-driven/parameterized
  (not hand-duplicated per register) to avoid combinational bloat.
- **ACK generation**: `i2c_rx` drives `sda_oe` low for one bit time after
  each received byte if `address_decode`/`register_decode` reports the
  transaction is valid (address matched, or general-call SWRST byte
  correct). NACK = simply not pulling SDA low (release it), matching open-
  drain bus semantics.
- **Auto-increment wrap and reserved-address read-as-zero** are handled in
  `register_decode`, not duplicated in `i2c_rx`, keeping the protocol FSM
  free of register-map knowledge (clean separation of concerns, smaller
  FSM, easier to verify independently of the register map).

### 7.2 Timing / oversampling

`clk_ref` is assumed >= 20x the SCL frequency (guaranteed at 25 MHz vs 1
MHz Fm+). SCL edges are detected by comparing synchronized-SCL against its
previous-cycle value; SDA is sampled only while synchronized-SCL is stable
high for setup/hold safety margin (a small counter debounces spikes
shorter than a configurable `SPIKE_FILTER_CYCLES`, mirroring the datasheet
spike-suppression spec of ~50 ns).

---

## 8. Register Architecture

Register storage lives entirely in `register_bank.sv`. Two storage
classes:

1. **Single-buffered registers** (take effect immediately on write; no
   shadow/active split needed because they are not part of the
   glitch-sensitive PWM output path): `MODE1`, `MODE2`, `SUBADR1..3`,
   `ALLCALLADR`, `PRE_SCALE` (write-gated by SLEEP, see Section 12),
   `DEVICE_ID` (read-only), `REVISION_ID` (read-only), SEMFONIX control
   registers `CHAN_ENABLE`, `CHAN_POLARITY`, `GROUP_UPDATE` (self-clearing
   strobe).
2. **Double-buffered (shadow/active) registers**: the 16 x 4 = 64
   `LEDn_ON_L/H`, `LEDn_OFF_L/H` registers, plus the 4 `ALL_LED_*`
   broadcast write-only registers which fan out into the same 64 shadow
   registers combinationally at write time (no separate storage for
   ALL_LED_* — see Section 9).

`register_decode.sv` performs address-to-storage-index mapping using a
single parameterized function (`addr_to_chan_field()`), not a giant
hand-written case statement duplicated 16 times — see Section 9 sharing
analysis.

Every register in the map is documented in
`docs/architecture/REGISTER_MAP.md` with: address, name, reset value,
access (RO/RW/W-only), bit fields, reserved-bit behavior, side effects.

---

## 9. PWM Architecture (Sharing / PPA Analysis)

**Shared, single-instance hardware:**
- `pwm_counter`: exactly one 12-bit free-running counter shared by all 16
  channels (matches the reference architecture's single "12-bit counter
  running continuously from 0000h to 0FFFh," Section 7.3.3). Duplicating
  this per channel would be pure waste — 16x flip-flops and 16x incrementer
  logic for zero functional benefit, since all channels compare against
  the identical count value.
- `prescale_gate` / prescaler tick generator: exactly one, feeding
  `pwm_counter`'s enable.
- `pwm_compare`: implemented as a small **combinational function**
  (`pwm_compare.sv`), instantiated once *per channel* (16 instances) —
  see below for why this one is replicated rather than time-multiplexed.

**Per-channel, replicated hardware (16x):**
- `pwm_channel.sv`: holds that channel's *active* on/off/full-on/full-off/
  enable/polarity bits (these are just wires from `register_bank`'s active
  array, not extra flops — the flops live in `register_bank`) and
  instantiates one `pwm_compare` plus the small output-stage mux
  (full-on/full-off override -> enable gate -> polarity xor -> OE mux).

**Why comparators are replicated, not shared/muxed:** All 16 channels must
independently drive their own LED pad *every clock cycle, simultaneously*
(different LEDs are on at different phases within the same 4096-count
frame — that is the entire point of the phase-offset feature). A
time-multiplexed shared comparator would require either (a) 16x the
compare bandwidth per timebase tick — impossible, since all 16 outputs
must be valid on the *same* tick — or (b) storing 16 output-latch bits
plus a scan sequencer, which is *more* area and more switching activity
than 16 small comparators, for no timing benefit. Each `pwm_compare` is a
single 12-bit magnitude comparator (`count == on`, `count == off`) — cheap,
low-fanout (only `pwm_counter`'s value fans out to all 16, which is
expected and unavoidable), and this fanout is the natural place to insert
a clock-tree-like buffer stage at synthesis if needed (documented in
Section 21, not built here since buffering is a P&R concern).

**ALL_LED_* broadcast — no duplicated storage:** `ALL_LED_ON_L/H` and
`ALL_LED_OFF_L/H` are **not** separate registers with their own storage;
writing them drives a `broadcast_wr` strobe + the write data into
`register_bank`'s shadow-write port for *all 16 channels simultaneously*
in one cycle (a single 16-way write-enable fan-out from one decoded
address, not 16 duplicated write-data busses — the data bus is already
shared, only the per-channel write-enable is replicated, which is
unavoidable and cheap, 16 AND gates).

**No multipliers, no dividers, no large combinational structures:** the
prescale-to-frequency relationship (`f = f_ref / (4096*(N+1))`) is
realized purely as a *counter compare* (count up to `active_prescale`,
then tick `pwm_counter`), never as an actual divide operation.

**Expected high-fanout signals:** `pwm_counter` value (12 bits x 16
channel comparators = 192 loads), `commit_pulse` (fans into 64+ shadow-
active copy registers), `rst_n_sync` (global, expected/acceptable). These
are flagged in Section 21 as synthesis-attention points (buffering/
duplication left to the synthesis tool / P&R, not hand-solved in RTL).

**Expected critical path:** I²C is asynchronous to nothing performance-
critical (it's 1000x slower than `clk_ref`), so the only meaningful timing
path is `pwm_counter` -> `pwm_compare` (12-bit equality compare) ->
output-stage mux -> `led_o` pad, a short, single-cycle combinational path.
The commit path (`shadow_regs` -> `active_regs` on `commit_pulse`) is a
simple mux-select-then-flop, also single cycle, not on the counter's
critical path since it only changes the *compare operands*, not the
counter itself.

---

## 10. Channel Architecture

Each `pwm_channel` instance (`rtl/pwm/pwm_channel.sv`) is purely
combinational + the compare logic; it owns no flops of its own (all state
is in `register_bank`'s active array — this keeps `pwm_channel` a thin,
easily-swappable/optimizable leaf, and avoids duplicating the same
flip-flops in two places).

Per-channel output decision (matches reference Section 7.3.3 semantics,
with SEMFONIX enable/polarity layered on top):

```
raw_on   = full_off ? 1'b0
         : full_on  ? 1'b1
         : (on_count <= off_count) ? (count >= on_count && count < off_count)
                                    : (count >= on_count || count < off_count);
gated    = raw_on & enable;
polarized= gated ^ polarity;
led_out  = oe_n_i ? outne_forced_value : polarized;
```

(`full_off` takes precedence over `full_on` per the reference datasheet's
explicit precedence rule in Section 7.3.3.)

---

## 11. Addressing Architecture

`address_decode.sv` compares the received 7-bit address byte against, in
priority order documented in `docs/architecture/ADDRESSING.md`:

1. General-Call / SWRST address `0000000` (R/W=0 only)
2. LED All-Call address (`ALLCALLADR[7:1]`, only if `MODE1.ALLCALL=1`)
3. Sub-Call addresses 1/2/3 (`SUBADR{1,2,3}[7:1]`, only if enabled)
4. Regular hardware+programmable slave address (`{1'b1, hw_addr_i}` fixed
   MSB per reference Fig. 4 pattern, i.e. `1 A5 A4 A3 A2 A1 A0`)

All four comparisons are 7-bit equality compares against the *same*
incoming address-byte register — one comparator per address type (5 total:
general-call, all-call, sub1, sub2, sub3, regular), not a chain of
duplicated shift-and-compare logic. This is already minimal; no further
sharing opportunity exists without adding mux latency to a bus-timing-
sensitive path.

---

## 12. Prescaler Architecture

`prescale_gate.sv`:
- Holds no counter of its own; it owns the **write-guard** logic only:
  `PRE_SCALE` register writes in `register_bank` are qualified by
  `active_sleep` (`MODE1.SLEEP==1`), per reference Section 7.3.5 ("can only
  be set when SLEEP bit is set to logic 1"). Attempted writes while awake
  are silently dropped (ACKed on the bus, but the stored value doesn't
  change) — a defined, safe behavior rather than "unpredictable results."
- The actual **tick generator** lives in `pwm_counter.sv` (kept together
  with the counter it feeds, avoiding an extra cross-module bus for a
  single enable pulse): an internal 8-bit up-counter compares against
  `active_prescale`; on match, it resets and pulses `pwm_counter`'s enable
  for one `clk_ref` cycle.
- SLEEP gating of the oscillator itself (`MODE1.SLEEP=1` => no PWM ticking,
  per reference Section 7.3.1, footnote 3/4) is implemented as the same
  enable pulse being forced to 0 while `active_sleep=1`, so `pwm_counter`
  (and hence all outputs) freeze but retain their last state — matching
  "no PWM control possible when oscillator is off."

---

## 13. Atomic Update ("Shadow/Active") Architecture

`shadow_active_ctrl.sv` generates the single `commit_pulse` used
everywhere active registers are updated. Sources (any one pulses
`commit_pulse` for exactly one `clk_ref` cycle):

1. **STOP-commit (OCH=0, default):** on `stop_event` from `i2c_rx`, if at
   least one shadow register was written since the last commit (tracked by
   a `dirty` flag set on any shadow write and cleared on commit) — matches
   reference: "Outputs change on STOP command."
2. **ACK-commit (OCH=1):** `register_decode` asserts `ack4_event` exactly
   when the 4th register of *any single* channel's ON/OFF group has just
   been ACKed (i.e., that channel's 4 shadow bytes are known-consistent).
   In this mode `commit_pulse` commits **all 16 channels' shadow state**
   (simplest correct behavior — committing only the touched channel would
   require 16 independent dirty/commit paths for a marginal case the
   reference itself treats as an all-channels concern in describing
   "Update on ACK requires all 4 PWM channel registers to be loaded before
   outputs will change on the last ACK"). This matches the datasheet
   footnote precisely for the touched channel, and is a safe superset for
   untouched channels (committing already-equal shadow==active data is a
   no-op).
3. **GROUP_UPDATE strobe (SEMFONIX extension):** a write of `1` to the
   `GROUP_UPDATE` register's commit bit produces one `commit_pulse` on the
   next cycle; the bit self-clears (reads back 0), so it behaves as an
   edge-triggered command, not a level.
4. **`sync_update_i` (SEMFONIX extension):** a synchronized (2-FF, since it
   is an external async pin), rising-edge-detected external pulse produces
   `commit_pulse` identically to GROUP_UPDATE. This lets multiple devices
   commit in the same `clk_ref` cycle if driven from a common external
   strobe.

**Glitch-freedom guarantee:** `active_regs` are only ever written by the
single `commit_pulse` mux (`active_regs <= commit_pulse ? shadow_regs :
active_regs`), never by the I²C write path directly. Therefore a master
that is interrupted mid-write (bus error, reset, aborted transaction)
leaves `active_regs` — and therefore `led_o` — completely unaffected until
a valid commit event occurs. This is the core invariant verified in
Section 14's assertions and in the integration testbench's "atomic
update" test group.

---

## 14. Phase-Control Architecture

Phase is realized entirely through the existing `on_count` value — no
separate "phase register" or extra hardware. `on_count` is the delay (in
1/4096ths of the frame) before the channel turns on; `off_count` is where
it turns back off. This matches reference Section 7.3.3 exactly, including
the wraparound case (`on_count > off_count` => channel is ON that spans
the 4095->0 wrap, ON during `[on_count, 4095] U [0, off_count)`), encoded
in the single comparator expression in Section 10.

---

## 15. Output-Control Architecture

Per-channel output stage (in `pwm_channel.sv`) implements, in order:
`full_off` override -> `full_on` override -> raw PWM compare -> SEMFONIX
`enable` gate -> SEMFONIX `polarity` XOR -> global `oe_n_i` /
`MODE2.OUTNE[1:0]` forced-value mux (reference Table 11 semantics: when
`oe_n_i` is high, output is forced per `OUTNE`/`OUTDRV`, independent of the
per-channel PWM state). `MODE2.INVRT` (global invert, applies when
`oe_n_i` is low) is applied as an additional XOR ahead of the per-channel
`polarity` XOR, so the two invert sources compose correctly and each can
be reasoned about independently in verification.

---

## 16. Error Handling

- **Reserved/invalid register address:** reads return `8'h00`; writes are
  accepted (ACKed, for bus-protocol correctness — refusing to ACK an
  in-range control-register value would violate the datasheet's own
  addressing model) but discarded (no storage exists, so hardware
  naturally drops them; no special-case mux needed for "unpredictable
  results" avoidance — the *absence* of storage for that address is itself
  the safe behavior).
- **Address auto-increment past the valid table:** wraps per the
  documented table (69->0 for core registers; roll-over 250-254 range as
  per reference remark) using a small parameterized wrap function, not
  per-address hard-coded logic.
- **Malformed SWRST general-call sequence** (wrong data byte, or more than
  one data byte): no ACK is given beyond the point of mismatch, and no
  reset occurs — "abort" behavior, matching reference Section 7.6 exactly.
- **SCL-held-low bus hang:** an optional timeout counter
  (`I2C_TIMEOUT_CYCLES`, default disabled/very large) forces `i2c_rx` back
  to `IDLE` if SCL has been continuously low longer than the timeout —
  documented as a SEMFONIX robustness extension, disableable via
  parameter for strict PCA9685-only compatibility testing.
- **Reset during an in-progress I²C transaction:** immediately forces
  `i2c_rx`/`i2c_tx` to IDLE and releases the bus (`sda_oe=0`); does not
  affect `active_regs` differently than a normal power-on reset (both go
  to the documented reset values).

---

## 17. Reset Values

| Register | Reset value | Notes |
|---|---|---|
| MODE1 | 8'h11 | RESTART=0, EXTCLK=0, AI=0, SLEEP=1, SUB1=0, SUB2=0, SUB3=0, ALLCALL=1 |
| MODE2 | 8'h04 | reserved=000, INVRT=0, OCH=0, OUTDRV=1, OUTNE=00 |
| SUBADR1 | 8'hE2 | |
| SUBADR2 | 8'hE4 | |
| SUBADR3 | 8'hE8 | |
| ALLCALLADR | 8'hE0 | |
| LEDn_ON_L/H (all n) | 8'h00 | on_count = 0 |
| LEDn_OFF_L/H (all n) | 8'h00 / 8'h10 | off_count = 0, but full_off(bit4 of H)=1 => channel fully OFF at reset |
| PRE_SCALE | 8'h1E | 200 Hz default @ 25 MHz reference, per reference Eq. 2 |
| CHAN_ENABLE[15:0] | 16'hFFFF | all channels enabled (full_off still forces output low) |
| CHAN_POLARITY[15:0] | 16'h0000 | non-inverted |
| GROUP_UPDATE | 8'h00 | self-clearing strobe bit |
| DEVICE_ID | fixed constant (e.g. 8'h53 'S') | read-only |
| REVISION_ID | 8'h01 | read-only, bump on RTL revision |

Full bit-level table lives in `docs/architecture/REGISTER_MAP.md`
(generated alongside `register_bank.sv`).

---

## 18. State Machines

1. **`i2c_rx` protocol FSM** — see Section 7.1 diagram. States:
   `IDLE, ADDR_BYTE, ADDR_ACK, CTRL_BYTE, CTRL_ACK, WR_DATA, WR_ACK,
   RD_DATA, RD_ACK_WAIT, GC_BYTE, GC_ACK, SWRST_BYTE, SWRST_ACK`.
   Illegal-transition protection: any unrecognized bit pattern / unexpected
   repeated-START defaults back to `ADDR_BYTE` (a repeated START always
   re-arms address matching, per I²C spec), and any STOP from *any* state
   returns to `IDLE`.
2. **`shadow_active_ctrl` commit FSM** — effectively a 1-bit "dirty" latch
   + combinational OR of commit sources; not a complex FSM, documented
   here for completeness since it is a control-flow element.
3. **Prescale tick generator** — free-running compare-and-reset counter,
   not a "state machine" in the FSM sense but documented as a controlled
   sequential element.

---

## 19. Important Timing Relationships

- `f_pwm = f_clk_ref / (4096 * (PRESCALE + 1))`, PRESCALE in [3, 255],
  giving `f_clk_ref/1048576` (min) to `f_clk_ref/16384` (max) — at a 25 MHz
  reference this reproduces the datasheet's 24 Hz .. 1526 Hz range exactly.
- I²C SCL must be significantly slower than `clk_ref` for correct
  oversampled bit detection; the design targets `clk_ref >= 20 * f_SCL_max`
  (25 MHz vs 1 MHz Fm+ => 25x margin, matching the reference part's own
  ratio).
- `commit_pulse` is guaranteed not to coincide with an in-progress shadow
  write to the *same* address within the same cycle in a way that loses
  data: shadow writes and the commit copy both happen on the same clock
  edge, and commit reads `shadow_regs` values that already reflect any
  same-cycle write (standard synchronous read-during-write-same-address
  handled by using blocking-free NBA ordering — shadow write NBA and
  commit-copy NBA both source from the same pre-edge shadow value, so a
  commit occurring on the exact same STOP cycle as the final data-byte ACK
  is intentionally defined as "the STOP always occurs at least one bit-time
  after the last ACK," so there is no same-cycle race in practice; verified
  explicitly in the integration testbench).

---

## 20. PPA Considerations

- **Power:** PWM outputs switch at most twice per 4096-count frame per
  channel (~3 kHz max toggle activity even at max PWM frequency) — 16
  channels is inherently low switching activity. The I²C block only
  toggles internal logic while a transaction is active (idle-bus = idle
  logic, no free-running comparators other than `pwm_counter` and the
  prescale tick counter, which are also small and low-fanout apart from
  the documented `pwm_counter` fanout).
- **Performance:** all paths are single-cycle at `clk_ref`; the input
  timing constraint of interest is the SCL/SDA input synchronizer setup
  time, not any internal path (`clk_ref` is expected to run far faster
  than logic depth requires — the design is not to be pushed for max
  `clk_ref` frequency, it is I²C-bus-rate-bound in practice).
- **Area:** dominated by the 16 x (2x12-bit + 2x1-bit) shadow + 16 x
  (2x12-bit + 2x1-bit) active storage = ~64 bytes x 2 register bits of
  flops, plus 16 small comparators. This is intentionally the largest
  block in the design (as it should be — it's the product's core
  function) and is not further reducible without giving up independent
  per-channel phase, which is a stated product requirement.

---

## 21. Expected Synthesis-Sensitive Structures

- `pwm_counter[11:0]` fanning out to 16 x `pwm_compare` instances (32 x
  12-bit compare operand loads total) — expect Yosys/synthesis to insert
  buffering; RTL does not hand-buffer this (P&R concern, out of scope).
- `commit_pulse` fanning out to ~64 x 12-bit + ~64 x 1-bit active-register
  enables — similar high-fanout control signal, same treatment.
- `rst_n_sync` — global reset fanout, standard and expected.
- Auto-increment wrap function — written as a single shared combinational
  function to avoid 70+ duplicated comparators; synthesis should collapse
  it efficiently since it's parameter-driven, not truly data-dependent
  per-address.

---

## 21a. 2026 Competitive Feature / PPA Review

Performed at the CHECKPOINT 2 boundary (register/control modules
complete, before `prescale_gate.sv`). Full writeup, per-candidate
scoring against customer usefulness / application expansion / RTL
area / timing-fanout / power / verification burden / manufacturability,
is in `docs/product/COMPETITIVE_REVIEW_2026.md`. Summary: no RTL,
register-map, or architecture changes resulted. TLC59116-style group
dimming/blinking was seriously evaluated and rejected — it would
require a second free-running shared timebase generator (counter +
comparator) plus new, undocumented-by-any-reference interaction
semantics threaded through every channel's existing 7-stage output
composition chain (`pwm_channel.sv`), for a feature that only serves
the LED-indicator subset of this part's general-purpose PWM/LED
customer base. See ADR-0002.

---

## 22. Implementation Order (This Repository)

1. `rtl/pwm/pwm_compare.sv` + unit tb — pure combinational comparator.
2. `rtl/pwm/pwm_counter.sv` + unit tb — shared timebase + prescale tick.
3. `rtl/pwm/pwm_channel.sv` + unit tb — single channel incl. full-on/off,
   enable, polarity.
4. `rtl/registers/register_bank.sv` + unit tb — shadow/active storage,
   reset values.
5. `rtl/registers/register_decode.sv` + unit tb — address map, auto-
   increment, reserved-address behavior.
6. `rtl/registers/address_decode.sv` + unit tb — slave/all-call/sub-addr/
   general-call matching.
7. `rtl/control/shadow_active_ctrl.sv` + unit tb — commit sources, dirty
   tracking.
8. `rtl/control/prescale_gate.sv` + unit tb — SLEEP write-guard.
9. `rtl/pwm/pwm_engine.sv` + unit tb — 16-channel integration, ALL_LED
   broadcast.
10. `rtl/i2c/i2c_bus_sync.sv`, `rtl/i2c/i2c_rx.sv`, `rtl/i2c/i2c_tx.sv`,
    `rtl/i2c/i2c_slave.sv` + unit tbs — protocol implementation.
11. `rtl/clock/clk_reset_sync.sv` + unit tb.
12. `rtl/top/semfonix_pwm16_top.sv` — integration.
13. `tb/integration/semfonix_pwm16_tb.sv` + `tb/models/*` reference model.
14. `tb/assertions/*` — SVA invariants bound into unit/integration tbs.
15. `scripts/synth_yosys.sh` + `yosys/*` — synthesis checkpoint.

---

## 23. Verification Strategy

- **Unit level:** every Level-1/2/3 module gets a self-checking directed
  testbench in `tb/unit/<area>/<module>_tb.sv`, driven by a simple
  clock/reset harness, with `$fatal`/pass-fail summary printed and a
  non-zero exit path on failure suitable for scripting.
- **Reference model:** `tb/models/pwm_ref_model.sv` (or a SystemVerilog
  class/`*.svh`) independently computes expected `led_o` from a mirrored
  copy of ON/OFF/full-on/full-off/enable/polarity/count state, *without*
  reusing the RTL's comparator code, so it is a true independent check.
  `tb/models/i2c_bfm.sv` is a bus-functional model (I²C master driver) used
  by both unit-level I²C tests and the integration testbench.
- **Integration testbench:** `tb/integration/semfonix_pwm16_tb.sv` drives
  the top level purely through `clk_ref`/`rst_n`/I²C pins/`oe_n_i`
  /`sync_update_i` (black-box from the DUT's perspective) and checks
  `led_o` against the reference model, per the full test list in Section
  12 of the task brief (reset, I²C protocol, PWM all-channel/all-duty-
  cycle, atomic update, addressing, stress).
- **Assertions:** SVA properties in `tb/assertions/*.sv`, bound (via
  `bind`) into the relevant RTL modules for simulation-only checking —
  kept out of the synthesizable RTL files themselves.
- **Status tracking:** every checkpoint's pass/fail results are recorded
  in `docs/IMPLEMENTATION_STATUS.md` as work proceeds (see that file).

---

## 24. Future Extension Boundaries

Explicitly reserved for possible future work (not built now, but the
architecture leaves room without redesign):

- Register-map extension block `0x50-0x5F` reserved for SEMFONIX-specific
  registers (`CHAN_ENABLE`, `CHAN_POLARITY`, `GROUP_UPDATE`, `DEVICE_ID`,
  `REVISION_ID` currently occupy the low end of this block; remaining
  addresses reserved/read-as-zero).
- `extclk_sel_i` / EXTCLK status bit reserved for a future real clock-mux
  if a second physical clock pin is ever brought into the digital domain
  (would require re-introducing CDC synchronizers at that boundary —
  explicitly *not* attempted in this RTL-only phase).
- `sync_update_i` groundwork already supports multi-device phase sync
  without further RTL changes.
- Physical design (floorplan/place/route/DRC/LVS/GDS, PDK-specific
  standard-cell mapping beyond generic Yosys synthesis) is explicitly out
  of scope for this repository and is not planned here.

---

## Architectural Decision Records

### ADR-0001 (initial)
Date: repository creation.
Decision: single shared `pwm_counter`, replicated `pwm_compare` per
channel, register storage owns all state (no state duplicated in
`pwm_channel`). Rationale: see Section 9. Status: ACCEPTED, baseline for
all subsequent RTL.

### ADR-0002 (2026 competitive review, CHECKPOINT 2 boundary)
Date: this session, after `shadow_active_ctrl.sv` / before
`prescale_gate.sv`.
Decision: **no architecture, register-map, or RTL changes.** Full
review in `docs/product/COMPETITIVE_REVIEW_2026.md`. Three candidates
seriously evaluated:
- TLC59116-style group dimming/blinking (GRPPWM/GRPFREQ/DMBLNK) —
  REJECTED (Rule 3: would add a second shared free-running timebase
  generator plus new interaction semantics with the SEMFONIX-only
  enable/polarity bits, threaded through all 16 channels' output
  composition chain, for a feature that only serves the LED-indicator
  subset of the target market).
- Register-triggered software reset (SWRST alternative) — DEFERRED,
  not rejected on merits; its consumer (`i2c_rx` soft-reset handling)
  doesn't exist yet (Checkpoint 4). Revisit then; extension block
  (`0x57-0x5F`) has room reserved if adopted.
- Active/committed-value readback for `LEDn_*` (debug feature,
  distinct from shadow readback) — REJECTED (no demonstrated customer
  pull; would be adding a feature because it's cheap, not because it's
  needed — the exact anti-pattern the product rule prohibits).

ADR-0001's shared-counter + per-channel-compare architecture was
re-examined per Rule 5 (change only on a serious architectural flaw)
and no flaw was found. Status: ACCEPTED — architecture stands
unchanged; implementation resumes at `prescale_gate.sv`
(Checkpoint 2, step 5 of 5).
