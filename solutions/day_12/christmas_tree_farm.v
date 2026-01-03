module christmas_tree_farm(
    input clk, 
    input rst,
    input [31:0] data_in,   
    input valid_in,         
    output ready,       
    output reg finished,
    output reg [63:0] result
);
    localparam NUM_REGIONS = 1000;
    localparam CHUNK1 = 1'b0;
    localparam CHUNK2 = 1'b1;

    reg word_cnt;
    reg [63:0] buffer;
    reg input_ready;

    reg [31:0] count_valid;
    reg [31:0] count_result;

    reg stage1_valid;
    reg [7:0] stage1_width;
    reg [7:0] stage1_height;
    reg [7:0] stage1_p1;
    reg [7:0] stage1_p2;
    reg [7:0] stage1_p3;
    reg [7:0] stage1_p4;
    reg [7:0] stage1_p5;
    reg [7:0] stage1_p6;

    reg stage2_valid;
    reg [11:0] stage2_pp1;
    reg [11:0] stage2_pp2; 
    reg [15:0] stage2_sum_presents1;
    reg [15:0] stage2_sum_presents2;

    reg stage2a_valid;
    reg [31:0] stage2a_actual_area;
    reg [31:0] stage2a_sum_presents;
    reg [11:0] stage2a_pp1;

    reg stage3_valid;
    reg [31:0] stage3_required_area;
    reg [31:0] stage3_actual_area;

    reg stage4_valid;
    reg stage4_fits;

    assign ready = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            word_cnt <= CHUNK1;
            input_ready <= 0;
            buffer <= 64'b0;
        end else begin
            input_ready <= 0;
            if (valid_in) begin
                if (word_cnt == CHUNK1) begin
                    buffer[31:0] <= data_in;
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
        if(rst) stage1_valid <= 0;
        else begin
            stage1_valid <= input_ready;
            if(input_ready) begin
                stage1_p1 <= buffer[7:0];
                stage1_p2 <= buffer[15:8];
                stage1_width <= buffer[23:16];
                stage1_height <= buffer[31:24];
                stage1_p3 <= buffer[39:32];
                stage1_p4 <= buffer[47:40];
                stage1_p5 <= buffer[55:48];
                stage1_p6 <= buffer[63:56];
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            stage2_valid <= 0;
            stage2_pp1 <= 0;
            stage2_pp2 <= 0;
            stage2_sum_presents1 <= 0;
            stage2_sum_presents2 <= 0;
        end else begin
            stage2_valid <= stage1_valid;
            if(stage1_valid) begin
                stage2_pp1 <= stage1_width[3:0] * stage1_height;
                stage2_pp2 <= stage1_width[7:4] * stage1_height;
                stage2_sum_presents1 <= stage1_p1 + stage1_p2 + stage1_p3;
                stage2_sum_presents2 <= stage1_p4 + stage1_p5 + stage1_p6;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            stage2a_valid <= 0;
            stage2a_actual_area <= 0;
            stage2a_sum_presents <= 0;
        end else begin
            stage2a_valid <= stage2_valid;
            if(stage2_valid) begin
                stage2a_pp1 <= stage2_pp1;
                stage2a_actual_area <= stage2_pp2 << 4;
                stage2a_sum_presents <= stage2_sum_presents1 + stage2_sum_presents2;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            stage3_valid <= 0;
            stage3_required_area <= 0;
            stage3_actual_area <= 0;
        end else begin
            stage3_valid <= stage2a_valid; 
            if(stage2a_valid) begin        
                stage3_required_area <= (stage2a_sum_presents << 3) + stage2a_sum_presents;
                stage3_actual_area <= stage2a_actual_area + stage2a_pp1;  
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            stage4_valid <= 0;
            stage4_fits <= 0;
        end else begin
            stage4_valid <= stage3_valid;
            if(stage3_valid) begin
                stage4_fits <= (stage3_required_area <= stage3_actual_area);
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            count_valid <= 0;
            count_result <= 0;
            finished <= 0;
            result <= 0;
        end else if(stage4_valid) begin
            count_valid <= count_valid + 1;
            if(stage4_fits) count_result <= count_result + 1;
            
            if(count_valid == NUM_REGIONS - 1) begin
                finished <= 1;
                result <= count_result + (stage4_fits ? 1 : 0);
            end
        end
    end
endmodule