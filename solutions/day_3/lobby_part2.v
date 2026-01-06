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
    
    reg [3:0] input_buffer [0:NUM_DIGITS + 7];
    reg [7:0] write_ptr;
    reg [7:0] read_ptr;
    reg [7:0] total_digits;
    reg [7:0] remaining;
    reg [3:0] digit;
    
    localparam LOAD = 0;
    localparam PROCESS = 1;
    localparam CONVERT = 2;
    localparam SUM = 3;

    reg [2:0] state;
    
    reg [47:0] current_number;
    reg [3:0] digits_selected;
    
    reg [47:0] convert_number;
    reg [3:0] convert_counter;
    reg [63:0] temp_shift;
    reg convert_active;
    
    reg [63:0] sum;
    reg [31:0] banks_completed;

    reg [3:0] current_digit;
    
    assign ready = (state == LOAD) && (write_ptr[2:0] == 3'b000);
    
    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= 0;
            total_digits <= 0;
            state <= LOAD;
            read_ptr <= 0;
            current_number <= 0;
            digits_selected <= 0;
            banks_completed <= 0;
            sum <= 0;
            finished <= 0;
        end else begin
            case (state)
                LOAD: begin
                    if (valid_in && ready) begin
                        input_buffer[write_ptr + 0] <= data_in[31:28];
                        input_buffer[write_ptr + 1] <= data_in[27:24];
                        input_buffer[write_ptr + 2] <= data_in[23:20];
                        input_buffer[write_ptr + 3] <= data_in[19:16];
                        input_buffer[write_ptr + 4] <= data_in[15:12];
                        input_buffer[write_ptr + 5] <= data_in[11:8];
                        input_buffer[write_ptr + 6] <= data_in[7:4];
                        input_buffer[write_ptr + 7] <= data_in[3:0];
                        
                        write_ptr <= write_ptr + 8;
                        
                        if (write_ptr >= ((NUM_DIGITS + 7) / 8) * 8 - 8) begin
                            total_digits <= ((NUM_DIGITS + 7) / 8) * 8; 
                            read_ptr <= 0;
                            current_number <= 0;
                            digits_selected <= 0;
                            state <= PROCESS;
                        end
                    end
                end
                
                PROCESS: begin
                    if (read_ptr < total_digits) begin
                        current_digit = input_buffer[read_ptr];
                        
                        remaining = total_digits - read_ptr;
                        
                        if (current_digit > current_number[47:44] && remaining >= 12) begin
                            current_number[47:44] <= current_digit;
                            current_number[43:0] <= 0;
                            digits_selected <= 1;
                        end else if (current_digit > current_number[43:40] && remaining >= 11) begin
                            current_number[43:40] <= current_digit;
                            current_number[39:0] <= 0;
                            digits_selected <= 2;
                        end else if (current_digit > current_number[39:36] && remaining >= 10) begin
                            current_number[39:36] <= current_digit;
                            current_number[35:0] <= 0;
                            digits_selected <= 3;
                        end else if (current_digit > current_number[35:32] && remaining >= 9) begin
                            current_number[35:32] <= current_digit;
                            current_number[31:0] <= 0;
                            digits_selected <= 4;
                        end else if (current_digit > current_number[31:28] && remaining >= 8) begin
                            current_number[31:28] <= current_digit;
                            current_number[27:0] <= 0;
                            digits_selected <= 5;
                        end else if (current_digit > current_number[27:24] && remaining >= 7) begin
                            current_number[27:24] <= current_digit;
                            current_number[23:0] <= 0;
                            digits_selected <= 6;
                        end else if (current_digit > current_number[23:20] && remaining >= 6) begin
                            current_number[23:20] <= current_digit;
                            current_number[19:0] <= 0;
                            digits_selected <= 7;
                        end else if (current_digit > current_number[19:16] && remaining >= 5) begin
                            current_number[19:16] <= current_digit;
                            current_number[15:0] <= 0;
                            digits_selected <= 8;
                        end else if (current_digit > current_number[15:12] && remaining >= 4) begin
                            current_number[15:12] <= current_digit;
                            current_number[11:0] <= 0;
                            digits_selected <= 9;
                        end else if (current_digit > current_number[11:8] && remaining >= 3) begin
                            current_number[11:8] <= current_digit;
                            current_number[7:0] <= 0;
                            digits_selected <= 10;
                        end else if (current_digit > current_number[7:4] && remaining >= 2) begin
                            current_number[7:4] <= current_digit;
                            current_number[3:0] <= 0;
                            digits_selected <= 11;
                        end else if (current_digit > current_number[3:0] && remaining >= 1) begin
                            current_number[3:0] <= current_digit;
                            digits_selected <= 12;
                        end
                        
                        read_ptr <= read_ptr + 1;
                    end else begin
                        convert_number <= current_number;
                        convert_counter <= 0;
                        temp_shift <= 0;
                        convert_active <= 1;
                        state <= CONVERT;
                        write_ptr <= 0; 
                    end
                end
                CONVERT: begin
                    if (convert_active) begin
                        if (convert_counter < 12) begin
                            digit = convert_number[47 - (convert_counter*4) -: 4];
                            temp_shift <= (temp_shift * 10) + digit;
                            convert_counter <= convert_counter + 1;
                        end else begin
                            convert_active <= 0;
                            state <= SUM;
                        end
                    end
                end
                SUM: begin
                    sum <= sum + temp_shift;
                    banks_completed <= banks_completed + 1;

                    if (banks_completed >= HEIGHT - 1) begin
                        result <= sum + temp_shift;
                        finished <= 1;
                    end else begin
                        state <= LOAD;
                    end
                end
            endcase
        end
    end
endmodule