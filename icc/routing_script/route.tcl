# ==============================================================================
# SCRIPT: route.tcl
# DESIGN: mips_cpu_top
# 
#   Signal Routing
#   + Post-Route Optimization
#   + Routing Verification
# ==============================================================================


echo "\n============================================================"
echo " ROUTING"
echo "============================================================\n"


# ==============================================================================
# 0. PROJECT SETUP
# ==============================================================================

set cell_name "mips_cpu_top"

#
# File:
#
#   .../icc/routing/route.tcl
#

set SCRIPT_DIR [file dirname [file normalize [info script]]]

#
# .../icc
#

set ICC_ROOT [file dirname $SCRIPT_DIR]

#
# .../full_flow_test
#

set PROJECT_ROOT [file dirname $ICC_ROOT]


#
# Shared Milkyway database:
#
#   .../icc/mips_cpu_top_Lib
#

set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"


#
# PDK root
#

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"


#
# Report directory
#

set LinkReport "${PROJECT_ROOT}/report/icc_test"

file mkdir $LinkReport



# ==============================================================================
# 1. TIMING LIBRARIES
# ==============================================================================

echo "\n*** SETUP TIMING LIBRARIES ***\n"


#
# MAX:
#   Max-delay side Setup
#
# MIN:
#   Min-delay side Hold
#

set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"

set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"


#
# Main target library
#

set target_library [list $MAX_LIB]


#
# Resolve standard-cell references
#

set link_library [list * $MAX_LIB]



# ==============================================================================
# 2. RC / TLU+ SETUP
# ==============================================================================

echo "\n*** SETUP RC CORNERS / TLU+ ***\n"


set Tlupmax "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"

set Tlupmin "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"

set Tech2itf "${LinkLibrary_mw}/astro/tech/tech2itf.map"



# ==============================================================================
# 3. OPEN CTS CHECKPOINT
# ==============================================================================

echo "\n*** OPEN CTS CHECKPOINT ***\n"


open_mw_lib $my_mw_lib

open_mw_cel "mw_mips_cts"

current_design $cell_name



# ==============================================================================
# 4. RESTORE TIMING / RC ENVIRONMENT
# ==============================================================================

echo "\n*** RESTORE TIMING / RC ENVIRONMENT ***\n"


#
# Associate MAX library with MIN timing version
#

set_min_library $MAX_LIB -min_version $MIN_LIB


#
# Restore interconnect RC corners
#

set_tlu_plus_files -max_tluplus $Tlupmax -min_tluplus $Tlupmin -tech2itf_map $Tech2itf


#
# Resolve design references
#

link



# ==============================================================================
# 5. PRE-ROUTE SANITY CHECKS
# ==============================================================================

echo "\n============================================================"
echo " PRE-ROUTE CHECKS"
echo "============================================================\n"


#
# Check RC setup
#

check_tlu_plus_files > ${LinkReport}/route_tluplus_check.rpt


#
# Check timing environment
#

check_timing > ${LinkReport}/route_check_timing_before.rpt


#
# Check clock
#

report_clock > ${LinkReport}/route_clock.rpt


#
# Check routing feasibility / congestion
#

check_routeability > ${LinkReport}/route_routeability_check.rpt


#
# Check physical database before route_opt
#

check_physical_design -stage pre_route_opt > ${LinkReport}/route_pre_route_check.rpt



# ==============================================================================
# 6. BASELINE BEFORE ROUTING
# ==============================================================================

echo "\n*** BASELINE BEFORE ROUTING ***\n"


#
# Setup timing before signal routing
#

report_timing -delay max > ${LinkReport}/route_before_setup.rpt


#
# Hold timing before signal routing
#

report_timing -delay min > ${LinkReport}/route_before_hold.rpt


#
# Constraint violations before route
#

report_constraint -all_violators > ${LinkReport}/route_before_constraint_violators.rpt


#
# Overall QoR
#

report_qor > ${LinkReport}/route_before_qor.rpt


#
# Placement utilization 
#

report_placement_utilization > ${LinkReport}/route_before_utilization.rpt


