#=============================================================================
# GM UNIVERSITY - Hardware Modelling using Verilog (UE25EC2302)
# Project Based Learning: Railway Level Crossing & Train Traffic Controller
# PowerShell Simulation Runner
#=============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Starting Verilog HDL Simulation via WSL Toolchain        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$wslPath = "/mnt/d/Projects/PBL Project"

Write-Host "[1/2] Compiling with Icarus Verilog and Running VVP..." -ForegroundColor Yellow
wsl sh -c "cd '$wslPath' && iverilog -g2005 -o sim/sim.out -I src src/*.v sim/railway_level_crossing_tb.v && vvp sim/sim.out"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[2/2] Simulation Finished Successfully!" -ForegroundColor Green
    Write-Host "VCD Waveform available at: sim\waveform.vcd" -ForegroundColor Green
    Write-Host "You can open this in GTKWave to view full timing traces." -ForegroundColor White
} else {
    Write-Host "`n[!] Simulation Failed with exit code $LASTEXITCODE" -ForegroundColor Red
}
