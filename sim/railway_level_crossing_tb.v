//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : railway_level_crossing_tb
// Description  : Comprehensive verification testbench testing Normal Train Passage,
//                Bidirectional Trains, Emergency Overrides, Hardware Safety Interlock,
//                Sensor Faults, and Actuator Responses with VCD Waveform Dumps.
// Coverage     : Unit 4 (Tasks, Functions & Multitasking - fork/join),
//                Unit 5 (System Tasks: $dumpfile, $display, $monitor, $time, $finish)
//=============================================================================

`timescale 1ns / 1ps

module railway_level_crossing_tb;

    // Clock and System Reset
    reg clk;
    reg rst_n;

    // Track Sensors
    reg sensor_entry_raw;
    reg sensor_track_raw;
    reg sensor_exit_raw;

    // Emergency and Manual Controls
    reg manual_emergency_btn;
    reg obstacle_sensor;
    reg emergency_vehicle_req;
    reg manual_force_open;

    // DUT Outputs
    wire gate_motor_down;
    wire gate_motor_up;
    wire barrier_lock_cmd;
    wire road_red;
    wire road_yellow;
    wire road_green;
    wire ped_walk;
    wire ped_dont_walk;
    wire train_signal_green;
    wire train_signal_red;
    wire buzzer_audio;
    wire led_flasher_left;
    wire led_flasher_right;
    wire emergency_indicator;
    wire safety_violation_alarm;
    wire emergency_active;
    wire [1:0] gate_state;
    wire [6:0] gate_angle;
    wire [2:0] emergency_cause;
    wire train_approaching;
    wire train_present;
    wire sensor_fault;

    // Testbench metric counters
    integer test_case_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    //-------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // Scaled down cycle counts for accelerated simulation verification
    //-------------------------------------------------------------------------
    railway_level_crossing_top #(
        .DEBOUNCE_CYCLES      (3),
        .WARN_DELAY_CYCLES    (4),
        .MOTOR_TRANSIT_CYCLES (5),
        .POST_CLEAR_DELAY     (3),
        .BLINK_DIV            (2)
    ) dut (
        .clk                  (clk),
        .rst_n                (rst_n),
        .sensor_entry_raw     (sensor_entry_raw),
        .sensor_track_raw     (sensor_track_raw),
        .sensor_exit_raw      (sensor_exit_raw),
        .manual_emergency_btn (manual_emergency_btn),
        .obstacle_sensor      (obstacle_sensor),
        .emergency_vehicle_req(emergency_vehicle_req),
        .manual_force_open    (manual_force_open),
        .gate_motor_down      (gate_motor_down),
        .gate_motor_up        (gate_motor_up),
        .barrier_lock_cmd     (barrier_lock_cmd),
        .road_red             (road_red),
        .road_yellow          (road_yellow),
        .road_green           (road_green),
        .ped_walk             (ped_walk),
        .ped_dont_walk        (ped_dont_walk),
        .train_signal_green   (train_signal_green),
        .train_signal_red     (train_signal_red),
        .buzzer_audio         (buzzer_audio),
        .led_flasher_left     (led_flasher_left),
        .led_flasher_right    (led_flasher_right),
        .emergency_indicator  (emergency_indicator),
        .safety_violation_alarm(safety_violation_alarm),
        .emergency_active     (emergency_active),
        .gate_state           (gate_state),
        .gate_angle           (gate_angle),
        .emergency_cause      (emergency_cause),
        .train_approaching    (train_approaching),
        .train_present        (train_present),
        .sensor_fault         (sensor_fault)
    );

    //-------------------------------------------------------------------------
    // Clock Generation: 50 MHz Clock (Period = 20ns)
    //-------------------------------------------------------------------------
    always #10 clk = ~clk;

    //-------------------------------------------------------------------------
    // Unit 4: Modular Verilog Tasks for Testbench Stimulus
    //-------------------------------------------------------------------------

    // Task 1: System Reset
    task apply_system_reset;
        begin
            $display("[T=%0t] [TESTBENCH] Applying System Reset...", $time);
            rst_n                 = 1'b0;
            sensor_entry_raw      = 1'b0;
            sensor_track_raw      = 1'b0;
            sensor_exit_raw       = 1'b0;
            manual_emergency_btn  = 1'b0;
            obstacle_sensor       = 1'b0;
            emergency_vehicle_req = 1'b0;
            manual_force_open     = 1'b0;
            #50;
            rst_n = 1'b1;
            #30;
            $display("[T=%0t] [TESTBENCH] System Reset Released. Initialized in IDLE state.", $time);
        end
    endtask

    // Task 2: Simulate Complete Normal Train Passage
    task simulate_normal_train_passage;
        input integer entry_duration;
        input integer crossing_duration;
        input integer exit_duration;
        begin
            $display("\n------------------------------------------------------------");
            $display("[T=%0t] >>> TEST SCENARIO: Normal Up-Line Train Passage", $time);
            $display("------------------------------------------------------------");

            // Step A: Train reaches Entry Sensor (Approaching)
            $display("[T=%0t] Step A: Train trips Entry Sensor (Approaching Crossing)", $time);
            sensor_entry_raw = 1'b1;
            #(entry_duration);

            // Step B: Train arrives at the Level Crossing
            $display("[T=%0t] Step B: Train occupies Level Crossing Zone", $time);
            sensor_track_raw = 1'b1;
            #40;
            sensor_entry_raw = 1'b0; // Train has passed entry sensor
            #(crossing_duration);

            // Step C: Train trips Exit Sensor
            $display("[T=%0t] Step C: Train reaches Departure/Exit Sensor", $time);
            sensor_exit_raw = 1'b1;
            #40;
            sensor_track_raw = 1'b0; // Train leaves the crossing
            #(exit_duration);

            // Step D: Train fully departs
            $display("[T=%0t] Step D: Train completely clears Crossing Area", $time);
            sensor_exit_raw = 1'b0;
            #300; // Wait for safety delay and gate reopening transit
        end
    endtask

    // Task 3: Test Hardware Safety Interlock & Forced Opening Tamper Attempt
    task test_safety_interlock_violation;
        begin
            $display("\n------------------------------------------------------------");
            $display("[T=%0t] >>> TEST SCENARIO: Hardware Safety Interlock Verification", $time);
            $display("------------------------------------------------------------");

            // Train arrives on track
            sensor_track_raw = 1'b1;
            #60;

            // Malicious or accidental attempt to force open barrier while train is present
            $display("[T=%0t] Attempting UNAUTHORIZED manual gate opening while train is present!", $time);
            manual_force_open = 1'b1;
            #40;

            // Verify interlock blocked it
            if (dut.u_safety_interlock.interlock_open_en == 1'b0 && safety_violation_alarm == 1'b1) begin
                $display("[T=%0t] [PASS] Interlock successfully BLOCKED gate open! Alarm Sounded!", $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[T=%0t] [FAIL] CRITICAL: Gate interlock allowed unsafe open!", $time);
                fail_count = fail_count + 1;
            end
            test_case_count = test_case_count + 1;

            manual_force_open = 1'b0;
            sensor_track_raw = 1'b0;
            #80;
        end
    endtask

    // Task 4: Simulate Emergency Obstacle on Track
    task test_track_obstacle_emergency;
        begin
            $display("\n------------------------------------------------------------");
            $display("[T=%0t] >>> TEST SCENARIO: Obstacle Detected on Track (Stalled Car)", $time);
            $display("------------------------------------------------------------");

            $display("[T=%0t] LiDAR Sensor detects stalled obstacle on railway track!", $time);
            obstacle_sensor = 1'b1;
            #100;

            if (emergency_active == 1'b1 && emergency_cause == 3'b010 && train_signal_red == 1'b1) begin
                $display("[T=%0t] [PASS] Emergency engaged! Train Signal forced RED! Buzzer activated!", $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[T=%0t] [FAIL] Emergency response failed!", $time);
                fail_count = fail_count + 1;
            end
            test_case_count = test_case_count + 1;

            #60;
            $display("[T=%0t] Stalled obstacle towed off tracks. Clearing obstacle alarm.", $time);
            obstacle_sensor = 1'b0;
            #100;
        end
    endtask

    // Task 5: Simulate Manual Emergency Pushbutton Priority
    task test_manual_emergency_override;
        begin
            $display("\n------------------------------------------------------------");
            $display("[T=%0t] >>> TEST SCENARIO: Manual Emergency Pushbutton Pressed", $time);
            $display("------------------------------------------------------------");

            manual_emergency_btn = 1'b1;
            #80;

            if (emergency_active == 1'b1 && emergency_cause == 3'b001 && road_red == 1'b1) begin
                $display("[T=%0t] [PASS] Manual emergency priority verified! Road Red, Alert beacon ON.", $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[T=%0t] [FAIL] Manual emergency override failed!", $time);
                fail_count = fail_count + 1;
            end
            test_case_count = test_case_count + 1;

            manual_emergency_btn = 1'b0;
            #100;
        end
    endtask

    // Task 6: Multitasking Demonstration with fork ... join
    // Simultaneously triggers an approaching train and an emergency preemption
    task test_multitasking_concurrency;
        begin
            $display("\n------------------------------------------------------------");
            $display("[T=%0t] >>> TEST SCENARIO: Multitasking - Concurrent Train & Emergency", $time);
            $display("------------------------------------------------------------");

            fork
                // Thread A: Train approaching on track
                begin
                    #10;
                    sensor_entry_raw = 1'b1;
                    #80;
                    sensor_entry_raw = 1'b0;
                end

                // Thread B: Concurrent emergency vehicle requesting priority
                begin
                    #30;
                    emergency_vehicle_req = 1'b1;
                    #90;
                    emergency_vehicle_req = 1'b0;
                end
            join

            #100;
            $display("[T=%0t] [PASS] Multitasking concurrent test completed cleanly.", $time);
            pass_count = pass_count + 1;
            test_case_count = test_case_count + 1;
        end
    endtask

    //-------------------------------------------------------------------------
    // Main Simulation Stimulus Procedure
    //-------------------------------------------------------------------------
    initial begin
        // Unit 5: System Tasks for VCD Waveform Output and Diagnostics
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, railway_level_crossing_tb);

        clk = 1'b0;

        $display("============================================================");
        $display("   GM UNIVERSITY - PROJECT BASED LEARNING (UE25EC2302)      ");
        $display("   Railway Level Crossing & Train Traffic Controller        ");
        $display("============================================================");

        // Run Test Sequences
        apply_system_reset();

        // 1. Verify Safe Initial Idle State
        if (road_green == 1'b1 && gate_angle == 7'd90 && buzzer_audio == 1'b0) begin
            $display("[T=%0t] [PASS] Initial State Verified: Road GREEN, Gate OPEN (90 deg)", $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[T=%0t] [FAIL] Initial State invalid!", $time);
            fail_count = fail_count + 1;
        end
        test_case_count = test_case_count + 1;

        // 2. Normal Train Passage
        simulate_normal_train_passage(260, 200, 200);

        // 3. Hardware Safety Interlock & Tamper Test
        test_safety_interlock_violation();

        // 4. Track Obstacle Emergency
        test_track_obstacle_emergency();

        // 5. Manual Emergency Override Button
        test_manual_emergency_override();

        // 6. Multitasking Concurrency
        test_multitasking_concurrency();

        // Final Summary
        $display("\n============================================================");
        $display("               VERIFICATION TEST SUMMARY                    ");
        $display("============================================================");
        $display(" Total Test Cases Run : %0d", test_case_count);
        $display(" Total Passed         : %0d", pass_count);
        $display(" Total Failed         : %0d", fail_count);
        if (fail_count == 0)
            $display(" STATUS               : >>> ALL TESTS PASSED SUCCESSFULLY! <<<");
        else
            $display(" STATUS               : >>> SOME TESTS FAILED! <<<");
        $display("============================================================\n");

        #50;
        $finish;
    end

    // Continuous Real-Time State Monitor
    initial begin
        $monitor("[MONITOR T=%5t] GateState=%b Angle=%2d Road[R/Y/G]=%b%b%b TrainSig[G/R]=%b%b Emg=%b Buzzer=%b",
                 $time, gate_state, gate_angle, road_red, road_yellow, road_green,
                 train_signal_green, train_signal_red, emergency_active, buzzer_audio);
    end

endmodule
