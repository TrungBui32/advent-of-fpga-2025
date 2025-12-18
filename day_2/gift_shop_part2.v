module gift_shop_part2(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 3'd0;
    localparam LOAD = 3'd1;
    localparam CHECK_PATTERN = 3'd2;
    localparam NEXT_NUM = 3'd3;
    localparam DONE = 3'd4;
        
    localparam LENGTH = 34;
    localparam MAX_PATTERN_LEN = 10;

    reg [2:0] state;
    reg [63:0] table_1 [0:LENGTH-1]; 
    reg [63:0] table_2 [0:LENGTH-1]; 

    reg [63:0] accumulator;
    reg [5:0] range_idx;
    reg [63:0] search_val;
    reg [63:0] val_1;
    reg [63:0] val_2;
    
    reg [3:0] digits [0:19]; 
    reg [4:0] digit_count;
    
    reg [63:0] check_val;
    reg check_valid;
    
    wire [MAX_PATTERN_LEN-1:0] pattern_matches;
    wire any_pattern_found;

    initial begin
        $readmemb("table_1.mem", table_1);
        $readmemb("table_2.mem", table_2);
    end

    wire [3:0] current_digits [0:19];
    genvar k;
    generate
        for(k = 0; k < 20; k = k + 1) begin : digit_extract_comb
            assign current_digits[k] = (search_val / (10 ** k)) % 10;
        end
    endgenerate
    integer i;
    always @(posedge clk) begin
        if(state == CHECK_PATTERN && !check_valid) begin 
            for(i = 0; i < 20; i = i + 1) begin
                digits[i] <= current_digits[i];
            end
            check_val <= search_val;
            check_valid <= 1'b1;
        end else if(state != CHECK_PATTERN) begin
            check_valid <= 1'b0;
        end
    end

    generate
        for(k = 1; k <= MAX_PATTERN_LEN; k = k + 1) begin : pattern_check
            reg match;
            integer i, j;
            
            always @(*) begin
                match = 1'b0;
                if(check_valid && digit_count >= 2*k && digit_count % k == 0) begin
                    match = 1'b1;
                    for(i = 0; i < k && match; i = i + 1) begin
                        for(j = 1; j < digit_count/k && match; j = j + 1) begin
                            if(digits[i] != digits[i + j*k]) begin
                                match = 1'b0;
                            end
                        end
                    end
                end
            end
            
            assign pattern_matches[k-1] = match;
        end
    endgenerate
    
    assign any_pattern_found = |pattern_matches;

    always @(*) begin
        digit_count = 0;
        if(check_val >= 64'd10000000000000000000) digit_count = 20;
        else if(check_val >= 64'd1000000000000000000) digit_count = 19;
        else if(check_val >= 64'd100000000000000000) digit_count = 18;
        else if(check_val >= 64'd10000000000000000) digit_count = 17;
        else if(check_val >= 64'd1000000000000000) digit_count = 16;
        else if(check_val >= 64'd100000000000000) digit_count = 15;
        else if(check_val >= 64'd10000000000000) digit_count = 14;
        else if(check_val >= 64'd1000000000000) digit_count = 13;
        else if(check_val >= 64'd100000000000) digit_count = 12;
        else if(check_val >= 64'd10000000000) digit_count = 11;
        else if(check_val >= 64'd1000000000) digit_count = 10;
        else if(check_val >= 64'd100000000) digit_count = 9;
        else if(check_val >= 64'd10000000) digit_count = 8;
        else if(check_val >= 64'd1000000) digit_count = 7;
        else if(check_val >= 64'd100000) digit_count = 6;
        else if(check_val >= 64'd10000) digit_count = 5;
        else if(check_val >= 64'd1000) digit_count = 4;
        else if(check_val >= 64'd100) digit_count = 3;
        else if(check_val >= 64'd10) digit_count = 2;
        else if(check_val >= 64'd1) digit_count = 1;
    end

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            finished <= 1'b0;
            accumulator <= 64'b0;
            range_idx <= 6'b0;
            check_valid <= 1'b0;
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
                    if(check_valid && any_pattern_found) begin
                        accumulator <= accumulator + check_val;
                    end
                    
                    if(check_valid) begin
                        state <= NEXT_NUM;
                    end
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
