module day_8(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam NUM_ELEMENT = 20;
    localparam DISTANCE_WIDTH = 64;
    localparam TABLE_SIZE = NUM_ELEMENT * (NUM_ELEMENT - 1); 
    localparam NUM_LOOP = 10;
    
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
    localparam TABLE_INIT = 3'd1;
    localparam SORT_DISTANCE = 3'd2;
    localparam CONNECT_BOX = 3'd3;
    localparam SORT_CIRCUIT = 3'd4;
    localparam COMPUTE_RESULT = 3'd5;
    localparam DONE = 3'd6;

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
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= TABLE_INIT;
                        sort_iter <= 0;
                        loop_count <= 0;
                        iter_distance_table <= 0;
                        circuit_index <= 0;
                        box_count <= 0;
                        idx = 0;
                    end
                end
                TABLE_INIT: begin
                    for (i = 0; i < NUM_ELEMENT; i = i + 1) begin
                        for (j = 0; j < NUM_ELEMENT; j = j + 1) begin
                            if (i < j) begin
                                distance_table[idx] = 
                                    (x[i] > x[j] ? (x[i] - x[j]) * (x[i] - x[j]) : (x[j] - x[i]) * (x[j] - x[i])) + 
                                    (y[i] > y[j] ? (y[i] - y[j]) * (y[i] - y[j]) : (y[j] - y[i]) * (y[j] - y[i])) +
                                    (z[i] > z[j] ? (z[i] - z[j]) * (z[i] - z[j]) : (z[j] - z[i]) * (z[j] - z[i]));
                            end else begin
                                distance_table[idx] = 64'hFFFFFFFFFFFFFFFF;
                            end
                            connection_src[idx] = i;
                            connection_dst[idx] = j;
                            idx = idx + 1;
                        end
                    end
                    state <= SORT_DISTANCE;

                    $display("Table Init Done");
                    // for (s = 0; s < 100; s = s + 1) begin
                    //     $display("Distance %0d: %0d between box %0d and box %0d", s, distance_table[s], connection_src[s], connection_dst[s]);
                    // end

                end
                SORT_DISTANCE: begin
                    sort_iter <= sort_iter + 1;
                    if(sort_iter < TABLE_SIZE - 1) begin
                        if(sort_iter[0] == 0) begin
                            for(s = 0; s < TABLE_SIZE; s = s + 1) begin
                                if(distance_table[s] > distance_table[s + 1]) begin
                                    distance_table[s] <= distance_table[s + 1];
                                    distance_table[s + 1] <= distance_table[s];
                                    connection_src[s] <= connection_src[s + 1];
                                    connection_src[s + 1] <= connection_src[s];
                                    connection_dst[s] <= connection_dst[s + 1];
                                    connection_dst[s + 1] <= connection_dst[s];
                                end 
                            end
                        end else begin
                            for(s = 1; s < TABLE_SIZE - 1; s = s + 1) begin
                                if(distance_table[s] > distance_table[s + 1]) begin
                                    distance_table[s] <= distance_table[s + 1];
                                    distance_table[s + 1] <= distance_table[s];
                                    connection_src[s] <= connection_src[s + 1];
                                    connection_src[s + 1] <= connection_src[s];
                                    connection_dst[s] <= connection_dst[s + 1];
                                    connection_dst[s + 1] <= connection_dst[s];
                                end 
                            end
                        end
                        $display("Distance Sort Iteration %0d", sort_iter);
                    end else begin
                        state <= CONNECT_BOX;
                        sort_iter <= 0;

                        $display("Distance Sort Done");
                        // for (s = 0; s < 100; s = s + 1) begin
                        //     $display("Distance %0d: %0d between box %0d and box %0d", s, distance_table[s], connection_src[s], connection_dst[s]);
                        // end

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
                            // move all boxes from dest circuit to src circuit
                            for(i = 0; i < circuit_size[dest_circuit_index]; i = i + 1) begin
                                circuit_table[src_circuit_index][circuit_size[src_circuit_index]] <= circuit_table[dest_circuit_index][i];
                                box_circuit[circuit_table[dest_circuit_index][i]] <= src_circuit_index;
                                circuit_size[src_circuit_index] <= circuit_size[src_circuit_index] + 1;
                            end
                            // clear the dest circuit size
                            circuit_size[dest_circuit_index] <= 0;
                        end
                    end

                    if(loop_count == NUM_LOOP) begin
                        state <= SORT_CIRCUIT;
                        $display("Box Connection Done");
                    end else begin
                        loop_count <= loop_count + 1;
                        iter_distance_table <= iter_distance_table + 1;
                    end
                end
                SORT_CIRCUIT: begin
                    sort_iter <= sort_iter + 1;
                    if(sort_iter < circuit_index) begin
                        if(sort_iter[0] == 0) begin
                            for(s = 0; s < circuit_index; s = s + 1) begin
                                if(circuit_size[s] < circuit_size[s + 1]) begin
                                    circuit_size[s] <= circuit_size[s + 1];
                                    circuit_size[s + 1] <= circuit_size[s];
                                end 
                            end
                        end else begin
                            for(s = 1; s < circuit_index - 1; s = s + 1) begin
                                if(circuit_size[s] < circuit_size[s + 1]) begin
                                    circuit_size[s] <= circuit_size[s + 1];
                                    circuit_size[s + 1] <= circuit_size[s];
                                end 
                            end
                        end
                    end else begin
                        state <= COMPUTE_RESULT;
                        $display("Circuit Sort Done");
                    end
                end 
                COMPUTE_RESULT: begin
                    box_count <= circuit_size[0] * circuit_size[1] * circuit_size[2];
                    state <= DONE;
                    $display("Result Computation Done");
                end
                DONE: begin
                    finished <= 1;
                    result <= box_count;
                    $display("Finished with result: %0d", box_count);
                end
            endcase
        end
    end
endmodule