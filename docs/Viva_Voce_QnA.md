# GM UNIVERSITY - DEPARTMENT OF ECE
## Course: UE25EC2302 - Hardware Modelling using Verilog
### Project Based Learning (PBL) - Viva Voce Questions & Answers Guide
### Project Title: Railway Level Crossing & Train Traffic Controller

---

### **CATEGORY 1: GENERAL PROJECT & SYSTEM ARCHITECTURE**

#### **Q1. What is the motivation behind developing this Railway Level Crossing Controller?**
**Answer:**  
Manual or unmanned railway level crossings are prone to fatal accidents due to human error, fatigue, delayed telephone communication between station masters and gatemen, or mechanical gate jamming. Our project implements a deterministic, automated digital system in Verilog HDL. It uses track sensors to detect approaching trains, provides early road warnings, automatically lowers barriers, and enforces a hardware gate-level interlock preventing unsafe gate opening while a train is passing.

#### **Q2. Walk us through the high-level architecture of your system.**
**Answer:**  
Our system follows a top-down hierarchical architecture (`railway_level_crossing_top.v`) composed of five specialized submodules:
1. `train_detection.v`: Glitch debouncing filter, train approach detection, crossing occupancy monitoring, and clearance detection.
2. `gate_safety_interlock.v`: Built purely with built-in gate primitives (`and`, `or`, `not`, `buf`) to enforce hardware failsafe locks.
3. `gate_controller.v`: A 4-state Mealy/Moore FSM regulating barrier movement ($90^\circ$ to $0^\circ$), pre-closure warning delays, and post-clearance safety buffers.
4. `traffic_light_controller.v`: Dataflow logic for road traffic lights (Red/Yellow/Green), pedestrian indicators, and railway track aspects.
5. `emergency_warning_module.v`: Dual-tone audible buzzer generator, alternating crossbuck wig-wag red LEDs, and priority encoder handling track obstacles, manual switches, and emergency vehicles.

#### **Q3. What makes your system "fail-safe"?**
**Answer:**  
In railway signaling, "fail-safe" means any system failure or abnormal condition must default to the safest state (Danger / Red / Barrier Locked). In our design:
1. **Hardware Safety Interlock:** Gate opening motor enable (`interlock_open_en`) is gated at the primitive logic gate level. Even if the FSM hangs or someone attempts forced unauthorized opening, the gate *cannot* receive an open signal while `train_present`, `train_approaching`, or `emergency_active` is high.
2. **Train Signal Aspect Interlocking:** The train signal only displays Green if the gate barrier angle is confirmed $0^\circ$ (fully lowered) AND no track obstacle is detected. Otherwise, it defaults to Red.
3. **Sensor Sequence Diagnostic:** If the crossing track sensor triggers before an entry sensor, the system flags a `sensor_fault` and defaults to barrier closure.

---

### **CATEGORY 2: VERILOG HDL CONCEPTS (UNITS 1 TO 6 MAPPING)**

#### **Q4. How did you apply Hierarchical Modelling (Unit 1)?**
**Answer:**  
In `railway_level_crossing_top.v`, we instantiate all five submodules using named port mapping (`.port_name(signal_name)`). Parameters such as `DEBOUNCE_CYCLES`, `WARN_DELAY_CYCLES`, and `BLINK_DIV` are parameterized at the top level and overridden during instantiation, enabling modular reuse and easy scaling.

#### **Q5. Why did you use Gate-Level Modelling (Unit 2) specifically for the Safety Interlock?**
**Answer:**  
In industrial safety systems (such as CENELEC SIL-4 railway standards), safety critical interlocks must be independent of procedural software logic. By designing `gate_safety_interlock.v` using Verilog gate primitives (`and`, `or`, `not`, `buf`), we model an actual combinational hardware circuit that directly governs physical actuator lines without relying on clock cycles or software registers.

#### **Q6. Distinguish between Dataflow and Behavioural Modelling as used in your project (Unit 3).**
**Answer:**  
- **Dataflow Modelling:** Expresses digital logic through continuous assignment statements (`assign`) evaluated whenever any operand changes. We used this in `traffic_light_controller.v` for instantaneous signal decoding (e.g. `assign road_green = gate_is_open & ~gate_warning & ~train_present;`).
- **Behavioural Modelling:** Describes algorithms and sequential behavior inside procedural blocks (`always @(posedge clk or negedge rst_n)`). We used this in `gate_controller.v` and `train_detection.v` to implement clock-edge-triggered Finite State Machines (FSM) and counters.

