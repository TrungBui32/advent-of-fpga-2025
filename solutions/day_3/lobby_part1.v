module lobby_part1(
    input clk, 
    input rst,
    input [31:0] data_in,   
    input valid_in,         
    output ready,       
    output reg finished,
    output reg [14:0] result
);
    localparam HEIGHT = 200;
    localparam NUM_TRANSACTION = 13;

    reg [31:0] input_buffer;
    reg [3:0] input_counter;
    reg input_ready;
    reg [7:0] input_number;
    reg [7:0] current_number;
    reg [31:0] sum;
    reg [31:0] ranges_completed;
    
    reg stage1_valid;
    reg [7:0] stage1_number;
    reg [27:0] stage1_input;

    reg stage2_valid;
    reg [7:0] stage2_number;
    reg [23:0] stage2_input;

    reg stage3_valid;
    reg [7:0] stage3_number;
    reg [19:0] stage3_input;

    reg stage4_valid;
    reg [7:0] stage4_number;
    reg [15:0] stage4_input;

    reg stage5_valid;
    reg [7:0] stage5_number;
    reg [11:0] stage5_input;

    reg stage6_valid;
    reg [7:0] stage6_number;
    reg [7:0] stage6_input;

    reg stage7_valid;
    reg [7:0] stage7_number;
    reg [3:0] stage7_input;

    reg stage8_valid;
    reg [7:0] stage8_number;

    reg stage9_valid;
    reg [7:0] stage9_number;

    reg stage10_valid;
    reg [31:0] stage10_number;

    reg [7:0] word_cnt;
    reg range_ready;

    assign ready = 1'b1;

    // load
    always @(posedge clk) begin
        if (rst) begin
            word_cnt <= 0;
            range_ready <= 0;
            input_ready <= 0;
        end else begin
            input_ready <= 0;
            if (valid_in && ready) begin
                input_buffer <= data_in;
                input_ready <= 1;
            end
        end
    end

    // stage 0:
    always @(posedge clk) begin
        if(rst) begin
            stage1_valid <= 0;
        end else begin
            if(input_ready) begin
                stage1_number <= {input_buffer[31:28], 4'd0};
                stage1_input <= input_buffer[27:0];
                stage1_valid <= 1;
            end else begin
                stage1_valid <= 0;
            end
        end
    end 

    // stage 1 
    always @(posedge clk) begin
        if(rst) begin
            stage2_valid <= 0;
        end else begin
            if(stage1_valid) begin
                stage2_number <= stage1_number;
                if(stage1_input[27:24] > stage1_number[7:4]) begin
                    stage2_number <= stage1_input[27:20];
                end else if(stage1_input[27:24] > stage1_number[3:0]) begin
                    stage2_number <= {stage1_number[7:4], stage1_input[27:24]};
                end
                stage2_input <= stage1_input[23:0];
                stage2_valid <= 1;
            end else begin
                stage2_valid <= 0;
            end
        end
    end 

    // stage 2 
    always @(posedge clk) begin
        if(rst) begin
            stage3_valid <= 0;
        end else begin
            if(stage2_valid) begin
                stage3_number <= stage2_number; 
                if(stage2_input[23:20] > stage2_number[7:4]) begin
                    stage3_number <= stage2_input[23:16];
                end else if(stage2_input[23:20] > stage2_number[3:0]) begin
                    stage3_number <= {stage2_number[7:4], stage2_input[23:20]};
                end
                stage3_input <= stage2_input[19:0];
                stage3_valid <= 1;
            end else begin
                stage3_valid <= 0;
            end
        end
    end

    // stage 3
    always @(posedge clk) begin
        if(rst) begin
            stage4_valid <= 0;
        end else begin
            if(stage3_valid) begin
                stage4_number <= stage3_number;
                if(stage3_input[19:16] > stage3_number[7:4]) begin
                    stage4_number <= stage3_input[19:12];
                end else if(stage3_input[19:16] > stage3_number[3:0]) begin
                    stage4_number <= {stage3_number[7:4], stage3_input[19:16]};
                end
                stage4_input <= stage3_input[15:0];
                stage4_valid <= 1;
            end else begin
                stage4_valid <= 0;
            end
        end
    end 

    // stage 4
    always @(posedge clk) begin
        if(rst) begin
            stage5_valid <= 0;
        end else begin
            if(stage4_valid) begin
                stage5_number <= stage4_number; 
                if(stage4_input[15:12] > stage4_number[7:4]) begin
                    stage5_number <= stage4_input[15:8];
                end else if(stage4_input[15:12] > stage4_number[3:0]) begin
                    stage5_number <= {stage4_number[7:4], stage4_input[15:12]};
                end
                stage5_input <= stage4_input[11:0];
                stage5_valid <= 1;
            end else begin
                stage5_valid <= 0;
            end
        end
    end 

    // stage 5
    always @(posedge clk) begin
        if(rst) begin
            stage6_valid <= 0;
        end else begin
            if(stage5_valid) begin
                stage6_number <= stage5_number; 
                if(stage5_input[11:8] > stage5_number[7:4]) begin
                    stage6_number <= stage5_input[11:4];
                end else if(stage5_input[11:8] > stage5_number[3:0]) begin
                    stage6_number <= {stage5_number[7:4], stage5_input[11:8]};
                end
                stage6_input <= stage5_input[7:0];
                stage6_valid <= 1;
            end else begin
                stage6_valid <= 0;
            end
        end
    end 

    // stage 6
    always @(posedge clk) begin
        if(rst) begin
            stage7_valid <= 0;
        end else begin
            if(stage6_valid) begin
                stage7_number <= stage6_number; 
                if(stage6_input[7:4] > stage6_number[7:4]) begin
                    stage7_number <= stage6_input;
                end else if(stage6_input[7:4] > stage6_number[3:0]) begin
                    stage7_number <= {stage6_number[7:4], stage6_input[7:4]};
                end
                stage7_input <= stage6_input[3:0];
                stage7_valid <= 1;
            end else begin
                stage7_valid <= 0;
            end
        end
    end 

    // stage 7 
    always @(posedge clk) begin
        if(rst) begin
            stage8_valid <= 0;
        end else begin
            if(stage7_valid) begin
                stage8_number <= stage7_number; 
                if(stage7_input[3:0] > stage7_number[3:0]) begin
                    stage8_number <= {stage7_number[7:4], stage7_input[3:0]};
                end
                stage8_valid <= 1;
            end else begin
                stage8_valid <= 0;
            end
        end
    end

    // abcd => ab, ac, ad, bc, bd, cd
    // ab: a >= b && a >= c && b >= c && b >= d
    // ac: a >= b && a >= c && c >= b && c >= d
    // ad: a >= b && a >= c && d >= b && d >= c
    // bc: b >= a && b >= c && c >= d
    // bd: b >= a && b >= c && d >= c
    // cd: c >= a && c >= b 

    wire [3:0] a, b, c, d;
    assign a = current_number[7:4];
    assign b = current_number[3:0];
    assign c = stage8_number[7:4];
    assign d = stage8_number[3:0];

    // stage 8 
    always @(posedge clk) begin
        if(rst) begin
            stage9_valid <= 0;
            input_counter <= 0;
            current_number <= 0;
        end else begin
            stage9_valid <= 0;  
            if(stage8_valid) begin
                if(input_counter == 0) begin
                    current_number <= stage8_number;
                    input_counter <= 1;
                end else if(input_counter < NUM_TRANSACTION - 1) begin
                    input_counter <= input_counter + 1;
                    if(a >= b && a >= c && b >= c && b >= d) begin
                        current_number <= {a,b};
                    end else if(a >= b && a >= c && c >= b && c >= d) begin
                        current_number <= {a,c};
                    end else if(a >= b && a >= c && d >= b && d >= c) begin
                        current_number <= {a,d};
                    end else if(b >= a && b >= c && c >= d) begin
                        current_number <= {b,c};
                    end else if(b >= a && b >= c && d >= c) begin
                        current_number <= {b,d};
                    end else begin
                        current_number <= {c,d};
                    end 
                end else begin
                    input_counter <= 0;
                    if(a >= b && a >= c && b >= c && b >= d) begin
                        current_number <= {a,b};
                    end else if(a >= b && a >= c && c >= b && c >= d) begin
                        current_number <= {a,c};
                    end else if(a >= b && a >= c && d >= b && d >= c) begin
                        current_number <= {a,d};
                    end else if(b >= a && b >= c && c >= d) begin
                        current_number <= {b,c};
                    end else if(b >= a && b >= c && d >= c) begin
                        current_number <= {b,d};
                    end else begin
                        current_number <= {c,d};
                    end 
                    stage9_valid <= 1;  
                end
            end
        end
    end

    // stage 9
    always @(posedge clk) begin
        if(rst) begin
            stage10_valid <= 0;
        end else begin
            if(stage9_valid) begin
                stage10_number <= (current_number[7:4] << 3) + (current_number[7:4] << 1) + current_number[3:0];
                stage10_valid <= 1;
            end else begin
                stage10_valid <= 0;
            end
        end
    end 

    // stage 10
    always @(posedge clk) begin
        if(rst) begin
            sum <= 0;
            result <= 0;
            finished <= 0;
            ranges_completed <= 0;
        end else begin
            if (ranges_completed == HEIGHT - 1 && stage10_valid && !finished) begin
                finished <= 1;
                result <= sum + stage10_number;
            end else if(stage10_valid && !finished) begin
                sum <= sum + stage10_number;
                ranges_completed <= ranges_completed + 1;
            end
        end
    end 
endmodule