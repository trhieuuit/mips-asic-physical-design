# ==========================================================================
# PRIME TIME (STA) SCRIPT FOR MIPS CPU (Based on Lecturer's Standard)
# ==========================================================================

# --- 1. ENVIRONMENT SETUP ---
if {![info exists env(ASIC_LIB_PATH)]} {
    puts "ERROR: Environment variable ASIC_LIB_PATH is not set!"
    puts "Please run: export ASIC_LIB_PATH=\"/path/to/your/lib\" first."
    exit 1
}

set design "mips_cpu_top"

# Set paths relative to your 'pt' directory (going up one level to the MIPS root)
set LinkProject "../../"
set LinkLibrary_db $env(ASIC_LIB_PATH)
set LinkNetlist "${LinkProject}/netlist"
set LinkSDC "${LinkProject}/netlist"  ;# DC saved the SDC file in the netlist folder
set LinkReport "${LinkProject}/report/pt"

# Create the report folder if it does not exist
file mkdir $LinkReport

# --- 2. LIBRARY SETUP ---
set link_library [list * ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

set target_library [list ${LinkLibrary_db}/saed90nm_min.db \
                         ${LinkLibrary_db}/saed90nm_typ.db \
                         ${LinkLibrary_db}/saed90nm_max.db]

# --- 3. READ NETLIST & CONSTRAINTS ---
echo "\n*** STAGE 1: Reading Gate-Level Netlist ***\n"
read_verilog ${LinkNetlist}/${design}_NL.v
current_design $design
link

echo "\n*** STAGE 2: Applying DC Timing Constraints ***\n"
read_sdc ${LinkSDC}/${design}_SDC.sdc

# --- 4. ECO HOLD FIXING ---
echo "\n*** STAGE 3: Testing ECO Hold Time Fixes ***\n"
fix_eco_timing -type hold -buffer_list {NBUFFX2 NBUFFX4 NBUFFX8 NBUFFX16 NBUFFX32}

# --- 5. GENERATE REPORTS ---
echo "\n*** STAGE 4: Generating Timing Reports ***\n"

# Report the 4 classic paths
report_timing -max_paths 20 -from [all_inputs] -to [all_registers -data_pins] > ${LinkReport}/inputstoflops.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/floptoflop.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_outputs] > ${LinkReport}/floptoputputs.rpt
report_timing -max_paths 20 -from [all_inputs] -to [all_outputs] > ${LinkReport}/inputstooutputs.rpt

# Report overall Setup (Max) and Hold (Min)
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max > ${LinkReport}/setuptiming.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type min > ${LinkReport}/holdtiming.rpt

# Report Physical Transitions and Capacitance
report_timing -transition_time -capacitance -nets -input_pins -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/tran_captiming.rpt

echo "\n*** PRIMETIME SIGN-OFF COMPLETE ***\n"
exit
