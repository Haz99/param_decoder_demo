//////////////////////////////////////////////////////////////////////
//!
//! **PROJECT:**             System_Verilog_Hardware_Common_Lib
//!
//! **LANGUAGE:**            Verilog, SystemVerilog
//!
//! **FILE:**                renaming_unit.sv
//!
//! **AUTHOR(S):**
//!
//!   - Javier Salamero Sanz         - javier.salamero@bsc.es (AI)
//!
//! **CONTRIBUTORS:**
//!
//! **REVISION:**
//!   * 0.0.1 - Initial release. (JS) 19/Dic/2022
//!
//!
//!
//! *Library compliance:*
//!
//! | Doc | Schematic | TB | ASRT |Params. Val.| Sintesys test| Unify Interface| Functional Model |
//! |-----|-----------|----|------|------------|--------------|----------------|------------------|
//! |  x  |    x      |  x |   x  |     x      |       x      |        x       |         x        |
//!
//!

module renaming_unit #(
    parameter PHYSICAL_REGISTERS = 64,
    parameter LOGICAL_REGISTERS = 32,
    parameter FE_WIDTH = 2,
    parameter COMMIT_WIDTH = 2,
    parameter MAX_SRC_PER_INSTR = 3,
    parameter GRADUATION_LIST_SIZE = 16,
    localparam PHY_REGS_BITS = $clog2(PHYSICAL_REGISTERS),
    localparam LOG_REGS_BITS = $clog2(LOGICAL_REGISTERS),
    localparam GRADUATION_LIST_BITS = $clog2(GRADUATION_LIST_SIZE)
) (
    input logic clk_i,
    input logic rstn_i,

    input logic valid_instr_i [FE_WIDTH-1:0],

    input logic [MAX_SRC_PER_INSTR-1:0] use_src_i [FE_WIDTH-1:0],
    input logic [MAX_SRC_PER_INSTR-1:0] [LOG_REGS_BITS-1:0] log_src_id_i [FE_WIDTH-1:0],

    input logic use_dst_i [FE_WIDTH-1:0],
    input logic [LOG_REGS_BITS-1:0] log_dst_id_i [FE_WIDTH-1:0],

    input logic valid_commit_gl_i [COMMIT_WIDTH-1:0],
    input logic [GRADUATION_LIST_SIZE-1:0] commit_gl_id_i [COMMIT_WIDTH-1:0],

    input logic valid_recovery_i [COMMIT_WIDTH-1:0],
    input logic [GRADUATION_LIST_BITS-1:0] recovery_gl_id_i [COMMIT_WIDTH-1:0],

    output logic valid_instr_o [FE_WIDTH-1:0],
    output logic [MAX_SRC_PER_INSTR-1:0] use_src_o [FE_WIDTH-1:0],
    output logic [MAX_SRC_PER_INSTR-1:0] [PHY_REGS_BITS-1:0] phys_src_id_o [FE_WIDTH-1:0],

    output logic use_dst_o [FE_WIDTH-1:0],
    output logic [PHY_REGS_BITS-1:0] phys_dst_id_o [FE_WIDTH-1:0],

    output logic out_of_resources_o, // GL slots, physical registers or RAT copies
    // OR/AND
    output logic [PHY_REGS_BITS-1:0] free_phys_regs_o
);

typedef struct packed {
    logic use_dst;
    logic [LOG_REGS_BITS-1:0] logical_reg;
    logic [PHY_REGS_BITS-1:0] old_physical_reg;
} gl_entry_lt;

// Structures
logic [PHY_REGS_BITS-1:0] frontend_register_alias_table [LOG_REGS_BITS-1:0];
logic [PHY_REGS_BITS-1:0] retirement_register_alias_table [LOG_REGS_BITS-1:0];
gl_entry_lt graduation_list [GRADUATION_LIST_SIZE-1:0];

// Input cleaning, if instruction is not valid, all related information should be 0
logic [MAX_SRC_PER_INSTR-1:0] use_src [FE_WIDTH-1:0];
logic use_dst [FE_WIDTH-1:0];
always_comb begin
    for (int i=0; i<FE_WIDTH; i++) begin
        for (int j=0; j<MAX_SRC_PER_INSTR; j++) begin
            use_src[i][j] = use_src_i[i][j] & valid_instr_i[i];
        end
        use_src[i] = use_dst_i[i] & valid_instr_i[i];
    end
end

