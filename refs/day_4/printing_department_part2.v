module printing_department_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);

    localparam WIDTH = 140;
    localparam HEIGHT = 140;
    localparam NUM_CHUNKS = 5;
    localparam CHUNK_SIZE = 28;
    
    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam CHECK = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;

    (* ram_style = "block" *)  reg [WIDTH-1:0] bank [0:HEIGHT-1];

    reg [14:0] current_count;
    reg [14:0] accessible_count;
    
    reg [7:0] row_idx; 
    reg diff_found_flag;

    reg [WIDTH-1:0] buffer_next_row_state;
    reg [WIDTH-1:0] next_row_state;

    reg [7:0] r_sum; 

    initial begin
        $readmemb("input.mem", bank);
    end

    reg [WIDTH-1:0] row_n_r, row_c_r, row_s_r;
    reg [7:0] stage_counts [0:NUM_CHUNKS-1];
    reg [7:0] final_row_count;
    reg [7:0] process_counter;

    always @(posedge clk) begin
        if (state == PROCESS && row_idx < HEIGHT) begin
            if (row_idx == 0) 
                row_n_r <= {WIDTH{1'b0}};
            else 
                row_n_r <= bank[row_idx - 1];
            
            row_c_r <= bank[row_idx];
            
            if (row_idx == HEIGHT - 1) 
                row_s_r <= {WIDTH{1'b0}};
            else 
                row_s_r <= bank[row_idx + 1];
        end
    end

    genvar g;
    generate
        for (g = 0; g < NUM_CHUNKS; g = g + 1) begin : chunk_gen
            reg [3:0] chunk_count;
            reg n, s, w, e, nw, ne, sw, se;
            reg [3:0] surrounded;
            integer k;
            
            always @(posedge clk) begin
                chunk_count = 0;
                
                for (k = g * CHUNK_SIZE; k < (g + 1) * CHUNK_SIZE && k < WIDTH; k = k + 1) begin
                    if (row_c_r[k]) begin
                        n = row_n_r[k];
                        s = row_s_r[k];
                        w = (k == 0) ? 1'b0 : row_c_r[k-1];
                        e = (k == WIDTH-1) ? 1'b0 : row_c_r[k+1];
                        nw = (k == 0) ? 1'b0 : row_n_r[k-1];
                        ne = (k == WIDTH-1) ? 1'b0 : row_n_r[k+1];
                        sw = (k == 0) ? 1'b0 : row_s_r[k-1];
                        se = (k == WIDTH-1) ? 1'b0 : row_s_r[k+1];

                        surrounded = n + s + w + e + nw + ne + sw + se;
                        buffer_next_row_state[k] <= (surrounded < 4) ? 1'b0 : 1'b1;
                        if (surrounded < 4) begin
                            chunk_count = chunk_count + 1;
                        end
                    end else begin
                        buffer_next_row_state[k] <= row_c_r[k];
                    end
                end
                stage_counts[g] <= chunk_count;
            end
        end
    endgenerate

    always @(posedge clk) begin
        final_row_count <= stage_counts[0] + stage_counts[1] + stage_counts[2] + stage_counts[3] + stage_counts[4];
        next_row_state <= buffer_next_row_state;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            current_count <= 0;
            row_idx <= 0;
            diff_found_flag <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= PROCESS;
                        row_idx <= 0;
                        accessible_count <= 0;
                        diff_found_flag <= 0;
                        process_counter <= 0;
                    end
                end
                PROCESS: begin
                    if (process_counter >= 3) begin
                        accessible_count <= accessible_count + final_row_count;
                        bank[process_counter-3] <= next_row_state;
                        if (bank[process_counter-3] != next_row_state) begin
                            diff_found_flag <= 1;
                        end
                    end

                    if (process_counter >= HEIGHT + 2) begin
                        state <= CHECK;
                    end else begin
                        row_idx <= row_idx + 1;
                        process_counter <= process_counter + 1;
                    end
                end
                CHECK: begin
                    current_count <= current_count + accessible_count;
                    
                    if (!diff_found_flag) begin
                        state <= DONE;
                    end else begin
                        state <= PROCESS;
                        row_idx <= 0;
                        accessible_count <= 0;
                        diff_found_flag <= 0;
                        process_counter <= 0;
                    end
                end
                DONE: begin
                    result <= current_count;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule