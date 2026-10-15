###################################################################
# MIPS CPU - Base Timing Constraints
# Design : mips_cpu_top
#
# Used for:
#   - Synthesis
#   - ICC Import
#   - Placement
#   - CTS
#   - Routing
#
# Clock period : 20 ns = 50 MHz
# Reset        : Asynchronous, Active-High
###################################################################

set sdc_version 1.8


# ==================================================================
# 1. UNITS
# ==================================================================

set_units \
    -time ns \
    -resistance MOhm \
    -capacitance fF \
    -voltage V \
    -current uA


# ==================================================================
# 2. OPERATING CONDITIONS
# ==================================================================

set_operating_conditions \
    -max WORST \
    -max_library saed90nm_max \
    -min BEST \
    -min_library saed90nm_min


# ==================================================================
# 3. CLOCK
# ==================================================================

# 20 ns period = 50 MHz
create_clock \
    -name clock \
    -period 20 \
    -waveform {0 10} \
    [get_ports clock]


# ------------------------------------------------------------------
# Clock uncertainty
#
# Setup margin : 1.0 ns
# Hold margin  : 0.1 ns
#
# ------------------------------------------------------------------

set_clock_uncertainty \
    -setup 1.0 \
    [get_clocks clock]

set_clock_uncertainty \
    -hold 0.1 \
    [get_clocks clock]


# ------------------------------------------------------------------
# Clock source transition
#
# 0.1 ns is an assumed source slew for this project.
# ------------------------------------------------------------------

set_clock_transition \
    -rise 0.1 \
    [get_clocks clock]

set_clock_transition \
    -fall 0.1 \
    [get_clocks clock]


# ==================================================================
# 4. ASYNCHRONOUS RESET
# ==================================================================

# reset is asynchronous active-high.
#
# For normal functional STA:
#   reset = 0 -> inactive
#
# Do NOT apply set_input_delay to reset.

set_case_analysis 0 [get_ports reset]


# ==================================================================
# 5. DATA INPUTS
# ==================================================================

set DATA_INPUT_PORTS \
    [get_ports {Inst* Dout*}]


# ------------------------------------------------------------------
# Input delay
#
# 4 ns is an external-interface assumption for this project.
# Using the same value for min/max preserves the behavior of the
# original project constraint.
#
# If real interface timing becomes available later, replace these
# with actual -max and -min values.
# ------------------------------------------------------------------

set_input_delay \
    -max \
    -clock [get_clocks clock] \
    4.0 \
    $DATA_INPUT_PORTS

set_input_delay \
    -min \
    -clock [get_clocks clock] \
    4.0 \
    $DATA_INPUT_PORTS


# Input slew assumption
set_input_transition \
    0.1 \
    $DATA_INPUT_PORTS


# ==================================================================
# 6. DATA OUTPUTS
# ==================================================================

set DATA_OUTPUT_PORTS \
    [get_ports {PC* Addr* Din* MemRead MemWrite}]


# ------------------------------------------------------------------
# Output delay
#
# Maximum output delay = 4 ns.
#
# For this personal project, use 0 ns as a simple hold-side
# external requirement instead of accidentally applying +4 ns
# to both max and min.
# ------------------------------------------------------------------

set_output_delay \
    -max \
    -clock [get_clocks clock] \
    4.0 \
    $DATA_OUTPUT_PORTS

set_output_delay \
    -min \
    -clock [get_clocks clock] \
    0.0 \
    $DATA_OUTPUT_PORTS


###################################################################
# END OF BASE SDC
###################################################################
