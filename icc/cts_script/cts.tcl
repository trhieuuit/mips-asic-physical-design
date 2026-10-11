# ==============================================================================
# SCRIPT: cts.tcl
# DESIGN: mips_cpu_top
#   Clock Tree Synthesis (CTS)
#   + Post-CTS Timing Optimization
#   + Hold Fixing
#   + Clock Routing
# ==============================================================================


echo "\n============================================================"
echo "CLOCK TREE SYNTHESIS"
echo "============================================================\n"


# ==============================================================================
# 0. PROJECT SETUP
# ==============================================================================

set cell_name "mips_cpu_top"
set SCRIPT_DIR [file dirname [file normalize [info script]]]


set ICC_ROOT [file dirname $SCRIPT_DIR]


set PROJECT_ROOT [file dirname $ICC_ROOT]



# Shared Milkyway Library:
#   .../icc/mips_cpu_top_Lib

set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

# PDK root

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"

# Report directory

set LinkReport "${PROJECT_ROOT}/report/icc_test"

file mkdir $LinkReport



# ==============================================================================
# 1. TIMING LIBRARIES
# ==============================================================================

echo "\n*** Config timing library ***\n"


#
# MAX:
#   max-delay side
#   Setup analysis
#
# MIN:
#   min-delay side
#   Hold analysis
#

set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"

set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"


#
# Main / target library
#

set target_library [list $MAX_LIB]


#
# Link library:
#
# *       : design/library 
# MAX_LIB : standard-cell timing library
#

set link_library [list * $MAX_LIB]



# ==============================================================================
# 2. RC / TLU+ SETUP
# ==============================================================================

echo "\n*** Config RC CORNERS / TLU+ ***\n"


set Tlupmax "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"

set Tlupmin "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"

set Tech2itf "${LinkLibrary_mw}/astro/tech/tech2itf.map"



# ==============================================================================
# 3. OPEN PLACEMENT CHECKPOINT
# ==============================================================================


open_mw_lib $my_mw_lib


open_mw_cel "mw_mips_placed"


current_design $cell_name



# ==============================================================================
# 4. RESTORE MIN/MAX TIMING ENVIRONMENT
# ==============================================================================

echo "\n*** RESTORE TIMING / RC ENVIRONMENT ***\n"


#
# Associate max-delay library với min-delay version.
#

set_min_library $MAX_LIB -min_version $MIN_LIB


#
# RC corners
#

set_tlu_plus_files -max_tluplus $Tlupmax -min_tluplus $Tlupmin -tech2itf_map $Tech2itf


#
# Resolve netlist references với timing library.
#

link



# ==============================================================================
# 5. PRE-CTS SANITY CHECKS
# ==============================================================================


#
# kiem tra TLU+
#

check_tlu_plus_files > ${LinkReport}/cts_tluplus_check.rpt


#
# kiem tra timing environment:
#
#   - missing clock
#   - unconstrained paths
#   - timing setup
#

check_timing > ${LinkReport}/cts_check_timing_before.rpt


#
# kiem tra clock  tu SDC
#

report_clock > ${LinkReport}/cts_clock_before.rpt


#
# kiem tra physical design da san sang cho CTS.
#

check_physical_design -stage pre_clock_opt > ${LinkReport}/cts_pre_clock_opt_check.rpt


#
# kiem tra clock-tree configuration.
#

check_clock_tree > ${LinkReport}/cts_clock_tree_check_before.rpt


#
# Clock tree baseline.
#

report_clock_tree -summary > ${LinkReport}/cts_clock_tree_before.rpt



# ==============================================================================
# 6. BASELINE TIMING BEFORE CTS
# ==============================================================================

echo "\n*** TIMING BASELINE TRUOC CTS ***\n"


#
# Max-delay / Setup side
#

report_timing -delay max > ${LinkReport}/cts_before_setup.rpt


#
# Min-delay / Hold side
#

report_timing -delay min > ${LinkReport}/cts_before_hold.rpt


#
# Electrical / timing constraint violations
#

report_constraint -all_violators > ${LinkReport}/cts_before_constraint_violators.rpt


#
# QoR truoc CTS
#

report_qor > ${LinkReport}/cts_before_qor.rpt



