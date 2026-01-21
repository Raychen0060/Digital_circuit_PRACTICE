`timescale 1ns/1ps

module TESTBENCH();

logic [3:0] in_n0, in_n1, in_n2, in_n3, in_n4, in_n5;
logic [4:0] opcode;
logic [8:0] out_n;

initial begin
    in_n0 = 13;
    in_n1 = 8;
    in_n2 = 9;
    in_n3 = 0;
    in_n4 = 9;
    in_n5 = 12;
    opcode = 5'b11001;
    #30
    in_n0 = 3;
    in_n1 = 4;
    in_n2 = 7;
    in_n3 = 5;
    in_n4 = 2;
    in_n5 = 14;
    opcode = 5'b11011;
    #30
    in_n0 = 8;
    in_n1 = 15;
    in_n2 = 3;
    in_n3 = 14;
    in_n4 = 13;
    in_n5 = 5;
    opcode = 5'b10111;
end

CN I_CN(
	.opcode(opcode), .in_n0(in_n0),
	.in_n1(in_n1),
	.in_n2(in_n2),	.in_n3(in_n3),
	.in_n4(in_n4),
	.in_n5(in_n5),
	.out_n(out_n)
);

endmodule