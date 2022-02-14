`timescale  1 ps / 1 ps
module grow_node_in_middle
#(
    parameter DIGIT_DIM=32
)
(
    input clk,
    input reset,
    input en,
    input [DIGIT_DIM-1:0] winner,
    input [DIGIT_DIM-1:0] node_next,
    output [DIGIT_DIM-1:0] weight,
    output is_done
);

reg done = 0;
reg init = 1;
reg [DIGIT_DIM-1:0] out;

reg [DIGIT_DIM-1:0] winner_in;
reg winner_in_valid = 0;
wire winner_in_ready;

reg [DIGIT_DIM-1:0] node_next_in;
reg node_next_in_valid = 0;
wire node_next_in_ready;

wire [DIGIT_DIM-1:0] new_weight_out;
reg new_weight_out_ready = 0;
wire new_weight_out_valid;

adder fpa_node_count_adder(
    .aclk(clk),
    .s_axis_a_tvalid(winner_in_valid),
    .s_axis_a_tready(winner_in_ready),
    .s_axis_a_tdata(winner_in),
    
    .s_axis_b_tvalid(node_next_in_valid),
    .s_axis_b_tready(node_next_in_ready),
    .s_axis_b_tdata(node_next_in),
    
    .m_axis_result_tvalid(new_weight_out_valid),
    .m_axis_result_tready(new_weight_out_ready),
    .m_axis_result_tdata(new_weight_out)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        done = 0;
        init = 1;
        
    end else if (en) begin    
        if (init) begin
            winner_in_valid = 1;
            node_next_in_valid = 1;
            new_weight_out_ready = 1;
            init = 0;
            
        end else if (new_weight_out_valid) begin
            out = new_weight_out;
            out[30:23] = new_weight_out[30:23]-1;
            done = 1;
            winner_in_valid = 0;
            node_next_in_valid = 0;
            new_weight_out_ready = 0;
            
        end
    end
end

assign is_done = done;
assign weight = out;

endmodule
