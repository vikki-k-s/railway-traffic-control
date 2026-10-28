//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : gate_controller
// Description  : Controls automatic physical barrier movement, warning delays,
//                barrier angle tracking, and interfaces with hardware safety interlock.
// Coverage     : Unit 3 (Behavioural & Dataflow), Unit 4 (Tasks & Functions),
//                Unit 5 (Parameters, System Tasks, Case statements)
//=============================================================================

`timescale 1ns / 1ps

module gate_controller #(
    parameter WARN_DELAY_CYCLES    = 5,  // Yellow light warning before closure
    parameter MOTOR_TRANSIT_CYCLES = 5,  // Cycles to transit between 90 and 0 deg
    parameter POST_CLEAR_DELAY     = 3   // Safety buffer after train clears before open
)(
    input  wire       clk,
    input  wire       rst_n,

    // Sensor / Detection status
    input  wire       train_approaching,
    input  wire       train_present,
    input  wire       train_cleared,
    input  wire       emergency_active,

    // Vetted signals from Gate Safety Interlock
    input  wire       interlock_open_en,
    input  wire       interlock_close_en,

    // Control requests to Interlock
    output reg        req_open,
    output reg        req_close,

    // Gate Motor Actuator outputs
    output reg        gate_motor_down,
    output reg        gate_motor_up,

    // Status Telemetry
    output reg  [1:0] gate_state,        // 00: OPEN, 01: CLOSING, 10: CLOSED, 11: OPENING
    output reg  [6:0] gate_angle,        // 0 degrees (horizontal/closed) to 90 (vertical/open)
    output wire       gate_is_closed,    // High when fully down (0 deg)
    output wire       gate_is_open,      // High when fully up (90 deg)
    output reg        gate_warning       // Pre-closure warning period active
);

    //-------------------------------------------------------------------------
    // Unit 5: State Machine Local Parameters
    //-------------------------------------------------------------------------
    localparam [1:0]
        ST_OPEN    = 2'b00,
        ST_CLOSING = 2'b01,
        ST_CLOSED  = 2'b10,
        ST_OPENING = 2'b11;

    reg [1:0] current_state, next_state;
    reg [7:0] timer_count;
    reg [7:0] clear_timer;

    //-------------------------------------------------------------------------
    // Unit 4: Verilog Function
    // Computes normalized health / telemetry code based on gate angle
    //-------------------------------------------------------------------------
    function [1:0] calc_angle_status;
        input [6:0] angle;
        begin
            if (angle == 7'd90)
                calc_angle_status = 2'b00; // Fully Open
            else if (angle == 7'd0)
                calc_angle_status = 2'b10; // Fully Closed
            else
                calc_angle_status = 2'b01; // In-Transit
        end
    endfunction

    //-------------------------------------------------------------------------
    // Unit 4: Verilog Task
    // Modularly updates barrier position angle based on motor direction
    //-------------------------------------------------------------------------
    task update_barrier_position;
        input       dir_up;
        input       dir_down;
        inout [6:0] angle;
        begin
            if (dir_down && (angle > 7'd0)) begin
                if (angle >= 7'd18)
                    angle = angle - 7'd18;
                else
                    angle = 7'd0;
            end else if (dir_up && (angle < 7'd90)) begin
                if (angle <= 7'd72)
                    angle = angle + 7'd18;
                else
                    angle = 7'd90;
            end
        end
    endtask

    //-------------------------------------------------------------------------
    // Unit 3: Dataflow Assignments
    //-------------------------------------------------------------------------
    assign gate_is_closed = (gate_angle == 7'd0) && (current_state == ST_CLOSED);
    assign gate_is_open   = (gate_angle == 7'd90) && (current_state == ST_OPEN);

    //-------------------------------------------------------------------------
    // Unit 3: Behavioural Sequential State Transitions
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= ST_OPEN;
            gate_state    <= ST_OPEN;
            gate_angle    <= 7'd90;
            timer_count   <= 8'd0;
            clear_timer   <= 8'd0;
            req_open      <= 1'b0;
            req_close     <= 1'b0;
            gate_warning  <= 1'b0;
            gate_motor_down <= 1'b0;
            gate_motor_up   <= 1'b0;
        end else begin
            current_state <= next_state;
            gate_state    <= next_state;

            // Timer management and motor actuation
            case (current_state)
                ST_OPEN: begin
                    gate_motor_down <= 1'b0;
                    gate_motor_up   <= 1'b0;
                    gate_angle      <= 7'd90;

                    if (train_approaching || train_present || emergency_active) begin
                        gate_warning <= 1'b1;
                        if (timer_count < WARN_DELAY_CYCLES) begin
                            timer_count <= timer_count + 1'b1;
                        end else begin
                            timer_count <= 8'd0;
                            req_close   <= 1'b1;
                            req_open    <= 1'b0;
                        end
                    end else begin
                        gate_warning <= 1'b0;
                        timer_count  <= 8'd0;
                        req_close    <= 1'b0;
                        req_open     <= 1'b1;
                    end
                end

                ST_CLOSING: begin
                    gate_warning <= 1'b1;
                    // Lower gate if interlock permits
                    if (interlock_close_en) begin
                        gate_motor_down <= 1'b1;
                        gate_motor_up   <= 1'b0;
                        update_barrier_position(1'b0, 1'b1, gate_angle);
                    end else begin
                        gate_motor_down <= 1'b0;
                    end
                end

                ST_CLOSED: begin
                    gate_warning    <= 1'b0;
                    gate_motor_down <= 1'b0;
                    gate_motor_up   <= 1'b0;
                    gate_angle      <= 7'd0;
                    timer_count     <= 8'd0;

                    // If train has cleared and no emergency, count post-clear buffer
                    if (train_cleared && !emergency_active) begin
                        clear_timer <= 8'd1;
                    end else if ((clear_timer > 8'd0) && (clear_timer < POST_CLEAR_DELAY)) begin
                        clear_timer <= clear_timer + 1'b1;
                    end else if (clear_timer >= POST_CLEAR_DELAY) begin
                        req_open    <= 1'b1;
                        req_close   <= 1'b0;
                    end else begin
                        req_close   <= 1'b1;
                        req_open    <= 1'b0;
                    end
                end

                ST_OPENING: begin
                    clear_timer  <= 8'd0;
                    gate_warning <= 1'b0;
                    // Raise gate if interlock permits safe opening
                    if (interlock_open_en) begin
                        gate_motor_up   <= 1'b1;
                        gate_motor_down <= 1'b0;
                        update_barrier_position(1'b1, 1'b0, gate_angle);
                    end else begin
                        // If unsafe condition emerges during opening, halt motor!
                        gate_motor_up <= 1'b0;
                    end
                end

                default: begin
                    current_state <= ST_OPEN;
                end
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // Next-State Combinational Evaluation
    //-------------------------------------------------------------------------
    always @(*) begin
        next_state = current_state;

        case (current_state)
            ST_OPEN: begin
                // Transition to closing after warning delay expires or on urgent emergency
                if ((timer_count >= WARN_DELAY_CYCLES) && (train_approaching || train_present || emergency_active))
                    next_state = ST_CLOSING;
            end

            ST_CLOSING: begin
                // Gate reaches horizontal 0 degrees
                if (gate_angle == 7'd0)
                    next_state = ST_CLOSED;
            end

            ST_CLOSED: begin
                // Transition to opening when clearance delay satisfied and safe
                if ((clear_timer >= POST_CLEAR_DELAY) && !train_present && !emergency_active)
                    next_state = ST_OPENING;
            end

            ST_OPENING: begin
                // Emergency or new train approaching immediately aborts opening
                if (emergency_active || train_approaching || train_present)
                    next_state = ST_CLOSING;
                else if (gate_angle >= 7'd90)
                    next_state = ST_OPEN;
            end

            default: next_state = ST_OPEN;
        endcase
    end

endmodule
