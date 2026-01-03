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
    reg [39:0] stage3_high_nibbles_start, stage3_high_nibbles_end;
    reg [39:0] stage3_low_nibbles_start,  stage3_low_nibbles_end;
    reg [31:0] stage3_half_len;

    reg stage4_valid;
    reg [31:0] stage4_half_len;
    reg [319:0] stage4_t_fstart, stage4_t_fend;
    reg [319:0] stage4_t_sstart, stage4_t_send;

    reg stage5_valid;
    reg [31:0] stage5_half_len;
    reg [159:0] stage5_L1_fstart, stage5_L1_fend;
    reg [159:0] stage5_L1_sstart, stage5_L1_send;

    reg stage6_valid;
    reg [31:0] stage6_half_len;
    reg [31:0] stage6_f_start, stage6_f_end;
    reg [31:0] stage6_s_start, stage6_s_end;
    
    reg stage7_valid;
    reg stage7_range_valid;
    reg [31:0] stage7_half_start;
    reg [31:0] stage7_half_end;
    reg [31:0] stage7_half_len;
    
    wire [31:0] stage2_half_len_wire;
    
    reg stage8_valid;
    reg stage8_range_valid;
    reg [31:0] stage8_mul_const;
    reg [31:0] stage8_sum_const;
    reg [31:0] stage8_addition;
    reg [31:0] stage8_half_len;
    
    wire [31:0] stage7_sub_const;
    
    reg stage10_valid, stage10_range_valid;
    reg [63:0] stage10_prod_mid;    
    reg [31:0] stage10_addition_q; 
    reg [31:0] stage10_half_len_q;

    reg stage9_valid, stage9_range_valid;
    reg [63:0] stage9_prod_partial;
    reg [31:0] stage9_addition_q;
    reg [31:0] stage9_half_len_q;

    reg [63:0] stage12_factor;
    reg  stage11_valid;
    reg stage11_range_valid;
    reg [63:0] stage11_immediate_sum;
    reg [31:0] stage11_half_len;

    reg stage12_valid, stage12_range_valid;
    reg [63:0] stage12_immediate_sum;

    reg stage13_valid, stage13_range_valid;
    reg [63:0] stage13_prod_partial;

    reg stage14_valid;
    reg stage14_range_valid;
    reg [63:0] stage14_result;
    
    reg [63:0] sum;
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

    function [319:0] extract_decimal_stage1; 
        input [39:0] bcd;
        input [31:0] num_digits;
        
        reg [31:0] t0, t1, t2, t3, t4, t5, t6, t7, t8, t9;
        
        begin
            t0 = (num_digits >= 1) ? bcd[3:0] : 32'd0;
            t1 = (num_digits >= 2) ? bcd[7:4] * 10 : 32'd0;
            t2 = (num_digits >= 3) ? bcd[11:8] * 100 : 32'd0;
            t3 = (num_digits >= 4) ? bcd[15:12] * 1000 : 32'd0;
            t4 = (num_digits >= 5) ? bcd[19:16] * 10000 : 32'd0;
            t5 = (num_digits >= 6) ? bcd[23:20] * 100000 : 32'd0;
            t6 = (num_digits >= 7) ? bcd[27:24] * 1000000 : 32'd0;
            t7 = (num_digits >= 8) ? bcd[31:28] * 10000000 : 32'd0;
            t8 = (num_digits >= 9) ? bcd[35:32] * 100000000 : 32'd0;
            t9 = (num_digits >= 10) ? bcd[39:36] * 1000000000 : 32'd0;

            extract_decimal_stage1 = {t9, t8, t7, t6, t5, t4, t3, t2, t1, t0};
        end
    endfunction

    function [159:0] extract_decimal_stage2; 
        input [319:0] stage1_output;  
        
        reg [31:0] t0, t1, t2, t3, t4, t5, t6, t7, t8, t9;
        reg [31:0] sum_L1_0, sum_L1_1, sum_L1_2, sum_L1_3, sum_L1_4;
        
        begin
            t0 = stage1_output[31:0];
            t1 = stage1_output[63:32];
            t2 = stage1_output[95:64];
            t3 = stage1_output[127:96];
            t4 = stage1_output[159:128];
            t5 = stage1_output[191:160];
            t6 = stage1_output[223:192];
            t7 = stage1_output[255:224];
            t8 = stage1_output[287:256];
            t9 = stage1_output[319:288];

            sum_L1_0 = t0 + t1;
            sum_L1_1 = t2 + t3;
            sum_L1_2 = t4 + t5;
            sum_L1_3 = t6 + t7;
            sum_L1_4 = t8 + t9;

            extract_decimal_stage2 = {sum_L1_4, sum_L1_3, sum_L1_2, sum_L1_1, sum_L1_0};
        end
    endfunction

    function [31:0] extract_decimal_stage3;
        input [159:0] stage2_output; 
        
        reg [31:0] sum_L1_0, sum_L1_1, sum_L1_2, sum_L1_3, sum_L1_4;
        reg [31:0] sum_L2_0, sum_L2_1, sum_L2_2;
        
        begin
            sum_L1_0 = stage2_output[31:0];
            sum_L1_1 = stage2_output[63:32];
            sum_L1_2 = stage2_output[95:64];
            sum_L1_3 = stage2_output[127:96];
            sum_L1_4 = stage2_output[159:128];

            sum_L2_0 = sum_L1_0 + sum_L1_1;
            sum_L2_1 = sum_L1_2 + sum_L1_3;
            sum_L2_2 = sum_L1_4;

            extract_decimal_stage3 = sum_L2_0 + sum_L2_1 + sum_L2_2;
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

    // stage 0
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
        end else begin
            if (range_ready) begin
                stage1_valid <= 1;
                stage1_range_start <= range_start_in;
                stage1_range_end <= range_end_in;
                stage1_start_len <= length(range_start_in);
                stage1_end_len <= length(range_end_in);
            end else begin
                stage1_valid <= 0;
            end
        end
    end
    
    // stage 1
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

    assign stage2_half_len_wire = stage2_start_len >> 1;

    // stage 2
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 0;
        end else begin
            stage3_valid <= stage2_valid;
            if (stage2_valid) begin
                stage3_half_len <= stage2_half_len_wire;
                stage3_high_nibbles_start <= stage2_range_start >> (stage2_half_len_wire << 2);
                stage3_high_nibbles_end <= stage2_range_end >> (stage2_half_len_wire << 2);
                stage3_low_nibbles_start <= stage2_range_start;
                stage3_low_nibbles_end <= stage2_range_end;
            end
        end
    end

    // stage 3
    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 0;
        end else begin
            stage4_valid <= stage3_valid;
            if (stage3_valid) begin
                stage4_half_len <= stage3_half_len;
                stage4_t_fstart <= extract_decimal_stage1(stage3_high_nibbles_start, stage3_half_len);
                stage4_t_fend   <= extract_decimal_stage1(stage3_high_nibbles_end, stage3_half_len);
                stage4_t_sstart <= extract_decimal_stage1(stage3_low_nibbles_start, stage3_half_len);
                stage4_t_send   <= extract_decimal_stage1(stage3_low_nibbles_end, stage3_half_len);
            end
        end
    end

    // stage 4
    always @(posedge clk) begin
        if (rst) begin
            stage5_valid <= 0;
        end else begin
            stage5_valid <= stage4_valid;
            if (stage4_valid) begin
                stage5_half_len <= stage4_half_len;
                stage5_L1_fstart <= extract_decimal_stage2(stage4_t_fstart);
                stage5_L1_fend   <= extract_decimal_stage2(stage4_t_fend);
                stage5_L1_sstart <= extract_decimal_stage2(stage4_t_sstart);
                stage5_L1_send   <= extract_decimal_stage2(stage4_t_send);
            end
        end
    end

    // stage 5
    always @(posedge clk) begin
        if (rst) begin
            stage6_valid <= 0;
        end else begin
            stage6_valid <= stage5_valid;
            if (stage5_valid) begin
                stage6_half_len <= stage5_half_len;
                stage6_f_start <= extract_decimal_stage3(stage5_L1_fstart);
                stage6_f_end   <= extract_decimal_stage3(stage5_L1_fend);
                stage6_s_start <= extract_decimal_stage3(stage5_L1_sstart);
                stage6_s_end   <= extract_decimal_stage3(stage5_L1_send);
            end
        end
    end
    
    // stage 6
    always @(posedge clk) begin
        if (rst) begin
            stage7_valid <= 0;
            stage7_range_valid <= 0;
        end else begin
            stage7_valid <= stage6_valid;
            stage7_range_valid <= stage6_valid;
            if (stage6_valid) begin
                stage7_half_len <= stage6_half_len;
                stage7_half_start <= (stage6_s_start > stage6_f_start) ? (stage6_f_start + 1) : stage6_f_start;
                stage7_half_end <= (stage6_s_end < stage6_f_end) ? (stage6_f_end - 1) : stage6_f_end;
            end
        end
    end 
    
    assign stage7_sub_const = stage7_half_end - stage7_half_start;
    
    // stage 7
    always @(posedge clk) begin
        if (rst) begin
            stage8_valid <= 0;
            stage8_range_valid <= 0;
        end else begin
            stage8_range_valid <= stage7_range_valid;
            
            if (stage7_valid && (stage7_half_end >= stage7_half_start)) begin
                stage8_sum_const <= stage7_half_start + stage7_half_end;
                stage8_half_len <= stage7_half_len;
                
                if (stage7_sub_const[0]) begin
                    stage8_addition <= 0;
                    stage8_mul_const <= (stage7_sub_const >> 1) + 1;
                end else begin
                    stage8_addition <= (stage7_half_start + stage7_half_end) >> 1;
                    stage8_mul_const <= stage7_sub_const >> 1;
                end
                
                stage8_valid <= 1;
            end else begin
                stage8_valid <= 0;
            end
        end
    end
    
    // stage 8
    always @(posedge clk) begin
        if (rst) begin
            stage9_valid <= 0;
            stage9_range_valid <= 0;
        end else begin
            stage9_valid <= stage8_valid;
            stage9_range_valid <= stage8_range_valid;
            if (stage8_valid) begin
                stage9_prod_partial <= stage8_mul_const * stage8_sum_const;
                stage9_addition_q <= stage8_addition;
                stage9_half_len_q <= stage8_half_len;
            end
        end
    end

    // stage 9
    always @(posedge clk) begin
        if (rst) begin
            stage10_valid <= 0;
            stage10_range_valid <= 0;
        end else begin
            stage10_valid <= stage9_valid;
            stage10_range_valid <= stage9_range_valid;
            if (stage9_valid) begin
                stage10_prod_mid <= stage9_prod_partial;
                stage10_addition_q <= stage9_addition_q;
                stage10_half_len_q <= stage9_half_len_q;
            end
        end
    end

    // stage 10
    always @(posedge clk) begin
        if (rst) begin
            stage11_valid <= 0;
            stage11_range_valid <= 0;
        end else begin
            stage11_valid <= stage10_valid;
            stage11_range_valid <= stage10_range_valid;
            if (stage10_valid) begin
                stage11_immediate_sum <= stage10_prod_mid + stage10_addition_q;
                stage11_half_len <= stage10_half_len_q;
            end
        end
    end

    // stage 11
    always @(posedge clk) begin
        if(rst) begin
            stage12_valid <= 0;
            stage12_range_valid <= 0;
        end else begin
            stage12_valid <= stage11_valid;
            stage12_range_valid <= stage11_range_valid;
            stage12_immediate_sum <= stage11_immediate_sum;
            stage12_factor <= power_ten(stage11_half_len) + 1;
        end
    end
    
    // stage 12
    always @(posedge clk) begin
        if (rst) begin
            stage13_valid <= 0;
            stage13_range_valid <= 0;
        end else begin
            stage13_valid <= stage12_valid;
            stage13_range_valid <= stage12_range_valid;
            if (stage12_valid) begin
                stage13_prod_partial <= stage12_immediate_sum * stage12_factor;
            end
        end
    end

    // stage 13
    always @(posedge clk) begin
        if (rst) begin
            stage14_valid <= 0;
            stage14_range_valid <= 0;
        end else begin
            stage14_valid <= stage13_valid;
            stage14_range_valid <= stage13_range_valid;
            if (stage13_valid) begin
                stage14_result <= stage13_prod_partial;
            end
        end
    end
    
    // stage 14
    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
            finished <= 0;
            result <= 0;
            ranges_completed <= 0;
        end else begin
            if (stage14_valid) begin
                sum <= sum + stage14_result;
            end
            
            if (stage14_range_valid) begin
                ranges_completed <= ranges_completed + 1;
            end
            
            if (ranges_completed == LENGTH - 1 && stage14_range_valid && !finished) begin
                finished <= 1;
                result <= sum + (stage14_valid ? stage14_result : 64'd0);
            end
        end
    end
endmodule