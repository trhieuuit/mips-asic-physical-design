# MIPS CPU ASIC Physical Design

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

Typical checkpoint:

```text
mw_mips_floorplan_done
```

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

Typical checkpoint:

```text
mw_mips_placed
```

![Placement](image/placement.png)

---

## 3. Clock Tree Synthesis

CTS builds the clock distribution network and inserts clock buffers to control:

- Clock skew
- Clock latency
- Clock transition
- Clock fanout

Typical checkpoint:

```text
mw_mips_cts
```

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

Global routing congestion:

![Global Routing Congestion](image/global_routing_congestion.png)

Detailed routing congestion:

![Detailed Routing Congestion](image/detailed_routing_congestion.png)

Final routed design:

![Routing Result](image/routing_1.png)

![Routing Result](image/routing_2.png)

Typical checkpoint:

```text
mw_mips_route
```

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

## Author

**Trọng Hiếu Lê**  
Computer Engineering  
University of Information Technology - VNU-HCM
