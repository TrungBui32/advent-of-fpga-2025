module playground_part1(
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

    reg [16:0] x [0:NUM_ELEMENT-1];
    reg [16:0] y [0:NUM_ELEMENT-1];
    reg [16:0] z [0:NUM_ELEMENT-1];

    reg [9:0] parent [0:NUM_ELEMENT-1];
    reg [9:0] size [0:NUM_ELEMENT-1];

    reg [63:0] min_distances [0:NUM_LOOP-1];        // NUM_LOOP here is not logically correct but works lol
    reg [9:0] min_src [0:NUM_LOOP-1];
    reg [9:0] min_dst [0:NUM_LOOP-1];
    
    reg [10:0] top1, top2, top3;

    integer k;
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
        $readmemb("z.mem", z);
    end

    localparam IDLE = 4'd0;
    localparam CALC_DISTANCE = 4'd1;
    localparam INSERT_DISTANCE = 4'd2;
    localparam CONNECT_BOX = 4'd3;
    localparam MERGE_CIRCUITS = 4'd4;
    localparam SCAN_CIRCUITS = 4'd5;
    localparam DONE = 4'd6;

    reg [3:0] state;
    reg [31:0] current_i, current_j;
    reg [63:0] current_distance;
    reg [31:0] loop_count;
    reg [31:0] num_stored;
    
    reg [9:0] circuit_id [0:NUM_ELEMENT-1];  
    reg [10:0] circuit_size [0:NUM_ELEMENT-1]; 
    reg [9:0] next_circuit_id; 
    
    reg [9:0] src_circuit, dst_circuit;
    reg [9:0] new_size;
    
    reg [31:0] insert_pos;
    reg found_pos;
    
    reg [31:0] merge_idx;
    
    reg [31:0] scan_idx;
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            current_i <= 0;
            current_j <= 0;
            loop_count <= 0;
            num_stored <= 0;
            top1 <= 0;
            top2 <= 0;
            top3 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CALC_DISTANCE;
                        current_i <= 0;
                        current_j <= 1;
                        loop_count <= 0;
                        num_stored <= 0;
                        top1 <= 0;
                        top2 <= 0;
                        top3 <= 0;
                        next_circuit_id <= 0;
                        
                        for (k = 0; k < NUM_LOOP; k = k + 1) begin
                            min_distances[k] <= {64{1'b1}};
                        end
                        for (k = 0; k < NUM_ELEMENT; k = k + 1) begin
                            parent[k] <= k;  
                            size[k] <= 1;
                            circuit_id[k] <= 10'd1023; 
                            circuit_size[k] <= 0;
                        end
                    end
                end
                
                CALC_DISTANCE: begin
                    current_distance <= (x[current_i] - x[current_j]) * (x[current_i] - x[current_j]) + 
                                        (y[current_i] - y[current_j]) * (y[current_i] - y[current_j]) + 
                                        (z[current_i] - z[current_j]) * (z[current_i] - z[current_j]);
                    state <= INSERT_DISTANCE;
                    found_pos <= 0;
                    insert_pos <= num_stored;
                end
                
                INSERT_DISTANCE: begin                    
                    if(!found_pos && insert_pos > 0) begin
                        if(current_distance > min_distances[insert_pos-1]) begin
                            found_pos <= 1;
                            min_distances[insert_pos] <= current_distance;
                            min_src[insert_pos] <= current_i;
                            min_dst[insert_pos] <= current_j;

                            if (num_stored < NUM_LOOP) begin
                                num_stored <= num_stored + 1;
                            end
                        
                            if (current_j == NUM_ELEMENT - 1) begin
                                if (current_i == NUM_ELEMENT - 2) begin
                                    state <= CONNECT_BOX;
                                    loop_count <= 0;
                                end else begin
                                    current_j <= current_i + 2;
                                    current_i <= current_i + 1;
                                    state <= CALC_DISTANCE;
                                end
                            end else begin
                                state <= CALC_DISTANCE;
                                current_j <= current_j + 1;
                            end
                        end else begin
                            min_distances[insert_pos] <= min_distances[insert_pos-1];
                            min_src[insert_pos] <= min_src[insert_pos-1];
                            min_dst[insert_pos] <= min_dst[insert_pos-1];
                            insert_pos <= insert_pos - 1;
                        end
                    end else begin
                        min_distances[0] <= current_distance;
                        min_src[0] <= current_i;
                        min_dst[0] <= current_j;

                        if (num_stored < NUM_LOOP) begin
                            num_stored <= num_stored + 1;
                        end
                        
                        if (current_j == NUM_ELEMENT - 1) begin
                            if (current_i == NUM_ELEMENT - 2) begin
                                state <= CONNECT_BOX;
                                loop_count <= 0;
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
                CONNECT_BOX: begin                    
                    src_circuit = circuit_id[min_src[loop_count]];
                    dst_circuit = circuit_id[min_dst[loop_count]];
                    
                    if (src_circuit == 10'd1023 && dst_circuit == 10'd1023) begin
                        circuit_id[min_src[loop_count]] <= next_circuit_id;
                        circuit_id[min_dst[loop_count]] <= next_circuit_id;
                        circuit_size[next_circuit_id] <= 2;
                        next_circuit_id <= next_circuit_id + 1;
                        
                        if (loop_count == NUM_LOOP - 1) begin
                            state <= SCAN_CIRCUITS;
                            top1 <= 0;
                            top2 <= 0;
                            top3 <= 0;
                            scan_idx <= 0;
                        end else begin
                            loop_count <= loop_count + 1;
                        end
                        
                    end else if (src_circuit == 10'd1023) begin
                        circuit_id[min_src[loop_count]] <= dst_circuit;
                        circuit_size[dst_circuit] <= circuit_size[dst_circuit] + 1;
                        
                        if (loop_count == NUM_LOOP - 1) begin
                            state <= SCAN_CIRCUITS;
                            top1 <= 0;
                            top2 <= 0;
                            top3 <= 0;
                            scan_idx <= 0;
                        end else begin
                            loop_count <= loop_count + 1;
                        end
                        
                    end else if (dst_circuit == 10'd1023) begin
                        circuit_id[min_dst[loop_count]] <= src_circuit;
                        circuit_size[src_circuit] <= circuit_size[src_circuit] + 1;
                        
                        if (loop_count == NUM_LOOP - 1) begin
                            state <= SCAN_CIRCUITS;
                            top1 <= 0;
                            top2 <= 0;
                            top3 <= 0;
                            scan_idx <= 0;
                        end else begin
                            loop_count <= loop_count + 1;
                        end
                        
                    end else if (src_circuit != dst_circuit) begin
                        new_size <= circuit_size[src_circuit] + circuit_size[dst_circuit];
                        merge_idx <= 0;
                        state <= MERGE_CIRCUITS;
                        
                    end else begin
                        if (loop_count == NUM_LOOP - 1) begin
                            state <= SCAN_CIRCUITS;
                            top1 <= 0;
                            top2 <= 0;
                            top3 <= 0;
                            scan_idx <= 0;
                        end else begin
                            loop_count <= loop_count + 1;
                        end
                    end
                end
                MERGE_CIRCUITS: begin
                    if (merge_idx < NUM_ELEMENT) begin
                        if (circuit_id[merge_idx] == dst_circuit) begin
                            circuit_id[merge_idx] <= src_circuit;
                        end
                        merge_idx <= merge_idx + 1;
                    end else begin
                        circuit_size[src_circuit] <= new_size;
                        circuit_size[dst_circuit] <= 0;
                        
                        if (loop_count == NUM_LOOP - 1) begin
                            state <= SCAN_CIRCUITS;
                            scan_idx <= 0;
                        end else begin
                            loop_count <= loop_count + 1;
                            state <= CONNECT_BOX;
                        end
                    end
                end
                SCAN_CIRCUITS: begin
                    if (scan_idx < next_circuit_id) begin
                        if (circuit_size[scan_idx] > top1) begin
                            top3 <= top2;
                            top2 <= top1;
                            top1 <= circuit_size[scan_idx];
                        end else if (circuit_size[scan_idx] > top2) begin
                            top3 <= top2;
                            top2 <= circuit_size[scan_idx];
                            end else if (circuit_size[scan_idx] > top3) begin
                            top3 <= circuit_size[scan_idx];
                        end
                        scan_idx <= scan_idx + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1;
                    result <= top1 * top2 * top3;
                end
            endcase
        end
    end
endmodule