module MIPS(
    //Input 
    clk,
    rst_n,
    in_valid,
    instruction,
	output_reg,
    //OUTPUT
    out_valid,
    out_1,
	out_2,
	out_3,
	out_4,
	instruction_fail
);
//Input 
input clk, rst_n, in_valid;
input [31:0] instruction;
input [19:0] output_reg;
//OUTPUT
output logic out_valid, instruction_fail;
output logic [31:0] out_1, out_2, out_3, out_4;

// Logic Declaration
logic [31:0] reg_file [5:0];
logic [31:0] instruction_reg;
logic [19:0] output_reg$1;
logic out_valid$1, legal;
logic [5:0] opcode, funct;
logic [4:0] rs, rt, rd, shamt , rd_nxt;
logic [31:0] rs_nxt, rt_nxt;
logic rs_legal, rt_legal, rd_legal, instruction_fail_nxt, op_nxt;
logic [15:0] imm_nxt;

logic [31:0] reg_file_nxt [5:0];
logic [31:0] rs_alu, rt_alu, result;
logic [4:0] rd_reg;
logic op, instruction_fail_reg$1;
logic [15:0] imm_alu;
logic [19:0] output_reg$2;
logic out_valid$2;

logic [19:0] output_reg$3;
logic out_valid$3, instruction_fail_reg$2;

// Stage1: FF 
always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid$1 <= 0;
        instruction_reg <= 0;
        output_reg$1 <= 0;
    end else begin
        out_valid$1 <= in_valid;
        instruction_reg <= (in_valid ? instruction : 0);
        output_reg$1 <= (in_valid ? output_reg : 0);
    end
end
// Stage1: Decode & Read Reg
assign {opcode, rs, rt, rd, shamt, funct} = instruction_reg;
assign imm_nxt = {rd, shamt, funct};
always_comb begin
    case(opcode)
        6'b000000: begin
            case(funct)
                6'b100000, 6'b100100, 6'b100101, 6'b100111, 6'b000000, 6'b000010: legal = 1; // R
                default: legal = 0; // Fail
            endcase
        end
        6'b001000: legal = 1; // I
        default: legal = 0;
    endcase
end
// check rs and allocate rs_nxt
always_comb begin
    case(rs)
        5'b10001: begin rs_nxt = reg_file[0]; rs_legal = 1; end
        5'b10010: begin rs_nxt = reg_file[1]; rs_legal = 1; end
        5'b01000: begin rs_nxt = reg_file[2]; rs_legal = 1; end
        5'b10111: begin rs_nxt = reg_file[3]; rs_legal = 1; end
        5'b11111: begin rs_nxt = reg_file[4]; rs_legal = 1; end
        5'b10000: begin rs_nxt = reg_file[5]; rs_legal = 1; end
        default: rs_legal = 0;
    endcase
end
// check rt and allocate rt_nxt
always_comb begin
    case(rt)
        5'b10001: begin rt_nxt = reg_file[0]; rt_legal = 1; end
        5'b10010: begin rt_nxt = reg_file[1]; rt_legal = 1; end
        5'b01000: begin rt_nxt = reg_file[2]; rt_legal = 1; end
        5'b10111: begin rt_nxt = reg_file[3]; rt_legal = 1; end
        5'b11111: begin rt_nxt = reg_file[4]; rt_legal = 1; end
        5'b10000: begin rt_nxt = reg_file[5]; rt_legal = 1; end
        default: rt_legal = 0;
    endcase
end
// check rd and allocate rd_nxt
assign rd_nxt = (op_nxt ? rt : rd);
always_comb begin
    case(rd_nxt) // notice
        5'b10001, 5'b10010, 5'b01000, 5'b10111, 5'b11111, 5'b10000: rd_legal = 1;
        default: rd_legal = 0;
    endcase
end

//connected to next stage
logic sure_legal;
assign sure_legal = rs_legal && rt_legal && rd_legal;
assign instruction_fail_nxt = (out_valid$1==0 ? 0 : ((legal==0 || sure_legal==0) ? 1 : 0));
assign op_nxt = opcode[3];

