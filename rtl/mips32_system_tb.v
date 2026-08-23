`timescale 1ns/1ps

module mips32_system_tb;
    localparam integer WORDS = 1024;
    localparam INIT_FILE = "../quartus/programs/booths_1_2.hex";
    localparam integer MAX_CYCLES = 300;

    reg clk;
    reg reset;
    integer cycles;

    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_mem_addr;
    wire [31:0] debug_mem_wdata;
    wire        debug_mem_we;
    wire [31:0] debug_reg_v0;
    wire [31:0] debug_reg_v1;
    wire [31:0] debug_reg_a0;
    wire [31:0] debug_reg_a1;
    wire [31:0] debug_reg_sp;
    wire [31:0] debug_reg_ra;

    mips32_system #(
        .WORDS(WORDS),
        .INIT_FILE(INIT_FILE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_mem_addr(debug_mem_addr),
        .debug_mem_wdata(debug_mem_wdata),
        .debug_mem_we(debug_mem_we),
        .debug_reg_v0(debug_reg_v0),
        .debug_reg_v1(debug_reg_v1),
        .debug_reg_a0(debug_reg_a0),
        .debug_reg_a1(debug_reg_a1),
        .debug_reg_sp(debug_reg_sp),
        .debug_reg_ra(debug_reg_ra)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        cycles = 0;
        #40;
        reset = 1'b0;
    end

    always @(posedge clk) begin
        if (!reset) begin
            cycles <= cycles + 1;
            if (cycles >= MAX_CYCLES) begin
                $display("Timeout after %0d cycles", cycles);
                $display("pc=0x%08h v0=0x%08h v1=0x%08h", debug_pc, debug_reg_v0, debug_reg_v1);
                $finish;
            end
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            $display("cycle=%0d pc=0x%08h instr=0x%08h v0=0x%08h v1=0x%08h",
                     cycles, debug_pc, debug_instruction, debug_reg_v0, debug_reg_v1);
        end
    end
endmodule
