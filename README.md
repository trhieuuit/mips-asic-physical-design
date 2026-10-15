# MIPS CPU ASIC Physical Design Flow

This project implements a complete ASIC design flow for a MIPS CPU, from RTL design and functional simulation to logic synthesis, physical design, and static timing analysis.
This project focus on Physical Design
The project uses the Synopsys ASIC toolchain and the SAED 90 nm standard-cell technology library.

---

## 1. Project Overview

The overall ASIC implementation flow is:

```text
RTL Design
    │
    ▼
RTL Simulation
   (VCS)
    │
    ▼
Logic Synthesis
(Design Compiler)
    │
    ├──────────────► Post-Synthesis Verification
    │                       │
    │                   Formality
    │                   PrimeTime
    │                       │
    ▼                       │
Physical Design             │
(IC Compiler)               │
    │                       │
    ├── Import              │
    ├── Floorplan           │
    ├── Placement           │
    ├── CTS                 │
    └── Routing             │
    │                       │
    ▼                       │
Post-Layout Netlist         │
    │                       │
    ├──────────────► Post-Layout Simulation
    │
    ├──────────────► Formal Verification
    │
    └──────────────► PrimeTime STA
```

The main objective of this project is to study and implement the complete RTL-to-layout ASIC flow and analyze timing, placement, clock distribution, congestion, and routing results.

---

## 2. Repository Structure

```text
.
├── dc/
│   ├── dc_script.tcl
│   └── dc_report/
│
├── fm/
│   ├── post_syn/
│   └── post_layout/
│
├── icc/
│   ├── import_script/
│   ├── floorplan_script/
│   ├── placement_script/
│   ├── cts_script/
│   ├── routing_script/
│   └── report/
│
├── image/
│
├── netlist/
│   ├── mips_cpu_top_NL.v
│   └── mips_cpu_top_post_layout.v
│
├── pt/
│   ├── post_syn/
│   └── post_layout/
│
├── report/
│   ├── pt/
│   └── pt_post_layout/
│
├── rtl/
│
├── sdc/
│
├── tb/
│
└── vcs/
    ├── pre_syn/
    ├── post_syn/
    └── post_layout/
```

---
# 3. MIPS CPU ASIC Physical Design

This project implements the physical design flow of a MIPS CPU using **Synopsys IC Compiler (ICC)** with the **SAED 90 nm** technology library.

The main flow is:

```text
Gate-Level Netlist
        │
        ▼
      Import
        │
        ▼
    Floorplan
        │
        ▼
     Placement
        │
        ▼
Clock Tree Synthesis
        │
        ▼
      Routing
        │
        ▼
 Post-Layout Design
```

## Project Structure

```text
icc/
├── import_script/
│   └── import.tcl
├── floorplan_script/
│   └── floorplan.tcl
├── placement_script/
│   └── placement.tcl
├── cts_script/
│   └── cts.tcl
├── routing_script/
│   └── route.tcl
└── report/
```

Input netlist:

```text
netlist/mips_cpu_top_NL.v
```

Timing constraint:

```text
sdc/mips_cpu_top_SDC.sdc
```

---

## 1. Floorplanning

The floorplanning stage defines the core area, I/O pins, power rings, power straps, and standard-cell power rails.



![Floorplan](image/floorplan.png)

---

## 2. Placement

Standard cells are placed and optimized for timing, utilization, and routability.

Main checks include:

```tcl
check_legality
report_timing
report_qor
report_congestion
```


![Placement](image/placement.png)

---

## 3. Clock Tree Synthesis

CTS builds the clock distribution network and inserts clock buffers to control:

- Clock skew
- Clock latency
- Clock transition
- Clock fanout



![Clock Tree Synthesis](image/cts.png)

---

## 4. Routing

Routing creates the physical metal connections between all placed cells.

The routing flow includes:

```text
Global Routing
      │
      ▼
Track Assignment
      │
      ▼
Detailed Routing
      │
      ▼
Routing Optimization
```

Main commands:

```tcl
route_opt
route_opt -incremental
verify_zrt_route
```

Final routed design:

![Routing Result](image/routing_1.png)

![Routing Result](image/routing_2.png)

Global routing congestion:

![Global Routing Congestion](image/global_routing_congestion.png)

Detailed routing congestion:

![Detailed Routing Congestion](image/detailed_routing_congestion.png)





---

## Physical Design Checkpoints

```text
mw_mips_imported
        │
        ▼
mw_mips_floorplan_done
        │
        ▼
mw_mips_placed
        │
        ▼
mw_mips_cts
        │
        ▼
mw_mips_route
```

Reports for each stage are stored in:

```text
icc/report/
├── import_report/
├── floorplan_report/
├── placement_report/
├── cts_report/
└── route_report/
```

---

# 4. Post-Layout Static Timing Analysis

Post-layout Static Timing Analysis (STA) was performed using
**Synopsys PrimeTime D-2010.06-SP2**.

The analysis uses the final routed gate-level netlist, extracted
interconnect parasitics (SPEF), timing constraints (SDC), and
SAED90nm standard-cell timing libraries.

Two timing analyses were performed:

- Setup Analysis: Maximum delay analysis using `saed90nm_max.db`.
- Hold Analysis: Minimum delay analysis using `saed90nm_min.db`.

The extracted parasitic information was used to evaluate timing
after placement, Clock Tree Synthesis (CTS), and routing.

## 4.1. Timing Constraints

The design was analyzed with the following constraints:

| Parameter | Value |
|---|---|
| Clock Name | clock |
| Target Clock Period | 20 ns |
| Target Frequency | 50 MHz |
| Clock Uncertainty (Setup) | 1.0 ns |
| Input Delay (Max) | 4.0 ns |
| Output Delay (Max) | 4.0 ns |
| Technology | SAED90nm |

The clock network was modeled using propagated clocks to account
for the actual clock-tree insertion delays after CTS.

## 4.2. Setup Timing Analysis

Setup timing analysis checks whether data arrives at the
destination before the required setup deadline.

The post-layout setup timing results are:

| Metric | Result |
|---|---|
| Clock Period | 20 ns |
| ICC Setup WNS | -0.03 ns |
| ICC Setup TNS | -0.03 ns |
| ICC Setup Violating Paths | 1 |
| PrimeTime Setup WNS | -0.05 ns |
| Setup Status | VIOLATED |

The worst setup slack reported by PrimeTime was:

```text
Worst Setup Slack = -0.05 ns
```

This indicates that the design has a remaining setup timing
violation of approximately 50 ps under the specified timing
constraints.

Although the target clock frequency was 50 MHz, complete
setup timing closure was not achieved.

### Critical Path Analysis

The critical path was identified as:

```text
Startpoint: Inst[22]
       |
       v
Register File Read MUX
       |
       v
ALU Subtractor
       |
       v
Endpoint: Addr[31]
```

The path propagates through multiple combinational logic stages,
including register-file selection logic and the 32-bit ALU
subtractor.

The long combinational path contributes significantly to the
overall propagation delay.

The ICC QoR report indicates:

| Metric | Value |
|---|---:|
| Critical Path Length | 11.03 ns |
| Levels of Logic | 78 |
| Critical Path Slack | -0.03 ns |

The large number of logic levels suggests that structural
optimization of the arithmetic datapath could further improve
timing performance.

## 4.3. Hold Timing Analysis

Hold timing analysis checks whether data remains stable for the
required minimum interval after the active clock edge.

The minimum-delay analysis was performed using the
SAED90nm minimum-delay library and extracted minimum parasitics.

The results are:

| Metric | Result |
|---|---|
| PrimeTime Worst Hold Slack | +0.93 ns |
| ICC Hold Violations | 0 |
| Hold Status | MET |

The worst hold slack was:

```text
Worst Hold Slack = +0.93 ns
```

The positive hold slack indicates that all reported hold timing
requirements were satisfied.

Therefore, no additional hold timing optimization was required
for the analyzed design.

---

# 5. Engineering Change Order (ECO) Optimization

Engineering Change Order (ECO) optimization was performed
after detailed routing to investigate timing improvements
without redesigning the complete circuit.

The main objective was to improve setup timing by increasing
the drive strength of selected standard cells along the
critical timing path.

Cell upsizing was performed using the Synopsys IC Compiler
`size_cell` command.

After each ECO modification, placement legalization,
incremental routing, parasitic extraction, and timing analysis
were performed.

## 5.1. ECO Experiments

Five manual ECO experiments were evaluated.

| Experiment | Modified Cell | Original Cell | New Cell | Setup WNS (ICC) |
|---|---|---|---|---:|
| Baseline | — | — | — | -0.06 ns |
| ECO 1 | U188 | NAND2X0 | NAND2X2 | **-0.03 ns** |
| ECO 2 | U180 | NAND3X0 | NAND3X1 | -0.16 ns |
| ECO 3 | U6 | AOI222X1 | AOI222X2 | -0.05 ns |
| ECO 4 | U169 | NAND3X0 | NAND3X1 | -0.17 ns |
| ECO 5 | U1128 | MUX41X1 | MUX41X2 | -0.04 ns |

