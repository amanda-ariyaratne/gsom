`timescale  1 ps / 1 ps

module gsom
#(
    parameter DIM = 11,
    parameter LOG2_DIM = 4, 
    parameter DIGIT_DIM = 32,
    parameter CS_COUNT = 6,
    
    parameter INIT_ROWS = 2,
    parameter INIT_COLS = 2,
    
    parameter MAX_ROWS = 15,
    parameter MAX_COLS = 15,
    
    parameter LOG2_ROWS = 5,         
    parameter LOG2_COLS = 5,

    parameter MAX_NODE_SIZE = 225,
    parameter LOG2_NODE_SIZE = 9,
    
    parameter GROWING_ITERATIONS = 10,
    parameter LOG2_GROWING_ITERATIONS = 4,
    parameter SMOOTHING_ITERATIONS = 5,
    parameter LOG2_SMOOTHING_ITERATIONS = 4,
    
    parameter TRAIN_ROWS = 900,
    parameter LOG2_TRAIN_ROWS = 10,
    parameter TEST_ROWS = 300,
    parameter LOG2_TEST_ROWS = 10, 
    
    parameter NUM_CLASSES = 2+1,
    parameter LOG2_NUM_CLASSES = 2,
    
    // model parameters
    parameter spread_factor = 32'h3DCCCCCD, //0.1
    parameter spread_factor_logval = 32'hBF800000, // BF800000 = -1
    
    parameter GT = 32'h41CAA0A3, //25.3284360229 = -11*ln(spread_factor)
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

reg [LOG2_ROWS-1:0] leftx, rightx, upx, bottomx;
reg [LOG2_COLS-1:0] lefty, righty, upy, bottomy;    

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
localparam [DIGIT_DIM-1:0] p_inf = 32'b0111_1111_1111_1111_1111_1111_1111_1111;
localparam [DIGIT_DIM-1:0] n_inf = 32'b1111_1111_1111_1111_1111_1111_1111_1111;

localparam delta_growing_iter = 3;
localparam delta_smoothing_iter = 3;

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
reg nca_en = 0;
reg nca_reset = 0;
reg [DIGIT_DIM-1:0] nca_count;
wire [DIGIT_DIM-1:0] nca_num_out;
wire nca_is_done;    

fpa_adder nca(
    .clk(clk),
    .en(nca_en),
    .reset(nca_reset),
    .num1(node_count_ieee754),
    .num2(nca_count),
    .num_out(nca_num_out),
    .is_done(nca_is_done)
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
reg mul_en = 0;
reg mul_reset = 0;
reg [DIGIT_DIM-1:0] mul_num1;
reg [DIGIT_DIM-1:0] mul_num2;
wire [DIGIT_DIM-1:0] mul_num_out;
wire mul_is_done;    

fpa_multiplier multiplier(
    .clk(clk),
    .en(mul_en),
    .reset(mul_reset),
    .num1(mul_num1),
    .num2(mul_num2),
    .num_out(mul_num_out),
    .is_done(mul_is_done)
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
            $display("controls_out[0]");
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
        mul_num1 = learning_rate;
        mul_num2 = smooth_learning_factor;
        mul_en = 1;
        mul_reset = 0;
        if (mul_is_done) begin
            current_learning_rate = mul_num_out;
            mul_en = 0;
            mul_reset = 1;
            iteration = -1;
            next_iteration_en = 1;
            fit_en = 0;
        end

    end else if (next_iteration_en && growing_iter_en) begin
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

        lr_reset = 0;
        lr_en = 1;
        if (lr_is_done) begin
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
        lr_en = 1;
        lr_reset = 0;
        if (lr_is_done) begin
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
//            if (iteration==1 && t1==120)
//                $finish;
            dist_enable = 1;
        end else begin
            next_iteration_en = 1;
        end
        next_t1_en = 0;

    end else if (dist_enable) begin
        controls_in[2] = 1;

        if (controls_out[2] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[2] = 0;
            matrix_i = 0;
            matrix_j = 0;
            min_distance_next_index = 0;
            min_distance = p_inf;
            dist_enable = 0;
            min_distance_en = 1;
        end

    end else if (min_distance_en) begin
        
        if (is_active_in_map(matrix_i, matrix_j)) begin
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
                    bmu_en=1;
                end
            end
        end
        
    end else if (bmu_en) begin  
        bmu[1] = minimum_distance_indices[min_distance_next_index-1][1];
        bmu[0] = minimum_distance_indices[min_distance_next_index-1][0];

        weights_update = 1;
        bmu_en = 0;

    end else if (weights_update) begin
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
        // winner error > GT        
        controls_in[4] = 1;
        if (controls_out[4] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[4] = 0;

            if (^error_overflowed) begin
                // spread or grow
                leftx = bmu[1]-1;    lefty = bmu[0];
                rightx = bmu[1]+1;   righty = bmu[0];
                upx = bmu[1];        upy = bmu[0]+1;
                bottomx = bmu[1];    bottomy = bmu[0]-1;

                if (is_active_in_map(leftx, lefty) && is_active_in_map(rightx, righty) && is_active_in_map(upx, upy) && is_active_in_map(bottomx, bottomy)) begin
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
        // spread error
        controls_in[5] = 1;
        if (controls_out[5] == { MAX_ROWS*MAX_COLS{1'b1} }) begin
            controls_in[5] = 0;    
            next_t1_en = 1;    
            spread_weighs_en = 0;      
            $display("spread_weighs_en");  
        end

    end else if (grow_nodes_en && up && right && bottom && left) begin
        // grow nodes
        grow_nodes_en = 0;
        controls_in[1] = 1;
        
        // increment the nodecount
        nca_count = !is_active_in_map(leftx, lefty) + !is_active_in_map(rightx, righty) + !is_active_in_map(upx, upy) + !is_active_in_map(bottomx, bottomy);
        nca_en = 1;
        nca_reset = 0;
        node_count = node_count + nca_count;
                
    end else if (controls_in[1] && nca_en) begin
        if (controls_out[1] == { MAX_ROWS*MAX_COLS {1'b1} } && nca_is_done) begin
            controls_in[1] = 0;
            next_t1_en = 1; 
            
            node_count_ieee754 = nca_num_out;
            nca_en = 0;
            nca_reset = 1;
            $display("grow nodes"); 
        end    
    end
end

always @(posedge clk) begin

    // check if node should be added
    if (grow_nodes_en && !up && !is_active_in_map(upx, upy) && !up_new_node_in_middle_en && !up_new_node_on_one_side_en) begin
        // new node up to the winner
        if (is_active_in_map(upx, upy+1)) begin
            up_new_node_in_middle_en = 1;
            up_new_node_in_middle_reset = 0;
            up_new_node_next_node = weights[upx][upy+1];
            $display("up %d %d", upx, upy);

        end else if (is_active_in_map(bmu[1], bmu[0]-1)) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("up %d %d", upx, upy);

        end else if (is_active_in_map(bmu[1]+1, bmu[0])) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("up %d %d", upx, upy);

        end else if (is_active_in_map(bmu[1]-1, bmu[0])) begin
            up_new_node_on_one_side_en = 1;
            up_new_node_on_one_side_reset = 0;
            up_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("up %d %d", upx, upy);

        end
    // check if node adding enabled -> check job done?
    end else if (up_new_node_in_middle_en) begin
        if (up_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            up_new_node_in_middle_en = 0;
            up_new_node_in_middle_reset = 1;
            up_weight = up_new_node_in_middle_weight;
            up = 1;
            $display("up addeded %d %d", upx, upy);
        end
    // check if node adding enabled -> check job done?
    end else if (up_new_node_on_one_side_en) begin
        if (up_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            up_new_node_on_one_side_en = 0;
            up_new_node_on_one_side_reset = 1;
            up_weight = up_new_node_on_one_side_weight;
            up = 1;
            $display("up addeded %d %d", upx, upy);
        end
    // if node adding no need
    end else begin
        up = 1;
    end
    
    if (!grow_nodes_en) up = 0;
end

always @(posedge clk) begin
    if (grow_nodes_en && !right && !is_active_in_map(rightx, righty) && !right_new_node_in_middle_en && !right_new_node_on_one_side_en) begin
        // new node right to the winner
        if (is_active_in_map(rightx+1, righty)) begin
            right_new_node_in_middle_en = 1;
            right_new_node_in_middle_reset = 0;
            right_new_node_next_node = weights[rightx+1][righty];
            $display("right %d %d", rightx, righty);

        end else if (is_active_in_map(bmu[1]-1, bmu[0])) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("right %d %d", rightx, righty);

        end else if (is_active_in_map(bmu[1], bmu[0]+1)) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("right %d %d", rightx, righty);

        end else if (is_active_in_map(bmu[1], bmu[0]-1)) begin
            right_new_node_on_one_side_en = 1;
            right_new_node_on_one_side_reset = 0;
            right_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("right %d %d", rightx, righty);
            
        end
    // check if node adding enabled -> check job done?
    end else if (right_new_node_in_middle_en) begin
        if (right_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            right_new_node_in_middle_en = 0;
            right_new_node_in_middle_reset = 1;
            right_weight = right_new_node_in_middle_weight;
            right = 1;
            $display("right addeded %d %d", rightx, righty);
        end
    // check if node adding enabled -> check job done?
    end else if (right_new_node_on_one_side_en) begin
        if (right_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            right_new_node_on_one_side_en = 0;
            right_new_node_on_one_side_reset = 1;
            right_weight = right_new_node_on_one_side_weight;
            right = 1;
            $display("right addeded %d %d", rightx, righty);
        end
    // if node adding no need
    end else begin
        right = 1;
    end
    
    if (!grow_nodes_en) right = 0;
end

always @(posedge clk) begin
    if (grow_nodes_en && !bottom && !is_active_in_map(bottomx, bottomy) && !bottom_new_node_in_middle_en && !bottom_new_node_on_one_side_en) begin
        // new node bottom to the winner
        if (is_active_in_map(bottomx, bottomy-1)) begin
            bottom_new_node_in_middle_en = 1;
            bottom_new_node_in_middle_reset = 0;
            bottom_new_node_next_node = weights[bottomx][bottomy-1];
            $display("bottom %d %d", bottomx, bottomy);

        end else if (is_active_in_map(bmu[1], bmu[0]+1)) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("bottom %d %d", bottomx, bottomy);

        end else if (is_active_in_map(bmu[1]+1, bmu[0])) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("bottom %d %d", bottomx, bottomy);

        end else if (is_active_in_map(bmu[1]-1, bmu[0])) begin
            bottom_new_node_on_one_side_en = 1;
            bottom_new_node_on_one_side_reset = 0;
            bottom_new_node_next_node = weights[bmu[1]-1][bmu[0]];
            $display("bottom %d %d", bottomx, bottomy);
        end
    // check if node adding enabled -> check job done?
    end else if (bottom_new_node_in_middle_en) begin
        if (bottom_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            bottom_new_node_in_middle_en = 0;
            bottom_new_node_in_middle_reset = 1;
            bottom_weight = bottom_new_node_in_middle_weight;
            bottom = 1;
            $display("bottom addeded %d %d", bottomx, bottomy);
        end
    // check if node adding enabled -> check job done?
    end else if (bottom_new_node_on_one_side_en) begin
        if (bottom_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            bottom_new_node_on_one_side_en = 0;
            bottom_new_node_on_one_side_reset = 1;
            bottom_weight = bottom_new_node_on_one_side_weight;
            bottom = 1;
            $display("bottom addeded %d %d", bottomx, bottomy);
        end
    // if node adding no need
    end else begin
        bottom = 1;
    end
    
    if (!grow_nodes_en) bottom = 0;
end


always @(posedge clk) begin
    if (grow_nodes_en && !left && !is_active_in_map(leftx, lefty) && !left_new_node_in_middle_en && !left_new_node_on_one_side_en) begin
        // new node left to the winner
        if (is_active_in_map(leftx-1, lefty)) begin
            left_new_node_in_middle_en = 1;
            left_new_node_in_middle_reset = 0;
            left_new_node_next_node = weights[leftx-1][lefty];
            $display("left %d %d", leftx, lefty);

        end else if (is_active_in_map(bmu[1]+1, bmu[0])) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]+1][bmu[0]];
            $display("left %d %d", leftx, lefty);

        end else if (is_active_in_map(bmu[1], bmu[0]+1)) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]][bmu[0]+1];
            $display("left %d %d", leftx, lefty);

        end else if (is_active_in_map(bmu[1], bmu[0]-1)) begin
            left_new_node_on_one_side_en = 1;
            left_new_node_on_one_side_reset = 0;
            left_new_node_next_node = weights[bmu[1]][bmu[0]-1];
            $display("left %d %d", leftx, lefty);
        end
    // check if node adding enabled -> check job done?
    end else if (left_new_node_in_middle_en) begin
        if (left_new_node_in_middle_is_done == {DIM {1'b1}}) begin
            left_new_node_in_middle_en = 0;
            left_new_node_in_middle_reset = 1;
            left_weight = left_new_node_in_middle_weight;
            left = 1;
            $display("left addeded %d %d", leftx, lefty);
        end
    // check if node adding enabled -> check job done?
    end else if (left_new_node_on_one_side_en) begin
        if (left_new_node_on_one_side_is_done == {DIM {1'b1}}) begin
            left_new_node_on_one_side_en = 0;
            left_new_node_on_one_side_reset = 1;
            left_weight = left_new_node_on_one_side_weight;
            left = 1;
            $display("left addeded %d %d", leftx, lefty);
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