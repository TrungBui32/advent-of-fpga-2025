module gift_shop_part1(
    input clk, 
    input rst,
    input [31:0] data_in,   
    input valid_in,         
    output ready,       
    output reg finished,
    output reg [63:0] result
);
    localparam LENGTH = 34; 
    localparam HEX_LENGTH = 40;

    reg [1:0] word_cnt;
    reg [79:0] range_buffer;
    reg range_ready;
    
    wire [HEX_LENGTH-1:0] range_start_in;
    wire [HEX_LENGTH-1:0] range_end_in;
    
    assign range_start_in = range_buffer[79:40];
    assign range_end_in = range_buffer[39:0];
    assign ready = !rst;  
    
    reg stage1_valid;
    reg [HEX_LENGTH-1:0] stage1_range_start;
    reg [HEX_LENGTH-1:0] stage1_range_end;
    reg [31:0] stage1_start_len;
    reg [31:0] stage1_end_len;
    
    reg stage2_valid;
    reg [HEX_LENGTH-1:0] stage2_range_start;
    reg [HEX_LENGTH-1:0] stage2_range_end;
    reg [31:0] stage2_start_len;
    
    reg stage3_valid;
    reg stage3_range_valid;
    reg [35:0] stage3_half_start;
    reg [35:0] stage3_half_end;
    reg [31:0] stage3_half_len;
    
    wire [31:0] stage3_half_len_wire;
    wire [35:0] stage3_first_half_start;
    wire [35:0] stage3_first_half_end;
    wire [35:0] stage3_second_half_start;
    wire [35:0] stage3_second_half_end;
    wire [35:0] stage3_final_half_start;
    wire [35:0] stage3_final_half_end;
    
    reg stage4_valid;
    reg stage4_range_valid;
    reg [35:0] stage4_mul_const;
    reg [35:0] stage4_sum_const;
    reg [35:0] stage4_addition;
    reg [31:0] stage4_half_len;
    
    wire [35:0] stage4_sub_const;
    
    reg stage5_valid;
    reg stage5_range_valid;
    reg [63:0] stage5_result;
    
    wire [63:0] stage5_temp_sum;
    wire [63:0] stage5_shifted_sum;
    
    reg [63:0] sum;
    reg [31:0] ranges_received;
    reg [31:0] ranges_completed;
    
    function [31:0] length;
        input [HEX_LENGTH-1:0] number;
        begin
            if(number[39:36] != 0) length = 32'd10;
            else if(number[35:32] != 0) length = 32'd9;
            else if(number[31:28] != 0) length = 32'd8;
            else if(number[27:24] != 0) length = 32'd7;
            else if(number[23:20] != 0) length = 32'd6;
            else if(number[19:16] != 0) length = 32'd5;
            else if(number[15:12] != 0) length = 32'd4;
            else if(number[11:8] != 0) length = 32'd3;
            else if(number[7:4] != 0) length = 32'd2;
            else length = 32'd1;
        end
    endfunction
    
    function [35:0] extract_decimal;
        input [HEX_LENGTH-1:0] bcd;
        input [31:0] num_digits;
        begin
            extract_decimal = 
                ((num_digits >= 1) ? bcd[3:0] : 4'd0) +
                ((num_digits >= 2) ? bcd[7:4] * 10 : 36'd0) +
                ((num_digits >= 3) ? bcd[11:8] * 100 : 36'd0) +
                ((num_digits >= 4) ? bcd[15:12] * 1000 : 36'd0) +
                ((num_digits >= 5) ? bcd[19:16] * 10000 : 36'd0) +
                ((num_digits >= 6) ? bcd[23:20] * 100000 : 36'd0) +
                ((num_digits >= 7) ? bcd[27:24] * 1000000 : 36'd0) +
                ((num_digits >= 8) ? bcd[31:28] * 10000000 : 36'd0) +
                ((num_digits >= 9) ? bcd[35:32] * 100000000 : 36'd0) +
                ((num_digits >= 10) ? bcd[39:36] * 1000000000 : 36'd0);
        end
    endfunction
    
    function [63:0] power_ten;
        input [31:0] exp;
        begin
            case(exp)
                0: power_ten = 64'd1;
                1: power_ten = 64'd10;
                2: power_ten = 64'd100;
                3: power_ten = 64'd1000;
                4: power_ten = 64'd10000;
                5: power_ten = 64'd100000;
                default: power_ten = 64'd1;
            endcase
        end
    endfunction
    
    localparam CHUNK1 = 2'd0;
    localparam CHUNK2 = 2'd1;
    localparam CHUNK3 = 2'd2;
    
    always @(posedge clk) begin
        if (rst) begin
            word_cnt <= 0;
            range_ready <= 0;
        end else begin
            range_ready <= 0;
            if (valid_in && ready) begin
                case(word_cnt)
                    CHUNK1: begin
                        range_buffer[31:0] <= data_in;
                        word_cnt <= 2'd1;
                    end
                    CHUNK2: begin
                        range_buffer[63:32] <= data_in;
                        word_cnt <= 2'd2;
                    end
                    CHUNK3: begin
                        range_buffer[79:64] <= data_in[15:0];
                        range_ready <= 1;
                        word_cnt <= 2'd0;
                    end
                endcase
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
            ranges_received <= 0;
        end else begin
            if (range_ready) begin
                stage1_valid <= 1;
                stage1_range_start <= range_start_in;
                stage1_range_end <= range_end_in;
                stage1_start_len <= length(range_start_in);
                stage1_end_len <= length(range_end_in);
                ranges_received <= ranges_received + 1;
            end else begin
                stage1_valid <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 0;
        end else begin
            if (stage1_valid) begin
                if (stage1_start_len[0] == 1'b1 && stage1_end_len[0] == 1'b1 && 
                    stage1_start_len >= stage1_end_len) begin
                    stage2_range_start <= 40'h0000000002;
                    stage2_range_end <= 40'h0000000001;
                    stage2_start_len <= 32'd2;
                    stage2_valid <= 1;
                end else begin
                    if (stage1_start_len[0] == 1'b1) begin
                        stage2_range_start <= 40'h1 << (stage1_start_len << 2);
                        stage2_start_len <= stage1_start_len + 1;
                    end else begin
                        stage2_range_start <= stage1_range_start;
                        stage2_start_len <= stage1_start_len;
                    end
                    
                    if (stage1_end_len[0] == 1'b1) begin 
                        stage2_range_end <= 40'h9999999999;
                    end else begin
                        stage2_range_end <= stage1_range_end;
                    end
                    
                    stage2_valid <= 1;
                end
            end else begin
                stage2_valid <= 0;
            end
        end
    end
    
    assign stage3_half_len_wire = stage2_start_len >> 1;
    
    assign stage3_first_half_start = extract_decimal(
        stage2_range_start >> (stage3_half_len_wire << 2), 
        stage3_half_len_wire
    );
    
    assign stage3_first_half_end = extract_decimal(
        stage2_range_end >> (stage3_half_len_wire << 2), 
        stage3_half_len_wire
    );
    
    assign stage3_second_half_start = extract_decimal(
        stage2_range_start, 
        stage3_half_len_wire
    );
    
    assign stage3_second_half_end = extract_decimal(
        stage2_range_end, 
        stage3_half_len_wire
    );
    
    assign stage3_final_half_start = (stage3_second_half_start > stage3_first_half_start) ? 
                                     (stage3_first_half_start + 1) : stage3_first_half_start;
    
    assign stage3_final_half_end = (stage3_second_half_end < stage3_first_half_end) ? 
                                   (stage3_first_half_end - 1) : stage3_first_half_end;
    
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 0;
            stage3_range_valid <= 0;
        end else begin
            if (stage2_valid) begin
                stage3_half_start <= stage3_final_half_start;
                stage3_half_end <= stage3_final_half_end;
                stage3_half_len <= stage3_half_len_wire;
                stage3_valid <= 1;
                stage3_range_valid <= 1;
            end else begin
                stage3_valid <= 0;
                stage3_range_valid <= 0;
            end
        end
    end
    
    assign stage4_sub_const = stage3_half_end - stage3_half_start;
    
    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 0;
            stage4_range_valid <= 0;
        end else begin
            stage4_range_valid <= stage3_range_valid;
            
            if (stage3_valid && (stage3_half_end >= stage3_half_start)) begin
                stage4_sum_const <= stage3_half_start + stage3_half_end;
                stage4_half_len <= stage3_half_len;
                
                if (stage4_sub_const[0]) begin
                    stage4_addition <= 0;
                    stage4_mul_const <= (stage4_sub_const >> 1) + 1;
                end else begin
                    stage4_addition <= (stage3_half_start + stage3_half_end) >> 1;
                    stage4_mul_const <= stage4_sub_const >> 1;
                end
                
                stage4_valid <= 1;
            end else begin
                stage4_valid <= 0;
            end
        end
    end
    
    assign stage5_temp_sum = stage4_mul_const * stage4_sum_const + stage4_addition;
    assign stage5_shifted_sum = stage5_temp_sum * power_ten(stage4_half_len);
    
    always @(posedge clk) begin
        if (rst) begin
            stage5_valid <= 0;
            stage5_range_valid <= 0;
        end else begin
            stage5_range_valid <= stage4_range_valid;
            
            if (stage4_valid) begin
                stage5_result <= stage5_shifted_sum + stage5_temp_sum;
                stage5_valid <= 1;
            end else begin
                stage5_valid <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
            finished <= 0;
            result <= 0;
            ranges_completed <= 0;
        end else begin
            if (stage5_valid) begin
                sum <= sum + stage5_result;
            end
            
            if (stage5_range_valid) begin
                ranges_completed <= ranges_completed + 1;
            end
            
            if (ranges_completed == LENGTH - 1 && stage5_range_valid && !finished) begin
                finished <= 1;
                if (stage5_valid) begin
                    result <= sum + stage5_result;  
                end else begin
                    result <= sum;
                end
            end
        end
    end
    
endmodule