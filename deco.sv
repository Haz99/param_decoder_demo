import deco_pkg::*;

module simple_instr_deco #(
    //parameter FE_WIDTH  = 2,          // Number of instructions to decode, width of the front-end // TODO: add support
    parameter VADDR_WIDTH = 32,         // Number of bits in the virtual address
    parameter MAX_ILEN = 32,            // Maximum instruction length
    parameter XCPT_CAUSE_WIDTH = 32,    // Length of the exception vector indicating the cause
    parameter XLEN  = 64,               // Registers length
    parameter MAX_SRCS_PER_INSTR = 3,   // Maximum number of sources per instruction
    parameter LOGICAL_REGS = 32,        // Number of logical registers
    localparam REG_ID_WIDTH = $clog2(LOGICAL_REGS)
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

    // Decoded information
    output logic instr_valid_o,
    output logic use_src_reg_o [MAX_SRCS_PER_INSTR-1:0],
    output logic [REG_ID_WIDTH-1:0] src_reg_id_o [MAX_SRCS_PER_INSTR-1:0],
    output logic use_dst_reg_o,
    output logic [REG_ID_WIDTH-1:0] dst_reg_id_o,
    output logic use_imm_o,
    output logic [XLEN-1:0] imm_o,
    output queue_et allocation_queue_o,
    output instr_type_et instr_type_o,
    output functional_unit_et functional_unit_o,

    // TODO: add support for exception detection
    output logic                         xcpt_valid_o,
    output logic [VADDR_WIDTH-1:0]       xcpt_origin_o,
    output logic [XCPT_CAUSE_WIDTH-1:0]  xcpt_cause_o,
);

    instruction_t instr_content;
    assign instr_content = instr_content_i;

    logic instr_valid, use_dst_reg, use_imm;
    logic use_src_reg [MAX_SRCS_PER_INSTR-1:0];
    logic [REG_ID_WIDTH-1:0] src_reg_id [MAX_SRCS_PER_INSTR-1:0];
    logic [REG_ID_WIDTH-1:0] dst_reg_id;
    logic [XLEN-1:0] imm;
    queue_et allocation_queue;
    functional_unit_et functional_unit;
    instr_type_et instr_type;

    always_comb begin
        use_dst_reg = 1'b0;
        use_imm = 1'b0;
        for (int i=0; i<MAX_SRCS_PER_INSTR; i++) begin
            use_src_reg[i] = 1'b0;
            src_reg_id[i] = '0;
        end
        dst_reg_id = '0;
        instr_type = LUI;
        allocation_queue = INTEGER_QUEUE;
        functional_unit = UNIT_ALU;
        if (instr_valid_i) begin
            case (instr_content.inst.common.opcode)
                    OP_LUI: begin
                    end
                    OP_AUIPC: begin
                    end
                    OP_JAL: begin
                    end
                    OP_JALR: begin
                    end
                    OP_BRANCH: begin
                    end
                    OP_LOAD: begin
                        // TODO: add common signals
                        case (instr_content.inst.common.func3)
                            F3_0: begin
                                instr_type = LB;
                            end
                            F3_1: begin
                                instr_type = LH;
                            end
                            F3_2: begin
                                instr_type = LW;
                            end
                            F3_4: begin
                                instr_type = LBU;
                            end
                            F3_5: begin
                                instr_type = LHU;
                            end
                            //---RV64I_on
                            F3_3: begin
                                instr_type = LD
                            end
                            F3_6: begin
                                instr_type = LWU;
                            end
                            //---RV64I_off
                            default: begin
                                // TODO: MARK AS ILLEGAL INSTRUCTION
                            end
                        endcase
                    end
                    OP_STORE: begin
                    end
                    OP_ALU_I: begin
                    end
                    OP_ALU: begin
                        // TODO: add common signals
                        case ({instr_content.inst.common.func3,instr_content.inst.common.func7})
                            {F3_0, F7_0}: begin
                                instr_type = ADD;
                            end
                            {F3_0, F7_32}: begin
                                instr_type = SUB;
                            end
                            {F3_1, F7_0}: begin
                                instr_type = SLL;
                            end
                            {F3_2, F7_0}: begin
                                instr_type = SLT;
                            end
                            {F3_3, F7_0}: begin
                                instr_type = SLTU;
                            end
                            {F3_4, F7_0}: begin
                                instr_type = XOR;
                            end
                            {F3_5, F7_0}: begin
                                instr_type = SRL;
                            end
                            {F3_5, F7_32}: begin
                                instr_type = SRA;
                            end
                            {F3_6, F7_0}: begin
                                instr_type = OR;
                            end
                            {F3_7, F7_0}: begin
                                instr_type = AND;
                            end
                            //---RV32M_on
                            {F3_0, F7_1}: begin
                                instr_type = MUL;
                            end
                            {F3_1, F7_1}: begin
                                instr_type = MULH;
                            end
                            {F3_2, F7_1}: begin
                                instr_type = MULHSU;
                            end
                            {F3_3, F7_1}: begin
                                instr_type = MULHU;
                            end
                            {F3_4, F7_1}: begin
                                instr_type = DIV;
                            end
                            {F3_5, F7_1}: begin
                                instr_type = DIVU;
                            end
                            {F3_6, F7_1}: begin
                                instr_type = REM;
                            end
                            {F3_7, F7_1}: begin
                                instr_type = REMU;
                            end
                            //---RV32M_on
                            default: begin
                                // TODO: MARK AS ILLEGAL INSTRUCTION
                            end


                    end
                    OP_FENCE: begin
                    end
                    OP_SYSTEM: begin
                    end

                    //---RV64I_on
                    OP_ALU_I_W:
                    OP_ALU_W:
                    //---RV64I_off

                    //----------------------------------- Base Integer Instructions Set

                    //---A_on
                    OP_ATOMICS:
                    //---A_off

                    //---F_on
                    OP_LOAD_FP:
                    OP_STORE_FP:
                    OP_FP:
                    OP_FMADD:
                    OP_FMSUB:
                    OP_FNMSUB:
                    OP_FNMADD:
                    default: begin
                        // TODO: MARK AS ILLEGAL INSTRUCTION
                    end
    end

endmodule
