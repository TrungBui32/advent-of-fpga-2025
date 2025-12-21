module gift_shop_part1(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 3'd0;
    localparam LOAD_RANGE = 3'd1;
    localparam NORMALIZE = 3'd2;
    localparam CALC_START_END = 3'd3;
    localparam GEN_NUMBERS = 3'd4;
    localparam SHIFTING = 3'd5;
    localparam CHECK = 3'd6;
    localparam DONE = 3'd7;
        
    localparam LENGTH = 34;
    localparam HEX_LENGTH = 40;

    reg [2:0] state;
    reg [HEX_LENGTH-1:0] table_1 [0:LENGTH-1]; 
    reg [HEX_LENGTH-1:0] table_2 [0:LENGTH-1]; 
    
    reg [HEX_LENGTH-1:0] range_start;
    reg [HEX_LENGTH-1:0] range_end;
    reg [5:0] table_idx;

    reg [31:0] start_len;
    reg [31:0] end_len;
    reg [31:0] half_len;
    reg [63:0] half_start;
    reg [63:0] second_half_start;
    reg [63:0] second_half_end;
    reg [63:0] half_end;
    reg [31:0] iter;

    reg [63:0] sum;
    reg [63:0] temp_sum;
    reg [63:0] temp_temp_sum;       // lol 

    initial begin
        $readmemh("table_1.mem", table_1);
        $readmemh("table_2.mem", table_2);
    end

    function [31:0] length;
        input [HEX_LENGTH-1:0] number;
        if(number[39:36] != 0) begin
            length = 32'd10;
        end else if(number[35:32] != 0) begin
            length = 32'd9;
        end else if(number[31:28] != 0) begin
            length = 32'd8;
        end else if(number[27:24] != 0) begin
            length = 32'd7;
        end else if(number[23:20] != 0) begin
            length = 32'd6;
        end else if(number[19:16] != 0) begin
            length = 32'd5;
        end else if(number[15:12] != 0) begin
            length = 32'd4;
        end else if(number[11:8] != 0) begin
            length = 32'd3;
        end else if(number[7:4] != 0) begin
            length = 32'd2;
        end else begin
            length = 32'd1;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            finished <= 1'b0;
            result <= 0;
            table_idx <= 0;
            sum <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= LOAD_RANGE;
                        table_idx <= 0;
                        sum <= 0;
                        temp_sum <= 0;
                        finished <= 1'b0;
                        iter <= 0;
                    end
                end
                LOAD_RANGE: begin
                    if(table_idx < LENGTH) begin
                        range_start <= table_1[table_idx];
                        range_end <= table_2[table_idx];
                        start_len <= length(table_1[table_idx]);
                        end_len <= length(table_2[table_idx]);
                        state <= NORMALIZE;
                    end else begin
                        state <= DONE;
                    end 
                end
                NORMALIZE: begin
                    // ignore the case start_end + 2 <= end_len as input does not contain such case
                    iter <= start_len;
                    if(start_len[0] == 1'b1 && end_len[0] == 1'b1 && start_len >= end_len) begin
                        state <= LOAD_RANGE;
                        if(table_idx < LENGTH - 1) begin
                            table_idx <= table_idx + 1;
                        end else begin
                            state <= DONE;
                        end
                    end else if(start_len[0] == 1'b1 || end_len[0] == 1'b1) begin
                        if(start_len[0] == 1'b1) begin
                            start_len <= start_len + 1;
                            range_start <= 40'h1 << (start_len << 2);
                            iter <= start_len + 1;
                        end
                        if(end_len[0] == 1'b1) begin 
                            // end_len <= end_len - 1;
                            range_end <= 40'h9999999999;
                            iter <= end_len - 1;
                        end
                        state <= CALC_START_END;
                    end else begin
                        state <= CALC_START_END;
                    end
                    
                    half_start <= 0;
                    half_end <= 0;
                    second_half_start <= 0;
                    second_half_end <= 0;
                end
                CALC_START_END: begin
                    if(iter > start_len >> 1) begin
                        half_start <= (half_start << 3) + (half_start << 1) + range_start[(iter << 2) - 1 -: 4];
                        half_end <= (half_end << 3) + (half_end << 1) + range_end[(iter << 2) - 1 -: 4];
                        second_half_start <= (second_half_start << 3) + (second_half_start << 1) + range_start[((iter - (start_len >> 1)) << 2) - 1 -: 4];
                        second_half_end <= (second_half_end << 3) + (second_half_end << 1) + range_end[((iter - (start_len >> 1)) << 2) - 1 -: 4];
                        iter <= iter - 1;
                    end else begin
                        if(second_half_start > half_start) begin
                            half_start <= half_start + 1;
                        end
                        if(second_half_end < half_end) begin
                            half_end <= half_end - 1;
                        end
                        half_len <= start_len >> 1;
                        state <= GEN_NUMBERS;
                        iter <= 0;
                    end
                end
                GEN_NUMBERS: begin
                    if(half_start <= half_end) begin
                        temp_sum <= temp_sum + half_start;
                        half_start <= half_start + 1;
                    end else begin
                        state <= SHIFTING;
                        temp_temp_sum <= temp_sum;
                    end
                end
                SHIFTING: begin
                    if(iter < half_len) begin
                        iter <= iter + 1;
                        temp_sum <= (temp_sum << 3) + (temp_sum << 1);
                    end else begin
                        state <= CHECK;
                    end
                end
                CHECK: begin
                    sum <= sum + temp_sum + temp_temp_sum;
                    temp_sum <= 0;
                    temp_temp_sum <= 0;
                    table_idx <= table_idx + 1;
                    state <= LOAD_RANGE;
                end
                DONE: begin
                    finished <= 1'b1;
                    result <= sum;
                end
            endcase
        end
    end
endmodule