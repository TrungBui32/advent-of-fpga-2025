module trash_compactor_part1 (
    input clk,
    input rst,
    input [31:0] data_in,  
    input op,
    input valid_in,
    output ready,
    output reg finished,
    output reg [63:0] result  
);
    localparam DATA_WIDTH = 16;
    localparam RESULT_WIDTH = 64;
    localparam NUM_ELEMENTS = 1000;
    localparam CHUNK1 = 1'b0;
    localparam CHUNK2 = 1'b1;
    
    reg word_cnt;
    reg [63:0] buffer;
    reg input_ready;
    reg buffer_op;
    
    reg stage1_valid;
    reg [DATA_WIDTH-1:0] stage1_line1;
    reg [DATA_WIDTH-1:0] stage1_line2;
    reg [DATA_WIDTH-1:0] stage1_line3;
    reg [DATA_WIDTH-1:0] stage1_line4;
    reg stage1_op;
    
    reg stage2_valid;
    reg [RESULT_WIDTH/2-1:0] stage2_result1;
    reg [RESULT_WIDTH/2-1:0] stage2_result2;
    reg stage2_op;
    
    reg stage3_valid;
    reg [RESULT_WIDTH-1:0] stage3_result;
    reg [DATA_WIDTH-1:0] stage3_low1;
    reg [DATA_WIDTH-1:0] stage3_low2;
    reg [DATA_WIDTH-1:0] stage3_high1;
    reg [DATA_WIDTH-1:0] stage3_high2;
    reg stage3_op;
    
    reg stage4_valid;
    reg [RESULT_WIDTH-1:0] stage4_result;
    reg [RESULT_WIDTH/2-1:0] stage4_hh;
    reg [RESULT_WIDTH/2-1:0] stage4_hl;
    reg [RESULT_WIDTH/2-1:0] stage4_lh;
    reg [RESULT_WIDTH/2-1:0] stage4_ll;
    reg stage4_op;
    
    reg stage5_valid;
    reg [RESULT_WIDTH-1:0] stage5_result;
    reg [RESULT_WIDTH-1:0] stage5_hh;
    reg [RESULT_WIDTH-1:0] stage5_hl;
    reg [RESULT_WIDTH-1:0] stage5_lh;
    reg [RESULT_WIDTH-1:0] stage5_ll;
    reg stage5_op;

    reg stage6_valid;
    reg [RESULT_WIDTH-1:0] stage6_result;

    reg [RESULT_WIDTH-1:0] sum_accumulator;
    reg [31:0] count_valid;
    
    assign ready = 1'b1;
    
    function [15:0] bcd_to_binary;
        input [15:0] bcd;
        reg [3:0] d3, d2, d1, d0;
        begin
            d3 = bcd[15:12];
            d2 = bcd[11:8];
            d1 = bcd[7:4];
            d0 = bcd[3:0];
            if(d2 == 0 && d1 == 0 && d0 == 0) begin
                bcd_to_binary = d3;
            end else if(d1 == 0 && d0 == 0) begin
                bcd_to_binary = d3 * 10 + d2;
            end else if(d0 == 0) begin
                bcd_to_binary = d3 * 100 + d2 * 10 + d1;
            end else begin
                bcd_to_binary = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
            end
        end
    endfunction
    
    always @(posedge clk) begin
        if (rst) begin
            word_cnt <= CHUNK1;
            input_ready <= 0;
            buffer <= 64'b0;
            buffer_op <= 0;
        end else begin
            input_ready <= 0;
            if (valid_in) begin
                if (word_cnt == CHUNK1) begin
                    buffer[31:0] <= data_in;
                    buffer_op <= op;
                    word_cnt <= CHUNK2;
                end else begin
                    buffer[63:32] <= data_in;
                    word_cnt <= CHUNK1;
                    input_ready <= 1;
                end
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
        end else begin
            stage1_valid <= input_ready;
            if (input_ready) begin
                stage1_line1 <= bcd_to_binary(buffer[15:0]);
                stage1_line2 <= bcd_to_binary(buffer[31:16]);
                stage1_line3 <= bcd_to_binary(buffer[47:32]);
                stage1_line4 <= bcd_to_binary(buffer[63:48]);
                stage1_op <= buffer_op;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 0;
            stage2_result1 <= 0;
            stage2_result2 <= 0;
        end else begin
            stage2_valid <= stage1_valid;
            if (stage1_valid) begin
                if (stage1_op == 1'b0) begin
                    stage2_result1 <= stage1_line1 * stage1_line2;
                    stage2_result2 <= stage1_line3 * stage1_line4;
                end else begin
                    stage2_result1 <= stage1_line1 + stage1_line2;
                    stage2_result2 <= stage1_line3 + stage1_line4;
                end
                stage2_op <= stage1_op;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 0;
            stage3_result <= 0;
            stage3_low1 <= 0;
            stage3_low2 <= 0;
            stage3_high1 <= 0;
            stage3_high2 <= 0;
        end else begin
            stage3_valid <= stage2_valid;
            if (stage2_valid) begin
                if (stage2_op == 1'b0) begin
                    stage3_low1 <= stage2_result1[15:0];
                    stage3_high1 <= stage2_result1[31:16];
                    stage3_low2 <= stage2_result2[15:0];
                    stage3_high2 <= stage2_result2[31:16];
                end else begin
                    stage3_result <= stage2_result1 + stage2_result2;
                end
                stage3_op <= stage2_op;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 0;
            stage4_result <= 0;
            stage4_hh <= 0;
            stage4_hl <= 0;
            stage4_lh <= 0;
            stage4_ll <= 0;
        end else begin
            stage4_valid <= stage3_valid;
            if (stage3_valid) begin
                if (stage3_op == 1'b0) begin
                    stage4_ll <= stage3_low1 * stage3_low2;
                    stage4_hh <= stage3_high1 * stage3_high2;
                    stage4_hl <= stage3_high1 * stage3_low2;
                    stage4_lh <= stage3_low1 * stage3_high2;
                end else begin
                    stage4_result <= stage3_result;
                end
                stage4_op <= stage3_op;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage5_valid <= 0;
            stage5_hh <= 0;
            stage5_hl <= 0;
            stage5_lh <= 0;
            stage5_ll <= 0;
            stage5_result <= 0;
        end else begin
            stage5_valid <= stage4_valid;
            if (stage4_valid) begin
                if (stage4_op == 1'b0) begin
                    stage5_hh <= stage4_hh << 32;
                    stage5_hl <= stage4_hl << 16;
                    stage5_lh <= stage4_lh << 16;
                    stage5_ll <= stage4_ll;
                end else begin
                    stage5_result <= stage4_result;
                end
                stage5_op <= stage4_op;
            end
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            stage6_valid <= 0;
            stage6_result <= 0;
        end else begin
            stage6_valid <= stage5_valid;
            if (stage5_valid) begin
                if (stage5_op == 1'b0) begin
                    stage6_result <= stage5_hh + stage5_hl + stage5_lh + stage5_ll;
                end else begin
                    stage6_result <= stage5_result;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            sum_accumulator <= 0;
            count_valid <= 0;
            finished <= 0;
            result <= 0;
        end else if (stage6_valid) begin
            sum_accumulator <= sum_accumulator + stage6_result;
            count_valid <= count_valid + 1;
            
            if (count_valid == NUM_ELEMENTS - 1) begin
                finished <= 1;
                result <= sum_accumulator + stage6_result;
            end
        end
    end
endmodule