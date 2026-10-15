# ==============================================================================
# SCRIPT: route.tcl
# DESIGN: mips_cpu_top
# TOOL  : Synopsys ICC D-2010.03-SP4
#
# INPUT  : mw_mips_cts
# WORK   : mw_mips_route_work
# OUTPUT : mw_mips_route_clean
#
# FLOW:
#   1. Restore timing / RC environment
#   2. Preserve the original CTS checkpoint
#   3. Global routing
#   4. Track assignment
#   5. Detailed routing
#   6. Routing, placement, clock-tree and timing verification
#
# IMPORTANT:
#   Do NOT run route_opt or route_opt -incremental in this project.
#   The staged ZRoute sequence previously achieved 0 opens and 0 DRCs.
# ===============================================================================

puts "\n============================================================"
puts " START SIGNAL ROUTING: mips_cpu_top"
puts "============================================================\n"

# ==============================================================================
# 0. PATHS AND PROJECT CONFIGURATION
# ===============================================================================

set cell_name "mips_cpu_top"

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ICC_ROOT [file dirname $SCRIPT_DIR]
set PROJECT_ROOT [file dirname $ICC_ROOT]

set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"
set DB_DIR "${PDK_ROOT}/syn_lib/syn_lib"
set PROCESS_DIR "${PDK_ROOT}/process"

set MAX_LIB "${DB_DIR}/saed90nm_max.db"
set MIN_LIB "${DB_DIR}/saed90nm_min.db"

set Tlupmax "${PROCESS_DIR}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"
set Tlupmin "${PROCESS_DIR}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"
set Tech2itf "${PROCESS_DIR}/astro/tech/tech2itf.map"

set LinkReport "${PROJECT_ROOT}/report/icc/route"
file mkdir $LinkReport

# ==============================================================================
# 1. LIBRARY SETUP
# ===============================================================================

puts "\n*** LIBRARY SETUP ***\n"

set target_library [list $MAX_LIB]
set link_library [list "*" $MAX_LIB]

# ==============================================================================
# 2. OPEN CTS CHECKPOINT AND CREATE A WORKING COPY
# ===============================================================================

puts "\n*** OPEN CTS CHECKPOINT ***\n"

open_mw_lib $my_mw_lib
open_mw_cel mw_mips_cts
current_design $cell_name

# Protect mw_mips_cts from any change by the router.
# For a clean rerun, start with fresh work/output CEL names in the MW library.
puts "\n*** SAVE ROUTING WORKING COPY ***\n"

save_mw_cel -as mw_mips_route_work
close_mw_cel
open_mw_cel mw_mips_route_work
current_design $cell_name

# ==============================================================================
# 3. RESTORE TIMING + RC SETUP
# ===============================================================================

puts "\n*** RESTORE TIMING AND RC CORNERS ***\n"

set_min_library $MAX_LIB -min_version $MIN_LIB
set_tlu_plus_files -max_tluplus $Tlupmax -min_tluplus $Tlupmin -tech2itf_map $Tech2itf
link

# CTS already built and routed the clock network.
# Keep the propagated clock model for routing / post-route STA.
set_propagated_clock [all_clocks]
update_timing

# ==============================================================================
# 4. CHECK BEFORE SIGNAL ROUTING
# ===============================================================================

puts "\n*** PRE-ROUTE CHECKS ***\n"

check_tlu_plus_files > "${LinkReport}/01_tluplus_check.rpt"
check_timing > "${LinkReport}/02_check_timing_before.rpt"
report_clock > "${LinkReport}/03_clock_before.rpt"
report_clock_tree -summary > "${LinkReport}/04_clock_tree_before.rpt"
check_legality > "${LinkReport}/05_legality_before.rpt"

report_timing -delay max -max_paths 20 > "${LinkReport}/06_setup_before.rpt"
report_timing -delay min -max_paths 20 > "${LinkReport}/07_hold_before.rpt"
report_qor > "${LinkReport}/08_qor_before.rpt"

# ==============================================================================
# 5. GLOBAL ROUTING
# ===============================================================================

puts "\n============================================================"
puts " GLOBAL ROUTING"
puts "============================================================\n"

route_zrt_global

# Congestion statistics after global routing.
report_congestion -grc_based -by_layer -routing_stage global > "${LinkReport}/09_global_congestion.rpt"

# ==============================================================================
# 6. TRACK ASSIGNMENT
# ===============================================================================

puts "\n============================================================"
puts " TRACK ASSIGNMENT"
puts "============================================================\n"

route_zrt_track

# ==============================================================================
# 7. DETAILED ROUTING
# ===============================================================================

puts "\n============================================================"
puts " DETAILED ROUTING"
puts "============================================================\n"

route_zrt_detail

# ==============================================================================
# 8. PHYSICAL VERIFICATION AFTER ROUTING
# ===============================================================================

puts "\n*** VERIFY ROUTING AND PLACEMENT ***\n"

verify_zrt_route > "${LinkReport}/10_verify_zrt_route.rpt"
check_legality > "${LinkReport}/11_legality_after.rpt"
check_clock_tree > "${LinkReport}/12_clock_tree_check_after.rpt"
report_clock_tree -summary > "${LinkReport}/13_clock_tree_summary_after.rpt"

# ==============================================================================
# 9. POST-ROUTE EXTRACTION AND TIMING
# ===============================================================================

puts "\n*** POST-ROUTE RC / STA ***\n"

# Extract route-based parasitics before final ICC timing reports.
# SPEF export is handled by export_post_layout.tcl in a later stage.
extract_rc
set_propagated_clock [all_clocks]
update_timing

report_timing -delay max -max_paths 20 > "${LinkReport}/14_setup_after.rpt"
report_timing -delay min -max_paths 20 > "${LinkReport}/15_hold_after.rpt"
report_constraint -all_violators > "${LinkReport}/16_constraint_violators_after.rpt"
report_qor > "${LinkReport}/17_qor_after.rpt"
report_placement_utilization > "${LinkReport}/18_placement_utilization_after.rpt"

# ==============================================================================
# 10. SAVE ROUTED CHECKPOINT
# ===============================================================================

# IMPORTANT: Read 10_verify_zrt_route.rpt and 11_legality_after.rpt.
# A successful TCL run alone does not guarantee DRC=0 or zero open nets.
# If violations exist, investigate them before using this checkpoint for signoff.

puts "\n*** SAVE ROUTING CHECKPOINT ***\n"

save_mw_cel -as mw_mips_route_clean

puts "\n============================================================"
puts " SIGNAL ROUTING SCRIPT COMPLETED"
puts " DESIGN     : $cell_name"
puts " CHECKPOINT : mw_mips_route_clean"
puts " REPORT DIR : $LinkReport"
puts " NEXT STEP  : Check verification and setup/hold reports"
puts "============================================================\n"
