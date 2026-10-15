# ====================================================================
# export_post_layout.tcl
# Export routed design for PrimeTime post-layout STA
#
# Outputs:
#   1. Post-layout Verilog netlist
#   2. Post-layout SDC
#   3. SPEF parasitic file
# ====================================================================

echo "\n============================================================"
echo " START POST-LAYOUT EXPORT"
echo "============================================================\n"


# ==============================================================================
# 0. PROJECT SETUP
# ==============================================================================

set cell_name "mips_cpu_top"

# .../icc/routing_script/export_post_layout.tcl
set SCRIPT_DIR [file dirname [file normalize [info script]]]

# .../icc
set ICC_ROOT [file dirname $SCRIPT_DIR]

# .../full_flow_test
set PROJECT_ROOT [file dirname $ICC_ROOT]

# Shared Milkyway library
set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

# Output directories
set NETLIST_DIR   "${PROJECT_ROOT}/netlist"
set SDC_DIR       "${PROJECT_ROOT}/sdc"
set PARASITIC_DIR "${PROJECT_ROOT}/parasitic"

file mkdir $NETLIST_DIR
file mkdir $SDC_DIR
file mkdir $PARASITIC_DIR


# ==============================================================================
# 1. LIBRARY SETUP
# ==============================================================================

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"

set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"
set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"

set target_library [list $MAX_LIB]
set link_library   [list * $MAX_LIB]


# ==============================================================================
# 2. TLU+ SETUP
# ==============================================================================

set Tlupmax "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmax.tluplus"
set Tlupmin "${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9m_1t_Cmin.tluplus"

set Tech2itf "${LinkLibrary_mw}/astro/tech/tech2itf.map"


# ==============================================================================
# 3. OPEN ROUTED DESIGN
# ==============================================================================

open_mw_lib $my_mw_lib
open_mw_cel mw_mips_setup_eco_best

current_design $cell_name

set_min_library $MAX_LIB -min_version $MIN_LIB

set_tlu_plus_files -max_tluplus $Tlupmax -min_tluplus $Tlupmin -tech2itf_map $Tech2itf

link


# ==============================================================================
# 4. CHECK DESIGN BEFORE EXPORT
# ==============================================================================

check_tlu_plus_files
check_timing
check_legality
verify_zrt_route


# ==============================================================================
# 5. EXTRACT POST-ROUTE RC
# ==============================================================================

extract_rc


# ==============================================================================
# 6. WRITE SPEF
# ==============================================================================

write_parasitics -format SPEF -no_name_mapping -output "${PARASITIC_DIR}/${cell_name}_post_layout.spef"


# ==============================================================================
# 7. WRITE POST-LAYOUT VERILOG NETLIST
# ==============================================================================

write_verilog "${NETLIST_DIR}/${cell_name}_post_layout.v"


# ==============================================================================
# 8. WRITE POST-LAYOUT SDC
# ==============================================================================

#write_sdc "${SDC_DIR}/${cell_name}_post_layout.sdc"


# ==============================================================================
# 9. DONE
# ==============================================================================

echo ""
echo "============================================================"
echo " POST-LAYOUT EXPORT COMPLETED"
echo "============================================================"

echo "Netlist:"
echo "  ${NETLIST_DIR}/${cell_name}_post_layout.v"

echo ""
echo "SDC:"
echo "  ${SDC_DIR}/${cell_name}_post_layout.sdc"

echo ""
echo "SPEF:"
echo "  ${PARASITIC_DIR}/${cell_name}_post_layout.spef"

echo "============================================================"
