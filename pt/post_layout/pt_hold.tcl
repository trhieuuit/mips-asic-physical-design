# ==============================================================================
# SCRIPT: pt_hold.tcl
# DESIGN: mips_cpu_top
# TOOL  : Synopsys PrimeTime D-2010.06-SP2
# STAGE : Post-layout HOLD / MIN STA (read-only analysis; no ECO)
# ==============================================================================

puts "\n============================================================"
puts " PRIME TIME POST-LAYOUT HOLD / MIN STA"
puts "============================================================\n"

# ==============================================================================
# 0. PROJECT PATHS
# ==============================================================================
set DESIGN "mips_cpu_top"
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set PT_ROOT [file dirname $SCRIPT_DIR]
set PROJECT_ROOT [file dirname $PT_ROOT]
set PDK_ROOT "/home/ltk/ASIC_LIB/Lib"
set LIB_DIR "${PDK_ROOT}/syn_lib/syn_lib"
set REPORT_DIR "${PROJECT_ROOT}/report/pt/post_layout"
file mkdir $REPORT_DIR

set NETLIST "${PROJECT_ROOT}/netlist/${DESIGN}_post_layout.v"
set SDC "${PROJECT_ROOT}/sdc/${DESIGN}_post_layout.sdc"
set SPEF_MIN "${PROJECT_ROOT}/parasitic/${DESIGN}_post_layout.spef.min"
set MIN_LIB "${LIB_DIR}/saed90nm_min.db"

# ==============================================================================
# 1. CHECK INPUT FILES
# ==============================================================================
foreach f [list $NETLIST $SDC $SPEF_MIN $MIN_LIB] {
    if {![file exists $f] || ![file readable $f]} {
        puts "ERROR: Missing or unreadable input file: $f"
        exit 1
    }
    puts "FOUND: $f"
}

# ==============================================================================
# 2. LIBRARY / LINK / NETLIST
# ==============================================================================
set search_path [list "." $LIB_DIR]
set link_path [list "*" $MIN_LIB]

puts "\n*** READ MIN LIBRARY + POST-LAYOUT NETLIST ***\n"
read_verilog $NETLIST
current_design $DESIGN
link_design $DESIGN

# ==============================================================================
# 3. CONSTRAINTS AND MIN OPERATING CONDITION
# ==============================================================================
puts "\n*** READ SDC ***\n"
read_sdc $SDC

# SAED90nm MIN library is analyzed at BEST operating condition.
set_operating_conditions BEST

# Post-CTS clock delays are calculated through the clock tree.
set_propagated_clock [all_clocks]

# ==============================================================================
# 4. MIN PARASITICS
# ==============================================================================
puts "\n*** READ MIN SPEF ***\n"
read_parasitics -format spef $SPEF_MIN
report_annotated_parasitics > "${REPORT_DIR}/hold_annotated_parasitics.rpt"

# ==============================================================================
# 5. UPDATE TIMING AND REPORTS
# ==============================================================================
puts "\n*** CHECK / UPDATE TIMING ***\n"
check_timing -verbose > "${REPORT_DIR}/hold_check_timing.rpt"
update_timing
report_clock > "${REPORT_DIR}/hold_clock.rpt"

puts "\n*** OVERALL HOLD (MIN) ***\n"
report_timing -delay_type min -max_paths 20 > "${REPORT_DIR}/post_layout_holdtiming.rpt"

# The four classic path categories.
report_timing -delay_type min -max_paths 20 -from [all_inputs] -to [all_registers -data_pins] > "${REPORT_DIR}/hold_input_to_register.rpt"
report_timing -delay_type min -max_paths 20 -from [all_registers -clock_pins] -to [all_registers -data_pins] > "${REPORT_DIR}/hold_register_to_register.rpt"
report_timing -delay_type min -max_paths 20 -from [all_registers -clock_pins] -to [all_outputs] > "${REPORT_DIR}/hold_register_to_output.rpt"
report_timing -delay_type min -max_paths 20 -from [all_inputs] -to [all_outputs] > "${REPORT_DIR}/hold_input_to_output.rpt"

# Optional detail: net delay, capacitance, slew.
report_timing -delay_type min -max_paths 20 -transition_time -capacitance -nets -input_pins > "${REPORT_DIR}/hold_transition_capacitance.rpt"
report_constraint -all_violators > "${REPORT_DIR}/hold_constraint_violators.rpt"

# Print the worst paths to the console, not just to files.
report_timing -delay_type min -max_paths 3

puts "\n============================================================"
puts " POST-LAYOUT HOLD STA COMPLETED"
puts " MIN library: $MIN_LIB"
puts " MIN SPEF   : $SPEF_MIN"
puts " Reports    : $REPORT_DIR"
puts "============================================================\n"

# When running batch mode with 'pt_shell -f pt_hold.tcl', uncomment:
# exit
