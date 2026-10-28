#!/bin/bash
#=============================================================================
# GM UNIVERSITY - Hardware Modelling using Verilog (UE25EC2302)
# Project Based Learning: Railway Level Crossing & Train Traffic Controller
# Automation Script: Compile & Run Icarus Verilog Simulation
#=============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "============================================================"
echo " Starting Verilog HDL Simulation (Icarus Verilog 12.0)     "
echo "============================================================"

cd "$PROJECT_ROOT"

# Step 1: Compile all source files and testbench
echo "[1/3] Compiling RTL and Testbench..."
iverilog -g2005 -o sim/sim.out -I src src/*.v sim/railway_level_crossing_tb.v

# Step 2: Execute VVP simulation engine
echo "[2/3] Executing Simulation with VVP..."
vvp sim/sim.out

# Step 3: Check VCD waveform output
if [ -f "sim/waveform.vcd" ]; then
    echo "[3/3] Success! VCD Waveform generated at: sim/waveform.vcd"
    echo "To view in GTKWave, run: gtkwave sim/waveform.vcd &"
else
    echo "[!] Warning: Waveform VCD file was not generated."
fi

echo "============================================================"
echo " Simulation Completed Successfully!                        "
echo "============================================================"
