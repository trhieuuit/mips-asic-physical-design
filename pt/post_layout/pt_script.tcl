# ==========================================================================
# PRIME TIME POST-LAYOUT (STA) SCRIPT FOR MIPS CPU 
# ==========================================================================

# --- 1. ENVIRONMENT SETUP ---
if {![info exists env(ASIC_LIB_PATH)]} {
    puts "ERROR: Environment variable ASIC_LIB_PATH is not set!"
    puts "Please run: export ASIC_LIB_PATH=\"/path/to/your/lib\" first."
    exit 1
}

set design "mips_cpu_top"

# Set paths relative to your 'pt' directory
set LinkProject "../.."
set LinkLibrary_db $env(ASIC_LIB_PATH)
set LinkNetlist "${LinkProject}/netlist"  ;# Assumes ICC saves post-layout netlist here
set LinkSDC "${LinkProject}/netlist"      ;# Assumes ICC saves post-layout SDC here
set LinkSPEF "${LinkProject}/netlist"     ;# Assumes ICC saves SPEF file here
set LinkReport "${LinkProject}/report/pt_post_layout"

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
echo "\n*** STAGE 1: Reading Post-Layout Netlist ***\n"
# [SỬA]: Đọc file netlist xuất ra từ IC Compiler
read_verilog ${LinkNetlist}/${design}_post_layout.v
current_design $design
link

echo "\n*** STAGE 2: Applying Post-Layout Constraints ***\n"
# [SỬA]: Đọc SDC xuất ra từ ICC (chứa thông tin propagated clock sau khi chạy CTS)
read_sdc ${LinkSDC}/${design}_post_layout.sdc

# --- 4. READ PARASITICS (THE MOST IMPORTANT STEP) ---
echo "\n*** STAGE 3: Reading Parasitics (RC) ***\n"
# [THÊM MỚI]: Nạp file .spef để tính toán độ trễ dây dẫn thực tế
read_parasitics ${LinkSPEF}/${design}.spef.min

# --- 5. ECO HOLD FIXING ---
# Ghi chú: Ở giai đoạn Post-Layout, nếu Hold vi phạm, ICC thường đã fix. 
# Chạy lệnh này trên PT chỉ để thử nghiệm (what-if analysis) trước khi quay lại ICC chèn buffer.
echo "\n*** STAGE 4: Testing ECO Hold Time Fixes ***\n"
fix_eco_timing -type hold -buffer_list {NBUFFX2 NBUFFX4 NBUFFX8 NBUFFX16 NBUFFX32}

# --- 6. GENERATE REPORTS ---
echo "\n*** STAGE 5: Generating Timing Reports ***\n"

# Report the 4 classic paths (Thêm tiền tố "post_layout_" để khỏi ghi đè file cũ)
report_timing -max_paths 20 -from [all_inputs] -to [all_registers -data_pins] > ${LinkReport}/post_layout_inputstoflops.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/post_layout_floptoflop.rpt
report_timing -max_paths 20 -from [all_registers -clock_pins] -to [all_outputs] > ${LinkReport}/post_layout_floptoputputs.rpt
report_timing -max_paths 20 -from [all_inputs] -to [all_outputs] > ${LinkReport}/post_layout_inputstooutputs.rpt

# Report overall Setup (Max) and Hold (Min)
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type max > ${LinkReport}/post_layout_setuptiming.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -delay_type min > ${LinkReport}/post_layout_holdtiming.rpt

# Report Physical Transitions and Capacitance
report_timing -transition_time -capacitance -nets -input_pins -from [all_registers -clock_pins] -to [all_registers -data_pins] > ${LinkReport}/post_layout_tran_captiming.rpt

echo "\n*** PRIMETIME POST-LAYOUT SIGN-OFF COMPLETE ***\n"
exit
