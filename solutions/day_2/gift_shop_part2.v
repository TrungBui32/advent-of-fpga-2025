module gift_shop_part2(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 4'd0;
    localparam LOAD_RANGE = 4'd1;
    localparam SPLIT_RANGE = 4'd2;
    localparam CAL_DEC = 4'd11;
    localparam CALC_DIVISOR = 4'd3;
    localparam CHOOSE_DIVISOR = 4'd4;
    localparam NORMALIZE = 4'd5;
    localparam CALC_START_END = 4'd6;
    localparam SUM = 4'd7;
    localparam MULTIPLY = 4'd8;
    localparam SHIFTING = 4'd9;
    localparam DONE = 4'd10;
        
    localparam LENGTH = 11;
    localparam HEX_LENGTH = 40;

    reg [3:0] state;
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

    reg [11:0] divisor_array;
    reg [1:0] num_divisor_iter;
    reg [3:0] current_divisor;

    reg [63:0] sum;
    reg [63:0] temp_sum;
    reg [63:0] temp_temp_sum;       // lol 
    reg [63:0] dec_start;
    reg [63:0] dec_end;
    
    reg [35:0] mul_const;
    reg [35:0] sum_const;
    reg [35:0] sub_const;
    reg [35:0] addition;

    reg [31:0] ref_current_divisor;
    reg [31:0] dup;

    reg note_start;
    reg note_end;
    reg range_splited;

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

    function [11:0] divisor;
        input [31:0] len;
        if(len == 32'd10) begin
            divisor = {4'd5, 4'd2, 4'd1};
        end else if(len == 32'd9) begin
            divisor = {4'd0, 4'd3, 4'd1};
        end else if(len == 32'd8) begin
            divisor = {4'd4, 4'd2, 4'd1};
        end else if(len == 32'd7) begin
            divisor = {8'd0, 4'd1};
        end else if(len == 32'd6) begin
            divisor = {4'd3, 4'd2, 4'd1};
        end else if(len == 32'd5) begin
            divisor = {8'd0, 4'd1};
        end else if(len == 32'd4) begin
            divisor = {4'd0, 4'd2, 4'd1};
        end else if(len == 32'd3) begin
            divisor = {8'd0, 4'd1};
        end else if(len == 32'd2) begin
            divisor = {8'd0, 4'd1};
        end else begin
            divisor = {12'd0};
        end 
    endfunction

    function [1:0] num_divisor;
        input [31:0] len;
        if(len == 32'd10) begin
            num_divisor = 2'd3;
        end else if(len == 32'd9) begin
            num_divisor = 2'd2;
        end else if(len == 32'd8) begin
            num_divisor = 2'd3;
        end else if(len == 32'd7) begin
            num_divisor = 2'd1;
        end else if(len == 32'd6) begin
            num_divisor = 2'd3;
        end else if(len == 32'd5) begin
            num_divisor = 2'd1;
        end else if(len == 32'd4) begin
            num_divisor = 2'd2;
        end else if(len == 32'd3) begin
            num_divisor = 2'd1;
        end else if(len == 32'd2) begin
            num_divisor = 2'd1;
        end else begin
            num_divisor = 2'd0;
        end 
    endfunction

    function normalize_start;
        input [31:0] len;
        input [HEX_LENGTH-1:0] start;
        if(len == 32'd10 && start[39:20] < start[19:0]) begin
            normalize_start = 1;
        end else if(len == 32'd9 && ((start[35:24] < start[23:12]) || (start[35:24] < start[11:0]))) begin
            normalize_start = 1;
        end else if(len == 32'd8 && (start[31:16] < start[15:0])) begin
            normalize_start = 1;
        end else if(len == 32'd7 && ((start[27:24] < start[23:20]) || (start[27:24] < start[19:16]) || (start[27:24] < start[15:12]) || (start[27:24] < start[11:8]) || (start[27:24] < start[7:4]) || (start[27:24] < start[3:0]))) begin
            normalize_start = 1;
        end else if(len == 32'd6 && (start[23:12] < start[11:0])) begin
            normalize_start = 1;
        end else if(len == 32'd5 && ((start[19:16] < start[15:12]) || (start[19:16] < start[11:8]) || (start[19:16] < start[7:4]) || (start[19:16] < start[3:0]))) begin
            normalize_start = 1;
        end else if(len == 32'd4 && (start[15:8] < start[7:0])) begin
            normalize_start = 1;
        end else if(len == 32'd3 && ((start[11:8] < start[7:4]) || (start[11:8] < start[3:0]))) begin
            normalize_start = 1;
        end else if(len == 32'd2 && ((start[7:4] < start[3:0]))) begin
            normalize_start = 1;
        end else begin
            normalize_start = 0;
        end 
    endfunction

    function normalize_end;
        input [31:0] len;
        input [HEX_LENGTH-1:0] start;
        if(len == 32'd10 && start[39:20] > start[19:0]) begin
            normalize_end = 1;
        end else if(len == 32'd9 && ((start[35:24] > start[23:12]) || (start[35:24] > start[11:0]))) begin
            normalize_end = 1;
        end else if(len == 32'd8 && (start[31:16] > start[15:0])) begin
            normalize_end = 1;
        end else if(len == 32'd7 && ((start[27:24] > start[23:20]) || (start[27:24] > start[19:16]) || (start[27:24] > start[15:12]) || (start[27:24] > start[11:8]) || (start[27:24] > start[7:4]) || (start[27:24] > start[3:0]))) begin
            normalize_end = 1;
        end else if(len == 32'd6 && (start[23:12] > start[11:0])) begin
            normalize_end = 1;
        end else if(len == 32'd5 && ((start[19:16] > start[15:12]) || (start[19:16] > start[11:8]) || (start[19:16] > start[7:4]) || (start[19:16] > start[3:0]))) begin
            normalize_end = 1;
        end else if(len == 32'd4 && (start[15:8] > start[7:0])) begin
            normalize_end = 1;
        end else if(len == 32'd3 && ((start[11:8] > start[7:4]) || (start[11:8] > start[3:0]))) begin
            normalize_end = 1;
        end else if(len == 32'd2 && ((start[7:4] > start[3:0]))) begin
            normalize_end = 1;
        end else begin
            normalize_end = 0;
        end 
    endfunction

    function [HEX_LENGTH-1:0] max_of_len;
        input [31:0] len;
        case(len)
            32'd1: max_of_len = 40'h9;
            32'd2: max_of_len = 40'h99;
            32'd3: max_of_len = 40'h999;
            32'd4: max_of_len = 40'h9999;
            32'd5: max_of_len = 40'h99999;
            32'd6: max_of_len = 40'h999999;
            32'd7: max_of_len = 40'h9999999;
            32'd8: max_of_len = 40'h99999999;
            32'd9: max_of_len = 40'h999999999;
            32'd10: max_of_len = 40'h9999999999;
        endcase
    endfunction

    function [HEX_LENGTH-1:0] min_of_len;
        input [31:0] len;
        case(len)
            32'd1: min_of_len = 40'h0;  
            32'd2: min_of_len = 40'h10;
            32'd3: min_of_len = 40'h100;
            32'd4: min_of_len = 40'h1000;
            32'd5: min_of_len = 40'h10000;
            32'd6: min_of_len = 40'h100000;
            32'd7: min_of_len = 40'h1000000;
            32'd8: min_of_len = 40'h10000000;
            32'd9: min_of_len = 40'h100000000;
            32'd10: min_of_len = 40'h1000000000;
        endcase
    endfunction

    integer i;
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
                        range_splited <= 1'b0;
                    end
                end
                LOAD_RANGE: begin
                    if(table_idx < LENGTH) begin
                        range_start <= table_1[table_idx];
                        range_end <= table_2[table_idx];
                        start_len <= length(table_1[table_idx]);
                        end_len <= length(table_2[table_idx]);
                        state <= SPLIT_RANGE;
                        dec_end <= 0;
                        dec_start <= 0;
                        $display(" ");
                        $display("LOAD_RANGE");
                        $display("range_start: %0h", table_1[table_idx]);
                        $display("range_end: %0h", table_2[table_idx]);
                        $display("start_len: %0d", length(table_1[table_idx]));
                        $display("end_len: %0d", length(table_2[table_idx]));
                    end else begin
                        state <= DONE;
                    end 
                end
                SPLIT_RANGE: begin
                    $display("SPLIT_RANGE");
                    if(start_len != end_len) begin
                        range_end <= max_of_len(start_len);
                        end_len <= start_len;  
                        table_1[table_idx] <= min_of_len(end_len);
                        range_splited <= 1'b1;
                        $display("Splitting: processing [%0h, %0h] (len=%0d)", range_start, range_end, start_len);
                        state <= CALC_DIVISOR;
                        iter <= start_len;
                    end else begin
                        state <= CALC_DIVISOR;
                        $display("Don't split");
                    end
                end
                CAL_DEC: begin 
                    $display("CALC_DEC");
                    if(iter > 0) begin
                        iter <= iter - 1;
                        dec_start <= (dec_start << 3) + (dec_start << 1) + range_start[(iter << 2) - 1 -: 4];
                        dec_end <= (dec_end << 3) + (dec_end << 1) + range_end[(iter << 2) - 1 -: 4];
                    end else begin  
                        state <= CALC_DIVISOR;
                    end
                end
                CALC_DIVISOR: begin
                    $display("CALC_DIVISOR");
                    if(start_len <= end_len) begin
                        divisor_array <= divisor(start_len);
                        num_divisor_iter <= num_divisor(start_len);
                        state <= CHOOSE_DIVISOR;
                        $display("divisor_array: %0h", divisor(start_len));
                        $display("num_divisor_iter: %0d", num_divisor(start_len));
                    end else begin
                        state <= LOAD_RANGE;
                        table_idx <= range_splited ? table_idx : table_idx + 1;
                        range_splited <= 1'b0;
                    end
                end
                CHOOSE_DIVISOR: begin
                    $display("CHOOSE_DIVISOR");
                    if(num_divisor_iter > 0) begin
                        current_divisor <= divisor_array[(num_divisor_iter << 2) - 1 -: 4];
                        dup <= start_len / divisor_array[(num_divisor_iter << 2) - 1 -: 4];
                        ref_current_divisor <= divisor_array[(num_divisor_iter << 2) - 1 -: 4] << 2;
                        num_divisor_iter <= num_divisor_iter - 1;
                        state <= NORMALIZE;
                        $display("current_divisor: %0d", divisor_array[(num_divisor_iter << 2) - 1 -: 4]);
                        $display("dup: %0d", start_len / divisor_array[(num_divisor_iter << 2) - 1 -: 4]);
                    end else begin
                        state <= LOAD_RANGE;
                        table_idx <= range_splited ? table_idx : table_idx + 1;
                        range_splited <= 1'b0;
                    end
                end
                NORMALIZE: begin
                    $display("NORMALIZE");
                    note_start <= normalize_start(start_len, range_start);
                    note_end <= normalize_end(end_len, range_end);
                    $display("note_start: %0d", normalize_start(start_len, range_start));
                    $display("note_end: %0d", normalize_end(end_len, range_end));
                    $display("CALC_START_END");
                    state <= CALC_START_END;
                    half_start <= 0;
                    half_end <= 0;
                    iter <= 0;    // 3 - 9
                end
                CALC_START_END: begin
                    if(iter < current_divisor) begin
                        half_start <= (half_start << 3) + (half_start << 1) + range_start[((start_len - iter) << 2) - 1 -: 4];
                        half_end <= (half_end << 3) + (half_end << 1) + range_end[((start_len - iter) << 2) - 1 -: 4];
                        // $display("half_start: %0d", (half_start << 3) + (half_start << 1) + range_start[((start_len - iter) << 2) - 1 -: 4]);
                        // $display("half_end: %0d", (half_end << 3) + (half_end << 1) + range_end[((start_len - iter) << 2) - 1 -: 4]);
                        iter <= iter + 1;
                    end else begin
                        if(note_start) begin
                           half_start <= half_start + 1; 
                           $display("half_start: %0d", half_start + 1);
                        end else begin
                            $display("half_start: %0d", half_start);
                        end
                        if(note_end) begin
                            half_end <= half_end - 1;
                            $display("half_end: %0d", half_end - 1);
                        end else begin
                            $display("half_end: %0d", half_end);
                        end
                        state <= SUM;
                        iter <= 0;
                    end
                end
                SUM: begin
                    $display("SUM");
                    if(half_end >= half_start) begin
                        sum_const <= half_start + half_end;
                        sub_const = half_end - half_start;
                        $display("sum_const: %0d", half_start + half_end);
                        if(sub_const[0]) begin
                            addition <= 0;
                            mul_const <= ((half_end - half_start) >> 1) + 1;
                            $display("mul_const: %0d", ((half_end - half_start) >> 1) + 1);
                            $display("addition: %0d", 0);
                        end else begin
                            addition <= (half_start + half_end) >> 1;
                            mul_const <= (half_end - half_start) >> 1;
                            $display("mul_const: %0d", (half_end - half_start) >> 1);
                            $display("addition: %0d", (half_start + half_end) >> 1);
                        end
                        state <= MULTIPLY;
                    end else begin 
                        state <= LOAD_RANGE;
                        table_idx <= range_splited ? table_idx : table_idx + 1;
                        range_splited <= 1'b0;
                    end 
                end
                MULTIPLY: begin
                    $display("MULTIPLY");
                    temp_sum <= mul_const*sum_const + addition;
                    temp_temp_sum <= mul_const*sum_const + addition;
                    $display("temp_sum: %0d", mul_const*sum_const + addition);
                    $display("SHIFTING");
                    state <= SHIFTING;
                    iter <= 0;
                    $display("temp_sum: %0d", mul_const*sum_const + addition);
                end
                SHIFTING: begin
                    if(iter < current_divisor) begin
                        iter <= iter + 1;
                        temp_sum <= (temp_sum << 3) + (temp_sum << 1);
                    end else begin
                        temp_sum <= temp_sum + temp_temp_sum;
                        $display("sum: %0d", sum);
                        $display("temp_sum: %0d", temp_sum);
                        $display("temp_temp_sum: %0d", temp_temp_sum);
                        if(dup - 1 > 1) begin 
                            dup <= dup - 1;
                            iter <= 0;
                        end else begin
                            temp_sum <= 0;
                            temp_temp_sum <= 0;
                            state <= CHOOSE_DIVISOR;
                            sum <= sum + temp_sum + temp_temp_sum;
                            $display("sum: %0d", temp_sum + temp_temp_sum);
                        end
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                    result <= sum;
                end
            endcase
        end
    end
endmodule