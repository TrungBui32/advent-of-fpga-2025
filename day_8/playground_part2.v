module playground_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam NUM_ELEMENT = 1000;
    localparam TABLE_SIZE = NUM_ELEMENT * NUM_ELEMENT / 2; 
    localparam PARALLEL = 1000;
    
    localparam COORD_WIDTH = 17;      
    localparam DIST_WIDTH  = 35;  
    localparam IDX_WIDTH   = 10;  
    
    localparam MAX_DISTANCE = {DIST_WIDTH{1'b1}}; 
    
    reg [COORD_WIDTH-1:0] x [0:NUM_ELEMENT-1];
    reg [COORD_WIDTH-1:0] y [0:NUM_ELEMENT-1];
    reg [COORD_WIDTH-1:0] z [0:NUM_ELEMENT-1];

    reg [DIST_WIDTH-1:0] distance_table [0:TABLE_SIZE-1];
    reg [DIST_WIDTH-1:0] distance_table_temp [0:TABLE_SIZE-1];

    reg [IDX_WIDTH-1:0] connection_src [0:TABLE_SIZE-1];
    reg [IDX_WIDTH-1:0] connection_dst [0:TABLE_SIZE-1];
    reg [IDX_WIDTH-1:0] connection_src_temp [0:TABLE_SIZE-1];
    reg [IDX_WIDTH-1:0] connection_dst_temp [0:TABLE_SIZE-1];

    reg [IDX_WIDTH-1:0] circuit_size [0:NUM_ELEMENT-1];
    reg [IDX_WIDTH-1:0] box_circuit [0:NUM_ELEMENT-1];

    reg [IDX_WIDTH-1:0] num_circuits;
    reg [IDX_WIDTH-1:0] last_src, last_dst;

    wire all_connected;
    assign all_connected = (num_circuits == 1);

    integer k;
    integer init_i, init_j;

    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
        $readmemb("z.mem", z);
        
        for (k = 0; k < NUM_ELEMENT; k = k + 1) begin
            circuit_size[k] = 1;
            box_circuit[k] = k; 
        end

        for (k = 0; k < TABLE_SIZE; k = k + 1) begin
            distance_table_temp[k] = MAX_DISTANCE;
            connection_src_temp[k] = 0;
            connection_dst_temp[k] = 0;
        end

        for(init_i = 0; init_i < NUM_ELEMENT; init_i = init_i + 1) begin
            for(init_j = init_i + 1; init_j < NUM_ELEMENT; init_j = init_j + 1) begin
                distance_table[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2] = 
                    (x[init_i] - x[init_j]) * (x[init_i] - x[init_j]) + 
                    (y[init_i] - y[init_j]) * (y[init_i] - y[init_j]) + 
                    (z[init_i] - z[init_j]) * (z[init_i] - z[init_j]);
                
                connection_src[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2] = init_i;
                connection_dst[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2] = init_j;
                            
                if(init_i == NUM_ELEMENT - 1) begin
                    distance_table[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2 + 1] = MAX_DISTANCE;
                    connection_src[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2 + 1] = 0;
                    connection_dst[init_i * NUM_ELEMENT + init_j - ((init_i + 2) * (init_i + 1)) / 2 + 1] = 0;
                end
            end
        end
    end

    localparam IDLE = 4'd0;
    localparam SORT = 4'd2;
    localparam MOVE = 4'd3;
    localparam MERGE_1 = 4'd4;
    localparam MERGE_2 = 4'd5;
    localparam MERGE_3 = 4'd6;
    localparam MERGE_4 = 4'd7;
    localparam MERGE_5 = 4'd8;
    localparam CONNECT_BOX = 4'd9;
    localparam COMPUTE_RESULT = 4'd10;
    localparam DONE = 4'd11;
    localparam CACHE = 4'd12;

    reg [3:0] state;

    integer i, j;
    reg sort_iter;

    reg [32:0] iter_distance_table_1;
    reg [32:0] iter_distance_table_2;
    reg [32:0] iter_distance_table_3;
    reg [32:0] iter_distance_table_4;

    reg [IDX_WIDTH-1:0] dest_circuit_index;
    reg [IDX_WIDTH-1:0] src_circuit_index;

    reg [63:0] box_count; 
    integer idx;
    reg sorted;

    reg [DIST_WIDTH-1:0] current_distance_1 [0:PARALLEL-1];
    reg [DIST_WIDTH-1:0] current_distance_2 [0:PARALLEL-1];
    reg [DIST_WIDTH-1:0] current_distance_3 [0:PARALLEL-1];
    reg [DIST_WIDTH-1:0] current_distance_4 [0:PARALLEL-1];

    reg [IDX_WIDTH-1:0] current_src_1 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_dst_1 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_src_2 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_dst_2 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_src_3 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_dst_3 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_src_4 [0:PARALLEL-1];
    reg [IDX_WIDTH-1:0] current_dst_4 [0:PARALLEL-1];

    reg [31:0] merge_iter_1;
    reg [31:0] merge_iter_2;
    reg [31:0] outer_iter;
    reg [31:0] inner_iter;
    reg [31:0] counter1;
    reg [31:0] counter2;

    reg [31:0] idx0, idx1, idx2, idx3, idx4; 
    reg [31:0] rem0, rem1, rem2, rem3, rem4;

    wire valid0 = (rem0 != 0);
    wire valid1 = (rem1 != 0);
    wire valid2 = (rem2 != 0);
    wire valid3 = (rem3 != 0);
    wire valid4 = (rem4 != 0);

    wire use_temp_as_source = (state == MERGE_4);

    wire [DIST_WIDTH-1:0] head0 = use_temp_as_source ? distance_table_temp[idx0] : distance_table[idx0];
    wire [DIST_WIDTH-1:0] head1 = use_temp_as_source ? distance_table_temp[idx1] : distance_table[idx1];
    wire [DIST_WIDTH-1:0] head2 = use_temp_as_source ? distance_table_temp[idx2] : distance_table[idx2];
    wire [DIST_WIDTH-1:0] head3 = use_temp_as_source ? distance_table_temp[idx3] : distance_table[idx3];
    wire [DIST_WIDTH-1:0] head4 = use_temp_as_source ? distance_table_temp[idx4] : distance_table[idx4];

    wire [IDX_WIDTH-1:0] conn_src0 = use_temp_as_source ? connection_src_temp[idx0] : connection_src[idx0];
    wire [IDX_WIDTH-1:0] conn_src1 = use_temp_as_source ? connection_src_temp[idx1] : connection_src[idx1];
    wire [IDX_WIDTH-1:0] conn_src2 = use_temp_as_source ? connection_src_temp[idx2] : connection_src[idx2];
    wire [IDX_WIDTH-1:0] conn_src3 = use_temp_as_source ? connection_src_temp[idx3] : connection_src[idx3];
    wire [IDX_WIDTH-1:0] conn_src4 = use_temp_as_source ? connection_src_temp[idx4] : connection_src[idx4];

    wire [IDX_WIDTH-1:0] conn_dst0 = use_temp_as_source ? connection_dst_temp[idx0] : connection_dst[idx0];
    wire [IDX_WIDTH-1:0] conn_dst1 = use_temp_as_source ? connection_dst_temp[idx1] : connection_dst[idx1];
    wire [IDX_WIDTH-1:0] conn_dst2 = use_temp_as_source ? connection_dst_temp[idx2] : connection_dst[idx2];
    wire [IDX_WIDTH-1:0] conn_dst3 = use_temp_as_source ? connection_dst_temp[idx3] : connection_dst[idx3];
    wire [IDX_WIDTH-1:0] conn_dst4 = use_temp_as_source ? connection_dst_temp[idx4] : connection_dst[idx4];

    wire [DIST_WIDTH-1:0] min_val;
    wire [2:0]            min_idx;
    wire                  min_valid;

    min5 #(
        .DATA_WIDTH(DIST_WIDTH)
    ) u_min5 (
        .val0     (head0),
        .val1     (head1),
        .val2     (head2),
        .val3     (head3),
        .val4     (head4),
        .valid0   (valid0),
        .valid1   (valid1),
        .valid2   (valid2),
        .valid3   (valid3),
        .valid4   (valid4),
        .min_val  (min_val),
        .min_idx  (min_idx),
        .min_valid(min_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            sort_iter <= 0;
            iter_distance_table_1 <= 0;
            box_count <= 0;
            sorted <= 0;
            num_circuits <= NUM_ELEMENT;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        sort_iter <= 0;
                        iter_distance_table_1 <= 0;
                        box_count <= 0;
                        idx = 0;
                        sorted <= 0;
                        num_circuits <= NUM_ELEMENT;
                        
                        iter_distance_table_1 <= 0;
                        iter_distance_table_2 <= PARALLEL;
                        iter_distance_table_3 <= 2*PARALLEL;
                        iter_distance_table_4 <= 3*PARALLEL;
                        state <= CACHE;
                    end
                end
                CACHE: begin
                    for(i = 0; i < PARALLEL; i = i + 1) begin
                        current_distance_1[i] <= distance_table[iter_distance_table_1 + i];
                        current_src_1[i] <= connection_src[iter_distance_table_1 + i];
                        current_dst_1[i] <= connection_dst[iter_distance_table_1 + i];

                        current_distance_2[i] <= distance_table[iter_distance_table_2 + i];
                        current_src_2[i] <= connection_src[iter_distance_table_2 + i];
                        current_dst_2[i] <= connection_dst[iter_distance_table_2 + i];

                        current_distance_3[i] <= distance_table[iter_distance_table_3 + i];
                        current_src_3[i] <= connection_src[iter_distance_table_3 + i];
                        current_dst_3[i] <= connection_dst[iter_distance_table_3 + i];

                        current_distance_4[i] <= distance_table[iter_distance_table_4 + i];
                        current_src_4[i] <= connection_src[iter_distance_table_4 + i];
                        current_dst_4[i] <= connection_dst[iter_distance_table_4 + i];
                    end
                    state <= SORT;
                end
                SORT: begin
                    if(sort_iter == 0) begin
                        sorted = 1;
                        for(i = 1; i < PARALLEL - 1; i = i + 2) begin
                            if(current_distance_1[i] > current_distance_1[i + 1]) begin
                                current_distance_1[i + 1] <= current_distance_1[i];
                                current_distance_1[i] <= current_distance_1[i + 1];
                                current_src_1[i + 1] <= current_src_1[i];
                                current_src_1[i] <= current_src_1[i + 1];
                                current_dst_1[i + 1] <= current_dst_1[i];
                                current_dst_1[i] <= current_dst_1[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_2[i] > current_distance_2[i + 1]) begin
                                current_distance_2[i + 1] <= current_distance_2[i];
                                current_distance_2[i] <= current_distance_2[i + 1];
                                current_src_2[i + 1] <= current_src_2[i];
                                current_src_2[i] <= current_src_2[i + 1];
                                current_dst_2[i + 1] <= current_dst_2[i];
                                current_dst_2[i] <= current_dst_2[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_3[i] > current_distance_3[i + 1]) begin
                                current_distance_3[i + 1] <= current_distance_3[i];
                                current_distance_3[i] <= current_distance_3[i + 1];
                                current_src_3[i + 1] <= current_src_3[i];
                                current_src_3[i] <= current_src_3[i + 1];
                                current_dst_3[i + 1] <= current_dst_3[i];
                                current_dst_3[i] <= current_dst_3[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_4[i] > current_distance_4[i + 1]) begin
                                current_distance_4[i + 1] <= current_distance_4[i];
                                current_distance_4[i] <= current_distance_4[i + 1];
                                current_src_4[i + 1] <= current_src_4[i];
                                current_src_4[i] <= current_src_4[i + 1];
                                current_dst_4[i + 1] <= current_dst_4[i];
                                current_dst_4[i] <= current_dst_4[i + 1];
                                sorted = 0;
                            end
                        end
                        sort_iter <= 1;
                    end else begin
                        for(i = 0; i < PARALLEL - 1; i = i + 2) begin
                            if(current_distance_1[i] > current_distance_1[i + 1]) begin
                                current_distance_1[i + 1] <= current_distance_1[i];
                                current_distance_1[i] <= current_distance_1[i + 1];
                                current_src_1[i + 1] <= current_src_1[i];
                                current_src_1[i] <= current_src_1[i + 1];
                                current_dst_1[i + 1] <= current_dst_1[i];
                                current_dst_1[i] <= current_dst_1[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_2[i] > current_distance_2[i + 1]) begin
                                current_distance_2[i + 1] <= current_distance_2[i];
                                current_distance_2[i] <= current_distance_2[i + 1];
                                current_src_2[i + 1] <= current_src_2[i];
                                current_src_2[i] <= current_src_2[i + 1];
                                current_dst_2[i + 1] <= current_dst_2[i];
                                current_dst_2[i] <= current_dst_2[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_3[i] > current_distance_3[i + 1]) begin
                                current_distance_3[i + 1] <= current_distance_3[i];
                                current_distance_3[i] <= current_distance_3[i + 1];
                                current_src_3[i + 1] <= current_src_3[i];
                                current_src_3[i] <= current_src_3[i + 1];
                                current_dst_3[i + 1] <= current_dst_3[i];
                                current_dst_3[i] <= current_dst_3[i + 1];
                                sorted = 0;
                            end
                            if(current_distance_4[i] > current_distance_4[i + 1]) begin
                                current_distance_4[i + 1] <= current_distance_4[i];
                                current_distance_4[i] <= current_distance_4[i + 1];
                                current_src_4[i + 1] <= current_src_4[i];
                                current_src_4[i] <= current_src_4[i + 1];
                                current_dst_4[i + 1] <= current_dst_4[i];
                                current_dst_4[i] <= current_dst_4[i + 1];
                                sorted = 0;
                            end
                        end
                        if(sorted) begin
                            state <= MOVE;
                            sorted <= 0;
                        end else begin
                            sort_iter <= 0;
                        end
                    end
                end
                MOVE: begin
                    for(i = 0; i < PARALLEL; i = i + 1) begin
                        distance_table[iter_distance_table_1 + i] <= current_distance_1[i];
                        connection_src[iter_distance_table_1 + i] <= current_src_1[i];
                        connection_dst[iter_distance_table_1 + i] <= current_dst_1[i];

                        distance_table[iter_distance_table_2 + i] <= current_distance_2[i];
                        connection_src[iter_distance_table_2 + i] <= current_src_2[i];
                        connection_dst[iter_distance_table_2 + i] <= current_dst_2[i];

                        distance_table[iter_distance_table_3 + i] <= current_distance_3[i];
                        connection_src[iter_distance_table_3 + i] <= current_src_3[i];
                        connection_dst[iter_distance_table_3 + i] <= current_dst_3[i];

                        distance_table[iter_distance_table_4 + i] <= current_distance_4[i];
                        connection_src[iter_distance_table_4 + i] <= current_src_4[i];
                        connection_dst[iter_distance_table_4 + i] <= current_dst_4[i];
                    end
                    if(iter_distance_table_1 + 4*PARALLEL < TABLE_SIZE) begin
                        iter_distance_table_1 <= iter_distance_table_1 + 4*PARALLEL;
                        iter_distance_table_2 <= iter_distance_table_2 + 4*PARALLEL;
                        iter_distance_table_3 <= iter_distance_table_3 + 4*PARALLEL;
                        iter_distance_table_4 <= iter_distance_table_4 + 4*PARALLEL;
                        state <= CACHE;
                    end else begin
                        state <= MERGE_1;
                        merge_iter_1 <= 0;
                        merge_iter_2 <= PARALLEL;
                        outer_iter <= 0;
                        inner_iter <= 0;
                        counter1 <= PARALLEL;
                        counter2 <= PARALLEL;
                    end
                end
                MERGE_1: begin
                    if(outer_iter < 250) begin
                        if(inner_iter < 2000) begin
                            if(counter1 == 0) begin
                                distance_table_temp[outer_iter * 2000 + inner_iter] <= distance_table[merge_iter_2];
                                connection_src_temp[outer_iter * 2000 + inner_iter] <= connection_src[merge_iter_2];
                                connection_dst_temp[outer_iter * 2000 + inner_iter] <= connection_dst[merge_iter_2];
                                merge_iter_2 <= merge_iter_2 + 1;
                                counter2 <= counter2 - 1;
                            end else if(counter2 == 0) begin
                                distance_table_temp[outer_iter * 2000 + inner_iter] <= distance_table[merge_iter_1];
                                connection_src_temp[outer_iter * 2000 + inner_iter] <= connection_src[merge_iter_1];
                                connection_dst_temp[outer_iter * 2000 + inner_iter] <= connection_dst[merge_iter_1];
                                merge_iter_1 <= merge_iter_1 + 1;
                                counter1 <= counter1 - 1;
                            end else if(distance_table[merge_iter_1] < distance_table[merge_iter_2]) begin
                                distance_table_temp[outer_iter * 2000 + inner_iter] <= distance_table[merge_iter_1];
                                connection_src_temp[outer_iter * 2000 + inner_iter] <= connection_src[merge_iter_1];
                                connection_dst_temp[outer_iter * 2000 + inner_iter] <= connection_dst[merge_iter_1];
                                merge_iter_1 <= merge_iter_1 + 1;
                                counter1 <= counter1 - 1;
                            end else begin
                                distance_table_temp[outer_iter * 2000 + inner_iter] <= distance_table[merge_iter_2];
                                connection_src_temp[outer_iter * 2000 + inner_iter] <= connection_src[merge_iter_2];
                                connection_dst_temp[outer_iter * 2000 + inner_iter] <= connection_dst[merge_iter_2];
                                merge_iter_2 <= merge_iter_2 + 1;
                                counter2 <= counter2 - 1;
                            end
                            inner_iter <= inner_iter + 1;
                        end else begin
                            outer_iter <= outer_iter + 1;
                            inner_iter <= 0;
                            counter1 <= PARALLEL;
                            counter2 <= PARALLEL;
                            merge_iter_1 <= merge_iter_1 + PARALLEL;
                            merge_iter_2 <= merge_iter_2 + PARALLEL;
                        end
                    end else begin
                        state <= MERGE_2;
                        merge_iter_1 <= 0;
                        merge_iter_2 <= 2000;
                        outer_iter <= 0;
                        inner_iter <= 0;
                        counter1 <= 2000;
                        counter2 <= 2000;
                    end
                end
                MERGE_2: begin
                    if(outer_iter < 125) begin
                        if(inner_iter < 4000) begin
                            if(counter1 == 0) begin
                                distance_table[outer_iter * 4000 + inner_iter] <= distance_table_temp[merge_iter_2];
                                connection_src[outer_iter * 4000 + inner_iter] <= connection_src_temp[merge_iter_2];
                                connection_dst[outer_iter * 4000 + inner_iter] <= connection_dst_temp[merge_iter_2];
                                merge_iter_2 <= merge_iter_2 + 1;
                                counter2 <= counter2 - 1;
                            end else if(counter2 == 0) begin
                                distance_table[outer_iter * 4000 + inner_iter] <= distance_table_temp[merge_iter_1];
                                connection_src[outer_iter * 4000 + inner_iter] <= connection_src_temp[merge_iter_1];
                                connection_dst[outer_iter * 4000 + inner_iter] <= connection_dst_temp[merge_iter_1];
                                merge_iter_1 <= merge_iter_1 + 1;
                                counter1 <= counter1 - 1;
                            end else if(distance_table_temp[merge_iter_1] < distance_table_temp[merge_iter_2]) begin
                                distance_table[outer_iter * 4000 + inner_iter] <= distance_table_temp[merge_iter_1];
                                connection_src[outer_iter * 4000 + inner_iter] <= connection_src_temp[merge_iter_1];
                                connection_dst[outer_iter * 4000 + inner_iter] <= connection_dst_temp[merge_iter_1];
                                merge_iter_1 <= merge_iter_1 + 1;
                                counter1 <= counter1 - 1;
                            end else begin
                                distance_table[outer_iter * 4000 + inner_iter] <= distance_table_temp[merge_iter_2];
                                connection_src[outer_iter * 4000 + inner_iter] <= connection_src_temp[merge_iter_2];
                                connection_dst[outer_iter * 4000 + inner_iter] <= connection_dst_temp[merge_iter_2];
                                merge_iter_2 <= merge_iter_2 + 1;
                                counter2 <= counter2 - 1;
                            end
                            inner_iter <= inner_iter + 1;
                        end else begin
                            outer_iter <= outer_iter + 1;
                            inner_iter <= 0;
                            counter1 <= 2000;
                            counter2 <= 2000;
                            merge_iter_1 <= merge_iter_1 + 2000;
                            merge_iter_2 <= merge_iter_2 + 2000;
                        end
                    end else begin
                        state <= MERGE_3;
                        outer_iter <= 0;
                        inner_iter <= 0;
                        idx0 <= 0;
                        idx1 <= 4000;
                        idx2 <= 8000;
                        idx3 <= 12000;
                        idx4 <= 16000;
                        rem0 <= 4000;
                        rem1 <= 4000;
                        rem2 <= 4000;
                        rem3 <= 4000;
                        rem4 <= 4000;
                    end
                end
                MERGE_3: begin
                    if(outer_iter < 25) begin
                        if(inner_iter < 20000) begin
                            if(min_valid) begin
                                distance_table_temp[outer_iter * 20000 + inner_iter] <= min_val;
                                case(min_idx)
                                    3'd0: begin
                                        connection_src_temp[outer_iter * 20000 + inner_iter] <= conn_src0;
                                        connection_dst_temp[outer_iter * 20000 + inner_iter] <= conn_dst0;
                                        idx0 <= idx0 + 1;
                                        rem0 <= rem0 - 1;
                                    end
                                    3'd1: begin
                                        connection_src_temp[outer_iter * 20000 + inner_iter] <= conn_src1;
                                        connection_dst_temp[outer_iter * 20000 + inner_iter] <= conn_dst1;
                                        idx1 <= idx1 + 1;
                                        rem1 <= rem1 - 1;
                                    end
                                    3'd2: begin
                                        connection_src_temp[outer_iter * 20000 + inner_iter] <= conn_src2;
                                        connection_dst_temp[outer_iter * 20000 + inner_iter] <= conn_dst2;
                                        idx2 <= idx2 + 1;
                                        rem2 <= rem2 - 1;
                                    end
                                    3'd3: begin
                                        connection_src_temp[outer_iter * 20000 + inner_iter] <= conn_src3;
                                        connection_dst_temp[outer_iter * 20000 + inner_iter] <= conn_dst3;
                                        idx3 <= idx3 + 1;
                                        rem3 <= rem3 - 1;
                                    end
                                    3'd4: begin
                                        connection_src_temp[outer_iter * 20000 + inner_iter] <= conn_src4;
                                        connection_dst_temp[outer_iter * 20000 + inner_iter] <= conn_dst4;
                                        idx4 <= idx4 + 1;
                                        rem4 <= rem4 - 1;
                                    end
                                endcase
                                inner_iter <= inner_iter + 1;
                            end
                        end else begin
                            outer_iter <= outer_iter + 1;
                            inner_iter <= 0;
                            idx0 <= outer_iter * 20000 + 20000;
                            idx1 <= outer_iter * 20000 + 20000 + 4000;
                            idx2 <= outer_iter * 20000 + 20000 + 8000;
                            idx3 <= outer_iter * 20000 + 20000 + 12000;
                            idx4 <= outer_iter * 20000 + 20000 + 16000;
                            rem0 <= 4000;
                            rem1 <= 4000;
                            rem2 <= 4000;
                            rem3 <= 4000;
                            rem4 <= 4000;
                        end
                    end else begin
                        state <= MERGE_4;
                        outer_iter <= 0;
                        inner_iter <= 0;
                        idx0 <= 0;
                        idx1 <= 20000;
                        idx2 <= 40000;
                        idx3 <= 60000;
                        idx4 <= 80000;
                        rem0 <= 20000;
                        rem1 <= 20000;
                        rem2 <= 20000;
                        rem3 <= 20000;
                        rem4 <= 20000;
                    end
                end
                MERGE_4: begin
                    if(outer_iter < 5) begin
                        if(inner_iter < 100000) begin
                            if(min_valid) begin
                                distance_table[outer_iter * 100000 + inner_iter] <= min_val;
                                case(min_idx)
                                    3'd0: begin
                                        connection_src[outer_iter * 100000 + inner_iter] <= conn_src0;
                                        connection_dst[outer_iter * 100000 + inner_iter] <= conn_dst0;
                                        idx0 <= idx0 + 1;
                                        rem0 <= rem0 - 1;
                                    end
                                    3'd1: begin
                                        connection_src[outer_iter * 100000 + inner_iter] <= conn_src1;
                                        connection_dst[outer_iter * 100000 + inner_iter] <= conn_dst1;
                                        idx1 <= idx1 + 1;
                                        rem1 <= rem1 - 1;
                                    end
                                    3'd2: begin
                                        connection_src[outer_iter * 100000 + inner_iter] <= conn_src2;
                                        connection_dst[outer_iter * 100000 + inner_iter] <= conn_dst2;
                                        idx2 <= idx2 + 1;
                                        rem2 <= rem2 - 1;
                                    end
                                    3'd3: begin
                                        connection_src[outer_iter * 100000 + inner_iter] <= conn_src3;
                                        connection_dst[outer_iter * 100000 + inner_iter] <= conn_dst3;
                                        idx3 <= idx3 + 1;
                                        rem3 <= rem3 - 1;
                                    end
                                    3'd4: begin
                                        connection_src[outer_iter * 100000 + inner_iter] <= conn_src4;
                                        connection_dst[outer_iter * 100000 + inner_iter] <= conn_dst4;
                                        idx4 <= idx4 + 1;
                                        rem4 <= rem4 - 1;
                                    end
                                endcase
                                inner_iter <= inner_iter + 1;
                            end
                        end else begin
                            outer_iter <= outer_iter + 1;
                            inner_iter <= 0;
                            idx0 <= outer_iter * 100000 + 100000;
                            idx1 <= outer_iter * 100000 + 100000 + 20000;
                            idx2 <= outer_iter * 100000 + 100000 + 40000;
                            idx3 <= outer_iter * 100000 + 100000 + 60000;
                            idx4 <= outer_iter * 100000 + 100000 + 80000;
                            rem0 <= 20000;
                            rem1 <= 20000;
                            rem2 <= 20000;
                            rem3 <= 20000;
                            rem4 <= 20000;
                        end
                    end else begin
                        state <= MERGE_5;
                        outer_iter <= 0;
                        inner_iter <= 0;
                        idx0 <= 0;
                        idx1 <= 100000;
                        idx2 <= 200000;
                        idx3 <= 300000;
                        idx4 <= 400000;
                        rem0 <= 100000;
                        rem1 <= 100000;
                        rem2 <= 100000;
                        rem3 <= 100000;
                        rem4 <= 100000;
                    end
                end
                MERGE_5: begin
                    if(inner_iter < 500000) begin
                        if(min_valid) begin
                            distance_table_temp[inner_iter] <= min_val;
                            case(min_idx)
                                3'd0: begin
                                    connection_src_temp[inner_iter] <= conn_src0;
                                    connection_dst_temp[inner_iter] <= conn_dst0;
                                    idx0 <= idx0 + 1;
                                    rem0 <= rem0 - 1;
                                end
                                3'd1: begin
                                    connection_src_temp[inner_iter] <= conn_src1;
                                    connection_dst_temp[inner_iter] <= conn_dst1;
                                    idx1 <= idx1 + 1;
                                    rem1 <= rem1 - 1;
                                end
                                3'd2: begin
                                    connection_src_temp[inner_iter] <= conn_src2;
                                    connection_dst_temp[inner_iter] <= conn_dst2;
                                    idx2 <= idx2 + 1;
                                    rem2 <= rem2 - 1;
                                end
                                3'd3: begin
                                    connection_src_temp[inner_iter] <= conn_src3;
                                    connection_dst_temp[inner_iter] <= conn_dst3;
                                    idx3 <= idx3 + 1;
                                    rem3 <= rem3 - 1;
                                end
                                3'd4: begin
                                    connection_src_temp[inner_iter] <= conn_src4;
                                    connection_dst_temp[inner_iter] <= conn_dst4;
                                    idx4 <= idx4 + 1;
                                    rem4 <= rem4 - 1;
                                end
                            endcase
                            inner_iter <= inner_iter + 1;
                        end
                    end else begin
                        for(k = 0; k < TABLE_SIZE; k = k + 1) begin
                            distance_table[k] <= distance_table_temp[k];
                            connection_src[k] <= connection_src_temp[k];
                            connection_dst[k] <= connection_dst_temp[k];
                        end
                        state <= CONNECT_BOX;
                        iter_distance_table_1 <= 0;
                    end
                end
                CONNECT_BOX: begin
                    if(!all_connected && iter_distance_table_1 < TABLE_SIZE) begin
                        src_circuit_index = box_circuit[connection_src[iter_distance_table_1]];
                        dest_circuit_index = box_circuit[connection_dst[iter_distance_table_1]];
                        
                        if(src_circuit_index != dest_circuit_index) begin
                            last_src <= connection_src[iter_distance_table_1]; 
                            last_dst <= connection_dst[iter_distance_table_1]; 
                            
                            for(i = 0; i < NUM_ELEMENT; i = i + 1) begin
                                if(box_circuit[i] == dest_circuit_index) begin
                                    box_circuit[i] <= src_circuit_index;
                                end
                            end
                            num_circuits <= num_circuits - 1;
                        end
                        iter_distance_table_1 <= iter_distance_table_1 + 1;
                    end else begin
                        state <= COMPUTE_RESULT;
                    end
                end
                COMPUTE_RESULT: begin
                    box_count <= x[last_src] * x[last_dst]; 
                    state <= DONE;
                end
                DONE: begin
                    finished <= 1;
                    result <= box_count;
                end
            endcase
        end
    end
endmodule