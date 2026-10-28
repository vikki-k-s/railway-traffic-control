# 🚆 Railway Level Crossing & Train Traffic Controller
### Hardware Modelling using Verilog (Course Code: UE25EC2302)
**GM University | Faculty of Engineering & Technology | Department of Electronics & Communication Engineering**  
*Semester: 3 | Total Marks: 40 | PBL Timeline: 14 Weeks*

---

[![Verilog HDL](https://img.shields.io/badge/HDL-Verilog%202005-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Simulation](https://img.shields.io/badge/Simulation-Icarus%20Verilog%2012.0-success.svg)](http://iverilog.icarus.com/)
[![Synthesis](https://img.shields.io/badge/Synthesis-Yosys%200.52-orange.svg)](https://yosyshq.net/yosys/)
[![GUI](https://img.shields.io/badge/Web%20Dashboard-Localhost%3A3000-brightgreen.svg)](#-interactive-web-scada-cockpit--live-simulation)
[![Tests](https://img.shields.io/badge/Verification%20Tests-5%2F5%20Passed-emerald.svg)](#-verification-test-suite--simulation-results)

---

## 📖 Executive Summary
Railway level crossings present severe collision hazards when operated manually or left unmanned. This project delivers an automated, fail-safe digital hardware controller designed and implemented in **Verilog HDL**. 

The system detects approaching and departing trains via debounced track sensors, automatically orchestrates motorized crossing barriers ($90^\circ$ to $0^\circ$), coordinates multi-lane road traffic lights and pedestrian signals, displays fail-safe railway track aspects (interlocking), and prioritizes emergency conditions (track obstacles, manual emergency stop, and emergency vehicle preemption).

The hardware architecture covers all six academic units of **UE25EC2302 (Hardware Modelling using Verilog)** and has been validated through automated self-checking testbenches, GTKWave waveform generation, and gate-level logic synthesis via Yosys.

---

## 🕹️ Interactive Web SCADA Cockpit & Live Simulation

An interactive HTML5/Tailwind SCADA control cockpit with authentic railway audio buzzer synthesis and real-time barrier animation is included in `gui/index.html`.

### Running on Localhost:
```bash
# Start the local server on port 3000:
python3 -m http.server 3000 --directory gui
```
👉 **Open in your browser:** [http://localhost:3000](http://localhost:3000)

#### Features:
- **Station Master & Gateman Login Portal:** Authenticate using Station ID (`GMU-DVG-LC42`) and PIN `1234` or click quick one-click demo presets.
- **Physical Level Crossing Visualizer:** Real-time barrier motor animation ($90^\circ \leftrightarrow 0^\circ$), train traversal on rails, road lights, and crossbuck wig-wag flashers.
- **Synthesized Web Audio Buzzer:** Realistic audible dual-tone warning buzzer and high-pitch emergency siren.
- **Interactive Stimulus Buttons:** Inject train arrivals, track zone occupancy, departure, stalled vehicles on tracks, and manual forced opening tamper tests.
- **Live Verilog Telemetry Stream:** Real-time event log mirroring the hardware FSM states.

---

## 🏛️ Syllabus Coverage Matrix (Units 1 to 6)

| Unit | Syllabus Objective | Hardware Module | Implementation Highlights |
|:---:|:---|:---|:---|
| **Unit 1** | **Hierarchical Design & Top-Down Modelling** | [`src/railway_level_crossing_top.v`](src/railway_level_crossing_top.v) | Structural instantiation of all 5 submodules, named port mapping (`.port(signal)`), parameter overrides. |
| **Unit 2** | **Modules, Ports & Gate-Level Modelling** | [`src/gate_safety_interlock.v`](src/gate_safety_interlock.v) | Built strictly using built-in primitive logic gates (`and`, `or`, `not`, `buf`). Hardware failsafe physically preventing barrier opening whenever a train or danger exists. |
| **Unit 3** | **Dataflow & Behavioural Modelling** | [`src/traffic_light_controller.v`](src/traffic_light_controller.v)<br>[`src/gate_controller.v`](src/gate_controller.v) | Continuous assignments (`assign`) with bitwise/ternary operators for road & train lights; clock-edge procedural blocks (`always @(posedge clk)`), non-blocking assignments (`<=`), and FSM `case` statements. |
| **Unit 4** | **Tasks, Functions & Multitasking** | [`src/train_detection.v`](src/train_detection.v)<br>[`src/gate_controller.v`](src/gate_controller.v)<br>[`sim/railway_level_crossing_tb.v`](sim/railway_level_crossing_tb.v) | Reusable `function check_sensor_validity` for diagnostic checking; `task update_barrier_position` for angular motor stepping; concurrent `fork...join` in testbench for asynchronous multitasking. |
| **Unit 5** | **Useful Techniques & System Tasks** | [`src/emergency_warning_module.v`](src/emergency_warning_module.v)<br>[`sim/railway_level_crossing_tb.v`](sim/railway_level_crossing_tb.v) | Parameters, localparams, loops, and system tasks: `$dumpfile`, `$dumpvars`, `$monitor`, `$display`, `$time`, `$finish`. |
| **Unit 6** | **Logic Synthesis & Gate-Level Netlist** | [`synth/synth.ys`](synth/synth.ys)<br>[`synth/railway_level_crossing_synth_netlist.v`](synth/railway_level_crossing_synth_netlist.v) | Complete synthesis via Yosys 0.52 to 287 standard logic cells with zero inferred latches. |

---

## 📐 System Architecture & Hardware Interlocking

```
                                   railway_level_crossing_top
                                                |
        +---------------------------------------+---------------------------------------+
        |                                       |                                       |
+-------v-------+                       +-------v-------+                       +-------v-------+
|train_detection|                       |gate_controller|                       |emergency_warn |
| - Debouncing  |                       | - FSM Moore   |                       | - Buzzer PWM  |
| - Up/Down Line|                       | - Angular Step|                       | - Wig-Wag LEDs|
| - Diagnostics |                       | - Lead Warning|                       | - Priority Enc|
+-------+-------+                       +-------+-------+                       +-------+-------+
        |                                       |                                       |
        +-------------------+-------------------+---------------------------------------+
                            |
                 +----------v------------+
                 | gate_safety_interlock | <--- Hardware Failsafe (Unit 2 Gate Primitives)
                 | - AND / OR / NOT / BUF|
                 | - Physical Clamp Lock |
                 +----------+------------+
                            |
                 +----------v------------+
                 |traffic_light_control  |
                 | - Road: R / Y / G     |
                 | - Ped: Walk / Don't   |
                 | - Train Aspect: R / G |
                 +-----------------------+
```

### Gate Controller Finite State Machine (FSM):
- **`ST_OPEN` ($90^\circ$):** Road traffic is Green; Train signal is Red; Barrier fully vertical.
- **`ST_CLOSING` ($90^\circ \to 0^\circ$):** Pre-closure warning delay expires; road light turns Yellow/Red; motor steps barrier down.
- **`ST_CLOSED` ($0^\circ$):** Barrier locked down; road is solid Red; train aspect switches to **GREEN (PROCEED)**.
- **`ST_OPENING` ($0^\circ \to 90^\circ$):** Train clears exit sensor; post-clearance safety buffer satisfies; motor raises barrier.

---

## 📁 Repository Directory Structure

```
.
├── src/                               # Synthesizable Verilog HDL Source Files
│   ├── train_detection.v              # Sensor filtering, approach/clearance detection
│   ├── gate_safety_interlock.v        # Unit 2: Pure gate-level primitive interlock
│   ├── gate_controller.v              # Unit 3/4/5: FSM barrier controller & motor drive
│   ├── traffic_light_controller.v     # Unit 3: Dataflow road, ped & railway signals
│   ├── emergency_warning_module.v     # Unit 3/5: Audio tone buzzer, wig-wag LEDs
│   └── railway_level_crossing_top.v   # Unit 1: Top-level hierarchical integration
│
├── sim/                               # Simulation & Waveform Verification
│   ├── railway_level_crossing_tb.v    # Self-checking testbench (5 test scenarios)
│   ├── run_simulation.ps1             # 1-Click PowerShell simulation script
│   ├── run_simulation.sh              # 1-Click Bash simulation script
│   └── waveform.vcd                   # Simulation trace dump for GTKWave
│
├── synth/                             # Unit 6: Logic Synthesis (Yosys)
│   ├── synth.ys                       # Yosys synthesis script
│   ├── run_synthesis.ps1              # 1-Click PowerShell synthesis script
│   ├── run_synthesis.sh               # 1-Click Bash synthesis script
│   ├── railway_level_crossing_synth_netlist.v  # Gate-level synthesized netlist
│   └── synth_report.txt               # Synthesis statistics (287 standard cells)
│
├── gui/                               # Interactive Web SCADA Dashboard
│   └── index.html                     # Self-contained Web visualizer with Audio & Login
│
├── docs/                              # Project Documentation
│   ├── PBL_Project_Report.md          # 12-Page IEEE-standard Project Report
│   └── Viva_Voce_QnA.md               # 13 high-yield Viva questions & answers
│
└── README.md                          # Repository Documentation
```

---

## 🚀 How to Run Simulation & Synthesis

### 1. Run Simulation with Icarus Verilog

#### Windows (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File .\sim\run_simulation.ps1
```

#### Linux / WSL:
```bash
./sim/run_simulation.sh
```

#### Manual Compilation:
```bash
iverilog -g2005 -o sim/sim.out -I src src/*.v sim/railway_level_crossing_tb.v
vvp sim/sim.out
```

### 2. View Waveforms in GTKWave
```bash
gtkwave sim/waveform.vcd &
```

### 3. Run Logic Synthesis (Yosys 0.52)
```powershell
powershell -ExecutionPolicy Bypass -File .\synth\run_synthesis.ps1
```

---

## 📊 Verification Test Suite & Simulation Results

All five automated self-checking test cases passed with zero safety violations:

| Test ID | Test Scenario Description | Expected Safety Action | Observed Behaviour | Status |
|:---:|:---|:---|:---|:---:|
| **TC-1** | System Initialization & Safe Idle | Gate $90^\circ$, Road Green, Buzzer Silent | Road Green, Gate $90^\circ$, Train Aspect Red | **PASS** |
| **TC-2** | Normal Inbound Train Passage | Warning $\to$ Descent $\to$ Passage $\to$ Ascent | Complete angular transit ($90^\circ \to 0^\circ \to 90^\circ$) | **PASS** |
| **TC-3** | Safety Interlock Tamper Protection | Hardware interlock blocks forced open | `interlock_open_en=0`, Security Alarm sounds | **PASS** |
| **TC-4** | Stalled Obstacle on Track (LiDAR Alert)| Road Red, Train Signal Red, Emergency Horn | Train signal forced RED; braking alert engaged | **PASS** |
| **TC-5** | Multitasking Concurrency (`fork...join`)| Asynchronous emergency preempts train | Emergency priority verified seamlessly | **PASS** |

### Synthesis Cell Utilization (Yosys Open Synthesis Suite):
- **Total Standard Cells:** **287 Cells**
- Logic Gates: 60 `AND`, 59 `NAND`, 32 `NOR`, 25 `NOT`, 22 `OR`, 13 `XOR/XNOR`, 4 `MUX`
- Sequential Elements: 40 DFF (`$_DFF_PN0_`), 30 DFFE with Enable (`$_DFFE_PN0P_`)

---

## 👥 Student Team & Individual Contribution Declaration

| Sl. No. | Student Name | Role | Core Contribution Area | Share |
|:---:|:---|:---|:---|:---:|
| 1 | **Vikas K S (Lead)** | System Architect | Top-level Hierarchy, State Machine Controller | 25% |
| 2 | **Team Member 2** | Interlock Specialist | Gate-level Safety Interlock, Primitives Logic | 25% |
| 3 | **Team Member 3** | Traffic & Actuator Lead | Traffic Light Controller, Emergency Warning, Sound/LEDs | 25% |
| 4 | **Team Member 4** | Verification & Synthesis | Testbench Tasks/Functions, Yosys Synthesis & Netlists | 25% |

---

## 📚 Course Details & Evaluation
- **Institution:** GM University, P.B. Road, Davanagere – 577 006, Karnataka, India
- **Course:** UE25EC2302 — Hardware Modelling using Verilog
- **Department:** Electronics & Communication Engineering, School of Engineering
- **Course Coordinator:** Mr. Santhosh B G
- **Head of the Department:** Dr. Praveen J
- **Director, School of Engineering:** Dr. Praveen J
