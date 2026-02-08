`timescale 1ns / 1ps
module VM(
    clk, rst_n,
    in_item_valid,
    in_item_price,
    
    in_coin_valid,
    in_coin,
    
    in_buy_item,
    in_rtn_coin,
    
    out_monitor,
    out_sell_num,
    out_consumer,
    out_valid
);
input clk, rst_n, in_item_valid, in_coin_valid, in_rtn_coin;
input [2:0] in_buy_item;
input [5:0] in_coin;
input [4:0] in_item_price;

output logic [8:0] out_monitor;
output logic [3:0] out_consumer;
output logic [5:0] out_sell_num;
output logic out_valid;

logic [2:0] cnt ,cnt_nxt;
logic [1:0] state, state_next;
parameter SET = 2'b00;
parameter COIN = 2'b01;
parameter BUY_OR_RTN = 2'b10;
parameter OUT = 2'b11;

assign cnt_nxt = ((state==SET || state==OUT) ? cnt + 1 : 3'd1);
assign out_valid = (state==OUT ? 1 : 0);

// FSM state
always_comb begin
    case(state)
        SET : state_next = (cnt==6 ? COIN : SET);
        COIN : state_next = (in_item_valid ? SET : ((in_rtn_coin==1 || in_buy_item!=0) ? BUY_OR_RTN : COIN));
        default :  state_next = (cnt==6 ? COIN : OUT);
    endcase
end

// SET state
logic [4:0] item [6:0];
always@(*) begin
    if(state_next==SET) begin
        item[0] = 0;
        item[1] = (cnt_nxt==1 ? in_item_price : item[1]);
        item[2] = (cnt_nxt==2 ? in_item_price : item[2]);
        item[3] = (cnt_nxt==3 ? in_item_price : item[3]);
        item[4] = (cnt_nxt==4 ? in_item_price : item[4]);
        item[5] = (cnt_nxt==5 ? in_item_price : item[5]);
        item[6] = (cnt_nxt==6 ? in_item_price : item[6]);
    end
end

//BUY_OR_RTN state
logic success,success_next;
always_comb begin
    case(state_next)
        BUY_OR_RTN : success_next = (out_monitor >= item[in_buy_item] ? 1 : 0); // return also included
        OUT : success_next = success;
        default : success_next = 0;
    endcase
end

logic [8:0] out_monitor_nxt;
assign out_monitor_nxt = ((success_next==1) ? 0 : out_monitor + in_coin);

// calculate
logic [8:0] remain,remain_nxt;
logic [3:0] num50, num50_nxt;
logic [1:0] num20, num20_nxt;
logic [2:0] num1,num1_nxt;
logic num10,num5, num10_nxt,num5_nxt;

logic [8:0] sub;
assign remain_nxt = (state_next==BUY_OR_RTN ? out_monitor - item[in_buy_item] : remain - sub);

always_comb begin
    case(cnt_nxt)
        3'd1: begin
            if(remain>=500)begin
                sub = 500; num50_nxt = 10;
            end else if(remain>=450)begin
                sub = 450; num50_nxt = 9;
            end else if(remain>=400)begin
                sub = 400; num50_nxt = 8;
            end else if(remain>=350)begin
                sub = 350; num50_nxt = 7;
            end else if(remain>=300)begin
                sub = 300; num50_nxt = 6;
            end else if(remain>=250)begin
                sub = 250; num50_nxt = 5;
            end else if(remain>=200)begin
                sub = 200; num50_nxt = 4;
            end else if(remain>=150)begin
                sub = 150; num50_nxt = 3;
            end else if(remain>=100)begin
                sub = 100; num50_nxt = 2;
            end else if(remain>=50) begin
                sub = 50; num50_nxt = 1;
            end else begin
                sub = 0; num50_nxt = 0;
            end
        end
        3'd2: begin
            if(remain>=40) begin
                sub = 40; num20_nxt = 2;
            end else if(remain>=20) begin
                sub = 20; num20_nxt = 1;
            end else begin
                sub = 0; num20_nxt = 0;
            end
        end
        3'd3: begin
            sub = (remain>=10 ? 10 : 0);
            num10_nxt = (remain>=10 ? 1 : 0);
        end
        3'd4: begin
            sub = (remain>=5 ? 5 : 0);
            num5_nxt = (remain>=5 ? 1 : 0);
        end
        3'd5: begin
            sub = remain;
            num1_nxt = remain;
        end
        default: begin end
    endcase
end

logic [2:0] sure_buy_item;
assign sure_buy_item = (success==1 ? sure_buy_item : in_buy_item);

// OUT state
always_comb begin
    if(success)begin
        case(cnt)
            3'd1: out_consumer = sure_buy_item;
            3'd2: out_consumer = num50;
            3'd3: out_consumer = num20;
            3'd4: out_consumer = num10;
            3'd5: out_consumer = num5;
            3'd6: out_consumer = num1;
            default: out_consumer = 0;
        endcase
    end else out_consumer = 0;
end

// sell_number
logic [5:0] sold [6:0];
logic [5:0] sold_nxt [6:0];
always_comb begin
    if(state_next==SET) begin
        sold_nxt = {0,0,0,0,0,0,0};
    end else if(state_next==BUY_OR_RTN && success_next)begin 
        if(sure_buy_item>=1 && sure_buy_item<=6) sold_nxt[sure_buy_item] = sold[sure_buy_item] + 1;
        else sold_nxt[sure_buy_item] = sold[sure_buy_item];
    end else sold_nxt[sure_buy_item] = sold[sure_buy_item];
end

assign out_sell_num = (cnt>=1 && cnt<=6 ? sold[cnt] : 0);

// sequential logic
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cnt <= 3'd0;
        state <= COIN;
        item[1] <= 0; item[2] <= 0; item[3] <= 0;
        item[4] <= 0; item[5] <= 0; item[6] <= 0;
        out_monitor <= 0;
        out_sell_num <= 0;
        success <= 0;
        
        remain <= 0;
        num50 <= 0;
        num20 <= 0;
        num10 <= 0;
        num5 <= 0;
        num1 <= 0;
        
        sold <= {0,0,0,0,0,0,0};
    end else begin
        state <= state_next;
        cnt <= cnt_nxt;
        out_monitor <= out_monitor_nxt;
        success <= success_next;
        
        remain <= remain_nxt;
        num50 <= num50_nxt;
        num20 <= num20_nxt;
        num10 <= num10_nxt;
        num5 <= num5_nxt;
        num1 <= num1_nxt;
        
        sold <= sold_nxt;
    end
end
initial begin
    out_monitor = 9'd0;
    out_sell_num = 6'd0;
    success = 0;
    cnt = 0;
    state = COIN;
    remain = 0;
    num50 = 0;
    num20 = 0;
    num10 = 0;
    num5 = 0;
    num1 = 0;
end

endmodule