#### **Q7. What is the difference between a Verilog `task` and `function`? Where are they used in your code (Unit 4)?**
**Answer:**  
| Feature | Verilog `function` | Verilog `task` |
|:---|:---|:---|
| **Simulation Time** | Executes in 0 simulation time (no `#`, `@`, or `wait`). | Can contain time delays (`#delay`, `@(posedge clk)`). |
| **Return Value** | Must return a single value via function name. | Does not return a value via name; uses `output` or `inout` arguments. |
| **Calls** | Can call other functions, but NOT tasks. | Can call other tasks and functions. |
| **Usage in Project** | `check_sensor_validity` in `train_detection.v` and `calc_angle_status` in `gate_controller.v`. | `update_barrier_position` in `gate_controller.v` and stimulus generation tasks in the testbench. |

#### **Q8. How did you demonstrate Multitasking in your testbench (Unit 4)?**
**Answer:**  
In `railway_level_crossing_tb.v`, we utilized the `fork ... join` construct inside `test_multitasking_concurrency`. One parallel thread models the physical arrival of a train on the tracks while another concurrent thread models an asynchronous emergency vehicle preemption call. This verifies that our controller correctly arbitrates simultaneous asynchronous events in real time.

#### **Q9. Explain the use of System Tasks and Parameters in your project (Unit 5).**
**Answer:**  
- **Parameters / Localparams:** Parameterize clock cycles, filter depths, and state encodings (`localparam ST_OPEN = 2'b00;`).
- **System Tasks:**
  - `$dumpfile("sim/waveform.vcd")` & `$dumpvars(0, dut)`: Dumps simulation signal histories for GTKWave waveform visualization.
  - `$monitor`: Automatically prints signal status whenever any monitored variable changes.
  - `$display` & `$time`: Prints testcase timestamps and pass/fail verdicts.
  - `$finish`: Safely terminates the simulation execution.

#### **Q10. How did you verify Logic Synthesis and Gate-Level Netlist (Unit 6)?**
**Answer:**  
We synthesized our design using the open-source **Yosys 0.52 Open Synthesis Suite**. We created a synthesis script (`synth/synth.ys`) that elaborated the design hierarchy, converted behavioural processes to RTLIL, executed optimization passes, and mapped the logic to standard gate cells (`AND`, `NAND`, `OR`, `NOR`, `XOR`, `DFF`). The synthesis resulted in **287 gate cells** with zero inferred latches, proving that our RTL code is 100% hardware-synthesizable.

---

### **CATEGORY 3: HARDWARE INTERFACING & SAFETY MECHANISMS**

#### **Q11. Why do you need sensor debouncing in `train_detection.v`?**
**Answer:**  
Physical wheel sensors, infrared beams, or magnetic axle counters on railway tracks experience mechanical vibration, electrical EMI from train overhead traction lines (25 kV AC), and debris. Without digital debouncing (`DEBOUNCE_CYCLES` shift registers), a single wheel vibration could falsely indicate multiple trains or premature departure.

#### **Q12. What happens if a car stalls on the tracks while a train is approaching?**
**Answer:**  
Our LiDAR/obstacle sensor triggers `obstacle_sensor = 1`. This immediately asserts `emergency_active = 1` with cause `010` (Track Obstacle). The system:
1. Immediately forces the train railway signal to solid RED (`train_signal_red = 1`), signaling the locomotive driver or Automatic Train Protection (ATP/Kavach) to apply emergency brakes.
2. Sounds a high-frequency emergency buzzer alarm.
3. Flashes the red alert beacon to notify road motorists and operators.

#### **Q13. What is the purpose of the post-clearance delay (`POST_CLEAR_DELAY`)?**
**Answer:**  
After a train's last wagon clears the exit sensor, a brief buffer delay (e.g. 3–5 seconds) is enforced before raising the barrier. This ensures that any trailing wagons, hanging chains, or secondary inspection locomotives have fully cleared the crossing danger zone before road motorists accelerate forward.
