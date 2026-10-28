#=============================================================================
# GM UNIVERSITY - Hardware Modelling using Verilog (UE25EC2302)
# Logic Synthesis Automation Script using Yosys in WSL
#=============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Running Logic Synthesis (Unit 6 Coverage) with Yosys       " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$wslPath = "/mnt/d/Projects/PBL Project"
wsl sh -c "cd '$wslPath' && yosys -s synth/synth.ys | tee synth/synth_report.txt"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[+] Synthesis Completed!" -ForegroundColor Green
    Write-Host "Gate-level Netlist generated: synth\railway_level_crossing_synth_netlist.v" -ForegroundColor Green
    Write-Host "Synthesis Report generated  : synth\synth_report.txt" -ForegroundColor Green
} else {
    Write-Host "`n[!] Synthesis Encountered Errors." -ForegroundColor Red
}
