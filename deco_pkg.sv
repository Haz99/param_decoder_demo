package deco_pkg;

// TODO: add a floating point datapath

parameter XLEN = 64;
parameter INST_SIZE = 32;

// Common for RISCV types
typedef struct packed {
    logic [31:25] func7;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] func3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
} instruction_common_t;

// Instruction formats
typedef struct packed {
    logic [31:25] func7;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] func3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
} instruction_rtype_t;

typedef struct packed {
    logic [31:20] imm;
    logic [19:15] rs1;
    logic [14:12] func3;
    logic [11:7]  rd;
    logic [6:0]   opcode;
} instruction_itype_t;

typedef struct packed {
    logic [31:25] imm5;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] func3;
    logic [11:7]  imm0;
    logic [6:0]  opcode;
} instruction_stype_t;

typedef struct packed {
    logic [31:31] imm12;
    logic [30:25] imm5;
    logic [24:20] rs2;
    logic [19:15] rs1;
    logic [14:12] func3;
    logic [11:8]  imm1;
    logic [7:7]   imm11;
    logic [6:0]   opcode;
} instruction_btype_t;

typedef struct packed {
    logic [31:12] imm;
    logic [11:7]  rd;
    logic [6:0]   opcode;
} instruction_utype_t;

typedef struct packed {
    logic [31:31] imm20;
    logic [30:21] imm1;
    logic [20:20] imm11;
    logic [19:12] imm12;
    logic [11:7]  rd;
    logic [6:0]   opcode;
} instruction_jtype_t;

// RISCV Instruction types
typedef union packed {
    logic [INST_SIZE-1:0] bits;
    instruction_common_t  common;
    instruction_rtype_t   rtype;
    instruction_itype_t   itype;
    instruction_stype_t   stype;
    instruction_btype_t   btype;
    instruction_utype_t   utype;
    instruction_jtype_t   jtype;
} instruction_t;

// Intruction opcodes
typedef enum logic [6:0] {
    // Minimal set of opcodes (RV32I and RV32E)
    OP_LUI       = 7'b0110111,
    OP_AUIPC     = 7'b0010111,
    OP_JAL       = 7'b1101111,
    OP_JALR      = 7'b1100111,
    OP_BRANCH    = 7'b1100011,
    OP_LOAD      = 7'b0000011,
    OP_STORE     = 7'b0100011,
    OP_ALU_I     = 7'b0010011,  // OP-IMM
    OP_ALU       = 7'b0110011,  // OP
    OP_FENCE     = 7'b0001111,
    OP_SYSTEM    = 7'b1110011,

    //---RV64I_on
    OP_ALU_I_W   = 7'b0011011,
    OP_ALU_W     = 7'b0111011,
    //---RV64I_off

    //----------------------------------- Base Integer Instructions Set

    //---A_on
    OP_ATOMICS   = 7'b0101111,
    //---A_off

    //---F_on
    OP_LOAD_FP   = 7'b0000111,
    OP_STORE_FP  = 7'b0100111,
    OP_FP        = 7'b1010011,
    OP_FMADD     = 7'b1000011,
    OP_FMSUB     = 7'b1000111,
    OP_FNMSUB    = 7'b1001011,
    OP_FNMADD    = 7'b1001111
    //---F_off

} opcode_et;

typedef enum logic [2:0] {
    F3_0 = 3'b000,
    F3_1 = 3'b001,
    F3_2 = 3'b010,
    F3_3 = 3'b011,
    F3_4 = 3'b100,
    F3_5 = 3'b101,
    F3_6 = 3'b110,
    F3_7 = 3'b111
} f3_et;

// TODO: complete this
typedef enum logic [6:0] {
    F7_0 = 7'b0000000,
    F7_1 = 7'b0000001,
    F7_2 = 7'b0000010,
    F7_3 = 7'b0000011,
    F7_4 = 7'b0000100,
    F7_5 = 7'b0000101,
    F7_6 = 7'b0000110,
    F7_7 = 7'b0000111,
    F7_8 = 7'b0001000,
    F7_9 = 7'b0001001,
    F7_10 = 7'b0001010,
    F7_32 = 7'b0100000,
} f7_et;

typedef enum logic [7:0] {
    // Minimal set of instructions (RV32I and RV32E)
    LUI, AUIPC, JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU, LB, LH, LW, LBU, LHU, SB, SH, SW,
    ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL,
    SRA, OR, AND, FENCE, ECALL, EBREAK,

    //---RV64I_on
    LWU, LD, SD, SLLI, SRLI, SRAI, ADDIW, SLLIW, SRLIW, SRAIW, ADDW, SUBW, SLLW, SRLW, SRAW,
    //---RV64I_off

    //---Zifencei_on
    FENCE_I,
    //---Zifencei_off

    //---Zicsr_on
    CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI,
    //---Zicsr_off

    //---RV32M_on
    MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU,
    //---RV32M_off

    //---RV64M_on
    MULW, DIVW, DIVUW, REMW, REMUW
    //---RV64M_off
} instr_type_et;


typedef enum logic [2:0] {
    INTEGER_QUEUE,
    MEMORY_QUEUE,
    FLOAT_QUEUE,
    GLOBAL_QUEUE,
    // Add here new queues
} queue_et;

typedef enum logic [3:0]{
    UNIT_ALU,                   // ALU
    UNIT_DIV,                   // DIVISION
    UNIT_MUL,                   // MULTIPLICATION
    UNIT_BRANCH,                // Branch computation
    UNIT_MEM,                   // Memory unit
    UNIT_FPU                    // Floating-point Unit
    // Add here new FUs
} functional_unit_et;   // Selection of funtional unit in exe stage

typedef enum logic [2:0]{
    RV32I,
    RV32E,
    RV64I
} base_integer_set_et;

typedef enum logic [2:0]{
    M,      // Integer multiplication and divison
    A,      // Atomic instructions
    NULL
} isa_extension_et;

endpackage
