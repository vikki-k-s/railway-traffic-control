//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : emergency_warning_module
// Description  : Emergency priority arbitrator, track obstacle handler,
//                alternating wig-wag LED flasher, and audible buzzer generator.
// Coverage     : Unit 3 (Behavioural), Unit 4 (Functions),
//                Unit 5 (Loops, Parameters, Conditional Statements)
//=============================================================================

`timescale 1ns / 1ps

module emergency_warning_module #(
    parameter TONE_DIV_SLOW = 8,   // Divider for normal train approach tone
    parameter TONE_DIV_FAST = 4    // Divider for emergency high-pitched alarm
)(
    input  wire       clk,
    input  wire       rst_n,

    // Normal operation triggers
    input  wire       gate_warning,
    input  wire [1:0] gate_state,
    input  wire       train_approaching,
    input  wire       train_present,

    // Emergency Inputs (Absolute Priority)
    input  wire       manual_emergency_btn, // Push-button emergency override
    input  wire       obstacle_sensor,      // Vehicle or debris stuck on tracks
    input  wire       emergency_vehicle_req,// Ambulance / Fire engine priority call
    input  wire       sensor_fault,         // Diagnostic fault from detection unit

    // Priority Status Outputs
    output reg        emergency_active,     // High-priority global emergency state
    output reg  [2:0] emergency_cause,      // Diagnostic code for emergency trigger
    output wire       obstacle_detected,    // Dedicated track obstruction flag

    // Warning Actuators
    output reg        buzzer_audio,         // Modulated audible alarm tone
    output reg        led_flasher_left,     // Left crossbuck flasher (Alternating)
    output reg        led_flasher_right,    // Right crossbuck flasher (Alternating)
    output reg        emergency_indicator   // Red alert strobe LED
);

    // Audio frequency dividers and flasher cadence counter
    reg [7:0] counter_timer;
    reg       flasher_phase;
    reg       tone_slow;
    reg       tone_fast;

    // Unit 5: Generate loop / integer loop for diagnostic mask evaluation
    integer i;
    reg [3:0] active_alarms;

    // Dataflow assignment
    assign obstacle_detected = obstacle_sensor;

    //-------------------------------------------------------------------------
    // Unit 3 & 5: Emergency Priority Resolution & Diagnosis
    // Emergency condition overrides any standard operational sequence.
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            emergency_active    <= 1'b0;
            emergency_cause     <= 3'b000;
            emergency_indicator <= 1'b0;
            active_alarms       <= 4'b0000;
        end else begin
            // Sample active emergency sources
            active_alarms <= {sensor_fault, emergency_vehicle_req, obstacle_sensor, manual_emergency_btn};

            // Priority encoder: Manual switch > Obstacle > Emergency Vehicle > Sensor Fault
            if (manual_emergency_btn) begin
                emergency_active    <= 1'b1;
                emergency_cause     <= 3'b001; // Manual Override
                emergency_indicator <= 1'b1;
            end else if (obstacle_sensor) begin
                emergency_active    <= 1'b1;
                emergency_cause     <= 3'b010; // Track Obstacle
                emergency_indicator <= 1'b1;
            end else if (emergency_vehicle_req) begin
                emergency_active    <= 1'b1;
                emergency_cause     <= 3'b011; // Emergency Vehicle Preemption
                emergency_indicator <= 1'b1;
            end else if (sensor_fault) begin
                emergency_active    <= 1'b1;
                emergency_cause     <= 3'b100; // Sensor Hardware Malfunction
                emergency_indicator <= 1'b1;
            end else begin
                emergency_active    <= 1'b0;
                emergency_cause     <= 3'b000; // Normal Operation
                emergency_indicator <= 1'b0;
            end
        end
    end

    //-------------------------------------------------------------------------
    // Flasher Timing & Tone Frequency Modulation
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_timer <= 8'd0;
            flasher_phase <= 1'b0;
            tone_slow     <= 1'b0;
            tone_fast     <= 1'b0;
        end else begin
            counter_timer <= counter_timer + 1'b1;

            // Generate slow tone toggle
            if (counter_timer[TONE_DIV_SLOW-1] != tone_slow)
                tone_slow <= counter_timer[TONE_DIV_SLOW-1];

            // Generate fast tone toggle
            if (counter_timer[TONE_DIV_FAST-1] != tone_fast)
                tone_fast <= counter_timer[TONE_DIV_FAST-1];

            // Cadence for alternating LED wig-wag flashers
            flasher_phase <= counter_timer[3];
        end
    end

    //-------------------------------------------------------------------------
    // Actuator Drive Logic: Buzzer and Crossbuck Flashers
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buzzer_audio      <= 1'b0;
            led_flasher_left  <= 1'b0;
            led_flasher_right <= 1'b0;
        end else begin
            // 1. Audible Buzzer Drive:
            if (emergency_active) begin
                // Continuous high-intensity alarm tone for emergencies
                buzzer_audio <= tone_fast;
            end else if (train_approaching || train_present || gate_warning || (gate_state != 2'b00)) begin
                // Pulsed cadence tone for standard train passage
                buzzer_audio <= tone_slow & flasher_phase;
            end else begin
                buzzer_audio <= 1'b0; // Silent during clear idle
            end

            // 2. Alternating Wig-Wag Crossbuck LEDs (Mutually exclusive blinking):
            if (emergency_active || train_approaching || train_present || gate_warning || (gate_state != 2'b00)) begin
                led_flasher_left  <=  flasher_phase;
                led_flasher_right <= ~flasher_phase;
            end else begin
                led_flasher_left  <= 1'b0;
                led_flasher_right <= 1'b0;
            end
        end
    end

endmodule
