`timescale 1ns / 1ps
module CN(
    // Input signals
    opcode,
	in_n0,
	in_n1,
	in_n2,
	in_n3,
	in_n4,
	in_n5,
    // Output signals
    out_n
);
//   INPUT AND OUTPUT DECLARATION                         
input [3:0] in_n0, in_n1, in_n2, in_n3, in_n4, in_n5;
input [4:0] opcode;
output logic [8:0] out_n;

// TODO
logic [4:0] arr [5:0];
logic [4:0] key [5:0];

address u0(in_n0,arr[0]);
address u1(in_n1,arr[1]);
address u2(in_n2,arr[2]);
address u3(in_n3,arr[3]);
address u4(in_n4,arr[4]);
address u5(in_n5,arr[5]);

// sort
sort uut(opcode[4:3],arr,key);

calculate ans(opcode[2:0],key,out_n);
endmodule

module address(
    input [3:0] in, // max 15
    output logic [4:0] value // max 31
);
always@(*)begin
    case(in)
        4'd0: value = 5'd9;
        4'd1: value = 5'd27;
        4'd2: value = 5'd30;
        4'd3: value = 5'd3;
        4'd4: value = 5'd11;
        4'd5: value = 5'd8;
        4'd6: value = 5'd26;
        4'd7: value = 5'd17;
        4'd8: value = 5'd3;
        4'd9: value = 5'd12;
        4'd10: value = 5'd1;
        4'd11: value = 5'd10;
        4'd12: value = 5'd15;
        4'd13: value = 5'd5;
        4'd14: value = 5'd23;
        4'd15: value = 5'd20;
    endcase
end
endmodule

module calculate(
    input logic [2:0] op,
    input logic [4:0] num [5:0],
    output logic [8:0] out
);
always@(*)begin
    case(op)
        3'b000: out = num[2] - num[1];
        3'b001: out = num[0] + num[3];
        3'b010: out = (num[3] * num[4])>>1;
        3'b011: out = num[1] + (num[5]<<1);
        3'b100: out = num[2] & num[1];
        3'b101: out = ~num[0];
        3'b110: out = num[4] ^ num[3];
        3'b111: out = num[1]<<1;
    endcase
end
endmodule

module sort(
    input [1:0] opcode,
    input logic [4:0] num [5:0],
    output logic [4:0] ValArray [5:0]
);

logic [2:0] i,j;

always @(*) begin
    ValArray = num;
    for(i=0; i<6; i=i+1) begin
        if(i & 2) begin
            for(j=1; j<5; j=j+2) begin
                if(ValArray[j] > ValArray[j+1]) begin
                    ValArray[j] ^= ValArray[j+1];
                    ValArray[j+1] ^= ValArray[j];
                    ValArray[j] ^= ValArray[j+1];
                end
            end
        end else begin
            for(j=0; j<5; j=j+2) begin
                if(ValArray[j] > ValArray[j+1]) begin
                    ValArray[j] ^= ValArray[j+1];
                    ValArray[j+1] ^= ValArray[j];
                    ValArray[j] ^= ValArray[j+1];
                end
            end
        end
    end
    case(opcode)
        2'b11: begin end
        2'b10: begin
            ValArray[0] ^= ValArray[5];
            ValArray[5] ^= ValArray[0];
            ValArray[0] ^= ValArray[5];
            
            ValArray[1] ^= ValArray[4];
            ValArray[4] ^= ValArray[1];
            ValArray[1] ^= ValArray[4];
            
            ValArray[2] ^= ValArray[3];
            ValArray[3] ^= ValArray[2];
            ValArray[2] ^= ValArray[3];
        end
        2'b01: ValArray = {num[0], num[1], num[2], num[3], num[4], num[5]};
        2'b00: ValArray = num;
    endcase
end

endmodule