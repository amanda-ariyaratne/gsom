`timescale  1 ns / 1 ps
module fpa_distance
#(
    parameter DIM=4,
    parameter DIGIT_DIM=32
)
(
    input wire clk,
    input wire en,
    input wire reset,
    input wire [DIGIT_DIM-1:0] num1,
    input wire [DIGIT_DIM-1:0] num2,
    output wire [DIGIT_DIM-1:0] num_out,
    output wire is_done
);

reg init=1;
reg done=0;

reg sub_en=0;
reg sub_reset=0;
reg [31:0] sub_in_1;
reg [31:0] sub_in_2;
wire [31:0] subtraction_out;
wire subtraction_done;

reg squrae_en=0;
reg squrae_reset=0;
reg [31:0] square_in;
wire [31:0] square_out;
wire square_done;

fpa_adder subtraction_unit(
    .clk(clk),
    .en(sub_en),
    .reset(sub_reset),
    .num1(sub_in_1),
    .num2(sub_in_2),
    .num_out(subtraction_out),
    .is_done(subtraction_done)
);

//reg adder1_a_tvalid;
//wire adder1_a_tready;
//reg [DIGIT_DIM-1:0] adder1_a_tdata;
//reg adder1_b_tvalid;
//wire adder1_b_tready;
//reg [DIGIT_DIM-1:0] adder1_b_tdata;
//wire adder1_result_tvalid;
//reg adder1_result_tready;
//wire [DIGIT_DIM-1:0] adder1_result_tdata;

//adder adder1(
//  .aclk(clk),
//  .s_axis_a_tvalid(adder1_a_tvalid),
//  .s_axis_a_tready(adder1_a_tready),
//  .s_axis_a_tdata(adder1_a_tdata),
//  .s_axis_b_tvalid(adder1_b_tvalid),
//  .s_axis_b_tready(adder1_b_tready),
//  .s_axis_b_tdata(adder1_b_tdata),
//  .m_axis_result_tvalid(adder1_result_tvalid),
//  .m_axis_result_tready(adder1_result_tready),
//  .m_axis_result_tdata(adder1_result_tdata)
//);

fpa_multiplier square_unit(
    .clk(clk),
    .en(squrae_en),
    .reset(squrae_reset),
    .num1(square_in),
    .num2(square_in),
    .num_out(square_out),
    .is_done(square_done)
);

always @(posedge clk or posedge reset) begin 

    if (reset) begin 
        done = 0;
        init=1;
        
    end else begin 
        if (en && init) begin
            
//            adder1_a_tdata = num1;
//            adder1_b_tdata = num2;
//            if (~adder1_b_tvalid) adder1_b_tdata[DIGIT_DIM-1] = ~adder1_b_tdata[DIGIT_DIM-1];
//            adder1_a_tvalid = 1;
//            adder1_b_tvalid = 1;
//            adder1_result_tready = 1;
        
            sub_in_1 = num1;
            sub_in_2 = num2;
            sub_in_2[DIGIT_DIM-1] = ~sub_in_2[DIGIT_DIM-1]; // flip the sign bit
            sub_en=1;
            sub_reset=0;
            init=0;
        end
        
        if (subtraction_done && !squrae_en) begin // if (adder1_result_tvalid && !squrae_en) begin
//            adder1_a_tvalid = 0;
//            adder1_b_tvalid = 0;
//            adder1_result_tready = 0;
            sub_en=0;
            sub_reset=1;
            
            square_in = subtraction_out; // adder1_result_tdata;
            squrae_en=1;
            squrae_reset=0;
        end
        
        if (square_done) begin 
            done = 1;    
            squrae_en=0;        
            squrae_reset=1; 
        end
    end
        
end

assign is_done = done;
assign num_out = square_out;

endmodule
