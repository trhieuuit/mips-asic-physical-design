
# --- 1. ENVIRONMENT SETUP ---
if {![info exists env(ASIC_LIB_PATH)]} {
    puts "ERROR: Environment variable ASIC_LIB_PATH is not set!"
    puts "Please run: export ASIC_LIB_PATH=\"/path/to/your/lib\" first."
    exit 1
}

set TOP_MODULE  "mips_cpu_top"

# Adjusted paths: Go up two levels from fm/post_syn/ to reach the root MIPS folder
set PROJECT_DIR "../.."
set RTL_DIR     "$PROJECT_DIR/rtl"
set NETLIST_DIR "$PROJECT_DIR/netlist"

set TARGET_LIB  "$env(ASIC_LIB_PATH)/saed90nm_typ.db"

# --- 2. LOAD TECHNOLOGY LIBRARY ---
echo "\n*** STAGE 1: Loading 90nm Library ***\n"
read_db $TARGET_LIB

# --- 3. LOAD REFERENCE DESIGN (The Golden RTL) ---
echo "\n*** STAGE 2: Loading Reference RTL ***\n"
read_verilog -r [glob $RTL_DIR/*.v]
set_top r:/WORK/$TOP_MODULE

# --- 4. LOAD IMPLEMENTATION DESIGN (The Gate Netlist) ---
echo "\n*** STAGE 3: Loading Synthesized Netlist ***\n"
read_verilog -i $NETLIST_DIR/${TOP_MODULE}_NL.v
set_top i:/WORK/$TOP_MODULE

# --- 5. MATCH AND VERIFY ---
echo "\n*** STAGE 4: Matching Compare Points ***\n"
match

echo "\n*** STAGE 5: Verifying Logic Equivalence ***\n"
verify

echo "\n*** FORMALITY CHECK COMPLETE ***\n"
exit