logic [PHY_REGS_BITS-1:0] free_phys_regs;

logic [MAX_SRC_PER_INSTR-1:0] src_collision [FE_WIDTH-1:0]; // Which src of each instruction has a collision with an older instruction
logic [MAX_SRC_PER_INSTR-1:0] [$clog2(FE_WIDTH)-1:0] src_collision_idx [FE_WIDTH-1:0]; // Which older instr produces the collision for each src of the younger instruction

general_purpose_free_list #(
        .LIST_SIZE(PHYSICAL_REGISTERS),
        .WR_PORTS(COMMIT_WIDTH), // TODO: maybe more in a recovery?
        .RD_PORTS(FE_WIDTH),
        .RPTR_INIT_VALUE(0),
        .WPTR_INIT_VALUE(PHYSICAL_REGISTERS),
        .UNORDERED_READS(1'b1),
        .DISORDERED_RST_EN(1'b0)
    ) general_purpose_free_list_inst (
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .wr_ens_i(),
        .wr_list_ports_i(),   //! Writes ports
        .rd_ens_i(use_dst),   //! Array of read enables, when set, the elements at the rd_list_ports_i are consireded used, and the rd pointer of the fifo will be congrently updated to ouput the next aviable.
        .rd_list_ports_o(phys_dst_id),   //! Read data port, phisical addresses of registers that are being allocated by the renaming process.
        .remaining_elements_o(free_phys_regs),
        .fifo_full_o(),
        .fifo_empty_o()
);

// Graduation list
type_param_fifo #(
    .ROW_TYP(gl_entry_lt),
    .DEPTH(GRADUATION_LIST_SIZE)
) type_param_fifo_inst (
    .clk_i(clk_i),          //! System clock.
    .rstn_i(rstn_i),         //! Asynchronous reset active low.

    input   ROW_TYP  data_in_i,      //! Write port of the queue, the data type conneceted here must be the same as the one provided in ROW_TYP parameter.
    input            rd_fifo_i,      //! Read port enable, when set, the queue increments the read pointer and put the next value en the queue at data_out_o port.
    input            wr_fifo_i,      //! Write port enable, when set, the values in data_in_i port are writen in the current write pointer, and then this is incremented.

    output  ROW_TYP  data_out_o,     //! Read port of the queue, the data type conneceted here must be the same as the one provided in ROW_TYP parameter.

    output  logic    fifo_full_o,    //! Set when the queue is full.
    output  logic    fifo_empty_o    //! Set when the queue is empty.

);

virtual_dependency_detector #(
    .FE_WIDTH(FE_WIDTH),
    .MAX_SRC_PER_INSTR(MAX_SRC_PER_INSTR)
) virtual_dependency_detector_inst (
    .use_src_i(use_src),
    .log_src_id_i(log_src_id_i),
    .use_dst_i(use_dst)
    .log_dst_id_i(log_dst_id_i),

    .src_collision_i(src_collision),
    .src_collision_idx_i(src_collision_idx),
);

// Frontend RAT Writting
always_ff @(posedge clk_i or negedge rstn_i) begin
    if(~rstn_i) begin
        frontend_register_alias_table <= 0;
    end else begin
        for (int i=0; i<FE_WIDTH; i++) begin: block_name
            if(use_dst[i]) begin
                frontend_register_alias_table[log_dst_id_i[i]] <= phys_dst_id[i];
            end
        end
    end
end

// Retirement RAT Writting

logic [PHY_REGS_BITS-1:0] [MAX_SRC_PER_INSTR-1:0] phys_src_id [FE_WIDTH-1:0];
logic [PHY_REGS_BITS-1:0] phys_dst_id [FE_WIDTH-1:0];

// Sources translation
always_comb begin
    for (int i=0; i<FE_WIDTH; i++) begin
        for (int j=0; j<MAX_SRC_PER_INSTR; j++) begin
            if (src_collision[i][j]) begin // There is a dependency with a younger instruction
                phys_src_id = phys_dst_id[src_collision_idx[i][j]]; // Assign the destination register of the producer
            end else begin // If not, read the RAT
                phys_src_id = frontend_register_alias_table[log_src_id_i[i][j]];
            end
        end
    end
end

// Output assignation
assign use_src_o = use_src;
assign phys_src_id_o = phys_src_id;
assign use_dst_o = use_dst;
assign phys_dst_id_o = phys_dst_id;


endmodule