module mips32_dual_port_ram #(
    parameter integer WORDS = 1024,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_data,
    input  wire [31:0] data_addr,
    input  wire        data_we,
    input  wire [31:0] data_wdata,
    output wire [31:0] data_rdata
);
    reg [31:0] memory [0:WORDS-1];
    integer i;

    wire [29:0] instr_index = instr_addr[31:2];
    wire [29:0] data_index = data_addr[31:2];

    assign instr_data = (instr_index < WORDS) ? memory[instr_index] : 32'b0;
    assign data_rdata = (data_index < WORDS) ? memory[data_index] : 32'b0;

    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            memory[i] = 32'b0;
        end
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always @(posedge clk) begin
        if (data_we && (data_index < WORDS)) begin
            memory[data_index] <= data_wdata;
        end
    end
endmodule
