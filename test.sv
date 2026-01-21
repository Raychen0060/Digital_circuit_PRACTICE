`timescale 1ns / 1ps
module Checkdigit(
    // Input signals
    in_num,
	in_valid,
	rst_n,
	clk,
    // Output signals
    out_valid,
    out
);
    input [3:0] in_num;
    input clk, rst_n, in_valid;
    output logic out_valid;
    output logic [3:0] out;
     
    reg [3:0] cnt;
    logic [4:0] sum; // sum may overflow so add 1 bit
    logic [3:0] act,ans,another;
    // if cnt==0, out_valid = 1
    assign out_valid = ~|cnt;
     
    assign act = (cnt[0] ? another : in_num);
    assign another = (in_num<=4 ? in_num<<1 : in_num-(9-in_num));
    
    assign ans = (sum>0 && sum<10 ? 10-sum : 15);
    assign out = (out_valid ? ans : 0);
     
     // read 1 : count
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) cnt <= 15;
        else cnt <= (in_valid ? cnt-1 : 15);
    end
    
     // read 2 : find digit
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) sum <= 0;
        else sum <= (in_valid ? (sum+act > 10 ? sum+act-10 : sum+act) : 0);
    end
endmodule
