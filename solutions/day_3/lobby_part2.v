module lobby_part2(
    input clk, 
    input rst,
    input [31:0] data_in,   
    input valid_in,         
    output ready,       
    output reg finished,
    output reg [63:0] result 
);
    localparam HEIGHT = 200;
    localparam NUM_DIGITS = 100;  
    localparam SELECT_DIGITS = 12; 
    
    reg [3:0] input_buffer_A [0:NUM_DIGITS + 7];
    reg [3:0] input_buffer_B [0:NUM_DIGITS + 7];
    reg current_write_buffer; 
    reg [7:0] stage1_write_ptr;
    reg stage1_buffer_ready; 
    
    reg stage2_active;
    reg stage2_read_buffer; 
    reg [7:0] stage2_read_ptr;
    reg [7:0] stage2_total_digits;
    reg [7:0] stage2_remaining;
    reg [47:0] stage2_current_number;
    reg [3:0] stage2_digits_selected;
    reg [3:0] stage2_current_digit;
    reg stage2_done;
    
    reg stage3_active;
    reg [47:0] stage3_convert_number;
    reg [3:0] stage3_convert_counter;
    reg [63:0] stage3_temp_shift;
    reg [3:0] stage3_digit;
    reg stage3_done;
    
    reg [63:0] sum;
    reg [31:0] banks_completed;

    assign ready = (stage1_write_ptr < NUM_DIGITS) && !stage1_buffer_ready;

    always @(posedge clk) begin
        if (rst) begin
            stage1_write_ptr <= 0;
            current_write_buffer <= 0;
            stage1_buffer_ready <= 0;
        end else begin
            if (valid_in && ready) begin
                if (current_write_buffer == 0) begin
                    input_buffer_A[stage1_write_ptr + 0] <= data_in[31:28];
                    input_buffer_A[stage1_write_ptr + 1] <= data_in[27:24];
                    input_buffer_A[stage1_write_ptr + 2] <= data_in[23:20];
                    input_buffer_A[stage1_write_ptr + 3] <= data_in[19:16];
                    input_buffer_A[stage1_write_ptr + 4] <= data_in[15:12];
                    input_buffer_A[stage1_write_ptr + 5] <= data_in[11:8];
                    input_buffer_A[stage1_write_ptr + 6] <= data_in[7:4];
                    input_buffer_A[stage1_write_ptr + 7] <= data_in[3:0];
                end else begin
                    input_buffer_B[stage1_write_ptr + 0] <= data_in[31:28];
                    input_buffer_B[stage1_write_ptr + 1] <= data_in[27:24];
                    input_buffer_B[stage1_write_ptr + 2] <= data_in[23:20];
                    input_buffer_B[stage1_write_ptr + 3] <= data_in[19:16];
                    input_buffer_B[stage1_write_ptr + 4] <= data_in[15:12];
                    input_buffer_B[stage1_write_ptr + 5] <= data_in[11:8];
                    input_buffer_B[stage1_write_ptr + 6] <= data_in[7:4];
                    input_buffer_B[stage1_write_ptr + 7] <= data_in[3:0];
                end
                stage1_write_ptr <= stage1_write_ptr + 8;
                
                if (stage1_write_ptr >= ((NUM_DIGITS + 7) / 8) * 8 - 8) begin
                    stage1_buffer_ready <= 1;
                end
            end
            
            if (stage1_buffer_ready && !stage2_active) begin
                stage1_buffer_ready <= 0;
                stage1_write_ptr <= 0;
                current_write_buffer <= ~current_write_buffer;
            end
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            stage2_active <= 0;
            stage2_read_ptr <= 0;
            stage2_total_digits <= 0;
            stage2_current_number <= 0;
            stage2_digits_selected <= 0;
            stage2_done <= 0;
            stage2_read_buffer <= 0;
        end else begin
            if (!stage2_active && stage1_buffer_ready) begin
                stage2_active <= 1;
                stage2_read_ptr <= 0;
                stage2_total_digits <= ((NUM_DIGITS + 7) / 8) * 8;
                stage2_current_number <= 0;
                stage2_digits_selected <= 0;
                stage2_done <= 0;
                stage2_read_buffer <= current_write_buffer;
            end else if (stage2_active && !stage2_done) begin
                if (stage2_read_ptr < stage2_total_digits) begin
                    if (stage2_read_buffer == 0) begin
                        stage2_current_digit = input_buffer_A[stage2_read_ptr];
                    end else begin
                        stage2_current_digit = input_buffer_B[stage2_read_ptr];
                    end
                    
                    stage2_remaining = stage2_total_digits - stage2_read_ptr;
                    
                    if (stage2_current_digit > stage2_current_number[47:44] && stage2_remaining >= 12) begin
                        stage2_current_number[47:44] <= stage2_current_digit;
                        stage2_current_number[43:0] <= 0;
                        stage2_digits_selected <= 1;
                    end else if (stage2_current_digit > stage2_current_number[43:40] && stage2_remaining >= 11) begin
                        stage2_current_number[43:40] <= stage2_current_digit;
                        stage2_current_number[39:0] <= 0;
                        stage2_digits_selected <= 2;
                    end else if (stage2_current_digit > stage2_current_number[39:36] && stage2_remaining >= 10) begin
                        stage2_current_number[39:36] <= stage2_current_digit;
                        stage2_current_number[35:0] <= 0;
                        stage2_digits_selected <= 3;
                    end else if (stage2_current_digit > stage2_current_number[35:32] && stage2_remaining >= 9) begin
                        stage2_current_number[35:32] <= stage2_current_digit;
                        stage2_current_number[31:0] <= 0;
                        stage2_digits_selected <= 4;
                    end else if (stage2_current_digit > stage2_current_number[31:28] && stage2_remaining >= 8) begin
                        stage2_current_number[31:28] <= stage2_current_digit;
                        stage2_current_number[27:0] <= 0;
                        stage2_digits_selected <= 5;
                    end else if (stage2_current_digit > stage2_current_number[27:24] && stage2_remaining >= 7) begin
                        stage2_current_number[27:24] <= stage2_current_digit;
                        stage2_current_number[23:0] <= 0;
                        stage2_digits_selected <= 6;
                    end else if (stage2_current_digit > stage2_current_number[23:20] && stage2_remaining >= 6) begin
                        stage2_current_number[23:20] <= stage2_current_digit;
                        stage2_current_number[19:0] <= 0;
                        stage2_digits_selected <= 7;
                    end else if (stage2_current_digit > stage2_current_number[19:16] && stage2_remaining >= 5) begin
                        stage2_current_number[19:16] <= stage2_current_digit;
                        stage2_current_number[15:0] <= 0;
                        stage2_digits_selected <= 8;
                    end else if (stage2_current_digit > stage2_current_number[15:12] && stage2_remaining >= 4) begin
                        stage2_current_number[15:12] <= stage2_current_digit;
                        stage2_current_number[11:0] <= 0;
                        stage2_digits_selected <= 9;
                    end else if (stage2_current_digit > stage2_current_number[11:8] && stage2_remaining >= 3) begin
                        stage2_current_number[11:8] <= stage2_current_digit;
                        stage2_current_number[7:0] <= 0;
                        stage2_digits_selected <= 10;
                    end else if (stage2_current_digit > stage2_current_number[7:4] && stage2_remaining >= 2) begin
                        stage2_current_number[7:4] <= stage2_current_digit;
                        stage2_current_number[3:0] <= 0;
                        stage2_digits_selected <= 11;
                    end else if (stage2_current_digit > stage2_current_number[3:0] && stage2_remaining >= 1) begin
                        stage2_current_number[3:0] <= stage2_current_digit;
                        stage2_digits_selected <= 12;
                    end
                    
                    stage2_read_ptr <= stage2_read_ptr + 1;
                end else begin
                    stage2_done <= 1;
                end
            end else if (stage2_done && !stage3_active) begin
                stage2_done <= 0;
                stage2_active <= 0;
            end
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            stage3_active <= 0;
            stage3_convert_counter <= 0;
            stage3_temp_shift <= 0;
            stage3_done <= 0;
        end else begin
            if (!stage3_active && stage2_done) begin
                stage3_active <= 1;
                stage3_convert_number <= stage2_current_number;
                stage3_convert_counter <= 0;
                stage3_temp_shift <= 0;
                stage3_done <= 0;
            end
            else if (stage3_active && !stage3_done) begin
                if (stage3_convert_counter < 12) begin
                    stage3_digit = stage3_convert_number[47 - (stage3_convert_counter*4) -: 4];
                    stage3_temp_shift <= (stage3_temp_shift * 10) + stage3_digit;
                    stage3_convert_counter <= stage3_convert_counter + 1;
                end else begin
                    stage3_done <= 1;
                end
            end
            else if (stage3_done) begin
                stage3_done <= 0;
                stage3_active <= 0;
            end
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            sum <= 0;
            banks_completed <= 0;
            finished <= 0;
            result <= 0;
        end else begin
            if (stage3_done) begin
                sum <= sum + stage3_temp_shift;
                banks_completed <= banks_completed + 1;
                if (banks_completed >= HEIGHT - 1) begin
                    result <= sum + stage3_temp_shift;
                    finished <= 1;
                end
            end
        end
    end 
endmodule