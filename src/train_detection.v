//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : train_detection
// Description  : Detects approaching trains, trains passing through crossing,
//                and trains clearing the crossing with sensor debouncing,
//                direction detection, and sensor health diagnostics.
// Coverage     : Unit 2 (Ports), Unit 3 (Behavioural & Dataflow),
//                Unit 4 (Verilog Functions), Unit 5 (Parameters & System Tasks)
//=============================================================================

`timescale 1ns / 1ps

module train_detection #(
    parameter DEBOUNCE_CYCLES = 3  // Glitch rejection filter threshold
)(
    input  wire        clk,
    input  wire        rst_n,

    // Raw sensor inputs from physical tracks (active-high)
    input  wire        sensor_entry_raw,  // Sensor 1: Located 500m before crossing
    input  wire        sensor_track_raw,  // Sensor 2: Located inside level crossing
    input  wire        sensor_exit_raw,   // Sensor 3: Located 200m after crossing

    // Filtered / conditioned status outputs
    output wire        sensor_entry_clean,
    output wire        sensor_track_clean,
    output wire        sensor_exit_clean,

    // High-level train movement status
    output reg         train_approaching, // Train detected approaching crossing
    output reg         train_present,     // Train occupying level crossing zone
    output reg         train_cleared,     // Pulse when train safely clears crossing
    output reg         train_direction,   // 0: Up-Line (Entry->Exit), 1: Down-Line (Exit->Entry)
    output reg         sensor_fault       // Abnormal sensor sequence detected
);

    //-------------------------------------------------------------------------
    // Unit 5: Local Parameters for Internal State Machine
    //-------------------------------------------------------------------------
    localparam [2:0]
        TRACK_IDLE       = 3'b000,
        TRAIN_INBOUND    = 3'b001,
        TRAIN_AT_CROSSING= 3'b010,
        TRAIN_OUTBOUND   = 3'b011,
        TRAIN_CLEARING   = 3'b100,
        FAULT_DETECTED   = 3'b101;

    reg [2:0] current_state, next_state;

    // Glitch Filter registers
    reg [DEBOUNCE_CYCLES-1:0] entry_shift;
    reg [DEBOUNCE_CYCLES-1:0] track_shift;
    reg [DEBOUNCE_CYCLES-1:0] exit_shift;

    reg entry_filtered, track_filtered, exit_filtered;
    reg entry_prev, exit_prev;

    // Edge detection wires
    wire entry_rising, exit_rising;

    //-------------------------------------------------------------------------
    // Unit 4: Verilog Function Concept
    // Validates if sensor activation sequence is physically plausible
    //-------------------------------------------------------------------------
    function check_sensor_validity;
        input entry_s;
        input track_s;
        input exit_s;
        input [2:0] state;
        begin
            // If track sensor triggers while in IDLE state without entry trigger,
            // an unexpected intrusion or sensor failure has occurred.
            if ((state == TRACK_IDLE) && track_s && !entry_s && !exit_s)
                check_sensor_validity = 1'b0; // Invalid / Fault condition
            else
                check_sensor_validity = 1'b1; // Valid physical progression
        end
    endfunction

    //-------------------------------------------------------------------------
    // Unit 3: Behavioural Debouncing / Glitch Filtering
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            entry_shift    <= {DEBOUNCE_CYCLES{1'b0}};
            track_shift    <= {DEBOUNCE_CYCLES{1'b0}};
            exit_shift     <= {DEBOUNCE_CYCLES{1'b0}};
            entry_filtered <= 1'b0;
            track_filtered <= 1'b0;
            exit_filtered  <= 1'b0;
            entry_prev     <= 1'b0;
            exit_prev      <= 1'b0;
        end else begin
            // Shift register for noise filtering
            entry_shift <= {entry_shift[DEBOUNCE_CYCLES-2:0], sensor_entry_raw};
            track_shift <= {track_shift[DEBOUNCE_CYCLES-2:0], sensor_track_raw};
            exit_shift  <= {exit_shift[DEBOUNCE_CYCLES-2:0], sensor_exit_raw};

            // Majority voting or full-window confirmation
            if (&entry_shift) entry_filtered <= 1'b1;
            else if (~|entry_shift) entry_filtered <= 1'b0;

            if (&track_shift) track_filtered <= 1'b1;
            else if (~|track_shift) track_filtered <= 1'b0;

            if (&exit_shift) exit_filtered <= 1'b1;
            else if (~|exit_shift) exit_filtered <= 1'b0;

            // Delayed registers for edge detection
            entry_prev <= entry_filtered;
            exit_prev  <= exit_filtered;
        end
    end

    //-------------------------------------------------------------------------
    // Unit 3: Dataflow Modelling (Continuous Assignments)
    //-------------------------------------------------------------------------
    assign sensor_entry_clean = entry_filtered;
    assign sensor_track_clean = track_filtered;
    assign sensor_exit_clean  = exit_filtered;

    assign entry_rising = entry_filtered & ~entry_prev;
    assign exit_rising  = exit_filtered  & ~exit_prev;

    //-------------------------------------------------------------------------
    // Unit 3: Sequential State Transition Logic
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= TRACK_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    //-------------------------------------------------------------------------
    // Unit 3 & Unit 5: Next-State Logic & Conditional Evaluation
    //-------------------------------------------------------------------------
    always @(*) begin
        next_state = current_state;

        // Diagnostic validation check using function
        if (!check_sensor_validity(entry_filtered, track_filtered, exit_filtered, current_state)) begin
            next_state = FAULT_DETECTED;
        end else begin
            case (current_state)
                TRACK_IDLE: begin
                    if (entry_rising)
                        next_state = TRAIN_INBOUND;
                    else if (exit_rising)
                        next_state = TRAIN_INBOUND; // Reverse direction train
                end

                TRAIN_INBOUND: begin
                    // Train reaches the level crossing
                    if (track_filtered)
                        next_state = TRAIN_AT_CROSSING;
                end

                TRAIN_AT_CROSSING: begin
                    // Train continues moving towards outbound detector
                    if (!track_filtered && (exit_filtered || entry_filtered))
                        next_state = TRAIN_OUTBOUND;
                    else if (!track_filtered && !exit_filtered && !entry_filtered)
                        // Safety timeout or premature clear
                        next_state = TRAIN_CLEARING;
                end

                TRAIN_OUTBOUND: begin
                    // Once all sensors go low, the train has completely passed
                    if (!track_filtered && !exit_filtered && !entry_filtered)
                        next_state = TRAIN_CLEARING;
                end

                TRAIN_CLEARING: begin
                    next_state = TRACK_IDLE;
                end

                FAULT_DETECTED: begin
                    // Clear fault when all sensors return to idle baseline
                    if (!entry_filtered && !track_filtered && !exit_filtered)
                        next_state = TRACK_IDLE;
                end

                default: next_state = TRACK_IDLE;
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // Output Generation (Registered Behavioural Logic)
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            train_approaching <= 1'b0;
            train_present     <= 1'b0;
            train_cleared     <= 1'b0;
            train_direction   <= 1'b0;
            sensor_fault      <= 1'b0;
        end else begin
            case (next_state)
                TRACK_IDLE: begin
                    train_approaching <= 1'b0;
                    train_present     <= 1'b0;
                    train_cleared     <= 1'b0;
                    sensor_fault      <= 1'b0;
                end

                TRAIN_INBOUND: begin
                    train_approaching <= 1'b1;
                    train_present     <= 1'b0;
                    train_cleared     <= 1'b0;
                    if (entry_rising)
                        train_direction <= 1'b0; // Up-line
                    else if (exit_rising)
                        train_direction <= 1'b1; // Down-line
                end

                TRAIN_AT_CROSSING, TRAIN_OUTBOUND: begin
                    train_approaching <= 1'b0;
                    train_present     <= 1'b1;
                    train_cleared     <= 1'b0;
                end

                TRAIN_CLEARING: begin
                    train_approaching <= 1'b0;
                    train_present     <= 1'b0;
                    train_cleared     <= 1'b1; // 1-cycle clearance strobe
                end

                FAULT_DETECTED: begin
                    sensor_fault      <= 1'b1;
                    train_present     <= 1'b1; // Safety failsafe: assume presence on fault!
                    train_approaching <= 1'b0;
                    train_cleared     <= 1'b0;
                end

                default: begin
                    train_approaching <= 1'b0;
                    train_present     <= 1'b0;
                    train_cleared     <= 1'b0;
                end
            endcase
        end
    end

endmodule