# ==============================================================================
# 7. CLOCK TREE DESIGN TARGETS
# ==============================================================================

echo "\n*** Thiet lap CTS TARGETS ***\n"


#
# Mot clock-tree driver khong drive quá 32 sinks.
#


set_clock_tree_options -max_fanout 32


#
# Maximum clock slew / transition.
#   0.2 ns = 200 ps


set_clock_tree_options -max_transition 0.2

#
# Target clock skew.
#   0.1 ns = 100 ps
#

set_clock_tree_options -target_skew 0.1



# ==============================================================================
# 8. CLOCK TREE SYNTHESIS
# ==============================================================================

echo "\n============================================================"
echo " BUILD CLOCK TREE"
echo "============================================================\n"


#
# CTS:
#
#   - identify clock sinks
#   - build tree topology
#   - insert clock buffers / inverters
#   - place clock-tree cells
#   - optimize fanout
#   - optimize transition
#   - balance skew
#
# -no_clock_route:
#
#   chưa detailed-route clock 
#

clock_opt -only_cts -no_clock_route



# ==============================================================================
# 9. CHECK CLOCK TREE AFTER BUILD
# ==============================================================================

echo "\n***  CHECK CLOCK TREE AFTER BUILD ***\n"


check_clock_tree > ${LinkReport}/cts_clock_tree_check_after_build.rpt


report_clock_tree -summary > ${LinkReport}/cts_clock_tree_after_build.rpt



# ==============================================================================
# 10. POST-CTS TIMING OPTIMIZATION + HOLD FIX
# ==============================================================================

echo "\n============================================================"
echo " POST-CTS OPTIMIZATION + HOLD FIX"
echo "============================================================\n"


#
# Sau CTS:
#
#   clock insertion delay
#   clock latency
#   clock skew
#
# Setup/Hold  optimize.
# -fix_hold_all_clocks:
#
#   - insert delay buffers
#   - resize cells
#   - move cells
#   - optimize data paths
#
#

clock_opt -fix_hold_all_clocks -no_clock_route



# ==============================================================================
# 11. CLOCK ROUTING
# ==============================================================================

echo "\n============================================================"
echo " ROUTE CLOCK NETWORK"
echo "============================================================\n"


#
# Route cac clock nets bang ZRoute.
#

route_zrt_group -all_clock_nets -reuse_existing_global_route true



# ==============================================================================
# 12. FINAL CLOCK TREE CHECK
# ==============================================================================

echo "\n*** FINAL CLOCK TREE CHECK***\n"


check_clock_tree > ${LinkReport}/cts_clock_tree_check_final.rpt


report_clock_tree -summary > ${LinkReport}/cts_${cell_name}_summary.rpt



# ==============================================================================
# 13. POST-CTS TIMING ANALYSIS
# ==============================================================================

echo "\n*** POST-CTS TIMING ANALYSIS***\n"


#
# Setup:
#
# Max-delay analysis.
#

report_timing -delay max > ${LinkReport}/cts_${cell_name}_setup.rpt


#
# Hold:
#
# Min-delay analysis.
#

report_timing -delay min > ${LinkReport}/cts_${cell_name}_hold.rpt



# ==============================================================================
# 14. CONSTRAINT / QoR REPORTS
# ==============================================================================

echo "\n*** QOR / CONSTRAINT REPORTS ***\n"


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

report_constraint -all_violators > ${LinkReport}/cts_${cell_name}_constraint_violators.rpt


#
# Overall Quality of Results
#

report_qor > ${LinkReport}/cts_${cell_name}_qor.rpt



# ==============================================================================
# 15. POST-CTS PHYSICAL CHECK
# ==============================================================================

echo "\n*** POST-CTS PHYSICAL CHECK ***\n"


#
#
#   clock buffers
#   clock inverters
#   hold buffers
#

check_legality > ${LinkReport}/cts_legality.rpt



# ==============================================================================
# 16. SAVE CTS CHECKPOINT
# ==============================================================================


save_mw_cel -as "mw_mips_cts"



echo "\n============================================================"
echo " CLOCK TREE SYNTHESIS COMPLETED"
echo " CHECKPOINT: mw_mips_cts"
echo "============================================================\n"
