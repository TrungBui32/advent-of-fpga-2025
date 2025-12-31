module printing_department_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);

    localparam WIDTH = 140;
    localparam HEIGHT = 140;
    localparam NUM_CHUNKS = 10;
    localparam CHUNK_SIZE = 14;
    
    localparam IDLE = 2'd0;
    localparam PROCESS = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    reg [WIDTH-1:0] bank [0:HEIGHT-1];
    reg [14:0] accessible_count;
    reg [7:0] row_idx;

    reg [WIDTH-1:0] row_n_r, row_c_r, row_s_r;
    reg [7:0] stage_counts [0:NUM_CHUNKS-1];
    reg [7:0] final_row_count;
    reg [7:0] process_counter;
    
    integer i;

    initial begin
        $readmemb("input.mem", bank);
    end

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
                        
                        if (surrounded < 4) begin
                            chunk_count = chunk_count + 1;
                        end
                    end
                end
                stage_counts[g] <= chunk_count;
            end
        end
    endgenerate

    always @(posedge clk) begin
        final_row_count <= stage_counts[0] + stage_counts[1] + stage_counts[2] + stage_counts[3] + stage_counts[4] + stage_counts[5] + stage_counts[6] + stage_counts[7] + stage_counts[8] + stage_counts[9];
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            accessible_count <= 0;
            row_idx <= 0;
            process_counter <= 0;
        end else begin
            case(state)
                IDLE: begin
                    finished <= 0;
                    if(start) begin
                        accessible_count <= 0;
                        state <= PROCESS;
                        row_idx <= 0;
                        process_counter <= 0;
                    end
                end
                PROCESS: begin
                    if (process_counter >= 3) begin
                        accessible_count <= accessible_count + final_row_count;
                    end
                    
                    if (row_idx < HEIGHT) begin
                        row_idx <= row_idx + 1;
                    end
                    
                    process_counter <= process_counter + 1;
                    
                    if (process_counter >= HEIGHT + 2) begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= accessible_count;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule