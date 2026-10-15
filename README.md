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

## Tools

- Synopsys IC Compiler
- Synopsys Design Compiler
- Synopsys PrimeTime
- SAED 90 nm technology library