ECO 1 was applied to the clean routing checkpoint.

ECO 2 through ECO 5 were independently evaluated using
ECO 1 as their common starting point.

This approach enabled a controlled comparison of different
cell-sizing modifications.

## 5.2. ECO Results

Among the evaluated configurations, ECO 1 achieved the
best setup timing result.

The worst setup slack improved from:

```text
Before ECO: -0.06 ns
After ECO:  -0.03 ns
```

This corresponds to an improvement of approximately 30 ps
in ICC setup timing.

However, not all cell-upsizing operations improved timing.

Some modifications increased the delay of the critical path,
resulting in worse setup slack.

This demonstrates that increasing cell drive strength does
not always improve circuit performance.

The final selected configuration was saved as:

```text
mw_mips_setup_eco_best
```

The final PrimeTime setup analysis reported a worst
setup slack of -0.05 ns.

---

# 6. Power, Performance, and Area (PPA) Evaluation

Post-layout PPA evaluation was performed using
Synopsys IC Compiler and Synopsys PrimeTime PX.

The evaluation includes:

- Area: Standard-cell area, core area, and utilization.
- Performance: Setup timing, hold timing, and target clock frequency.
- Power: Internal power, switching power, and leakage power.

The results correspond to the selected post-layout ECO
implementation.

## 6.1. Area Analysis

The physical implementation was evaluated using the ICC
`report_area`, `report_placement_utilization`, and `report_qor`
commands.

### Standard Cell Area

| Area Metric | Result |
|---|---:|
| Combinational Area | 46,028.39 µm² |
| Noncombinational Area | 34,062.34 µm² |
| **Total Cell Area** | **80,090.73 µm²** |
| Reported Net Interconnect Area | 12,098.91 µm² |
| Reported Design Area | 92,189.64 µm² |

The total standard-cell area is:

\[
A_{cell} = A_{comb} + A_{noncomb}
\]

\[
A_{cell} = 46028.39 + 34062.34
\]

\[
\boxed{A_{cell} = 80090.73\ \mu m^2}
\]

### Placement Utilization

The final placement utilization results are:

| Parameter | Value |
|---|---:|
| Core Width | 358.40 µm |
| Core Height | 357.12 µm |
| Core Area | 127,991.81 µm² |
| **Standard Cell Utilization** | **62.57%** |
| Non-fixed Cell Utilization | 62.24% |
| Macro Cell Count | 0 |

Placement utilization is calculated as:

\[
Utilization = \frac{Cell\ Area}{Core\ Area}\times100\%
\]

\[
Utilization =
\frac{80090.73}{127991.81}\times100\%
\]

\[
\boxed{Utilization \approx 62.57\%}
\]

The utilization indicates that approximately 62.57% of
the placement region is occupied by standard cells.

The remaining area provides placement whitespace and
supports physical optimization and routing.

### Cell Count

The final design contains:

| Cell Type | Count |
|---|---:|
| Total Leaf Cells | 4,730 |
| Buffer/Inverter Cells | 678 |
| Clock Tree Buffer/Inverter Cells | 210 |
| Hierarchical Cells | 10 |
| SRAM Macros | 0 |

The register file was implemented using standard cells
rather than a dedicated SRAM macro.

---

## 6.2. Performance Analysis

The timing performance was evaluated using extracted
post-layout parasitics.

| Performance Metric | Result |
|---|---:|
| Target Clock Period | 20 ns |
| Target Frequency | 50 MHz |
| Setup WNS (ICC) | -0.03 ns |
| Setup TNS (ICC) | -0.03 ns |
| Setup WNS (PrimeTime) | -0.05 ns |
| Hold WNS (PrimeTime) | +0.93 ns |
| Setup Timing Status | VIOLATED |
| Hold Timing Status | MET |

The manual ECO optimization reduced the setup violation,
but the design did not fully satisfy the required setup
timing at the target clock period.

Hold timing requirements were successfully satisfied.

---

## 6.3. Power Analysis

Power estimation was performed using
**Synopsys PrimeTime PX D-2010.06-SP2**.

The analysis was configured in averaged power analysis mode.

The SAED90nm maximum-delay library was used under the
WORST operating condition.