//Stage2: FF
always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        output_reg$2 <= 0;
        out_valid$2 <= 0;
        instruction_fail_reg$1 <= 0;
        op <= 0;
        rs_alu <= 0;
        rt_alu <= 0;
        rd_reg <= 0;
        imm_alu <= 0;
    end else begin
        output_reg$2 <= output_reg$1;
        out_valid$2 <= out_valid$1;
        instruction_fail_reg$1 <= instruction_fail_nxt;
        op <= op_nxt;
        rs_alu <= rs_nxt;
        rt_alu <= rt_nxt;
        rd_reg <= rd_nxt;
        imm_alu <= imm_nxt;
    end
end
//Stage3: ALU calculate
always_comb begin
    if(!op)begin
        case(imm_alu[5:0])
            6'b100000: result = rs_alu + rt_alu;
            6'b100100: result = rs_alu & rt_alu;
            6'b100101: result = rs_alu | rt_alu;
            6'b100111: result = ~(rs_alu | rt_alu);
            6'b000000: result = rt_alu << imm_alu[10:6];
            6'b000010: result = rt_alu >> imm_alu[10:6];
        endcase
    end else result = rs_alu + imm_alu;
end

always_comb begin
    if(instruction_fail_reg$1) reg_file_nxt = reg_file;
    else begin
        case(rd_reg)
            5'b10001: reg_file_nxt = {reg_file[5], reg_file[4], reg_file[3], reg_file[2], reg_file[1], result};
            5'b10010: reg_file_nxt = {reg_file[5], reg_file[4], reg_file[3], reg_file[2], result, reg_file[0]};
            5'b01000: reg_file_nxt = {reg_file[5], reg_file[4], reg_file[3], result, reg_file[1], reg_file[0]};
            5'b10111: reg_file_nxt = {reg_file[5], reg_file[4], result, reg_file[2], reg_file[1], reg_file[0]};
            5'b11111: reg_file_nxt = {reg_file[5], result, reg_file[3], reg_file[2], reg_file[1], reg_file[0]};
            5'b10000: reg_file_nxt = {result, reg_file[4], reg_file[3], reg_file[2], reg_file[1], reg_file[0]};
            default: reg_file_nxt = reg_file;
        endcase
    end
end

//Stage3: FF & Write back
always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        reg_file <= {0,0,0,0,0,0};
        output_reg$3 <= 0;
        out_valid$3 <= 0;
        instruction_fail_reg$2 <= 0;
    end else begin
        reg_file <= reg_file_nxt;
        output_reg$3 <= output_reg$2;
        out_valid$3 <= out_valid$2;
        instruction_fail_reg$2 <= instruction_fail_reg$1;
    end
end
//Stage3: Output select
always_comb begin
    if(instruction_fail) begin
        out_1 = 0; out_2 = 0; out_3 = 0; out_4 = 0;
    end else begin
        case(output_reg$3[4:0])
            5'b10001: out_1 = reg_file[0];
            5'b10010: out_1 = reg_file[1];
            5'b01000: out_1 = reg_file[2];
            5'b10111: out_1 = reg_file[3];
            5'b11111: out_1 = reg_file[4];
            5'b10000: out_1 = reg_file[5];
            default: out_1 = 0;
        endcase
        case(output_reg$3[9:5])
            5'b10001: out_2 = reg_file[0];
            5'b10010: out_2 = reg_file[1];
            5'b01000: out_2 = reg_file[2];
            5'b10111: out_2 = reg_file[3];
            5'b11111: out_2 = reg_file[4];
            5'b10000: out_2 = reg_file[5];
            default: out_2 = 0;
        endcase
        case(output_reg$3[14:10])
            5'b10001: out_3 = reg_file[0];
            5'b10010: out_3 = reg_file[1];
            5'b01000: out_3 = reg_file[2];
            5'b10111: out_3 = reg_file[3];
            5'b11111: out_3 = reg_file[4];
            5'b10000: out_3 = reg_file[5];
            default: out_3 = 0;
        endcase
        case(output_reg$3[19:15])
            5'b10001: out_4 = reg_file[0];
            5'b10010: out_4 = reg_file[1];
            5'b01000: out_4 = reg_file[2];
            5'b10111: out_4 = reg_file[3];
            5'b11111: out_4 = reg_file[4];
            5'b10000: out_4 = reg_file[5];
            default: out_4 = 0;
        endcase
    end
end
assign out_valid = out_valid$3;
assign instruction_fail = instruction_fail_reg$2;
endmodule
