module find_highest #(
    parameter WIDTH = 333
) (
    input clk,
    input rst,
    input start,
    input  [WIDTH - 1:0] num,
    output reg finished,
    output reg [39:0] result_1
);
    localparam IDLE = 3'd0;
    localparam FILL = 3'd1;
    localparam PRE_TRACE = 3'd2;
    localparam TRACE = 3'd3;
    localparam SUM = 3'd4;
    localparam DONE = 3'd5;

    reg [2:0] state;
    reg [3:0] digit_array [0:11];  
    reg [3:0] current_digit;
    reg [WIDTH-1:0] temp_num;
    reg shift;
    reg [3:0] count;
    reg [39:0] result;
    
    reg [3:0] i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            finished <= 1'b0;
            result <= 40'd0;
            i <= 4'd0;
            current_digit <= 4'd0;
            count <= 4'd0;
            shift <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if(start) begin
                        i <= 0;
                        state <= FILL;
                        temp_num <= num;
                        current_digit <= 4'd0;
                        count <= 4'd0;
                        shift <= 1'b0;
                        result <= 40'd0;
                    end
                end
                FILL: begin
                    if(i < 12) begin
                        digit_array[i] <= temp_num % 10;
                        temp_num <= temp_num / 10;
                        i <= i + 1;
                    end else begin 
                        state <= PRE_TRACE;
                        i <= 0;
                    end 
                end
                PRE_TRACE: begin
                    if(temp_num > 0) begin
                        current_digit <= temp_num % 10;
                        count <= 4'd11;
                        shift <= 1'b1;
                        state <= TRACE;
                        temp_num <= temp_num / 10;
                    end else begin
                        state <= SUM;
                    end
                end
                TRACE: begin
                    if(shift && count >= 0) begin
                        if(current_digit >= digit_array[count]) begin
                            digit_array[count] <= current_digit;
                            current_digit <= digit_array[count];
                        end else begin
                            shift <= 1'b0;
                        end
                    end else begin 
                        state <= PRE_TRACE;
                    end 
                    count <= count - 1;
                end
                SUM: begin
                    if(i < 12) begin
                        result <= result * 10 + digit_array[11 - i];
                        i <= i + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1'b1;
                    result_1 <= result;
                end
                default: state <= IDLE;
            endcase
        end
    end


endmodule