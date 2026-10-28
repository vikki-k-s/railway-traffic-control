//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : traffic_light_controller
// Description  : Controls road traffic lights (Red/Yellow/Green), pedestrian signals,
//                and railway track aspect signals (Clear/Danger).
// Coverage     : Unit 3 - Dataflow (assign) & Behavioural modelling,
//                Unit 5 - Parameters & Conditional Statements
//=============================================================================

`timescale 1ns / 1ps

module traffic_light_controller #(
    parameter BLINK_DIV = 4  // Clock divider for flasher effects
)(
    input  wire clk,
    input  wire rst_n,

    // Inputs from Gate Controller & Safety Interlock
    input  wire [1:0] gate_state,        // 00: OPEN, 01: CLOSING, 10: CLOSED, 11: OPENING
    input  wire       gate_is_closed,    // Barrier confirmed fully lowered
    input  wire       gate_is_open,      // Barrier confirmed fully raised
    input  wire       gate_warning,      // Warning lead time active

    // Inputs from Train Detection & Emergency Module
    input  wire       train_approaching,
    input  wire       train_present,
    input  wire       emergency_active,
    input  wire       obstacle_detected,

    // Road Traffic Light Outputs
    output wire       road_red,          // Road traffic STOP
    output wire       road_yellow,       // Road traffic CAUTION / PRE-CLOSURE
    output wire       road_green,        // Road traffic GO

    // Pedestrian Crossing Outputs
    output wire       ped_walk,          // Pedestrian WALK (White/Green)
    output wire       ped_dont_walk,     // Pedestrian DO NOT CROSS (Solid Red)

    // Train Track Signal Aspects (Train Traffic Control)
    output wire       train_signal_green,// PROCEED: Gate fully closed and track verified clear
    output wire       train_signal_red   // DANGER / HALT: Gate not fully closed or obstacle present
);

    // Flasher clock generation register
    reg [BLINK_DIV-1:0] clk_counter;
    wire blink_pulse;

    // Behavioural clock division for flasher
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= {BLINK_DIV{1'b0}};
        end else begin
            clk_counter <= clk_counter + 1'b1;
        end
    end

    // Flasher strobe for pulsing amber/yellow warning
    assign blink_pulse = clk_counter[BLINK_DIV-1];

    //-------------------------------------------------------------------------
    // Unit 3: Dataflow Modelling (Continuous Assignments with Boolean Expressions)
    //-------------------------------------------------------------------------

    // 1. Road Green: Safe ONLY when gate is fully open AND no train approaching AND no train present AND no emergency
    assign road_green = (gate_is_open) & (~gate_warning) & (~train_approaching) & (~train_present) & (~emergency_active);

    // 2. Road Yellow: Active during pre-closure warning phase OR closing transit
    assign road_yellow = (gate_warning || (gate_state == 2'b01)) & (~emergency_active);

    // 3. Road Red: STOP when gate is closed, closing, opening, or during emergency/presence
    assign road_red = (gate_state == 2'b10) || (gate_state == 2'b11) || 
                      emergency_active     || (gate_warning && blink_pulse) ||
                      (gate_state == 2'b01);

    // 4. Pedestrian Walk / Don't Walk signals
    assign ped_walk      = road_green;
    assign ped_dont_walk = ~road_green;

    // 5. Train Track Signals (Railway interlocking rule):
    // Train can ONLY receive Green aspect if barrier is 100% verified closed AND no obstacle is on tracks!
    assign train_signal_green = (gate_is_closed) & (~obstacle_detected) & (~emergency_active);
    assign train_signal_red   = ~train_signal_green;

endmodule
