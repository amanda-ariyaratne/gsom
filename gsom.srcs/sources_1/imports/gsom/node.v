`timescale  1 ps / 1 ps
module node #(
    parameter DIM=11,
    parameter DIGIT_DIM=32,
    parameter LOG2_MAX_ROWS=4,
    parameter LOG2_MAX_COLS=4,
    parameter CS_COUNT = 6
) (
    input clk,
    input reset,
    input [CS_COUNT-1:0] controls_in,
    
    input [DIGIT_DIM-1:0] row,
    input [DIGIT_DIM-1:0] col,
    input [DIGIT_DIM*DIM-1:0] current_input,

    input [LOG2_MAX_ROWS-1:0] winner_row,
    input [LOG2_MAX_COLS-1:0] winner_col,
    input [DIGIT_DIM*DIM*4-1: 0] neighbor_weights,

    input [3:0] nb_radius,
    input [DIGIT_DIM-1:0] learning_rate,
    input [DIGIT_DIM-1:0] GT,
    input [DIGIT_DIM-1:0] FD,

    output [DIGIT_DIM*DIM-1:0] weight_out,
    output active,
    output [DIGIT_DIM-1:0] distance,
    output [CS_COUNT-1:0] controls_out,
    output error_overflowed
);

///////////////////////////////////////////**************************variables**************************/////////////////////////////////////////////////////

reg [DIGIT_DIM*DIM-1:0] weight=0;
reg [DIGIT_DIM-1:0] error=0;
reg is_active=0;
reg [LOG2_MAX_COLS-1:0] hz_dist = 0;
reg [LOG2_MAX_ROWS-1:0] vt_dist = 0;
reg growing_started=0;

reg [CS_COUNT-1:0] controls_out_signals = 0;
reg error_overflowed_signal = 0;

assign active = is_active;
assign weight_out = weight;
assign controls_out = controls_out_signals;
assign error_overflowed = error_overflowed_signal;

///////////////////////////////////////////**************************calculate distance**************************/////////////////////////////////////////////////////
reg distance_en=0;
reg distance_reset=0;
wire distance_done;

euclidean_distance
#(
    .DIM(DIM),
    .DIGIT_DIM(DIGIT_DIM)
)
distance_module(
    .clk(clk),
    .en(distance_en),
    .reset(distance_reset),
    .weight(weight),
    .current_input(current_input),    
    .distance_out(distance),
    .is_done(distance_done)
);

///////////////////////////////////////////**************************update_bmu && update_neighbour**************************/////////////////////////////////////////////////////
reg update_en=0;
reg update_reset=0;
reg [DIGIT_DIM-1:0]  update_learning_rate;
wire [DIGIT_DIM*DIM-1:0] update_out;
wire [DIM-1:0] update_done;

genvar update_i;
generate
    for (update_i=1; update_i<=DIM; update_i=update_i+1) begin
        update_bmu 
        #(
            .DIM(DIM),
            .DIGIT_DIM(DIGIT_DIM)
        )
        update_weight(
            .clk(clk),
            .en(update_en),
            .reset(update_reset),
            .weight(weight[update_i*DIGIT_DIM-1 -:DIGIT_DIM]),
            .train_row(current_input[update_i*DIGIT_DIM-1 -:DIGIT_DIM]),
            .alpha(update_learning_rate),
            .updated_weight(update_out[update_i*DIGIT_DIM-1 -:DIGIT_DIM]),
            .is_done(update_done[update_i-1])
        );
    end
endgenerate

///////////////////////////////////////////**************************update_node_error_spreading**************************/////////////////////////////////////////////////////
reg update_error_en = 0;
reg update_error_reset = 0;
wire [DIGIT_DIM-1:0] updated_error;
wire update_error_done;

fpa_multiplier update_error(
    .clk(clk),
    .en(update_error_en),
    .reset(update_error_reset),
    .num1(error),
    .num2(FD),
    .num_out(updated_error),
    .is_done(update_error_done)
);


///////////////////////////////////////////**************************update_node_error**************************/////////////////////////////////////////////////////
reg node_error_add_en=0;
reg node_error_add_reset;
wire [DIGIT_DIM-1:0] node_error_add_out;
wire node_error_add_done;

fpa_adder node_error_adder(
    .clk(clk),
    .en(node_error_add_en),
    .reset(node_error_add_reset),
    .num1(error),
    .num2(distance),
    .num_out(node_error_add_out),
    .is_done(node_error_add_done)
);

///////////////////////////////////////////**************************get_min**************************/////////////////////////////////////////////////////
wire [1:0] comp_out;
wire comp_done;
reg comp_en=0;
reg comp_reset=0;

fpa_comparator get_max(
    .clk(clk),
    .en(comp_en),
    .reset(comp_reset),
    .num1(GT),
    .num2(error),
    .num_out(comp_out),
    .is_done(comp_done)
);

///////////////////////////////////////////**************************/////////////////////////////////////////////////////

always @(posedge clk or posedge reset) begin
    if (reset) begin
        weight = 0;
        error = 0;
        is_active = 0;

    end else begin
        case(controls_in)

            // activate initial 4 nodes
            1 : begin
                if (row==4 && col==4) begin
                    weight=neighbor_weights[DIGIT_DIM*DIM*1-1 -:DIGIT_DIM*DIM];
                    is_active=1;

                end else if (row==4 && col==5) begin
                    weight=neighbor_weights[DIGIT_DIM*DIM*2-1 -:DIGIT_DIM*DIM];
                    is_active=1;

                end else if (row==5 && col==4) begin
                    weight=neighbor_weights[DIGIT_DIM*DIM*3-1 -:DIGIT_DIM*DIM];
                    is_active=1;

                end else if (row==5 && col==5) begin
                    weight=neighbor_weights[DIGIT_DIM*DIM*4-1 -:DIGIT_DIM*DIM];
                    is_active=1;

                end
                controls_out_signals[0] = 1;
            end

            // insert node 
            2 : begin
                
                if (!is_active && !controls_out_signals[1]) begin
                    if (winner_row == row+1 && winner_col == col) begin
                        weight=neighbor_weights[DIGIT_DIM*DIM*1-1 -:DIGIT_DIM*DIM];
                        is_active=1;
    
                    end else if (winner_row == row && winner_col+1 == col) begin
                        weight=neighbor_weights[DIGIT_DIM*DIM*2-1 -:DIGIT_DIM*DIM];
                        is_active=1;
    
                    end else if (winner_row == row-1 && winner_col == col) begin
                        weight=neighbor_weights[DIGIT_DIM*DIM*3-1 -:DIGIT_DIM*DIM];
                        is_active=1;
    
                    end else if (winner_row == row && winner_col-1 == col) begin
                        weight=neighbor_weights[DIGIT_DIM*DIM*4-1 -:DIGIT_DIM*DIM];
                        is_active=1;
    
                    end
                end
                controls_out_signals[1] = 1;

            end

            // calculate euclidean distance
            4 : begin
                if (is_active && !controls_out_signals[2]) begin
                    distance_en=1;
                    distance_reset=0;
                    if (distance_done) begin
                        distance_en=0;
                        distance_reset=1;
                        controls_out_signals[2] = 1;
                    end 
                    
                end else
                    controls_out_signals[2] = 1;

            end

            // weight update bmu or neighbor
            8 : begin
                if (is_active && !controls_out_signals[3]) begin
                    if (row > winner_row) begin 
                        vt_dist = row - winner_row;
                    end else begin 
                        vt_dist = winner_row - row;
                    end
                    if (col > winner_col) begin 
                        hz_dist = col - winner_col;
                    end else begin
                        hz_dist = winner_col - col;
                    end
    
                    // winner update
                    if (hz_dist + vt_dist == 0) begin
                        //$display("bmu %d %d %d %b %b", row, col, node_error_add_done, update_done, {DIM{1'b1}});
                        update_en=1;
                        update_reset=0;
    
                        node_error_add_en=1;
                        node_error_add_reset=0;
    
                        if (update_done=={DIM{1'b1}} && node_error_add_done) begin
                            update_en=0;
                            update_reset=1;
    
                            node_error_add_en=0;
                            node_error_add_reset=1;
                            error = node_error_add_out;
    
                            comp_reset = 0;
                            comp_en = 1;
    
                            controls_out_signals[3] = 1;
                        end
    
                    // neighbor update
                    end else if (hz_dist + vt_dist <= nb_radius) begin
                        update_en=1;
                        update_reset=0;
    
                        if (update_done=={DIM{1'b1}}) begin
                            update_en=0;
                            update_reset=1;
    
                            controls_out_signals[3] = 1;
                        end
                        
                    end else
                        controls_out_signals[3] = 1;
                    
                end else
                    controls_out_signals[3] = 1;
            end

            // decide to grow or not
            16 : begin

                if (winner_row == row && winner_col == col && !controls_out_signals[4]) begin
                    comp_en = 1;
                    comp_reset = 0;
                    
                    if (comp_done) begin
                        if (comp_out==2 || comp_out==0) begin
                            error_overflowed_signal = 1;
                            
                        end else if (comp_out==1) begin
                            error_overflowed_signal = 0;
                            
                        end
                        comp_en = 0;
                        comp_reset = 1;
                        controls_out_signals[4] = 1;
                    end

                end else begin
                    error_overflowed_signal = 0;
                    controls_out_signals[4] = 1;
                end
                
            end

            // spread error
            32 : begin
                if (!controls_out_signals[5]) begin
                    if (winner_row==row && winner_col==col) begin 
                        error = GT;
                        error[30:23] = GT[30:23]-1;
                        controls_out_signals[5] = 1;
    
                    end else if ((winner_row==row+1 && winner_col==col) || 
                                (winner_row==row && winner_col==col+1) || 
                                (winner_row==row-1 && winner_col==col) || 
                                (winner_row==row && winner_col==col-1)) begin 
    
                        update_error_en=1;
                        update_error_reset=0;
                        if (update_error_done) begin
                            update_error_en=0;
                            update_error_reset=1;
                            error = updated_error;
    
                            controls_out_signals[5] = 1;
                        end
                        
                    end else controls_out_signals[5] = 1;
                    
                end
            end

            // when no signal comes in
            default: begin
                controls_out_signals = {CS_COUNT{1'b0}};
                error_overflowed_signal = 0;
            end   
        endcase      
    end
end 

endmodule
