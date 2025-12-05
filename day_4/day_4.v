module day_4(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [14:0] result
);

    localparam WIDTH = 140;
    localparam HEIGHT = 140;
    
    localparam IDLE = 3'd0;
    localparam COUNT = 3'd1;
    localparam PROCESS = 3'd2;
    localparam CHECK = 3'd3;
    localparam DONE = 3'd4;

    reg [2:0] state;

    reg [WIDTH-1:0] bank [0:HEIGHT-1];

    reg [14:0] current_count;
    reg [14:0] start_count;
    reg [14:0] iteration_count;
    
    reg [7:0] row_idx; 
    reg diff_found_flag;

    integer j;
    integer x, y;

    reg [WIDTH-1:0] row_n, row_c, row_s; 
    reg [WIDTH-1:0] next_row_state;
    reg [7:0] row_pop_count; 

    integer k;
    reg [7:0] r_sum; 

    initial begin
        $readmemb("input.mem", bank);
    end

    reg n, s, w, e, nw, ne, sw, se;
    reg [3:0] surrounded;
    reg keep;

    always @(*) begin
        if (row_idx == 0) row_n = {WIDTH{1'b0}};
        else row_n = bank[row_idx - 1];

        row_c = bank[row_idx];

        if (row_idx == HEIGHT - 1) row_s = {WIDTH{1'b0}};
        else row_s = bank[row_idx + 1];

        row_pop_count = 0;
        
        for (j = 0; j < WIDTH; j = j + 1) begin
            n = row_n[j];
            s = row_s[j];
            w = (j == 0) ? 1'b0 : row_c[j-1];
            e = (j == WIDTH-1) ? 1'b0 : row_c[j+1];
            nw = (j == 0) ? 1'b0 : row_n[j-1];
            ne = (j == WIDTH-1) ? 1'b0 : row_n[j+1];
            sw = (j == 0) ? 1'b0 : row_s[j-1];
            se = (j == WIDTH-1) ? 1'b0 : row_s[j+1];

            surrounded = n + s + w + e + nw + ne + sw + se;
            keep = (surrounded < 4) ? 1'b0 : 1'b1;
            next_row_state[j] = row_c[j] & keep;
            if (next_row_state[j]) begin
                row_pop_count = row_pop_count + 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            start_count <= 0;
            current_count <= 0;
            row_idx <= 0;
            diff_found_flag <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        start_count <= 0;
                        state <= COUNT;
                        row_idx <= 0;
                        start_count <= 0;
                    end
                end
                COUNT: begin
                    r_sum = 0;
                    for(k = 0; k < WIDTH; k = k + 1) begin
                        if(bank[row_idx][k]) begin 
                            r_sum = r_sum + 1;
                        end
                    end
                    
                    start_count <= start_count + r_sum;

                    if(row_idx == HEIGHT-1) begin
                        state <= PROCESS;
                        row_idx <= 0;
                        iteration_count <= 0;
                        diff_found_flag <= 0;
                    end else begin
                        row_idx <= row_idx + 1;
                    end
                end
                PROCESS: begin
                    bank[row_idx] <= next_row_state;
                    iteration_count <= iteration_count + row_pop_count;
                    if (bank[row_idx] != next_row_state) begin
                        diff_found_flag <= 1;
                    end
                    if (row_idx == HEIGHT - 1) begin
                        state <= CHECK;
                    end else begin
                        row_idx <= row_idx + 1;
                    end
                end
                CHECK: begin
                    current_count <= iteration_count;
                    
                    if (!diff_found_flag) begin
                        state <= DONE;
                    end else begin
                        state <= PROCESS;
                        row_idx <= 0;
                        iteration_count <= 0;
                        diff_found_flag <= 0;
                    end
                end
                DONE: begin
                    result <= start_count - current_count;
                    finished <= 1;
                end
            endcase
        end
    end
endmodule