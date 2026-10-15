# ==============================================================================
# SCRIPT: 02_floorplan.tcl
# DESIGN: mips_cpu_top
#
#
#   - Opne checkpoint after Import
#   - Initialize Die/Core floorplan
#   - Place top-level pins
#   - Prepare placement constraints
#   - Create Power/Ground network
#   - Check floorplan before Placement
#   - Save checkpoint
# ==============================================================================

# ==============================================================================
# 0. PROJECT / LIBRARY SETUP
# ==============================================================================

set cell_name "mips_cpu_top"
set SCRIPT_DIR [file dirname [file normalize [info script]]]

# .../icc
set ICC_ROOT [file dirname $SCRIPT_DIR]

# Shared Milkyway database
set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"

set LinkProject ".."
set LinkReport "${LinkProject}/report/icc/floorplan"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"

file mkdir $LinkReport


# ------------------------------------------------------------------------------
# Timing libraries
# ------------------------------------------------------------------------------

set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"
set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"

set target_library [list $MAX_LIB]

set link_library [list \
    * \
    $MAX_LIB \
]


# ------------------------------------------------------------------------------
# RC libraries
# ------------------------------------------------------------------------------

set Tlupmax \
    "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"

set Tlupmin \
    "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"

set Tech2itf \
    "${LinkLibrary_mw}/astro/tech/tech2itf.map"

# ==============================================================================
# 1. OPEN IMPORT CHECKPOINT
# ==============================================================================

echo "\n*** OPEN IMPORT CHECKPOINT ***\n"

open_mw_lib $my_mw_lib

open_mw_cel "mw_mips_imported"

current_design $cell_name


# Setup  min/max environment cho ICC 
set_min_library \
    $MAX_LIB \
    -min_version $MIN_LIB

set_tlu_plus_files \
    -max_tluplus $Tlupmax \
    -min_tluplus $Tlupmin \
    -tech2itf_map $Tech2itf


# Resolve references

link


# Basic checks

check_tlu_plus_files \
    > ${LinkReport}/floorplan_tluplus_check.rpt

check_timing \
    > ${LinkReport}/floorplan_check_timing.rpt

report_clock \
    > ${LinkReport}/floorplan_clock.rpt

# ==============================================================================
# 2. INITIALIZE FLOORPLAN
# ==============================================================================

echo "\n ***INITIALIZE DIE / CORE ***\n"

#
# 60% utilization 
#

set Core_util 0.60

#
# SAED90 standard-cell site:
#
# X pitch  0.32 um
# row height 2.88 um
#
#


set Core_space_X 15.04
set Core_space_Y 14.40

initialize_floorplan \
	-core_utilization $Core_util \
	-left_io2core $Core_space_X \
	-right_io2core  $Core_space_X \
	-bottom_io2core $Core_space_Y \
	-top_io2core    $Core_space_Y

# ==============================================================================
# 3. TOP-LEVEL PIN PLANNING
# ==============================================================================

echo "\n*** PIN PLANNING ***\n"


#
#
# Inst              -> Left
# Clock / Reset     -> Top
# Dout              -> Right
# Data/Memory IF    -> Bottom
#

set_pin_physical_constraints\
	-pin_name [get_object_name [get_ports {clock reset}]]\
	-side 2

set_pin_physical_constraints \
    -pin_name [get_object_name [get_ports {Inst*}]] \
    -side 1


set_pin_physical_constraints \
    -pin_name [get_object_name [get_ports {Dout*}]] \
    -side 3


set_pin_physical_constraints \
    -pin_name [get_object_name \
        [get_ports {PC* Addr* Din* MemRead MemWrite}]] \
    -side 4


#
# Global pin-assignment policy.
#
#


#set_fp_pin_constraints \
#    -block_level \
#    -use_physical_constraints on \
#    -keep_buses_together on \
#    -bus_ordering lsb_to_msb \
#    -corner_keepout_percent_side 5 \
#    -pin_spacing 2


#
# 
#
# set_pin_physical_constraints: rule.
# place_fp_pins: assign physical pin locations.
#

place_fp_pins -block_level

# Check pin assignment

check_fp_pin_assignment \
    > ${LinkReport}/floorplan_pin_check.rpt

# ==============================================================================
# 4. LOGIC REGIONS / BOUNDS
# ==============================================================================

echo "\n*** LOGIC REGIONS / BOUNDS ***\n"

#
#

# create_bounds \
#     -name BOUND_REGFILE \
#     -type soft \
#     -dimension {60 60} \
#     [get_cells "dat_path_inst/u1_reg_file"]

# create_bounds \
#     -name BOUND_ALU \
#     -type soft \
#     -dimension {60 60} \
#     [get_cells "dat_path_inst/u2_alu"]

# ==============================================================================
# 5. PLACEMENT BLOCKAGES
# ==============================================================================
echo "\n*** PLACEMENT BLOCKAGES ***\n"

#
# Production flow chi toa khi:
#
#   - macro halo/channel
#   - routing congestion
#   - PG routing
#   - analog/IP keepout
#   - reserved placement region



# ==============================================================================
# 6. POWER / GROUND LOGICAL CONNECTION
# ==============================================================================

echo "\n*** DERIVE PG CONNECTION ***"

derive_pg_connection -create_ports all -power_net VDD -power_pin VDD -ground_net VSS -ground_pin VSS -tie

# ==============================================================================
# 7. CREATE CORE POWER RINGS
# ==============================================================================

echo "\n*** TẠO VDD / VSS CORE RINGS ***\n"

#
# M6: vertical segments
# M7: horizontal segments.

#

set PG_RING_WIDTH 0.8

# ------------------------------------------------------------------------------
# Inner VSS ring
# ------------------------------------------------------------------------------

