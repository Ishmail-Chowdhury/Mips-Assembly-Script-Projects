module mips32_core (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] instr_addr,
    input  wire [31:0] instr_data,
    output wire [31:0] data_addr,
    input  wire [31:0] data_rdata,
    output wire [31:0] data_wdata,
    output wire        data_we,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_reg_v0,
    output wire [31:0] debug_reg_v1,
    output wire [31:0] debug_reg_a0,
    output wire [31:0] debug_reg_a1,
    output wire [31:0] debug_reg_sp,
    output wire [31:0] debug_reg_ra
);
    reg [31:0] pc;
    reg [31:0] registers [0:31];
    integer i;

    wire [5:0] opcode = instr_data[31:26];
    wire [4:0] rs = instr_data[25:21];
    wire [4:0] rt = instr_data[20:16];
    wire [4:0] rd = instr_data[15:11];
    wire [4:0] shamt = instr_data[10:6];
    wire [5:0] funct = instr_data[5:0];
    wire [15:0] imm = instr_data[15:0];
    wire [25:0] jump_index = instr_data[25:0];

    wire [31:0] rs_value = (rs == 0) ? 32'b0 : registers[rs];
    wire [31:0] rt_value = (rt == 0) ? 32'b0 : registers[rt];
    wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};
    wire [31:0] zero_ext_imm = {16'b0, imm};
    wire [31:0] pc_plus_4 = pc + 32'd4;
    wire [31:0] branch_target = pc_plus_4 + (sign_ext_imm << 2);
    wire [31:0] jump_target = {pc_plus_4[31:28], jump_index, 2'b00};

    reg [31:0] alu_result;
    reg [31:0] writeback_value;
    reg [31:0] next_pc;
    reg [4:0] writeback_register;
    reg writeback_enable;
    reg mem_write_enable;

    assign instr_addr = pc;
    assign data_addr = rs_value + sign_ext_imm;
    assign data_wdata = rt_value;
    assign data_we = mem_write_enable;
    assign debug_pc = pc;
    assign debug_instruction = instr_data;
    assign debug_reg_v0 = registers[2];
    assign debug_reg_v1 = registers[3];
    assign debug_reg_a0 = registers[4];
    assign debug_reg_a1 = registers[5];
    assign debug_reg_sp = registers[29];
    assign debug_reg_ra = registers[31];

    always @(*) begin
        alu_result = 32'b0;
        writeback_value = 32'b0;
        writeback_register = 5'b0;
        writeback_enable = 1'b0;
        mem_write_enable = 1'b0;
        next_pc = pc_plus_4;

        case (opcode)
            6'h00: begin
                case (funct)
                    6'h20: begin
                        alu_result = rs_value + rt_value;
                        writeback_value = alu_result;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h22: begin
                        alu_result = rs_value - rt_value;
                        writeback_value = alu_result;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h24: begin
                        writeback_value = rs_value & rt_value;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h25: begin
                        writeback_value = rs_value | rt_value;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h26: begin
                        writeback_value = rs_value ^ rt_value;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h27: begin
                        writeback_value = ~(rs_value | rt_value);
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h2A: begin
                        writeback_value = ($signed(rs_value) < $signed(rt_value)) ? 32'd1 : 32'd0;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h00: begin
                        writeback_value = rt_value << shamt;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h02: begin
                        writeback_value = rt_value >> shamt;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h03: begin
                        writeback_value = $signed(rt_value) >>> shamt;
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h06: begin
                        writeback_value = rt_value >> rs_value[4:0];
                        writeback_register = rd;
                        writeback_enable = 1'b1;
                    end
                    6'h08: begin
                        next_pc = rs_value;
                    end
                    default: begin
                    end
                endcase
            end
            6'h08: begin
                writeback_value = rs_value + sign_ext_imm;
                writeback_register = rt;
                writeback_enable = 1'b1;
            end
            6'h0C: begin
                writeback_value = rs_value & zero_ext_imm;
                writeback_register = rt;
                writeback_enable = 1'b1;
            end
            6'h0D: begin
                writeback_value = rs_value | zero_ext_imm;
                writeback_register = rt;
                writeback_enable = 1'b1;
            end
            6'h0F: begin
                writeback_value = {imm, 16'b0};
                writeback_register = rt;
                writeback_enable = 1'b1;
            end
            6'h23: begin
                writeback_value = data_rdata;
                writeback_register = rt;
                writeback_enable = 1'b1;
            end
            6'h2B: begin
                mem_write_enable = 1'b1;
            end
            6'h04: begin
                if (rs_value == rt_value) begin
                    next_pc = branch_target;
                end
            end
            6'h05: begin
                if (rs_value != rt_value) begin
                    next_pc = branch_target;
                end
            end
            6'h02: begin
                next_pc = jump_target;
            end
            6'h03: begin
                writeback_value = pc_plus_4;
                writeback_register = 5'd31;
                writeback_enable = 1'b1;
                next_pc = jump_target;
            end
            default: begin
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else begin
            pc <= next_pc;
            if (writeback_enable && (writeback_register != 0)) begin
                registers[writeback_register] <= writeback_value;
            end
            registers[0] <= 32'b0;
        end
    end
endmodule
