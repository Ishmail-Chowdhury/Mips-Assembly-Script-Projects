module mips32_system #(
    parameter integer WORDS = 1024,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_mem_addr,
    output wire [31:0] debug_mem_wdata,
    output wire        debug_mem_we,
    output wire [31:0] debug_reg_v0,
    output wire [31:0] debug_reg_v1,
    output wire [31:0] debug_reg_a0,
    output wire [31:0] debug_reg_a1,
    output wire [31:0] debug_reg_sp,
    output wire [31:0] debug_reg_ra
);
    wire [31:0] instr_addr;
    wire [31:0] instr_data;
    wire [31:0] data_addr;
    wire [31:0] data_rdata;
    wire [31:0] data_wdata;
    wire data_we;

    assign debug_mem_addr = data_addr;
    assign debug_mem_wdata = data_wdata;
    assign debug_mem_we = data_we;

    mips32_core core (
        .clk(clk),
        .reset(reset),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_addr(data_addr),
        .data_rdata(data_rdata),
        .data_wdata(data_wdata),
        .data_we(data_we),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_reg_v0(debug_reg_v0),
        .debug_reg_v1(debug_reg_v1),
        .debug_reg_a0(debug_reg_a0),
        .debug_reg_a1(debug_reg_a1),
        .debug_reg_sp(debug_reg_sp),
        .debug_reg_ra(debug_reg_ra)
    );

    mips32_dual_port_ram #(
        .WORDS(WORDS),
        .INIT_FILE(INIT_FILE)
    ) memory (
        .clk(clk),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_addr(data_addr),
        .data_we(data_we),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata)
    );
endmodule
