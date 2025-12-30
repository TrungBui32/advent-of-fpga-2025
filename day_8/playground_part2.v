module playground_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam NUM_ELEMENT = 1000;
    localparam HEAP_SIZE = 499500;  
    
    reg [16:0] x [0:NUM_ELEMENT-1];
    reg [16:0] y [0:NUM_ELEMENT-1];
    reg [16:0] z [0:NUM_ELEMENT-1];

    reg [63:0] min_distances [0:HEAP_SIZE-1];       
    reg [9:0] min_src [0:HEAP_SIZE-1];
    reg [9:0] min_dst [0:HEAP_SIZE-1];
    
    reg [9:0] last_src, last_dst;  
    reg [10:0] num_circuits;       

    integer k;
    initial begin
        $readmemb("x.mem", x);
        $readmemb("y.mem", y);
        $readmemb("z.mem", z);
    end

    localparam IDLE = 4'd0;
    localparam CALC_DISTANCE = 4'd1;
    localparam INSERT_DISTANCE = 4'd2;
    localparam BUBBLE_UP = 4'd3;
    localparam HEAPIFY_DOWN = 4'd4;
    localparam CONNECT_BOX = 4'd5;
    localparam MERGE_CIRCUITS = 4'd6;
    localparam EXTRACT_MIN = 4'd7;
    localparam DONE = 4'd8;

    reg [3:0] state;
    reg [31:0] current_i, current_j;
    reg [63:0] current_distance;
    reg [31:0] num_stored;
    
    reg [9:0] circuit_id [0:NUM_ELEMENT-1];  
    
    reg [9:0] src_circuit, dst_circuit;
    reg [9:0] current_src, current_dst;
    
    reg [31:0] merge_idx;
    
    reg [31:0] bubble_idx;
    reg [31:0] heapify_idx;
    reg [31:0] parent_idx;
    reg [31:0] left_child_idx, right_child_idx;
    
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            current_i <= 0;
            current_j <= 0;
            num_stored <= 0;
            num_circuits <= NUM_ELEMENT;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CALC_DISTANCE;
                        current_i <= 0;
                        current_j <= 1;
                        num_stored <= 0;
                        num_circuits <= NUM_ELEMENT;
                        
                        for (k = 0; k < HEAP_SIZE; k = k + 1) begin
                            min_distances[k] <= {64{1'b1}};
                        end
                        for (k = 0; k < NUM_ELEMENT; k = k + 1) begin
                            circuit_id[k] <= k;  
                        end
                    end
                end
                CALC_DISTANCE: begin
                    current_distance <= (x[current_i] - x[current_j]) * (x[current_i] - x[current_j]) + 
                                        (y[current_i] - y[current_j]) * (y[current_i] - y[current_j]) + 
                                        (z[current_i] - z[current_j]) * (z[current_i] - z[current_j]);
                    state <= INSERT_DISTANCE;
                end
                INSERT_DISTANCE: begin      
                    if(num_stored < HEAP_SIZE) begin
                        min_distances[num_stored] <= current_distance;
                        min_src[num_stored] <= current_i;
                        min_dst[num_stored] <= current_j;
                        num_stored <= num_stored + 1;
                        bubble_idx <= num_stored;
                        state <= BUBBLE_UP;
                    end else begin
                        if(current_distance < min_distances[0]) begin
                            min_distances[0] <= current_distance;
                            min_src[0] <= current_i;
                            min_dst[0] <= current_j;
                            heapify_idx <= 0;
                            state <= HEAPIFY_DOWN;
                        end else begin
                            if (current_j == NUM_ELEMENT - 1) begin
                                if (current_i == NUM_ELEMENT - 2) begin
                                    state <= EXTRACT_MIN;
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
                end
                BUBBLE_UP: begin
                    if(bubble_idx > 0) begin
                        parent_idx = (bubble_idx - 1) >> 1;
                        if(min_distances[parent_idx] > min_distances[bubble_idx]) begin
                            min_distances[parent_idx] <= min_distances[bubble_idx];
                            min_src[parent_idx] <= min_src[bubble_idx];
                            min_dst[parent_idx] <= min_dst[bubble_idx];

                            min_distances[bubble_idx] <= min_distances[parent_idx];
                            min_src[bubble_idx] <= min_src[parent_idx];
                            min_dst[bubble_idx] <= min_dst[parent_idx];

                            bubble_idx <= parent_idx;
                        end else begin
                            if (current_j == NUM_ELEMENT - 1) begin
                                if (current_i == NUM_ELEMENT - 2) begin
                                    state <= EXTRACT_MIN;
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
                    end else begin
                        if (current_j == NUM_ELEMENT - 1) begin
                            if (current_i == NUM_ELEMENT - 2) begin
                                state <= EXTRACT_MIN;
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
                HEAPIFY_DOWN: begin
                    left_child_idx = (heapify_idx << 1) + 1;
                    right_child_idx = (heapify_idx << 1) + 2;
                    
                    if(left_child_idx < num_stored && right_child_idx < num_stored) begin
                        if(min_distances[left_child_idx] < min_distances[right_child_idx] && 
                           min_distances[left_child_idx] < min_distances[heapify_idx]) begin
                            min_distances[left_child_idx] <= min_distances[heapify_idx];
                            min_src[left_child_idx] <= min_src[heapify_idx];
                            min_dst[left_child_idx] <= min_dst[heapify_idx];

                            min_distances[heapify_idx] <= min_distances[left_child_idx];
                            min_src[heapify_idx] <= min_src[left_child_idx];
                            min_dst[heapify_idx] <= min_dst[left_child_idx];

                            heapify_idx <= left_child_idx;
                        end else if(min_distances[right_child_idx] < min_distances[heapify_idx]) begin
                            min_distances[right_child_idx] <= min_distances[heapify_idx];
                            min_src[right_child_idx] <= min_src[heapify_idx];
                            min_dst[right_child_idx] <= min_dst[heapify_idx];

                            min_distances[heapify_idx] <= min_distances[right_child_idx];
                            min_src[heapify_idx] <= min_src[right_child_idx];
                            min_dst[heapify_idx] <= min_dst[right_child_idx];

                            heapify_idx <= right_child_idx;
                        end else begin
                            if (current_j == NUM_ELEMENT - 1) begin
                                if (current_i == NUM_ELEMENT - 2) begin
                                    state <= EXTRACT_MIN;
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
                    end else if(left_child_idx < num_stored) begin
                        if(min_distances[left_child_idx] < min_distances[heapify_idx]) begin
                            min_distances[left_child_idx] <= min_distances[heapify_idx];
                            min_src[left_child_idx] <= min_src[heapify_idx];
                            min_dst[left_child_idx] <= min_dst[heapify_idx];

                            min_distances[heapify_idx] <= min_distances[left_child_idx];
                            min_src[heapify_idx] <= min_src[left_child_idx];
                            min_dst[heapify_idx] <= min_dst[left_child_idx];

                            heapify_idx <= left_child_idx;
                        end else begin
                            if (current_j == NUM_ELEMENT - 1) begin
                                if (current_i == NUM_ELEMENT - 2) begin
                                    state <= EXTRACT_MIN;
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
                    end else begin
                        if (current_j == NUM_ELEMENT - 1) begin
                            if (current_i == NUM_ELEMENT - 2) begin
                                state <= EXTRACT_MIN;
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
                EXTRACT_MIN: begin
                    if(num_stored > 0 && num_circuits > 1) begin
                        current_src <= min_src[0];
                        current_dst <= min_dst[0];
                        
                        min_distances[0] <= min_distances[num_stored - 1];
                        min_src[0] <= min_src[num_stored - 1];
                        min_dst[0] <= min_dst[num_stored - 1];
                        
                        num_stored <= num_stored - 1;
                        heapify_idx <= 0;
                        state <= CONNECT_BOX;
                    end else begin
                        state <= DONE;
                    end
                end
                
                CONNECT_BOX: begin               
                    src_circuit = circuit_id[current_src];
                    dst_circuit = circuit_id[current_dst];
                    
                    if (src_circuit != dst_circuit) begin
                        last_src <= current_src;
                        last_dst <= current_dst;
                        merge_idx <= 0;
                        num_circuits <= num_circuits - 1;
                        state <= MERGE_CIRCUITS;
                    end else begin
                        heapify_idx <= 0;
                        state <= HEAPIFY_DOWN;
                    end
                end
                MERGE_CIRCUITS: begin
                    if (merge_idx < NUM_ELEMENT) begin
                        if (circuit_id[merge_idx] == dst_circuit) begin
                            circuit_id[merge_idx] <= src_circuit;
                        end
                        merge_idx <= merge_idx + 1;
                    end else begin
                        if (num_circuits == 1) begin
                            state <= DONE;
                        end else begin
                            heapify_idx <= 0;
                            state <= HEAPIFY_DOWN;
                        end
                    end
                end
                DONE: begin
                    finished <= 1;
                    result <= x[last_src] * x[last_dst];
                end
            endcase
        end
    end
endmodule