create_rectangular_rings -nets {VSS} -left_offset 0.8 -left_segment_layer M6 -left_segment_width 0.8 -right_offset 0.8 -right_segment_layer M6 -right_segment_width 0.8 -bottom_offset 0.8 -bottom_segment_layer M7 -bottom_segment_width 0.8 -top_offset 0.8 -top_segment_layer M7 -top_segment_width 0.8


# ------------------------------------------------------------------------------
# Outer VDD ring
# ------------------------------------------------------------------------------
create_rectangular_rings -nets {VDD} -left_offset 2.4 -left_segment_layer M6 -left_segment_width 0.8 -right_offset 2.4 -right_segment_layer M6 -right_segment_width 0.8 -bottom_offset 2.4 -bottom_segment_layer M7 -bottom_segment_width 0.8 -top_offset 2.4 -top_segment_layer M7 -top_segment_width 0.8

# ==============================================================================
# 8. CREATE POWER STRAP MESH
# ==============================================================================

echo "\n*** TẠO PG STRAPS / MESH ***\n"


# ------------------------------------------------------------------------------
# lay Core Boundary
# ------------------------------------------------------------------------------

set core_bbox [get_attribute [get_core_area] bbox]

set core_ll [lindex $core_bbox 0]
set core_ur [lindex $core_bbox 1]

set core_llx [lindex $core_ll 0]
set core_lly [lindex $core_ll 1]

set core_urx [lindex $core_ur 0]
set core_ury [lindex $core_ur 1]


# ------------------------------------------------------------------------------
# PG parameters
#
# VDD ----6um---- VSS ----6um---- VDD
#
# ------------------------------------------------------------------------------

set PG_STRAP_WIDTH 0.5

set PG_PAIR_PITCH 12.0
set PG_NET_SPACING 6.0

set PG_EDGE_MARGIN 6.0


# ------------------------------------------------------------------------------
# Vertical mesh on M6
# ------------------------------------------------------------------------------

set VDD_V_START [expr {$core_llx + $PG_EDGE_MARGIN}]
set VSS_V_START [expr {$VDD_V_START + $PG_NET_SPACING}]

set NUM_VDD_V [expr {
    int(($core_urx - $VDD_V_START) / $PG_PAIR_PITCH) + 1
}]

set NUM_VSS_V [expr {
    int(($core_urx - $VSS_V_START) / $PG_PAIR_PITCH) + 1
}]


create_power_straps \
    -direction vertical \
    -start_at $VDD_V_START \
    -num_placement_strap $NUM_VDD_V \
    -increment_x_or_y $PG_PAIR_PITCH \
    -nets {VDD} \
    -layer M6 \
    -width $PG_STRAP_WIDTH \
    -do_not_route_over_macros


create_power_straps \
    -direction vertical \
    -start_at $VSS_V_START \
    -num_placement_strap $NUM_VSS_V \
    -increment_x_or_y $PG_PAIR_PITCH \
    -nets {VSS} \
    -layer M6 \
    -width $PG_STRAP_WIDTH \
    -do_not_route_over_macros


# ------------------------------------------------------------------------------
# Horizontal mesh on M7
# ------------------------------------------------------------------------------

set VDD_H_START [expr {$core_lly + $PG_EDGE_MARGIN}]
set VSS_H_START [expr {$VDD_H_START + $PG_NET_SPACING}]

set NUM_VDD_H [expr {
    int(($core_ury - $VDD_H_START) / $PG_PAIR_PITCH) + 1
}]

set NUM_VSS_H [expr {
    int(($core_ury - $VSS_H_START) / $PG_PAIR_PITCH) + 1
}]


create_power_straps \
    -direction horizontal \
    -start_at $VDD_H_START \
    -num_placement_strap $NUM_VDD_H \
    -increment_x_or_y $PG_PAIR_PITCH \
    -nets {VDD} \
    -layer M7 \
    -width $PG_STRAP_WIDTH \
    -do_not_route_over_macros


create_power_straps \
    -direction horizontal \
    -start_at $VSS_H_START \
    -num_placement_strap $NUM_VSS_H \
    -increment_x_or_y $PG_PAIR_PITCH \
    -nets {VSS} \
    -layer M7 \
    -width $PG_STRAP_WIDTH \
    -do_not_route_over_macros
# ==============================================================================
# 9. STANDARD-CELL POWER RAILS
# ==============================================================================

echo "\n*** PREROUTE STANDARD-CELL RAILS ***\n"

#
# Rail -> strap -> ring
#

preroute_standard_cells \
    -mode rail \
    -nets {VDD VSS}


# ==============================================================================
# 10. PG / PHYSICAL CHECKS
# ==============================================================================

echo "\n*** POWER / FLOORPLAN CHECKS ***\n"


verify_pg_nets \
    > ${LinkReport}/floorplan_pg_check.rpt


#
# check database before Placement .
#

check_physical_design \
    -stage pre_place_opt \
    > ${LinkReport}/floorplan_pre_place_check.rpt


# ==============================================================================
# 11. WRITE FLOORPLAN DATA
# ==============================================================================

echo "\n*** WRITE FLOORPLAN DATA ***\n"

write_floorplan \
    ${LinkReport}/mips_cpu_floorplan.tcl

write_pin_pad_physical_constraints \
    ${LinkReport}/mips_cpu_pin_pad.tcl


# ==============================================================================
# 12. SAVE CHECKPOINT
# ==============================================================================

save_mw_cel \
    -as "mw_mips_floorplan_done"


echo "\n============================================================"
echo " FLOORPLANNING COMPLETE"
echo " CHECKPOINT: mw_mips_floorplan_done"
echo "============================================================\n"
