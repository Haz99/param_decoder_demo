
module simple_instr_deco #(
    //parameter FE_WIDTH  = 2,          // Number of instructions to decode, width of the front-end
    parameter VADDR_WIDTH = 32,         // Number of bits in the virtual address
    parameter MAX_ILEN = 32,            // Maximum instruction length
    parameter XCPT_CAUSE_WIDTH = 32,    // Length of the exception vector indicating the cause
    parameter XLEN  = 64,               // Registers length
    parameter MAX_SRCS_PER_INSTR = 3,   // Maximum number of sources per instruction
    parameter LOGICAL_REGS = 32         // Number of logical registers
) (
    // Input signals
    input logic                         instr_valid_i,
    input logic [VADDR_WIDTH-1:0]       instr_pc_i,
    input logic [MAX_ILEN-1:0           instr_content_i,

    // TODO: add support for branch prediction
    input logic                         bp_is_branch_i,
    input logic                         bp_decision_i,
    input logic [VADDR_WIDTH-1:0]       bp_pred_addr_i,

    // TODO: add support for exception propagation
    input logic                         xcpt_valid_i,
    input logic [VADDR_WIDTH-1:0]       xcpt_origin_i,
    input logic [XCPT_CAUSE_WIDTH-1:0]  xcpt_cause_i,

    

    // TODO: add support for exception detection
    input logic                         xcpt_valid_o,
    input logic [VADDR_WIDTH-1:0]       xcpt_origin_o,
    input logic [XCPT_CAUSE_WIDTH-1:0]  xcpt_cause_o,
);

endmodule
