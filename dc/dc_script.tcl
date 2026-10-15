#path setup

if {![info exists env(ASIC_LIB_PATH)]} {
    puts "ERROR: Environment variable ASIC_LIB_PATH is not set!"
    puts "Please run: export ASIC_LIB_PATH=\"/path/to/your/lib\" before running DC."
    exit 1
}

set LinkProject ".."
set LinkLibrary_db $env(ASIC_LIB_PATH)
set LinkSource "${LinkProject}/rtl"
set LinkReport "${LinkProject}/report/dc"
set LinkNetlist "${LinkProject}/netlist"

#create report folder

file mkdir $LinkReport

#Library setup

define_design_lib WORK -path "work" 
set search_path [list . $LinkLibrary_db $LinkSource]


# Loading Min (Fast), Typ (Typical), and Max (Slow) libraries
set target_library [list saed90nm_min.db saed90nm_typ.db saed90nm_max.db]
set link_library   [list * saed90nm_min.db saed90nm_typ.db saed90nm_max.db]


#read design
analyze -format verilog [glob $LinkSource/*.v]
elaborate mips_cpu_top
current_design mips_cpu_top
uniquify
check_design > ${LinkReport}/synth_check_design.rpt

#operating condition - best to worst analysis
set_min_library "saed90nm_max.db" -min_version "saed90nm_min.db"
set_operating_conditions -min BEST -max WORST

#timing constraints
set design "mips_cpu_top"
set time_scale 20 ;# 50MHz
set tran [expr (0.05 * $time_scale)]
set delay_in [expr (0.2 * $time_scale)]
set delay_out [expr (0.2 * $time_scale)]

#clock constraint
create_clock -period $time_scale -waveform "0 [expr $time_scale / 2.0]" [get_ports clock]
set_clock_uncertainty $tran [get_clocks clock]
set_clock_latency $tran [get_clocks clock] 
set_clock_transition $tran [get_clocks clock]

#I/O constraints
set_input_delay $delay_in [all_inputs] -clock clock
set_output_delay $delay_out  [all_outputs] -clock clock

#compile 
compile -area_effort medium -map_effort medium

#report & export
report_area > ${LinkReport}/${design}_synth_area.rpt
report_cell > ${LinkReport}/${design}_synth_cell.rpt
report_qor  > ${LinkReport}/${design}_synth_qor.rpt
report_resources > ${LinkReport}/${design}_synth_resources.rpt

write_sdc ${LinkNetlist}/${design}_SDC.sdc
write -hierarchy -format verilog -output ${LinkNetlist}/${design}_NL.v
write -format ddc -hierarchy -output ${LinkNetlist}/${design}_NL.ddc

exit
