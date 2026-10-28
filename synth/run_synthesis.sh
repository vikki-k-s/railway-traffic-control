#!/bin/bash
#=============================================================================
# GM UNIVERSITY - Hardware Modelling using Verilog (UE25EC2302)
# Logic Synthesis Automation Script using Yosys Open Synthesis Suite
#=============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "============================================================"
echo " Starting Logic Synthesis with Yosys Suite                 "
echo "============================================================"

cd "$PROJECT_ROOT"
yosys -s synth/synth.ys | tee synth/synth_report.txt

echo "============================================================"
echo " Synthesis Finished Successfully!                           "
echo " Gate-level Netlist : synth/railway_level_crossing_synth_netlist.v"
echo " Synthesis Report   : synth/synth_report.txt               "
echo "============================================================"
