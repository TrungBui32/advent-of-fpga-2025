module day_2(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam CHECK_PATTERN = 3'b010;
    localparam NEXT_NUM = 3'b011;
    localparam DONE = 3'b100;
        
    localparam LENGTH = 34;

    reg [2:0] state;
    reg [63:0] table_1 [0:LENGTH-1]; 
    reg [63:0] table_2 [0:LENGTH-1]; 

    reg [63:0] accumulator;
    reg [5:0] range_idx;
    reg [63:0] search_val;
    reg [63:0] val_1;
    reg [63:0] val_2;
    
    reg [63:0] temp_num;
    reg [3:0] digits [0:19]; 
    reg [4:0] digit_count;
    reg [4:0] pattern_len;
    reg [4:0] repeat_count;
    reg [4:0] i, j;
    reg pattern_match;
    reg pattern_found;

    initial begin
        $readmemb("table_1.mem", table_1);
        $readmemb("table_2.mem", table_2);
    end

    function [4:0] count_digits;
        input [63:0] num;
        reg [63:0] temp;
        begin
            count_digits = 0;
            temp = num;
            while (temp > 0) begin
                count_digits = count_digits + 1;
                temp = temp / 10;
            end
        end
    endfunction

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            finished <= 1'b0;
            accumulator <= 64'b0;
            range_idx <= 6'b0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        accumulator <= 64'b0;
                        range_idx <= 6'b0;
                        state <= LOAD;
                    end
                end
                
                LOAD: begin
                    if(range_idx < LENGTH) begin
                        val_1 <= table_1[range_idx];
                        val_2 <= table_2[range_idx];
                        search_val <= table_1[range_idx];
                        range_idx <= range_idx + 1;
                        state <= CHECK_PATTERN;
                    end else begin
                        state <= DONE;
                    end
                end
                
                CHECK_PATTERN: begin
                    temp_num = search_val;
                    digit_count = count_digits(search_val);
                    
                    for(i = 0; i < digit_count; i = i + 1) begin
                        digits[i] = temp_num % 10;
                        temp_num = temp_num / 10;
                    end
                    
                    pattern_found = 1'b0;
                    
                    for(pattern_len = 1; pattern_len <= digit_count/2 && !pattern_found; pattern_len = pattern_len + 1) begin
                        if(digit_count % pattern_len == 0) begin
                            repeat_count = digit_count / pattern_len;
                            
                            if(repeat_count >= 2) begin
                                pattern_match = 1'b1;
                                
                                for(i = 0; i < pattern_len && pattern_match; i = i + 1) begin
                                    for(j = 1; j < repeat_count && pattern_match; j = j + 1) begin
                                        if(digits[i] != digits[i + j * pattern_len]) begin
                                            pattern_match = 1'b0;
                                        end
                                    end
                                end
                                
                                if(pattern_match) begin
                                    pattern_found = 1'b1;
                                end
                            end
                        end
                    end
                    
                    if(pattern_found) begin
                        accumulator <= accumulator + search_val;
                    end
                    
                    state <= NEXT_NUM;
                end
                
                NEXT_NUM: begin
                    if(search_val < val_2) begin
                        search_val <= search_val + 1;
                        state <= CHECK_PATTERN;
                    end else begin
                        state <= LOAD;
                    end
                end
                
                DONE: begin
                    result <= accumulator;
                    finished <= 1'b1;
                end
            endcase 
        end 
    end 
endmodule
