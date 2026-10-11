#!/bin/bash

echo "================================================="
echo " STAGE 1: CLEANING OLD FILES"
echo "================================================="
rm -rf simv simv.daidir csrc ucli.key *.log *.vpd *.fsdb DVEfiles/ simv.vdb/ urgReport/

echo "================================================="
echo " STAGE 2: COMPILING RTL WITH COVERAGE"
echo "================================================="
vcs -debug_pp +v2k -f list.txt -cm line+cond+fsm+tgl -l compile.log

echo "================================================="
echo " STAGE 3: RUNNING SIMULATION & COLLECTING DATA"
echo "================================================="
if [ -f "simv" ]; then
    ./simv -l sim.log -cm line+cond+fsm+tgl
    
    echo "================================================="
    echo " STAGE 4: GENERATING PLAIN TEXT COVERAGE REPORT"
    echo "================================================="
    # -format text forces it to skip HTML. 
    urg -dir simv.vdb -format text
    
    # Print the final score summary directly to the terminal
    echo "--- COVERAGE DASHBOARD SUMMARY ---"
    cat urgReport/dashboard.txt
else
    echo "=> Compilation FAILED! Check compile.log"
    exit 1
fi
