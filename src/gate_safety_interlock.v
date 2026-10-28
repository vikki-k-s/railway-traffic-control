//=============================================================================
// GM UNIVERSITY - Faculty of Engineering & Technology
// Department of Electronics & Communication Engineering
// Course Code: UE25EC2302 | Hardware Modelling using Verilog | Semester: 3
// Project Based Learning (PBL): Railway Level Crossing & Train Traffic Controller
//-----------------------------------------------------------------------------
// Module Name  : gate_safety_interlock
// Description  : Hardware safety interlock circuit preventing unsafe gate opening
//                during train presence or emergency. Pure gate-level primitive
//                modelling providing hardware failsafe enforcement.
// Coverage     : Unit 2 - Gate-level Modelling (and, or, not, nand, nor, xor, buf)
//=============================================================================

`timescale 1ns / 1ps

module gate_safety_interlock (
    input  wire req_open,           // Open request from Controller FSM
    input  wire req_close,          // Close request from Controller FSM
    input  wire train_present,      // Train currently occupying crossing
    input  wire train_approaching,  // Train approaching crossing
    input  wire emergency_active,   // Active emergency override / track hazard
    input  wire manual_force_open,  // External attempt to force open gate

    output wire interlock_open_en,  // Vetted permission to open gate motor
    output wire interlock_close_en, // Vetted command to close gate motor
    output wire barrier_lock_cmd,   // Physical magnetic lock clamp on barrier
    output wire safety_violation_alarm // Warning alarm on illegal opening attempt
);

    // Internal interlock connection wires
    wire not_train_present;
    wire not_train_approaching;
    wire not_emergency;
    wire danger_condition;
    wire normal_safe_permit;
    wire illegal_override_attempt;
    wire close_demand_combined;
    wire open_permit_gated;

    //-------------------------------------------------------------------------
    // Unit 2: Built-in Gate Primitives Instantiation
    //-------------------------------------------------------------------------

    // 1. Invert hazard conditions
    not u_inv_tp   (not_train_present, train_present);
    not u_inv_ta   (not_train_approaching, train_approaching);
    not u_inv_emg  (not_emergency, emergency_active);

    // 2. Combine any active hazard or train presence
    // danger_condition = train_present | train_approaching | emergency_active
    or u_or_danger (danger_condition, train_present, train_approaching, emergency_active);

    // 3. Normal safe permit: Gate is only safe to open when NO danger condition exists
    // normal_safe_permit = (~train_present) & (~train_approaching) & (~emergency_active)
    and u_and_safe (normal_safe_permit, not_train_present, not_train_approaching, not_emergency);

    // 4. Open motor enable: Requires both FSM open request AND verified safe permit
    // interlock_open_en = req_open & normal_safe_permit & (~manual_force_open | normal_safe_permit)
    and u_and_open (interlock_open_en, req_open, normal_safe_permit);

    // 5. Close motor enable: Any danger condition or FSM close request mandates closure
    // close_demand_combined = req_close | danger_condition
    or u_or_close  (interlock_close_en, req_close, danger_condition);

    // 6. Barrier physical magnetic lock clamp: Energized whenever train is present or emergency active
    // barrier_lock_cmd = danger_condition
    buf u_buf_lock (barrier_lock_cmd, danger_condition);

    // 7. Safety violation alarm: If someone triggers manual force open while danger exists
    // safety_violation_alarm = manual_force_open & danger_condition
    and u_and_alarm (safety_violation_alarm, manual_force_open, danger_condition);

endmodule
