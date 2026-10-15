# ==============================================================================
# SCRIPT: placement.tcl
# DESIGN: mips_cpu_top
# Standard Cell Placement + Pre-CTS Optimization
# ==============================================================================

echo "\n============================================================"
echo "PLACEMENT"
echo "============================================================\n"


# ==============================================================================
# 0. PROJECT SETUP
# ==============================================================================

set cell_name "mips_cpu_top"

# .../icc/placement/placement.tcl
set SCRIPT_DIR   [file dirname [file normalize [info script]]]

# .../icc
set ICC_ROOT     [file dirname $SCRIPT_DIR]

set PROJECT_ROOT [file dirname $ICC_ROOT]

# Shared Milkyway library
set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

# PDK
set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"

# Report
set LinkReport "${PROJECT_ROOT}/report/icc/placement"
file mkdir $LinkReport


# ==============================================================================
# 1. TIMING LIBRARIES
# ==============================================================================

set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"
set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"

set target_library [list $MAX_LIB]

set link_library [list \
    * \
    $MAX_LIB \
]


# ==============================================================================
# 2. RC / TLU+ SETUP
# ==============================================================================

set Tlupmax \
    "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"

set Tlupmin \
    "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"

set Tech2itf \
    "${LinkLibrary_mw}/astro/tech/tech2itf.map"


# ==============================================================================
# 3. OPEN FLOORPLAN CHECKPOINT
# ==============================================================================

echo "\n*** MỞ CHECKPOINT FLOORPLAN ***\n"

open_mw_lib $my_mw_lib

open_mw_cel "mw_mips_floorplan_done"

current_design $cell_name


# ==============================================================================
# 4. RESTORE TIMING / RC ENVIRONMENT
# ==============================================================================

set_min_library \
    $MAX_LIB \
    -min_version $MIN_LIB

set_tlu_plus_files \
    -max_tluplus $Tlupmax \
    -min_tluplus $Tlupmin \
    -tech2itf_map $Tech2itf

link


# ==============================================================================
# 5. PRE-PLACEMENT CHECKS
# ==============================================================================

echo "\n*** PRE-PLACEMENT CHECK ***\n"

check_tlu_plus_files \
    > ${LinkReport}/placement_tluplus_check.rpt

check_timing \
    > ${LinkReport}/placement_check_timing_before.rpt

report_clock \
    > ${LinkReport}/placement_clock.rpt

check_physical_design -stage pre_place_opt \
    > ${LinkReport}/placement_pre_place_check.rpt


# ==============================================================================
# 6. BASELINE REPORT BEFORE PLACEMENT
# ==============================================================================

echo "\n*** BASELINE REPORT BEFORE PLACEMENT ***\n"

report_timing -delay max \
    > ${LinkReport}/placement_before_setup.rpt

report_timing -delay min \
    > ${LinkReport}/placement_before_hold.rpt

report_constraint -all_violators \
    > ${LinkReport}/placement_before_constraints.rpt


# ==============================================================================
# 7. STANDARD CELL PLACEMENT + OPTIMIZATION
# ==============================================================================

echo "\n*** RUN PLACE_OPT ***\n"

place_opt -congestion -effort high


# ==============================================================================
# 8. POST-PLACEMENT LEGALITY CHECK
# ==============================================================================

echo "\n*** POST-PLACEMENT LEGALITY CHECK ***\n"

check_legality \
    > ${LinkReport}/placement_legality.rpt


# ==============================================================================
# 9. POST-PLACEMENT TIMING REPORTS
# ==============================================================================

echo "\n*** POST-PLACEMENT TIMING REPORTS ***\n"

report_timing -delay max \
    > ${LinkReport}/placement_setup.rpt

report_timing -delay min \
    > ${LinkReport}/placement_hold.rpt

report_constraint -all_violators \
    > ${LinkReport}/placement_constraint_violators.rpt

report_qor \
    > ${LinkReport}/placement_qor.rpt


# ==============================================================================
# 10. UTILIZATION / CONGESTION REPORT
# ==============================================================================

report_placement_utilization \
    > ${LinkReport}/placement_utilization.rpt

report_congestion \
    > ${LinkReport}/placement_congestion.rpt


# ==============================================================================
# 11. CHECK READY FOR CTS
# ==============================================================================

echo "\n*** PRE-CTS PHYSICAL CHECK ***\n"

check_physical_design -stage pre_clock_opt \
    > ${LinkReport}/placement_pre_cts_check.rpt


# ==============================================================================
# 12. SAVE PLACEMENT CHECKPOINT
# ==============================================================================

save_mw_cel -as "mw_mips_placed"


echo "\n============================================================"
echo " PLACEMENT COMPLETED"
echo " CHECKPOINT: mw_mips_placed"
echo "============================================================\n"
