module laboratories_part1(
    input clk,
    input rst,
    input [31:0] data_in,  
    input valid_in,
    output ready,
    output reg finished,
    output reg [31:0] result
);
    localparam HEIGHT = 142;
    localparam WIDTH = 141;
    localparam MIDDLE = 70;

    reg [2:0] chunk_cnt;
    reg [140:0] row_buffer;
    reg row_complete;

    reg stage1_valid;
    reg [WIDTH-1:0] stage1_row_data;
    
    reg stage2_valid;
    reg [WIDTH-1:0] stage2_splits;
    reg [WIDTH-1:0] stage2_next_beams;
    
    reg stage3_valid;
    reg [1:0] stage3_level1 [0:70];
    
    reg stage4_valid;
    reg [2:0] stage4_level2 [0:35];
    
    reg stage5_valid;
    reg [3:0] stage5_level3 [0:17];
    
    reg stage6_valid;
    reg [4:0] stage6_level4 [0:8];
    
    reg stage7_valid;
    reg [5:0] stage7_level5 [0:2];
    
    reg stage8_valid;
    reg [6:0] stage8_level6;
    
    reg [WIDTH-1:0] current_beams;
    
    reg [7:0] rows_processed;
    reg [31:0] sum;
    
    integer i, j;

    assign ready = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            chunk_cnt <= 3'd0;
            row_buffer <= 141'd0;
            row_complete <= 1'b0;
        end else begin
            row_complete <= 1'b0;
            if (valid_in) begin
                case(chunk_cnt)
                    3'd0: row_buffer[31:0] <= data_in;
                    3'd1: row_buffer[63:32] <= data_in;
                    3'd2: row_buffer[95:64] <= data_in;
                    3'd3: row_buffer[127:96] <= data_in;
                    3'd4: begin
                        row_buffer[140:128] <= data_in[12:0];
                        row_complete <= 1'b1;
                    end
                endcase
                chunk_cnt <= (chunk_cnt == 3'd4) ? 3'd0 : chunk_cnt + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            stage1_row_data <= {WIDTH{1'b0}};
        end else begin
            stage1_valid <= row_complete;
            if (row_complete) begin
                stage1_row_data <= row_buffer;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            stage2_splits <= {WIDTH{1'b0}};
            stage2_next_beams <= {WIDTH{1'b0}};
            current_beams <= {WIDTH{1'b0}};
            current_beams[MIDDLE] <= 1'b1;  
        end else begin
            stage2_valid <= stage1_valid;
            if (stage1_valid) begin
                stage2_splits <= current_beams & stage1_row_data;
                
                for (i = 0; i < WIDTH; i = i + 1) begin
                    if (i == 0) begin
                        stage2_next_beams[i] <= (current_beams[i+1] && stage1_row_data[i+1]) || (current_beams[i] && !stage1_row_data[i]);
                    end else if (i == WIDTH-1) begin
                        stage2_next_beams[i] <= (current_beams[i-1] && stage1_row_data[i-1]) || (current_beams[i] && !stage1_row_data[i]);
                    end else begin
                        stage2_next_beams[i] <= (current_beams[i-1] && stage1_row_data[i-1]) || (current_beams[i+1] && stage1_row_data[i+1]) || (current_beams[i] && !stage1_row_data[i]);
                    end
                end
                current_beams <= stage2_next_beams;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 1'b0;
        end else begin
            stage3_valid <= stage2_valid;
            if (stage2_valid) begin
                for (j = 0; j < 70; j = j + 1) begin
                    stage3_level1[j] <= stage2_splits[j*2] + stage2_splits[j*2+1];
                end
                stage3_level1[70] <= {1'b0, stage2_splits[140]};
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 1'b0;
        end else begin
            stage4_valid <= stage3_valid;
            if (stage3_valid) begin
                for (j = 0; j < 35; j = j + 1) begin
                    stage4_level2[j] <= stage3_level1[j*2] + stage3_level1[j*2+1];
                end
                stage4_level2[35] <= {1'b0, stage3_level1[70]};
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage5_valid <= 1'b0;
        end else begin
            stage5_valid <= stage4_valid;
            if (stage4_valid) begin
                for (j = 0; j < 18; j = j + 1) begin
                    stage5_level3[j] <= stage4_level2[j*2] + stage4_level2[j*2+1];
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage6_valid <= 1'b0;
        end else begin
            stage6_valid <= stage5_valid;
            if (stage5_valid) begin
                for (j = 0; j < 9; j = j + 1) begin
                    stage6_level4[j] <= stage5_level3[j*2] + stage5_level3[j*2+1];
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage7_valid <= 1'b0;
        end else begin
            stage7_valid <= stage6_valid;
            if (stage6_valid) begin
                stage7_level5[0] <= stage6_level4[0] + stage6_level4[1] + stage6_level4[2];
                stage7_level5[1] <= stage6_level4[3] + stage6_level4[4] + stage6_level4[5];
                stage7_level5[2] <= stage6_level4[6] + stage6_level4[7] + stage6_level4[8];
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            stage8_valid <= 1'b0;
            stage8_level6 <= 7'd0;
        end else begin
            stage8_valid <= stage7_valid;
            if (stage7_valid) begin
                stage8_level6 <= stage7_level5[0] + stage7_level5[1] + stage7_level5[2];
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            sum <= 32'd0;
            rows_processed <= 8'd0;
            finished <= 1'b0;
            result <= 32'd0;
        end else if (stage8_valid) begin
            sum <= sum + stage8_level6;
            rows_processed <= rows_processed + 1;
            
            if (rows_processed == HEIGHT - 1) begin
                finished <= 1'b1;
                result <= sum + stage8_level6;
            end
        end
    end
endmodule