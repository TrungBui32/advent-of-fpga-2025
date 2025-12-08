module day_8(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam NUM_ELEMENT = 1000;
    localparam DISTANCE_WIDTH = 64;
    localparam TABLE_SIZE = NUM_ELEMENT * (NUM_ELEMENT - 1); 
    localparam NUM_LOOP = 1000;
    
    // Design Notes: 3 tables
    // Table 1: store the x, y, z coordinates of each box, box valid, and box circuit
    // Table 2: store the distance ranking table, connection source and destination
    // Table 3: store the circuit index, circuit table and circuit size

    reg [16:0] x [0:NUM_ELEMENT-1];
    reg [16:0] y [0:NUM_ELEMENT-1];
    reg [16:0] z [0:NUM_ELEMENT-1];

    // to store the distance ranking table
    reg [DISTANCE_WIDTH-1:0] distance_table [0:TABLE_SIZE-1];

    // to store whether a box has been connected
    reg [NUM_ELEMENT-1:0] box_valid;

    // to store the list of box in a circuit, each line represents a circuit, position of the box stored (0-999)
    reg [9:0] circuit_table [0:NUM_ELEMENT-1][0:NUM_ELEMENT-1];

    // to store the size of each circuit
    reg [9:0] circuit_size [0:NUM_ELEMENT-1];

    // which circuit each box belongs to
    reg [9:0] box_circuit [0:NUM_ELEMENT-1];

    // 2 tables to store the sources and destinations of each connection
    reg [9:0] connection_src [0:TABLE_SIZE-1];
    reg [9:0] connection_dst [0:TABLE_SIZE-1];

    integer k;
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
        $readmemb("z.mem", z);
        for (k = 0; k < NUM_ELEMENT; k = k + 1) begin
            box_valid[k] = 1;
            circuit_size[k] = 0;
            box_circuit[k] = 0;
        end
    end

    localparam IDLE = 3'd0;
    localparam CALC_DISTANCE = 3'd1;
    localparam FIND_POS = 3'd2;
    localparam SHIFT = 3'd3;
    localparam CONNECT_BOX = 3'd4;
    localparam SORT_CIRCUIT = 3'd5;
    localparam COMPUTE_RESULT = 3'd6;
    localparam DONE = 3'd7;

    reg [2:0] state;

    integer s, i, j;
    reg [32:0] sort_iter;
    reg [32:0] loop_count;
    reg [32:0] iter_distance_table;
    reg [32:0] circuit_index;

    reg [32:0] dest_circuit_index;
    reg [32:0] src_circuit_index;

    reg [32:0] box_count;
    integer idx;
    reg sorted;

    reg [31:0] current_i, current_j;
    reg [63:0] current_distance;
    reg [31:0] insert_pos;
    reg need_insert;
    reg [31:0] num_stored;
    reg [9:0] merge_size;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            sort_iter <= 0;
            loop_count <= 0;
            iter_distance_table <= 0;
            circuit_index <= 0;
            box_count <= 0;
            sorted <= 0;
            insert_pos <= 0;
            need_insert <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CALC_DISTANCE;
                        sort_iter <= 0;
                        loop_count <= 0;
                        iter_distance_table <= 0;
                        circuit_index <= 0;
                        box_count <= 0;
                        idx = 0;
                        sorted <= 0;
                        current_i <= 0;
                        current_j <= 1;
                        insert_pos <= 0;
                        need_insert <= 0;
                        num_stored <= 0;
                        for (k = 0; k < NUM_LOOP; k = k + 1) begin
                            distance_table[k] <= {DISTANCE_WIDTH{1'b1}};
                        end
                    end
                end
                CALC_DISTANCE: begin
                    current_distance <= (x[current_i] - x[current_j]) * (x[current_i] - x[current_j]) + 
                                                        (y[current_i] - y[current_j]) * (y[current_i] - y[current_j]) + 
                                                        (z[current_i] - z[current_j]) * (z[current_i] - z[current_j]);

                    state <= FIND_POS;
                    insert_pos <= 0;
                    need_insert <= 0;
                end
                FIND_POS: begin
                    if(num_stored < NUM_LOOP || current_distance < distance_table[num_stored-1]) begin
                        for(i = 0; i < num_stored; i = i + 1) begin
                            if(current_distance < distance_table[i]) begin
                                insert_pos = i;
                                need_insert = 1;
                                i = num_stored; // break
                            end
                        end
                        if(!need_insert && num_stored < NUM_LOOP) begin
                            need_insert = 1;
                            insert_pos <= num_stored;
                        end
                    end 

                    if(need_insert) begin
                        state <= SHIFT;
                    end else begin
                        if(current_j == NUM_ELEMENT - 1) begin
                            if(current_i == NUM_ELEMENT - 2) begin
                                state <= CONNECT_BOX;
                            end else begin
                                current_j <= current_i + 2;
                                current_i <= current_i + 1;
                                state <= CALC_DISTANCE;
                            end
                        end else begin
                            state <= CALC_DISTANCE;
                            current_j <= current_j + 1;
                        end
                    end
                end
                SHIFT: begin
                    for(i = NUM_LOOP - 1; i > insert_pos; i = i - 1) begin
                        distance_table[i] <= distance_table[i-1];
                        connection_src[i] <= connection_src[i-1];
                        connection_dst[i] <= connection_dst[i-1];
                    end

                    // insert
                    distance_table[insert_pos] <= current_distance;
                    connection_src[insert_pos] <= current_i;
                    connection_dst[insert_pos] <= current_j;

                    if(num_stored < NUM_LOOP) begin
                        num_stored <= num_stored + 1;
                    end

                    if(current_j == NUM_ELEMENT - 1) begin
                        if(current_i == NUM_ELEMENT - 2) begin
                            state <= CONNECT_BOX;
                        end else begin
                            current_j <= current_i + 2;
                            current_i <= current_i + 1;
                            state <= CALC_DISTANCE;
                        end
                    end else begin
                        state <= CALC_DISTANCE;
                        current_j <= current_j + 1;
                    end
                end
                CONNECT_BOX: begin
                    // case 1: both boxes are valid, connect them into a new circuit
                    if(box_valid[connection_src[iter_distance_table]] == 1 && box_valid[connection_dst[iter_distance_table]] == 1) begin
                        // mark both boxes as invalid
                        box_valid[connection_src[iter_distance_table]] <= 0;
                        box_valid[connection_dst[iter_distance_table]] <= 0;

                        // create a new circuit
                        circuit_table[circuit_index][0] <= connection_src[iter_distance_table];
                        circuit_table[circuit_index][1] <= connection_dst[iter_distance_table];
                        circuit_size[circuit_index] <= 2;
                        circuit_index <= circuit_index + 1;

                        // store which circuit the boxes belong to
                        box_circuit[connection_src[iter_distance_table]] <= circuit_index;
                        box_circuit[connection_dst[iter_distance_table]] <= circuit_index;
                    
                    // case 2: src is valid, connect it to the dest circuit
                    end else if(box_valid[connection_src[iter_distance_table]] == 1 && box_valid[connection_dst[iter_distance_table]] == 0) begin
                        // mark the src box as invalid
                        box_valid[connection_src[iter_distance_table]] <= 0;

                        // get the dest circuit index
                        dest_circuit_index = box_circuit[connection_dst[iter_distance_table]];

                        // add the src box to the dest circuit
                        circuit_table[dest_circuit_index][circuit_size[dest_circuit_index]] <= connection_src[iter_distance_table];
                        circuit_size[dest_circuit_index] <= circuit_size[dest_circuit_index] + 1;
                        box_circuit[connection_src[iter_distance_table]] <= dest_circuit_index;

                    // case 3: dest is valid, connect it to the src circuit
                    end else if(box_valid[connection_src[iter_distance_table]] == 0 && box_valid[connection_dst[iter_distance_table]] == 1) begin
                        // mark the dest box as invalid
                        box_valid[connection_dst[iter_distance_table]] <= 0;

                        // get the src circuit index
                        src_circuit_index = box_circuit[connection_src[iter_distance_table]];

                        // add the dest box to the src circuit
                        circuit_table[src_circuit_index][circuit_size[src_circuit_index]] <= connection_dst[iter_distance_table];
                        circuit_size[src_circuit_index] <= circuit_size[src_circuit_index] + 1;
                        box_circuit[connection_dst[iter_distance_table]] <= src_circuit_index;
                    
                    // case 4: both boxes are already connected
                    end else begin
                        // move to 1 circuit if they are in different circuits
                        if(box_circuit[connection_src[iter_distance_table]] != box_circuit[connection_dst[iter_distance_table]]) begin
                            src_circuit_index = box_circuit[connection_src[iter_distance_table]];
                            dest_circuit_index = box_circuit[connection_dst[iter_distance_table]];
                            
                            // Store size before loop
                            merge_size = circuit_size[dest_circuit_index];
                            
                            // Update all boxes' circuit assignment
                            for(i = 0; i < NUM_ELEMENT; i = i + 1) begin
                                if(box_circuit[i] == dest_circuit_index) begin
                                    box_circuit[i] <= src_circuit_index;
                                end
                            end
                            
                            // Copy circuit table
                            for(i = 0; i < merge_size; i = i + 1) begin
                                circuit_table[src_circuit_index][circuit_size[src_circuit_index] + i] <= 
                                    circuit_table[dest_circuit_index][i];
                            end
                            
                            // Update sizes after loop
                            circuit_size[src_circuit_index] <= circuit_size[src_circuit_index] + merge_size;
                            circuit_size[dest_circuit_index] <= 0;
                        end
                    end

                    if(loop_count == NUM_LOOP - 1) begin
                        state <= SORT_CIRCUIT;
                    end else begin
                        loop_count <= loop_count + 1;
                        iter_distance_table <= iter_distance_table + 1;
                    end
                end
                SORT_CIRCUIT: begin
                    sort_iter <= sort_iter + 1;
                    if(sort_iter < circuit_index) begin
                        if(sort_iter[0] == 0) begin
                            for(s = 0; s < circuit_index - 1; s = s + 2) begin
                                if(circuit_size[s] < circuit_size[s + 1]) begin
                                    circuit_size[s] <= circuit_size[s + 1];
                                    circuit_size[s + 1] <= circuit_size[s];
                                end 
                            end
                        end else begin
                            for(s = 1; s < circuit_index - 1; s = s + 2) begin
                                if(circuit_size[s] < circuit_size[s + 1]) begin
                                    circuit_size[s] <= circuit_size[s + 1];
                                    circuit_size[s + 1] <= circuit_size[s];
                                end 
                            end
                        end
                    end else begin
                        state <= COMPUTE_RESULT;
                    end
                end 
                COMPUTE_RESULT: begin
                    box_count <= circuit_size[0] * circuit_size[1] * circuit_size[2];
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