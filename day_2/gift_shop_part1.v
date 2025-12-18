module gift_shop_part1(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 3'b000;
    localparam LOAD = 3'b001;
    localparam EXTRACT_DIGITS = 3'b010;
    localparam CHECK_PATTERN = 3'b011;
    localparam NEXT_NUM = 3'b100;
    localparam DONE = 3'b101;
        
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
    reg [4:0] half_count;
    reg [4:0] check_idx;
    reg pattern_match;
    integer j;

    initial begin
        $readmemb("table_1.mem", table_1);
        $readmemb("table_2.mem", table_2);
        for(j = 0; j < 20; j = j + 1) begin
            digits[j] = 0;
        end
    end

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
                    if(search_val >= 64'd0 && search_val <= 64'd99) begin
                        if(search_val / 10 == search_val % 10) begin
                            accumulator <= accumulator + search_val;
                        end
                    end else if (search_val >= 64'd1000 && search_val <= 64'd9999) begin 
                        if(search_val / 100 == search_val % 100) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd100000 && search_val <= 64'd999999) begin 
                        if(search_val / 1000 == search_val % 1000) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd10000000 && search_val <= 64'd99999999) begin 
                        if(search_val / 10000 == search_val % 10000) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd1000000000 && search_val <= 64'd9999999999) begin 
                        if(search_val / 100000 == search_val % 100000) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd100000000000 && search_val <= 64'd999999999999) begin 
                        if(search_val / 1000000 == search_val % 1000000) begin 
                            accumulator <= accumulator + search_val;
                        end
                    end else if (search_val >= 64'd10000000000000 && search_val <= 64'd99999999999999) begin 
                        if(search_val / 10000000 == search_val % 10000000) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd1000000000000000 && search_val <= 64'd9999999999999999) begin 
                        if(search_val / 100000000 == search_val % 100000000) begin 
                            accumulator <= accumulator + search_val;
                        end 
                    end else if (search_val >= 64'd100000000000000000 && search_val <= 64'd999999999999999999) begin 
                        if(search_val / 1000000000 == search_val % 1000000000) begin 
                            accumulator <= accumulator + search_val;
                        end
                    end else if (search_val >= 64'd10000000000000000000 && search_val <= 64'd18446744073709551615) begin 
                        if(search_val / 64'd10000000000 == search_val % 64'd10000000000) begin 
                            accumulator <= accumulator + search_val;
                        end
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