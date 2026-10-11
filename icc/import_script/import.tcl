# ==============================================================================
# SCRIPT: 01_import.tcl
# DESIGN: mips_cpu_top
# 
#   - Create Milkyway design database
#   - Load technology / physical reference library
#   - Setup RC corners using TLU+
#   - Setup min/max timing libraries
#   - Import gate-level netlist
#   - Read SDC
#   - Check basic timing 
#   - Lưu checkpoint cho Floorplanning
# ==============================================================================



# ==============================================================================
# 0. DESIGN / PROJECT SETUP
# ==============================================================================


set cell_name "mips_cpu_top"


set SCRIPT_DIR [file dirname [file normalize [info script]]]

set ICC_ROOT [file dirname $SCRIPT_DIR]

# Shared Milkyway database
set my_mw_lib "${ICC_ROOT}/${cell_name}_Lib"

set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"
set LinkProject "../../"

set LinkLibrary_mw "${PDK_ROOT}/process"
set LinkLibrary_db "${PDK_ROOT}/syn_lib/syn_lib"


set LinkNetlist "${LinkProject}/netlist"
set LinkSDC 	"${LinkProject}/netlist"
set LinkReport	"${LinkProject}/report/icc/import"

file mkdir $LinkReport

# ==============================================================================
# 1. TECHNOLOGY / PHYSICAL LIBRARY
# ==============================================================================


set Techfile "${LinkLibrary_mw}/astro/tech/astroTechFile.tf"

set Ref_lib\
	"${LinkLibrary_mw}/astro/fram/saed90nm_fr"
set Tlumax\
	"${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9_1t_Cmax.tluplus"
set Tlumax\
	"${LinkLibrary_mw}/star_rcxt/tluplus/saed90nm_1p9_1t_Cmin.tluplus"

set Tech2itf\
	"${LinkLibrary_mw}/astro/tech/tech2itf.map"


# ==============================================================================
# 2. TIMING LIBRARIES
# ==============================================================================


set MAX_LIB "${LinkLibrary_db}/saed90nm_max.db"
set MIN_LIB "${LinkLibrary_db}/saed90nm_min.db"
set TYP_LIB "${LinkLibrary_db}/saed90nm_typ.db"


#
# flow min/max:
#
#   MAX_LIB -> max-delay / setup side
#   MIN_LIB -> min-delay / hold side
#
#

set target_library [list $MAX_LIB]

set link_library [list \
	*\ 
	$MAX_LIB
]

# ==============================================================================
# 3. Check input file
# ==============================================================================


set NETLIST_FILE "${LinkNetlist}/${cell_name}_NL.v"
set SDC_FILE     "${LinkSDC}/${cell_name}_SDC.sdc"


foreach f [list\
	$Techfile\
	$Ref_lib\	
	$Tlumax\
	$Tlumin\
	$Tech2itf\
	$MAX_LIB\
	$MIN_LIB \
	$TYP_LIB\
	$NETLIST_FILE\
	$SDC_FILE] {


if {![file exists $f]} {
	puts "ERROR: not found:"
        puts "       $f"
        exit 1
	}
}
	
# ==============================================================================
# 4. CREATE MILKYWAY LIBRARY
# ==============================================================================

echo "\n*** CREATE MILKYWAY LIBRARY ***\n"


set RECREATE_MW_LIB 1


if {[file exists $my_mw_lib]} {

    if {$RECREATE_MW_LIB} {

        puts "WARNING: Delete old Milkyway library:"
        puts "         $my_mw_lib"

        file delete -force $my_mw_lib

    } else {

        puts "ERROR: Milkyway library already exists:"
	puts "       $my_mw_lib"
	puts "Set RECREATE_MW_LIB = 1 to recreate it."
	exit 1
    }
}

 
create_mw_lib \
    -technology $Techfile \
    -mw_reference_library $Ref_lib \
    $my_mw_lib

open_mw_lib $my_mw_lib

# ==============================================================================
# 5. RC CORNERS / TLU+
# ==============================================================================

echo "\n*** TLU+ ***\n"

set_tlu_plus_files\
	-max_tluplus $
	-min_tluplus $Tlupmin \
	-tech2itf_map $Tech2itf

check tlu_plus_files\
	>${LinkReport}/import_tluplus_check.rpt

# ==============================================================================
# 6. MIN / MAX TIMING LIBRARY RELATIONSHIP
# ==============================================================================
#
# Max library used to main timing/reference library.
# Min library used to min-delay / hold analysis.
#

set_min_library \
    $MAX_LIB \
    -min_version $MIN_LIB

list_libs \
    > ${LinkReport}/import_libraries.rpt

# ==============================================================================
# 7. IMPORT GATE-LEVEL NETLIST
# ==============================================================================
echo "\n*** IMPORT NETLIST ***\n"

import_designs \
    -format verilog \
    -top $cell_name \
    -cel $cell_name \
    $NETLIST_FILE

current_design $cell_name

# ==============================================================================
# 8. RESOLVE HIERARCHY / LIBRARY REFERENCES
# ==============================================================================
#
#

uniquify

link

uniquify_fp_mw_cel

# ==============================================================================
# 9. READ TIMING CONSTRAINTS
# ==============================================================================

echo "\n*** READ SDC FILE ***\n"

read_sdc $SDC_FILE


# ==============================================================================
# 10. SANITY CHECKS
# ==============================================================================

echo "\n*** CHECK DESIGN / TIMING ***\n"

check_timing \
    > ${LinkReport}/import_check_timing.rpt

report_clock \
    > ${LinkReport}/import_clock.rpt

report_constraint -all_violators \
    > ${LinkReport}/import_constraint_violators.rpt


# ==============================================================================
# 11. SAVE IMPORT CHECKPOINT
# ==============================================================================

save_mw_cel -as "mw_mips_imported"


echo "\n============================================================"
echo " IMPORT COMPLETED"
echo " CHECKPOINT: mw_mips_imported"
echo "============================================================\n"