Because no simulation-based VCD or SAIF switching activity
was provided, vector-free power estimation was used.

PrimeTime PX propagated switching activity through the
gate-level design to estimate dynamic power consumption.

### Power Results

| Power Component | Power (mW) | Percentage |
|---|---:|---:|
| Net Switching Power | 0.1290 | 25.26% |
| Cell Internal Power | 0.1229 | 24.07% |
| **Total Dynamic Power** | **0.2519** | **49.33%** |
| Cell Leakage Power | 0.2588 | 50.67% |
| **Total Power** | **0.5107** | **100%** |

Dynamic power is calculated as:

\[
P_{dynamic} = P_{internal} + P_{switching}
\]

\[
P_{dynamic} = 0.1229 + 0.1290
\]

\[
\boxed{P_{dynamic} = 0.2519\ mW}
\]

Total power is calculated as:

\[
P_{total} = P_{dynamic} + P_{leakage}
\]

\[
\boxed{P_{total} = 0.5107\ mW}
\]

### Power Distribution

The power consumption was distributed across different
standard-cell groups.

| Power Group | Total Power (mW) | Percentage |
|---|---:|---:|
| Clock Network | 0.1646 | 32.23% |
| Registers | 0.0937 | 18.34% |
| Combinational Logic | 0.2525 | 49.43% |

Combinational logic accounts for the largest portion
of the estimated total power consumption.

The clock distribution network also contributes
significantly to the total power.

### Power Analysis Limitations

The reported power results are preliminary estimates.

No workload-specific switching activity was provided
through VCD or SAIF simulation files.

Therefore, the estimated dynamic power does not necessarily
represent the actual power consumption when executing
a specific MIPS program.

Additionally, the PrimeTime PX power checks identified
some slew and load conditions outside the characterized
library table ranges.

More accurate power analysis would require simulation-based
switching activity and further validation of the
timing and power models.

---

# 7. Final PPA Summary

The following table summarizes the final post-layout
implementation results.

| Category | Metric | Result |
|---|---|---:|
| Technology | Process Technology | SAED90nm |
| Design | Top Module | mips_cpu_top |
| Area | Total Cell Area | **80,090.73 µm²** |
| Area | Core Area | 127,991.81 µm² |
| Area | Core Utilization | **62.57%** |
| Area | Standard Cell Count | 4,730 |
| CTS | Clock Buffers/Inverters | 210 |
| Performance | Target Frequency | 50 MHz |
| Performance | Target Clock Period | 20 ns |
| Performance | Setup WNS (PrimeTime) | **-0.05 ns** |
| Performance | Hold WNS (PrimeTime) | **+0.93 ns** |
| Power | Internal Power | 0.1229 mW |
| Power | Switching Power | 0.1290 mW |
| Power | Dynamic Power | 0.2519 mW |
| Power | Leakage Power | 0.2588 mW |
| Power | Total Power (Vector-Free) | **0.5107 mW** |

**Note:** The target frequency is 50 MHz, but setup timing closure
was not fully achieved at the corresponding 20 ns clock period.

---

# 8. Conclusion

This project demonstrates the implementation of a MIPS CPU
through the major stages of the ASIC physical design flow
using Synopsys tools and the SAED90nm technology library.

The physical design flow includes floorplanning, standard-cell
placement, Clock Tree Synthesis, global routing, detailed
routing, parasitic extraction, and post-layout static
timing analysis.

The final implementation contains 4,730 standard cells
with a total cell area of 80,090.73 µm² and a core
utilization of 62.57%.

Post-layout timing analysis reported a worst setup slack
of -0.05 ns and a worst hold slack of +0.93 ns.

Manual ECO experiments demonstrated how standard-cell
upsizing affects critical path timing.

The best ECO configuration improved ICC setup slack
by approximately 30 ps compared to the routing baseline.

PrimeTime PX estimated a total power consumption of
0.5107 mW using vector-free switching activity estimation.

Although the complete setup timing requirements were not
fully satisfied, the project provides practical experience
with physical implementation, timing analysis, routing
verification, and engineering change orders.

Future improvements may include:

- Optimizing the critical combinational datapath.
- Evaluating alternative ALU architectures.
- Improving setup timing closure.
- Performing workload-based power analysis using VCD/SAIF.
- Extending physical verification and signoff.



## Tools

- Synopsys IC Compiler
- Synopsys Design Compiler
- Synopsys PrimeTime
- SAED 90 nm technology library