#
# Congestion estimate
#

report_congestion > ${LinkReport}/route_before_congestion.rpt



# ==============================================================================
# 7. MAIN SIGNAL ROUTING + OPTIMIZATION
# ==============================================================================

echo "\n============================================================"
echo " MAIN ROUTE_OPT"
echo "============================================================\n"


#
# route_opt:  flow routing + optimization.
#
# Conceptually:
#
#   Global routing
#       ↓
#   Track assignment
#       ↓
#   Detailed routing
#       ↓
#   Timing-driven optimization
#       ↓
#   Electrical / routing DRC repair
#
# Tool:
#
#   - insert buffers
#   - resize cells
#   - reroute nets
#   - optimize setup
#   - optimize hold
#   - fix transition / capacitance violations
#

route_opt



# ==============================================================================
# 8. INCREMENTAL POST-ROUTE OPTIMIZATION
# ==============================================================================

echo "\n============================================================"
echo " INCREMENTAL ROUTE OPTIMIZATION"
echo "============================================================\n"


route_opt -incremental



# ==============================================================================
# 9. ROUTING VERIFICATION
# ==============================================================================

echo "\n============================================================"
echo " ROUTING VERIFICATION"
echo "============================================================\n"


#
# Check ZRoute:
#
#   opens
#   shorts
#   routing DRC
#   connectivity problems
#

verify_zrt_route > ${LinkReport}/route_${cell_name}_zrt_verify.rpt



# ==============================================================================
# 10. POST-ROUTE TIMING ANALYSIS
# ==============================================================================

echo "\n*** POST-ROUTE TIMING ANALYSIS ***\n"



#
# Setup / Max-delay
#

report_timing -delay max > ${LinkReport}/route_${cell_name}_setup.rpt


#
# Hold / Min-delay
#

report_timing -delay min > ${LinkReport}/route_${cell_name}_hold.rpt



# ==============================================================================
# 11. POST-ROUTE CONSTRAINT / QOR ANALYSIS
# ==============================================================================

echo "\n*** POST-ROUTE QoR / CONSTRAINT ANALYSIS ***\n"


#
# Constraint violations:
#
#   setup
#   hold
#   max transition
#   max capacitance
#   max fanout
#   ...
#

report_constraint -all_violators > ${LinkReport}/route_${cell_name}_constraint_violators.rpt


#
# Overall QoR
#

report_qor > ${LinkReport}/route_${cell_name}_qor.rpt


#
# Final utilization
#

report_placement_utilization > ${LinkReport}/route_${cell_name}_utilization.rpt


#
# Congestion after routing
#

report_congestion > ${LinkReport}/route_${cell_name}_congestion.rpt



# ==============================================================================
# 12. POST-ROUTE LEGALITY CHECK
# ==============================================================================

echo "\n*** POST-ROUTE PLACEMENT LEGALITY CHECK ***\n"


#
# route_opt:
#
#   - insert buffers
#   - resize cells
#   - move cells
#
# check placement legality.
#

check_legality > ${LinkReport}/route_${cell_name}_legality.rpt



# ==============================================================================
# 13. STANDARD-CELL FILLER
# ==============================================================================






# ==============================================================================
# 14. FINAL ROUTING VERIFICATION
# ==============================================================================

echo "\n*** FINAL ROUTING VERIFICATION ***\n"


#
# Verify routing
#

verify_zrt_route > ${LinkReport}/route_${cell_name}_final_verify.rpt


#
# Final constraint report
#

report_constraint -all_violators > ${LinkReport}/route_${cell_name}_final_constraint_violators.rpt


#
# Final QoR
#

report_qor > ${LinkReport}/route_${cell_name}_final_qor.rpt



# ==============================================================================
# 15. SAVE ROUTED CHECKPOINT
# ==============================================================================

echo "\n*** SAVE ROUTED CHECKPOINT ***\n"


save_mw_cel -as "mw_mips_route"



echo "\n============================================================"
echo " ROUTING COMPLETED"
echo " CHECKPOINT: mw_mips_route"
echo "============================================================\n"
