`timescale  1 ps / 1 ps
module update_bmu
#(
    parameter DIM=11,
    parameter DIGIT_DIM=32
)
(
    input wire clk,
    input wire en,
    input wire reset,
    input wire [DIGIT_DIM-1:0] weight,
    input wire [DIGIT_DIM-1:0] train_row,
    input wire [DIGIT_DIM-1:0] alpha,
    output wire [DIGIT_DIM-1:0] updated_weight,
    output wire is_done    
);

reg [DIGIT_DIM-1:0] out;

reg en_1=1;
reg en_2=0;
reg en_3=0;
reg en_4=0;

reg done=0;

reg en_add=0;
reg add_reset;
reg [DIGIT_DIM-1:0] add_in_1;
reg [DIGIT_DIM-1:0] add_in_2;
wire [DIGIT_DIM-1:0] add_out;
wire add_done;

reg en_mul=0;
reg mul_reset;
reg [DIGIT_DIM-1:0] mul_in_1;
reg [DIGIT_DIM-1:0] mul_in_2;
wire [DIGIT_DIM-1:0] mul_out;
wire mul_done;

assign updated_weight = add_out;
assign is_done = done;

fpa_adder add(
    .clk(clk),
    .en(en_add),
    .reset(add_reset),
    .num1(add_in_1),
    .num2(add_in_2),
    .num_out(add_out),
    .is_done(add_done)
);

fpa_multiplier multiply(
    .clk(clk),
    .en(en_mul),
    .reset(mul_reset),
    .num1(mul_in_1),
    .num2(mul_in_2),
    .num_out(mul_out),
    .is_done(mul_done)
);

always @(posedge reset) begin
    done = 0;
    en_1=1;
end

always @(posedge clk) begin
    if (en && en_1) begin
        add_reset = 0;
        add_in_1 = weight;
        add_in_2 = train_row;
        add_in_1[DIGIT_DIM-1] = 1; // indicate subtraction
        en_add = 1; // on the adder module
        
        en_1=0; // off this block
        en_2=1; // on next block
    end
end

always @(posedge clk) begin
    if (en && en_2 && add_done) begin
        en_add=0; // off adder module
        add_reset = 1;
        
        mul_reset = 0;
        mul_in_1 = add_out;
        mul_in_2 = alpha;
        en_mul = 1; // on the adder module
        
        en_2=0; // off this block
        en_3=1; // on next block
    end
end

always @(posedge clk) begin
    if (en && en_3 && mul_done) begin
        en_mul=0; // off multi module
        mul_reset = 1;
        
        add_reset = 0;
        add_in_1 = weight;
        add_in_2 = mul_out;
        en_add = 1; // on the adder module
        
        en_3=0; // off this block
        en_4=1; // on next block
    end
end

always @(posedge clk) begin
    if (en && en_4 && add_done) begin
        en_add = 0;
        add_reset=1;
        done=1;
        en_4=0;
    end
end

endmodule