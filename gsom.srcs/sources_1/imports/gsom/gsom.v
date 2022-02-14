`timescale 1ns / 1ps

module gsom
#(
    parameter DIM = 4,
    parameter LOG2_DIM = 3, 
    parameter DIGIT_DIM = 32,
    parameter CS_COUNT = 6,
    
    parameter INIT_ROWS = 2,
    parameter INIT_COLS = 2,
    
    parameter MAX_ROWS = 10,
    parameter MAX_COLS = 10,
    
    parameter LOG2_ROWS = 4,         
    parameter LOG2_COLS = 4,

    parameter MAX_NODE_SIZE = 100,
    parameter LOG2_NODE_SIZE = 7,
    
    parameter GROWING_ITERATIONS = 20,
    parameter LOG2_GROWING_ITERATIONS = 5,
    parameter SMOOTHING_ITERATIONS = 10,
    parameter LOG2_SMOOTHING_ITERATIONS = 4,
    parameter delta_growing_iter = 5,
    parameter delta_smoothing_iter = 3,
    
    parameter TRAIN_ROWS = 75,
    parameter LOG2_TRAIN_ROWS = 7,
    parameter TEST_ROWS = 150,
    parameter LOG2_TEST_ROWS = 8, 
    
    parameter LOG2_NUM_CLASSES = 2,
    
    // model parameters
    parameter spread_factor = 32'h3DCCCCCD, //0.1
    parameter spread_factor_logval = 32'hBF800000, // BF800000 = -1
    
    parameter GT = 32'h41135D8E, //9.21034037198 = -4*ln(spread_factor)
    parameter learning_rate=32'h3E99999A, // 0.3
    parameter smooth_learning_factor= 32'h3F4CCCCD, //0.8
    parameter max_radius=4,
    parameter FD=32'h3F8CCCCD, //1.1
    parameter r=32'h40733333, //3.8
    parameter alpha=32'h3F666666 //0.9
)
(
    input clk,
    input reset,
    output done_training
);

///////////////////////////////////////////**************************variables**************************/////////////////////////////////////////////////////

reg [LOG2_NODE_SIZE-1:0] node_count = 0;
reg [DIGIT_DIM-1:0] node_count_ieee754 = 32'h00000000;

reg [DIGIT_DIM-1:0] growth_threshold;
reg signed [3:0] radius;
reg [DIGIT_DIM-1:0] current_learning_rate;
reg signed [LOG2_GROWING_ITERATIONS:0] iteration;

reg signed [LOG2_TRAIN_ROWS:0] t1 = 0;
reg signed [LOG2_TEST_ROWS:0] t2 = 0;

reg init_gsom = 1;
reg fit_en = 0;
reg growing_iter_en = 0;
reg smoothing_iter_en = 0;
reg get_LR_en = 0;
reg grow_en = 0;
reg smooth_en = 0;
reg weights_update=0;
reg adjust_weights_en=0;
reg smoothing_en=0;
reg spread_weighs_en=0;
reg grow_nodes_en=0;
reg node_count_adder_en = 0;

reg next_iteration_en = 0;
reg next_t1_en = 0;

reg dist_enable = 0;
reg init_neigh_search_en=0;  
reg nb_search_en=0;
reg not_man_dist_en=0;
reg write_en = 0;
reg is_completed = 0;
reg min_distance_en=0;
reg bmu_en=0;
reg test_mode=0;
reg classification_en=0;

reg [DIGIT_DIM-1:0] min_distance;
reg [LOG2_ROWS-1:0] minimum_distance_indices [MAX_NODE_SIZE-1:0][1:0];
reg [LOG2_NODE_SIZE-1:0] min_distance_next_index = 0;
integer matrix_i, matrix_j;

reg [LOG2_ROWS-1:0] bmu [1:0];
reg [LOG2_ROWS-1:0] bmu_i;
reg [LOG2_COLS-1:0] bmu_j;

reg [LOG2_ROWS-1:0] left_j, right_j, up_j, bottom_j;
reg [LOG2_COLS-1:0] left_i, right_i, up_i, bottom_i;    

reg up = 1, right = 1, bottom = 1, left =1;
///////////////////////////////////////////**************************initialize_inputs**************************/////////////////////////////////////////////////////

reg [DIGIT_DIM*DIM-1:0] trainX [TRAIN_ROWS-1:0];    
reg [DIGIT_DIM*DIM-1:0] testX [TEST_ROWS-1:0];
reg [LOG2_NUM_CLASSES-1:0] trainY [TRAIN_ROWS-1:0];
reg [LOG2_NUM_CLASSES-1:0] testY [TEST_ROWS-1:0];
reg [DIGIT_DIM*DIM-1:0] random_weights [INIT_ROWS + INIT_COLS - 1:0];

initial begin
    $readmemb("som_train_x.mem", trainX);
    $readmemb("som_train_y.mem", trainY);
    $readmemb("som_test_x.mem", testX);
    $readmemb("som_test_y.mem", testY);
    $readmemb("gsom_weights.mem", random_weights);
end


///////////////////////////////////////////**************************weight_modules**************************/////////////////////////////////////////////////////
reg [DIGIT_DIM-1:0] p_inf = 32'b0_11111111_00000000_00000000_0000000;
reg [DIGIT_DIM-1:0] n_inf = 32'b1_11111111_00000000_00000000_0000000;

reg [CS_COUNT-1:0] controls_in=0;

//reg [DIGIT_DIM*DIM*4-1: 0] neighbor_weights;

reg [DIGIT_DIM*DIM-1: 0] up_weight;
reg [DIGIT_DIM*DIM-1: 0] right_weight;
reg [DIGIT_DIM*DIM-1: 0] bottom_weight;
reg [DIGIT_DIM*DIM-1: 0] left_weight;

wire [DIGIT_DIM*DIM-1 :0] weights [MAX_ROWS-1: 0][MAX_COLS-1: 0];
wire is_active [MAX_ROWS-1: 0][MAX_COLS-1: 0];
wire [DIGIT_DIM-1 :0] distances [MAX_ROWS-1: 0][MAX_COLS-1: 0];
wire [MAX_ROWS*MAX_COLS-1: 0] controls_out [CS_COUNT-1:0];
wire [MAX_ROWS*MAX_COLS-1: 0] error_overflowed;


genvar i, j;
generate
    for (i = 0; i < MAX_ROWS; i = i + 1) begin
        for (j = 0; j < MAX_COLS; j = j + 1) begin
            node #(
                .DIM(DIM),
                .DIGIT_DIM(DIGIT_DIM),
                .LOG2_MAX_COLS(LOG2_COLS),
                .LOG2_MAX_ROWS(LOG2_ROWS),
                .CS_COUNT(CS_COUNT)
            ) weight_module(
                .clk(clk),
                .reset(reset),
                .controls_in(controls_in),
    
                .row(i),
                .col(j),
                .current_input(trainX[t1]),
    
                .winner_row(bmu[1]),
                .winner_col(bmu[0]),
                .neighbor_weights({left_weight, bottom_weight, right_weight, up_weight}),
    
                .nb_radius(radius),
                .learning_rate(current_learning_rate),
                .GT(GT),
                .FD(FD),
    
                .weight_out(weights[i][j]),
                .active(is_active[i][j]),
                .distance(distances[i][j]),
                .controls_out({controls_out[5][i*MAX_ROWS+j], controls_out[4][i*MAX_ROWS+j], controls_out[3][i*MAX_ROWS+j], controls_out[2][i*MAX_ROWS+j], controls_out[1][i*MAX_ROWS+j], controls_out[0][i*MAX_ROWS+j]}),
                .error_overflowed(error_overflowed[i*MAX_ROWS+j])
            );
        end    
    end
endgenerate

///////////////////////////////////////////**************************new_node_in_middle**************************/////////////////////////////////////////////////////
reg [DIGIT_DIM*DIM-1:0] winner;

reg [DIGIT_DIM*DIM-1:0] up_new_node_next_node;

reg up_new_node_in_middle_en = 0;
reg up_new_node_in_middle_reset = 1;
wire [DIM-1:0] up_new_node_in_middle_is_done;
wire [DIGIT_DIM*DIM-1:0] up_new_node_in_middle_weight;

reg up_new_node_on_one_side_en = 0;
reg up_new_node_on_one_side_reset = 1;
wire [DIM-1:0] up_new_node_on_one_side_is_done;
wire [DIGIT_DIM*DIM-1:0] up_new_node_on_one_side_weight;

reg [DIGIT_DIM*DIM-1:0] right_new_node_next_node;

reg right_new_node_in_middle_en = 0;
reg right_new_node_in_middle_reset = 1;
wire [DIM-1:0] right_new_node_in_middle_is_done;
wire [DIGIT_DIM*DIM-1:0] right_new_node_in_middle_weight;

reg right_new_node_on_one_side_en = 0;
reg right_new_node_on_one_side_reset = 1;
wire [DIM-1:0] right_new_node_on_one_side_is_done;
wire [DIGIT_DIM*DIM-1:0] right_new_node_on_one_side_weight;

reg [DIGIT_DIM*DIM-1:0] bottom_new_node_next_node;

reg bottom_new_node_in_middle_en = 0;
reg bottom_new_node_in_middle_reset = 1;
wire [DIM-1:0] bottom_new_node_in_middle_is_done;
wire [DIGIT_DIM*DIM-1:0] bottom_new_node_in_middle_weight;

reg bottom_new_node_on_one_side_en = 0;
reg bottom_new_node_on_one_side_reset = 1;
wire [DIM-1:0] bottom_new_node_on_one_side_is_done;
wire [DIGIT_DIM*DIM-1:0] bottom_new_node_on_one_side_weight;

reg [DIGIT_DIM*DIM-1:0] left_new_node_next_node;

reg left_new_node_in_middle_en = 0;
reg left_new_node_in_middle_reset = 1;
wire [DIM-1:0] left_new_node_in_middle_is_done;
wire [DIGIT_DIM*DIM-1:0] left_new_node_in_middle_weight;

reg left_new_node_on_one_side_en = 0;
reg left_new_node_on_one_side_reset = 1;
wire [DIM-1:0] left_new_node_on_one_side_is_done;
wire [DIGIT_DIM*DIM-1:0] left_new_node_on_one_side_weight;

genvar nim_dim_i;
generate
    for (nim_dim_i=0; nim_dim_i<DIM; nim_dim_i=nim_dim_i+1) begin
        grow_node_in_middle 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        up_grow_node_in_middle_module(
            .clk(clk),
            .reset(up_new_node_in_middle_reset),
            .en(up_new_node_in_middle_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(up_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(up_new_node_in_middle_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(up_new_node_in_middle_is_done[nim_dim_i])
        );
    
        grow_node_on_one_side 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        up_grow_node_on_one_side_module(
            .clk(clk),
            .reset(up_new_node_on_one_side_reset),
            .en(up_new_node_on_one_side_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(up_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(up_new_node_on_one_side_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(up_new_node_on_one_side_is_done[nim_dim_i])
        );
    
        grow_node_in_middle 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        right_grow_node_in_middle_module(
            .clk(clk),
            .reset(right_new_node_in_middle_reset),
            .en(right_new_node_in_middle_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(right_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(right_new_node_in_middle_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(right_new_node_in_middle_is_done[nim_dim_i])
        );
    
        grow_node_on_one_side 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        right_grow_node_on_one_side_module(
            .clk(clk),
            .reset(right_new_node_on_one_side_reset),
            .en(right_new_node_on_one_side_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(right_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(right_new_node_on_one_side_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(right_new_node_on_one_side_is_done[nim_dim_i])
        );
    
        grow_node_in_middle 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        bottom_grow_node_in_middle_module(
            .clk(clk),
            .reset(bottom_new_node_in_middle_reset),
            .en(bottom_new_node_in_middle_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(bottom_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(bottom_new_node_in_middle_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(bottom_new_node_in_middle_is_done[nim_dim_i])
        );
    
        grow_node_on_one_side 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        bottom_grow_node_on_one_side_module(
            .clk(clk),
            .reset(bottom_new_node_on_one_side_reset),
            .en(bottom_new_node_on_one_side_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(bottom_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(bottom_new_node_on_one_side_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(bottom_new_node_on_one_side_is_done[nim_dim_i])
        );
    
        grow_node_in_middle 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        left_grow_node_in_middle_module(
            .clk(clk),
            .reset(left_new_node_in_middle_reset),
            .en(left_new_node_in_middle_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(left_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(left_new_node_in_middle_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(left_new_node_in_middle_is_done[nim_dim_i])
        );
    
        grow_node_on_one_side 
        #(
            .DIGIT_DIM(DIGIT_DIM)
        )
        left_grow_node_on_one_side_module(
            .clk(clk),
            .reset(left_new_node_on_one_side_reset),
            .en(left_new_node_on_one_side_en),
            .winner(winner[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM ]),
            .node_next(left_new_node_next_node[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .weight(left_new_node_on_one_side_weight[(DIGIT_DIM*(nim_dim_i+1))-1 -:DIGIT_DIM] ),
            .is_done(left_new_node_on_one_side_is_done[nim_dim_i])
        );
    end
endgenerate
///////////////////////////////////////////**************************learning_rate**************************/////////////////////////////////////////////////////
reg lr_en = 0;
reg lr_reset = 0;
wire [DIGIT_DIM-1:0] lr_out;
wire lr_is_done;

gsom_learning_rate lr(
    .clk(clk), .en(lr_en), .reset(lr_reset),
    .node_count(node_count_ieee754),
    .prev_learning_rate(current_learning_rate),
    .alpha(alpha),
    .learning_rate(lr_out),
    .is_done(lr_is_done)
);

///////////////////////////////////////////**************************node_count_adder**************************/////////////////////////////////////////////////////
reg node_count_ieee754_valid = 0;
wire node_count_ieee754_ready;

reg [DIGIT_DIM-1:0] no_of_new_node;

reg [DIGIT_DIM-1:0] nca_count;
reg nca_count_valid = 0;
wire nca_count_ready;

wire [DIGIT_DIM-1:0] nca_num_out;
wire nca_num_out_valid;
reg nca_num_out_ready = 0;


adder fpa_node_count_adder(
    .aclk(clk),
    .s_axis_a_tvalid(node_count_ieee754_valid),
    .s_axis_a_tready(node_count_ieee754_ready),
    .s_axis_a_tdata(node_count_ieee754),
    .s_axis_b_tvalid(nca_count_valid),
    .s_axis_b_tready(nca_count_ready),
    .s_axis_b_tdata(nca_count),
    .m_axis_result_tvalid(nca_num_out_valid),
    .m_axis_result_tready(nca_num_out_ready),
    .m_axis_result_tdata(nca_num_out)
);

///////////////////////////////////////////**************************get_min**************************/////////////////////////////////////////////////////
reg [DIGIT_DIM-1:0] comp_in_1;
reg [DIGIT_DIM-1:0] comp_in_2;
wire [1:0] comp_out;
wire comp_done;
reg comp_en=0;
reg comp_reset=0;

fpa_comparator get_min(
    .clk(clk),
    .en(comp_en),
    .reset(comp_reset),
    .num1(comp_in_1),
    .num2(comp_in_2),
    .num_out(comp_out),
    .is_done(comp_done)
);

///////////////////////////////////////////**************************multiplier**************************/////////////////////////////////////////////////////
reg [DIGIT_DIM-1:0] mul_num1;
reg mul_num1_valid = 0;
wire mul_num1_ready;

reg [DIGIT_DIM-1:0] mul_num2;
reg mul_num2_valid = 0;
wire mul_num2_ready;

wire [DIGIT_DIM-1:0] mul_num_out;
reg mul_num_out_ready = 0;
wire mul_num_out_valid;

multiplier fpa_multiplier(
    .aclk(clk),
    .s_axis_a_tvalid(mul_num1_valid),
    .s_axis_a_tready(mul_num1_ready),
    .s_axis_a_tdata(mul_num1),
    
    .s_axis_b_tvalid(mul_num2_valid),
    .s_axis_b_tready(mul_num2_ready),
    .s_axis_b_tdata(mul_num2),
    
    .m_axis_result_tvalid(mul_num_out_valid),
    .m_axis_result_tready(mul_num_out_ready),
    .m_axis_result_tdata(mul_num_out)
);
///////////////////////////////////////////**************************check_is_in_map**************************/////////////////////////////////////////////////////
function is_active_in_map;
    input [LOG2_ROWS-1:0] coord_i;
    input [LOG2_COLS-1:0] coord_j;

    begin
        if (coord_i >= MAX_ROWS || coord_j >= MAX_COLS) begin
            is_active_in_map = 1; // to prevent from adding a new node
        end else begin
            is_active_in_map = is_active[coord_i][coord_j];
        end
    end
endfunction

///////////////////////////////////////////**************************always block**************************/////////////////////////////////////////////////////

always @(posedge clk) begin
    if (init_gsom) begin
        controls_in[0] = 1;
        // Todo : don't know whether this is correct or not
        up_weight = random_weights[0];
        right_weight = random_weights[1];
        bottom_weight = random_weights[2];
        left_weight = random_weights[3];
        
        if (controls_out[0] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            $display("initialized first four nodes");
            controls_in[0] = 0;
            node_count = 4;        
            node_count_ieee754 = 32'h40800000;
            init_gsom = 0;
            fit_en = 1;
            growing_iter_en = 1;
        end
        
    end else if (fit_en && growing_iter_en) begin
        $display("fit_en && growing_iter_en");
        current_learning_rate = learning_rate;
        iteration = -1;            
        next_iteration_en = 1;
        fit_en = 0;

    end else if (fit_en && smoothing_iter_en) begin
        $display("fit_en && smoothing_iter_en");
        mul_num1 = learning_rate;
        mul_num2 = smooth_learning_factor;
        
        mul_num1_valid = 1;
        mul_num2_valid = 1;
        mul_num_out_ready = 1;
        
        if (mul_num_out_valid) begin
            current_learning_rate = mul_num_out;
            
            mul_num1_valid = 0;
            mul_num2_valid = 0;
            mul_num_out_ready = 0;
            
            iteration = -1;
            next_iteration_en = 1;
            fit_en = 0;
        end

    end else if (next_iteration_en && growing_iter_en) begin
        $display("next_iteration_en && growing_iter_en");
        if (iteration < GROWING_ITERATIONS) begin
            iteration = iteration + 1;

            // neighbourhood                
            if (iteration <= delta_growing_iter) begin
                radius = 4;
            end else if ((iteration <= delta_growing_iter*2) && (iteration > delta_growing_iter*1)) begin
                radius = 2;
            end else if ((iteration <= delta_growing_iter*3) && (iteration > delta_growing_iter*2)) begin
                radius = 1;
            end 
            
            // learning rate
            if (iteration != 0) begin
                get_LR_en = 1;

            end else begin
                current_learning_rate = learning_rate;
                grow_en = 1;
            end
        end else begin
            fit_en = 1;
            smoothing_iter_en = 1;                
            growing_iter_en = 0;
        end
        next_iteration_en = 0;

    end else  if (get_LR_en && growing_iter_en) begin
    // learning rate calculation
        $display("growing phase - calculating learning rate");
        lr_reset = 0;
        lr_en = 1;
        if (lr_is_done) begin
            $display("growing phase - finish calculating learning rate");
            lr_en = 0;
            lr_reset = 1;
            current_learning_rate = lr_out;
            get_LR_en = 0;
            grow_en = 1;
        end

    end else if (grow_en) begin    
    // grow network
    
        grow_en = 0;
        t1 = -1;
        next_t1_en = 1;

    end else if (next_iteration_en && smoothing_iter_en) begin
        $display("next_iteration_en && smoothing_iter_en");
        if (iteration < SMOOTHING_ITERATIONS) begin
            iteration = iteration + 1;

            // neighbourhood                
            if (iteration <= delta_smoothing_iter) begin
                radius = 4;                
            end else if ((iteration <= delta_smoothing_iter*2) && (iteration > delta_smoothing_iter*1)) begin
                radius = 2;
            end else if ((iteration <= delta_smoothing_iter*3) && (iteration > delta_smoothing_iter*2)) begin
                radius = 1;
            end 
            
            // learning rate
            if (iteration != 0)
                get_LR_en = 1;
            else 
                smooth_en = 1;
            
            next_iteration_en = 0;

        end else begin
            iteration = -1;
            write_en = 1;
            //is_completed = 1;
            smoothing_iter_en = 0;
        end

    end else if (get_LR_en && smoothing_iter_en) begin
    // calculate learning rate
        $display("smoothing phase - calculating learning rate");
        lr_en = 1;
        lr_reset = 0;
        if (lr_is_done) begin
            $display("smoothing phase - finish calculating learning rate");
            lr_en = 0;
            lr_reset = 1;
            current_learning_rate = lr_out;
            get_LR_en = 0;
            smooth_en = 1;
        end

    end else if (smooth_en) begin
        smooth_en = 0;
        t1 = -1;
        next_t1_en = 1;

    end else if (next_t1_en) begin
        if (t1 < TRAIN_ROWS-1) begin
            t1 = t1 + 1; 
            $display("iter %d t1 %d node count %d", iteration, t1, node_count);
            dist_enable = 1;
            
        end else begin
            next_iteration_en = 1;
        end
        next_t1_en = 0;

    end else if (dist_enable) begin
        $display("dist_enable");
        controls_in[2] = 1;

        if (controls_out[2] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            $display("calculated all distances");
            controls_in[2] = 0;
            matrix_i = 0;
            matrix_j = 0;
            min_distance = p_inf;
            dist_enable = 0;
            min_distance_en = 1;
        end

    end else if (min_distance_en) begin
        $display("min_distance_en");
        if (is_active_in_map(matrix_i, matrix_j)) begin
            $display("matrix_i %d matrix_j %d", matrix_i, matrix_j);
            comp_in_1 = min_distance;
            comp_in_2 = distances[matrix_i][matrix_j];
            comp_reset = 0;
            comp_en = 1;
            
            if (comp_done) begin
                comp_en = 0;
                comp_reset = 1;
                
                if (comp_out==0) begin
                    minimum_distance_indices[min_distance_next_index][1] = matrix_i;
                    minimum_distance_indices[min_distance_next_index][0] = matrix_j;
                    min_distance_next_index = min_distance_next_index + 1;
                
                end else if (comp_out==1) begin
                    min_distance = distances[matrix_i][matrix_j];
                    minimum_distance_indices[0][1] = matrix_i;
                    minimum_distance_indices[0][0] = matrix_j;              
                    min_distance_next_index = 1;
                end 
                
                matrix_j = matrix_j + 1;
                if (matrix_j == MAX_COLS) begin
                    matrix_i = matrix_i + 1;
                    matrix_j = 0;
                    if (matrix_i == MAX_ROWS) begin
                        min_distance_en=0;
                        bmu_en=1;
                    end
                end
                
            end
        end else begin
            matrix_j = matrix_j + 1;
            if (matrix_j == MAX_COLS) begin
                matrix_i = matrix_i + 1;
                matrix_j = 0;
                if (matrix_i == MAX_ROWS) begin
                    min_distance_en=0;
                    weights_update=1;
                end
            end
        end
        
    end else if (weights_update) begin
        $display("weights_update");
        //$display("weights_update %h", controls_out[3]); 
        // update weights
        controls_in[3] = 1;            
        if (controls_out[3] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[3] = 0;
            weights_update = 0;
            if (growing_iter_en)
                adjust_weights_en = 1;
            else 
                next_t1_en = 1;
        end

    end else if (adjust_weights_en) begin
        $display("adjust_weights_en");
        // winner error > GT        
        controls_in[4] = 1;
        if (controls_out[4] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[4] = 0;

            if (^error_overflowed) begin
                // spread or grow
                left_j = bmu[0]-1;    left_i = bmu[1];
                right_j = bmu[0]+1;   right_i = bmu[1];
                up_j = bmu[0];        up_i = bmu[1]+1;
                bottom_j = bmu[0];    bottom_i = bmu[1]-1;

                if (is_active_in_map(left_i, left_j) && is_active_in_map(right_i, right_j) && is_active_in_map(up_i, up_j) && is_active_in_map(bottom_i, bottom_j)) begin
                    spread_weighs_en = 1;   

                end else begin
                    grow_nodes_en = 1;
                    winner = weights[bmu[1]][bmu[0]];
                end
                adjust_weights_en = 0;       

            end else begin
                next_t1_en = 1;
                bmu_en=0;
            end
        end
        

    end else if (spread_weighs_en) begin
        $display("spread_weighs_en");
        // spread error
        controls_in[5] = 1;
        if (controls_out[5] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[5] = 0;    
            next_t1_en = 1;    
            spread_weighs_en = 0;      
            $display("spread_weighs_en %d %d", bmu[1], bmu[0]);  
        end

    end else if (grow_nodes_en && up && right && bottom && left) begin
        $display("grow_nodes_en && up && right && bottom && left");
        // grow nodes
        grow_nodes_en = 0;
        controls_in[1] = 1;
        
        // increment the nodecount
        no_of_new_node = !is_active_in_map(left_i, left_j) + !is_active_in_map(right_i, right_j) + !is_active_in_map(up_i, up_j) + !is_active_in_map(bottom_i, bottom_j);
        node_count = node_count + no_of_new_node;
        
        if (no_of_new_node==1)
            nca_count = 32'h3F800000;
        else if (no_of_new_node==2)
            nca_count = 32'h40000000;
        else if (no_of_new_node==3)
            nca_count = 32'h40400000;
            
        nca_count_valid = 1;
        node_count_ieee754_valid = 1;
        nca_num_out_ready = 1;  
        
    end else if (controls_in[1]) begin
        $display("controls_in[1]");
        if (controls_out[1] == { MAX_ROWS*MAX_COLS {1'b1} } && nca_num_out_valid) begin
            controls_in[1] = 0;
            next_t1_en = 1; 
            
            node_count_ieee754 = nca_num_out;
            
            nca_count_valid = 0;
            node_count_ieee754_valid = 0;
            nca_num_out_ready = 0;
            $display("grow nodes"); 
        end
    end
end

always @(posedge clk) begin

    // check if node should be added
    if (grow_nodes_en && !up && !is_active_in_map(up_i, up_j) && !up_new_node_in_middle_en && !up_new_node_on_one_side_en) begin
        // new node up to the winner
        if (is_active_in_map(up_i+1, up_j)) begin
            up_new_node_in_middle_en = 1;
            up_new_node_in_middle_reset = 0;
            up_new_node_next_node = weights[up_i+1][up_j];
            $display("up 1 %d %d %h %h", up_i, up_j, up_new_node_next_node, winner);

        end else if ( is_active_in_map(bmu[1]-1, bmu[0]) && is_active[bmu[1]-1][bmu[0]] ) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("up 1 %d %d %h %h", up_i, up_j, up_new_node_next_node, winner);

        end else if (is_active_in_map(bmu[1], bmu[0]+1)  && is_active[bmu[1]][bmu[0]+1] ) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("up 1 %d %d %h %h", up_i, up_j, up_new_node_next_node, winner);

        end else if (is_active_in_map(bmu[1], bmu[0]-1)  && is_active[bmu[1]][bmu[0]-1] ) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("up 1 %d %d %h %h", up_i, up_j, up_new_node_next_node, winner);

        end
    // check if node adding enabled -> check job done?
    end else if (up_new_node_in_middle_en) begin
        if (up_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            up_new_node_in_middle_en = 0;
            up_new_node_in_middle_reset = 1;
            up_weight = up_new_node_in_middle_weight;
            up = 1;
            $display("up addeded %d %d", up_i, up_j);
        end
    // check if node adding enabled -> check job done?
    end else if (up_new_node_on_one_side_en) begin
        if (up_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            up_new_node_on_one_side_en = 0;
            up_new_node_on_one_side_reset = 1;
            up_weight = up_new_node_on_one_side_weight;
            up = 1;
            $display("up addeded %d %d", up_i, up_j);
        end
    // if node adding no need
    end else begin
        up = 1;
    end
    
    if (!grow_nodes_en) up = 0;
end

always @(posedge clk) begin
    if (grow_nodes_en && !right && !is_active_in_map(right_i, right_j) && !right_new_node_in_middle_en && !right_new_node_on_one_side_en) begin
        // new node right to the winner
        if (is_active_in_map(right_i, right_j+1)) begin
            right_new_node_in_middle_en = 1;
            right_new_node_in_middle_reset = 0;
            right_new_node_next_node = weights[right_i][right_j+1];
            $display("right 1 %d %d", right_i, right_j);

        end else if (is_active_in_map(bmu[1], bmu[0]-1) && is_active[bmu[1]][bmu[0]-1]) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("right 2 %d %d", right_i, right_j);

        end else if (is_active_in_map(bmu[1]+1, bmu[0]) && is_active[bmu[1]+1][bmu[0]]) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("right 3 %d %d", right_i, right_j);

        end else if (is_active_in_map(bmu[1]-1, bmu[0]) && is_active[bmu[1]-1][bmu[0]]) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("right 4 %d %d", right_i, right_j);
            
        end
    // check if node adding enabled -> check job done?
    end else if (right_new_node_in_middle_en) begin
        if (right_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            right_new_node_in_middle_en = 0;
            right_new_node_in_middle_reset = 1;
            right_weight = right_new_node_in_middle_weight;
            right = 1;
            $display("right addeded %d %d", right_i, right_j);
        end
    // check if node adding enabled -> check job done?
    end else if (right_new_node_on_one_side_en) begin
        if (right_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            right_new_node_on_one_side_en = 0;
            right_new_node_on_one_side_reset = 1;
            right_weight = right_new_node_on_one_side_weight;
            right = 1;
            $display("right addeded %d %d", right_i, right_j);
        end
    // if node adding no need
    end else begin
        right = 1;
    end
    
    if (!grow_nodes_en) right = 0;
end

always @(posedge clk) begin
    if (grow_nodes_en && !bottom && !is_active_in_map(bottom_i, bottom_j) && !bottom_new_node_in_middle_en && !bottom_new_node_on_one_side_en) begin
        // new node bottom to the winner
        if (is_active_in_map(bottom_i-1, bottom_j) == 1) begin
            bottom_new_node_in_middle_en = 1;
            bottom_new_node_in_middle_reset = 0;
            bottom_new_node_next_node = weights[bottom_i-1][bottom_j];
            $display("bottom in middle %d %d %b", bottom_i, bottom_j, is_active[bottom_i-1][bottom_j]);

        end else if (is_active_in_map(bmu[1]+1, bmu[0]) && is_active[bmu[1]+1][bmu[0]]) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("bottom on one side %d %d %d %d", bottom_i, bottom_j, bmu[1]+1, bmu[0]);

        end else if (is_active_in_map(bmu[1], bmu[0]+1) && is_active[bmu[1]][bmu[0]+1]) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("bottom on one side %d %d %d %d", bottom_i, bottom_j, bmu[1], bmu[0]+1);

        end else if (is_active_in_map(bmu[1], bmu[0]-1) && is_active[bmu[1]][bmu[0]-1]) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("bottom on one side %d %d %d %d", bottom_i, bottom_j, bmu[1], bmu[0]-1);

        end
    // check if node adding enabled -> check job done?
    end else if (bottom_new_node_in_middle_en) begin
        if (bottom_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            bottom_new_node_in_middle_en = 0;
            bottom_new_node_in_middle_reset = 1;
            bottom_weight = bottom_new_node_in_middle_weight;
            bottom = 1;
            $display("bottom addeded %d %d", bottom_i, bottom_j);
        end
    // check if node adding enabled -> check job done?
    end else if (bottom_new_node_on_one_side_en) begin
        if (bottom_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            bottom_new_node_on_one_side_en = 0;
            bottom_new_node_on_one_side_reset = 1;
            bottom_weight = bottom_new_node_on_one_side_weight;
            bottom = 1;
            $display("bottom addeded %d %d", bottom_i, bottom_j);
        end
    // if node adding no need
    end else begin
        bottom = 1;
    end
    
    if (!grow_nodes_en) bottom = 0;
end


always @(posedge clk) begin
    if (grow_nodes_en && !left && !is_active_in_map(left_i, left_j) && !left_new_node_in_middle_en && !left_new_node_on_one_side_en) begin
        // new node left to the winner
        if (is_active_in_map(left_i, left_j-1)) begin
            left_new_node_in_middle_en = 1;
            left_new_node_in_middle_reset = 0;
            left_new_node_next_node = weights[left_i][left_j-1];
            $display("left %d %d", left_i, left_j);

        end else if (is_active_in_map(bmu[1], bmu[0]+1) && is_active[bmu[1]][bmu[0]+1]) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("left %d %d", left_i, left_j);

        end else if (is_active_in_map(bmu[1]+1, bmu[0]) && is_active[bmu[1]+1][bmu[0]]) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("left %d %d", left_i, left_j);

        end else if (is_active_in_map(bmu[1]-1, bmu[0]) && is_active[bmu[1]-1][bmu[0]]) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("left %d %d", left_i, left_j);
        end
    // check if node adding enabled -> check job done?
    end else if (left_new_node_in_middle_en) begin
        if (left_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            left_new_node_in_middle_en = 0;
            left_new_node_in_middle_reset = 1;
            left_weight = left_new_node_in_middle_weight;
            left = 1;
            $display("left addeded %d %d", left_i, left_j);
        end
    // check if node adding enabled -> check job done?
    end else if (left_new_node_on_one_side_en) begin
        if (left_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            left_new_node_on_one_side_en = 0;
            left_new_node_on_one_side_reset = 1;
            left_weight = left_new_node_on_one_side_weight;
            left = 1;
            $display("left addeded %d %d", left_i, left_j);
        end
    // if node adding no need
    end else begin
        left = 1;
    end
    
    if (!grow_nodes_en) left = 0;
end

///////////////////////////////////////////**************************write_weights**************************/////////////////////////////////////////////////////
integer file_dir, file_i, file_j, item_bit;    
always @(posedge clk) begin
    if (write_en) begin
        file_dir = $fopen("/home/aari/Projects/Vivado/gsom/weight_out.data", "w");
        for (file_i=0; file_i<=MAX_ROWS-1; file_i=file_i+1) begin
            for (file_j=MAX_COLS-1; file_j>=0; file_j=file_j-1) begin
                for (item_bit=DIM*DIGIT_DIM-1; item_bit>=0; item_bit=item_bit-1) begin
                    $fwriteb(file_dir, weights[file_i][file_j][item_bit]);
                end
                $fwrite(file_dir, " ");
            end
            $fwrite(file_dir, "\n");
        end
        
        #10 $fclose(file_dir);            
        is_completed = 1;   
        $finish;
    end
end

endmodule