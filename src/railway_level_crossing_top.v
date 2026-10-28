//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : railway_level_crossing_top
// Description  : Hierarchical Top-Level Integration Module uniting Train Detection,
//                Gate Safety Interlock, Gate Motor Controller, Road Traffic Signals,
//                and Emergency/Warning Module.
// Coverage     : Unit 1 (Hierarchical Design), Units 2-6 (Synthesis & Integration)
//=============================================================================

`timescale 1ns / 1ps

module railway_level_crossing_top #(
    parameter DEBOUNCE_CYCLES      = 3,
    parameter WARN_DELAY_CYCLES    = 5,
    parameter MOTOR_TRANSIT_CYCLES = 5,
    parameter POST_CLEAR_DELAY     = 3,
    parameter BLINK_DIV            = 4
)(
    // Clock and System Reset
    input  wire clk,
    input  wire rst_n,

    // Track Sensors (Physical Inputs)
    input  wire sensor_entry_raw,      // Entry Detector (Approach)
    input  wire sensor_track_raw,      // Track Zone Detector (Crossing Occupancy)
    input  wire sensor_exit_raw,       // Exit Detector (Departing)

    // Emergency and Manual Controls
    input  wire manual_emergency_btn,  // Emergency stop push-button
    input  wire obstacle_sensor,       // Track obstacle sensor (LiDAR / loop)
    input  wire emergency_vehicle_req, // Emergency road vehicle preemption request
    input  wire manual_force_open,     // Tamper / Forced gate opening input (safety test)

    // Gate Motor Actuators & Physical Locks
    output wire gate_motor_down,       // Motor drive: Descend barrier
    output wire gate_motor_up,         // Motor drive: Ascend barrier
    output wire barrier_lock_cmd,      // Physical electromagnetic locking clamp

    // Road Traffic Lights
    output wire road_red,              // Road signal: STOP
    output wire road_yellow,           // Road signal: CAUTION
    output wire road_green,            // Road signal: GO

    // Pedestrian Crossing Indicators
    output wire ped_walk,              // Pedestrian cross authorized
    output wire ped_dont_walk,         // Pedestrian hold / do not cross

    // Railway Train Traffic Signals
    output wire train_signal_green,    // Train Aspect: CLEAR / PROCEED
    output wire train_signal_red,      // Train Aspect: DANGER / STOP

    // Visual & Acoustic Warning Subsystem
    output wire buzzer_audio,          // Auditory warning tone
    output wire led_flasher_left,      // Crossbuck wig-wag red LED (Left)
    output wire led_flasher_right,     // Crossbuck wig-wag red LED (Right)
    output wire emergency_indicator,   // System emergency alert beacon
    output wire safety_violation_alarm,// Security interlock violation alarm

    // System Telemetry & Diagnostic Status
    output wire       emergency_active,// Active emergency status
    output wire [1:0] gate_state,      // 00: Open, 01: Closing, 10: Closed, 11: Opening
    output wire [6:0] gate_angle,      // Real-time barrier angle (0-90 deg)
    output wire [2:0] emergency_cause, // Diagnostic reason code
    output wire       train_approaching,// Inbound train detected
    output wire       train_present,   // Train currently crossing
    output wire       sensor_fault     // Sensor abnormality flag
);

    //-------------------------------------------------------------------------
    // Internal Interconnect Wires (Unit 1: Hierarchical Port Connections)
    //-------------------------------------------------------------------------
    wire sensor_entry_clean;
    wire sensor_track_clean;
    wire sensor_exit_clean;
    wire train_cleared;
    wire train_direction;

    wire req_open;
    wire req_close;
    wire interlock_open_en;
    wire interlock_close_en;

    wire gate_is_closed;
    wire gate_is_open;
    wire gate_warning;

    wire obstacle_detected;

    //-------------------------------------------------------------------------
    // Submodule 1: Train Detection Module
    //-------------------------------------------------------------------------
    train_detection #(
        .DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)
    ) u_train_detection (
        .clk                (clk),
        .rst_n              (rst_n),
        .sensor_entry_raw   (sensor_entry_raw),
        .sensor_track_raw   (sensor_track_raw),
        .sensor_exit_raw    (sensor_exit_raw),
        .sensor_entry_clean (sensor_entry_clean),
        .sensor_track_clean (sensor_track_clean),
        .sensor_exit_clean  (sensor_exit_clean),
        .train_approaching  (train_approaching),
        .train_present      (train_present),
        .train_cleared      (train_cleared),
        .train_direction    (train_direction),
        .sensor_fault       (sensor_fault)
    );

    //-------------------------------------------------------------------------
    // Submodule 2: Gate Safety Interlock (Pure Gate-Level Unit 2)
    //-------------------------------------------------------------------------
    gate_safety_interlock u_safety_interlock (
        .req_open               (req_open),
        .req_close              (req_close),
        .train_present          (train_present),
        .train_approaching      (train_approaching),
        .emergency_active       (emergency_active),
        .manual_force_open      (manual_force_open),
        .interlock_open_en      (interlock_open_en),
        .interlock_close_en     (interlock_close_en),
        .barrier_lock_cmd       (barrier_lock_cmd),
        .safety_violation_alarm (safety_violation_alarm)
    );

    //-------------------------------------------------------------------------
    // Submodule 3: Gate Controller Module
    //-------------------------------------------------------------------------
    gate_controller #(
        .WARN_DELAY_CYCLES    (WARN_DELAY_CYCLES),
        .MOTOR_TRANSIT_CYCLES (MOTOR_TRANSIT_CYCLES),
        .POST_CLEAR_DELAY     (POST_CLEAR_DELAY)
    ) u_gate_controller (
        .clk                (clk),
        .rst_n              (rst_n),
        .train_approaching  (train_approaching),
        .train_present      (train_present),
        .train_cleared      (train_cleared),
        .emergency_active   (emergency_active),
        .interlock_open_en  (interlock_open_en),
        .interlock_close_en (interlock_close_en),
        .req_open           (req_open),
        .req_close          (req_close),
        .gate_motor_down    (gate_motor_down),
        .gate_motor_up      (gate_motor_up),
        .gate_state         (gate_state),
        .gate_angle         (gate_angle),
        .gate_is_closed     (gate_is_closed),
        .gate_is_open       (gate_is_open),
        .gate_warning       (gate_warning)
    );

    //-------------------------------------------------------------------------
    // Submodule 4: Traffic Light Controller Module
    //-------------------------------------------------------------------------
    traffic_light_controller #(
        .BLINK_DIV(BLINK_DIV)
    ) u_traffic_controller (
        .clk                (clk),
        .rst_n              (rst_n),
        .gate_state         (gate_state),
        .gate_is_closed     (gate_is_closed),
        .gate_is_open       (gate_is_open),
        .gate_warning       (gate_warning),
        .train_approaching  (train_approaching),
        .train_present      (train_present),
        .emergency_active   (emergency_active),
        .obstacle_detected  (obstacle_detected),
        .road_red           (road_red),
        .road_yellow        (road_yellow),
        .road_green         (road_green),
        .ped_walk           (ped_walk),
        .ped_dont_walk      (ped_dont_walk),
        .train_signal_green (train_signal_green),
        .train_signal_red   (train_signal_red)
    );

    //-------------------------------------------------------------------------
    // Submodule 5: Emergency and Warning Module
    //-------------------------------------------------------------------------
    emergency_warning_module #(
        .TONE_DIV_SLOW(8),
        .TONE_DIV_FAST(4)
    ) u_emergency_warning (
        .clk                  (clk),
        .rst_n                (rst_n),
        .gate_warning         (gate_warning),
        .gate_state           (gate_state),
        .train_approaching    (train_approaching),
        .train_present        (train_present),
        .manual_emergency_btn (manual_emergency_btn),
        .obstacle_sensor      (obstacle_sensor),
        .emergency_vehicle_req(emergency_vehicle_req),
        .sensor_fault         (sensor_fault),
        .emergency_active     (emergency_active),
        .emergency_cause      (emergency_cause),
        .obstacle_detected    (obstacle_detected),
        .buzzer_audio         (buzzer_audio),
        .led_flasher_left     (led_flasher_left),
        .led_flasher_right    (led_flasher_right),
        .emergency_indicator  (emergency_indicator)
    );

endmodule
