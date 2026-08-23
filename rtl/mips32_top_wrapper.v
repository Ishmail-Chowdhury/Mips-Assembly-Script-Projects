module mips32_top_wrapper #(
    parameter integer WORDS = 1024,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_v0,
    output wire [31:0] debug_v1
);
    wire [31:0] debug_instruction_unused;
    wire [31:0] debug_mem_addr_unused;
    wire [31:0] debug_mem_wdata_unused;
    wire        debug_mem_we_unused;
    wire [31:0] debug_reg_a0_unused;
    wire [31:0] debug_reg_a1_unused;
    wire [31:0] debug_reg_sp_unused;
    wire [31:0] debug_reg_ra_unused;

    mips32_system #(
        .WORDS(WORDS),
        .INIT_FILE(INIT_FILE)
    ) system_i (
        .clk(clk),
        .reset(reset),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction_unused),
        .debug_mem_addr(debug_mem_addr_unused),
        .debug_mem_wdata(debug_mem_wdata_unused),
        .debug_mem_we(debug_mem_we_unused),
        .debug_reg_v0(debug_v0),
        .debug_reg_v1(debug_v1),
        .debug_reg_a0(debug_reg_a0_unused),
        .debug_reg_a1(debug_reg_a1_unused),
        .debug_reg_sp(debug_reg_sp_unused),
        .debug_reg_ra(debug_reg_ra_unused)
    );
endmodule
