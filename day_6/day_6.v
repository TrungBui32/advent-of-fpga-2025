module day_6 (
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result  
);
    localparam DATA_WIDTH = 16;
    localparam NUM_ELEMENTS = 1000;  
    localparam RESULT_WIDTH = 64;    

    reg [DATA_WIDTH-1:0] line1 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line2 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line3 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line4 [0:NUM_ELEMENTS-1];
    reg op [0:NUM_ELEMENTS-1];

    reg [RESULT_WIDTH-1:0] result_array [0:NUM_ELEMENTS-1];
    
    reg [2:0] state;
    reg [15:0] idx;
    reg [RESULT_WIDTH-1:0] sum_accumulator;
    wire [DATA_WIDTH-1:0] temp_values [0:3];

    wire [3:0] line1_digit0, line1_digit1, line1_digit2, line1_digit3;
    wire [3:0] line2_digit0, line2_digit1, line2_digit2, line2_digit3;
    wire [3:0] line3_digit0, line3_digit1, line3_digit2, line3_digit3;
    wire [3:0] line4_digit0, line4_digit1, line4_digit2, line4_digit3;

    wire [15:0] bcd_values [3:0];

    wire [DATA_WIDTH-1:0] extracted_value0_1000, extracted_value1_1000, extracted_value2_1000, extracted_value3_1000;
    wire [DATA_WIDTH-1:0] extracted_value0_100, extracted_value1_100, extracted_value2_100, extracted_value3_100;
    wire [DATA_WIDTH-1:0] extracted_value0_10, extracted_value1_10, extracted_value2_10, extracted_value3_10;
    wire [DATA_WIDTH-1:0] extracted_value0_1, extracted_value1_1, extracted_value2_1, extracted_value3_1;
        
    localparam IDLE = 3'd0;
    localparam CALC = 3'd1;
    localparam DONE = 3'd2;

    function [15:0] divide_by_10;
        input [15:0] num;
        reg [31:0] temp;
        begin
            temp = num * 32'hCCCD;  
            divide_by_10 = temp >> 19;
        end
    endfunction

    initial begin
        $readmemh("line1.mem", line1);
        $readmemh("line2.mem", line2);
        $readmemh("line3.mem", line3);
        $readmemh("line4.mem", line4);
        $readmemh("op.mem", op);
    end

    assign line1_digit0 = line1[idx][3:0];
    assign line1_digit1 = line1[idx][7:4];
    assign line1_digit2 = line1[idx][11:8];
    assign line1_digit3 = line1[idx][15:12];

    assign line2_digit0 = line2[idx][3:0];
    assign line2_digit1 = line2[idx][7:4];
    assign line2_digit2 = line2[idx][11:8];
    assign line2_digit3 = line2[idx][15:12];

    assign line3_digit0 = line3[idx][3:0];
    assign line3_digit1 = line3[idx][7:4];
    assign line3_digit2 = line3[idx][11:8];
    assign line3_digit3 = line3[idx][15:12];

    assign line4_digit0 = line4[idx][3:0];
    assign line4_digit1 = line4[idx][7:4];
    assign line4_digit2 = line4[idx][11:8];
    assign line4_digit3 = line4[idx][15:12];

    assign extracted_value0_1000 = line1_digit0;
    assign extracted_value0_100 = (line1_digit0 << 3) + (line1_digit0 << 1) + line2_digit0; 
    assign extracted_value0_10 = (line1_digit0 << 6) + (line1_digit0 << 5) + (line1_digit0 << 2) + (line2_digit0 << 3) + (line2_digit0 << 1) + line3_digit0;
    assign extracted_value0_1 = (line1_digit0 << 9) + (line1_digit0 << 8) + (line1_digit0 << 7) + (line1_digit0 << 6) + (line1_digit0 << 5) + (line1_digit0 << 3) +
                                (line2_digit0 << 6) + (line2_digit0 << 5) + (line2_digit0 << 2) + (line3_digit0 << 3) + (line3_digit0 << 1) + line4_digit0;

    assign extracted_value1_1000 = line1_digit1;
    assign extracted_value1_100 = (line1_digit1 << 3) + (line1_digit1 << 1) + line2_digit1; 
    assign extracted_value1_10 = (line1_digit1 << 6) + (line1_digit1 << 5) + (line1_digit1 << 2) + (line2_digit1 << 3) + (line2_digit1 << 1) + line3_digit1;
    assign extracted_value1_1 = (line1_digit1 << 9) + (line1_digit1 << 8) + (line1_digit1 << 7) + (line1_digit1 << 6) + (line1_digit1 << 5) + (line1_digit1 << 3) +
                                (line2_digit1 << 6) + (line2_digit1 << 5) + (line2_digit1 << 2) + (line3_digit1 << 3) + (line3_digit1 << 1) + line4_digit1;
    
    assign extracted_value2_1000 = line1_digit2;
    assign extracted_value2_100 = (line1_digit2 << 3) + (line1_digit2 << 1) + line2_digit2; 
    assign extracted_value2_10 = (line1_digit2 << 6) + (line1_digit2 << 5) + (line1_digit2 << 2) + (line2_digit2 << 3) + (line2_digit2 << 1) + line3_digit2;
    assign extracted_value2_1 = (line1_digit2 << 9) + (line1_digit2 << 8) + (line1_digit2 << 7) + (line1_digit2 << 6) + (line1_digit2 << 5) + (line1_digit2 << 3) +
                                (line2_digit2 << 6) + (line2_digit2 << 5) + (line2_digit2 << 2) + (line3_digit2 << 3) + (line3_digit2 << 1) + line4_digit2;
    
    assign extracted_value3_1000 = line1_digit3;
    assign extracted_value3_100 = (line1_digit3 << 3) + (line1_digit3 << 1) + line2_digit3; 
    assign extracted_value3_10 = (line1_digit3 << 6) + (line1_digit3 << 5) + (line1_digit3 << 2) + (line2_digit3 << 3) + (line2_digit3 << 1) + line3_digit3;
    assign extracted_value3_1 = (line1_digit3 << 9) + (line1_digit3 << 8) + (line1_digit3 << 7) + (line1_digit3 << 6) + (line1_digit3 << 5) + (line1_digit3 << 3) +
                                (line2_digit3 << 6) + (line2_digit3 << 5) + (line2_digit3 << 2) + (line3_digit3 << 3) + (line3_digit3 << 1) + line4_digit3;


    assign bcd_values[0] = {line1_digit0, line2_digit0, line3_digit0, line4_digit0};
    assign bcd_values[1] = {line1_digit1, line2_digit1, line3_digit1, line4_digit1};
    assign bcd_values[2] = {line1_digit2, line2_digit2, line3_digit2, line4_digit2};
    assign bcd_values[3] = {line1_digit3, line2_digit3, line3_digit3, line4_digit3};
    
    assign temp_values[0] = (bcd_values[0][11:0] == 0) ? extracted_value0_1000 :
                            (bcd_values[0][7:0] == 0) ? extracted_value0_100 :
                            (bcd_values[0][3:0] == 0) ? extracted_value0_10 :
                            extracted_value0_1;

    assign temp_values[1] = (bcd_values[1][11:0] == 0) ? extracted_value1_1000 :
                            (bcd_values[1][7:0] == 0) ? extracted_value1_100 :
                            (bcd_values[1][3:0] == 0) ? extracted_value1_10 :
                            extracted_value1_1;

    assign temp_values[2] = (bcd_values[2][11:0] == 0) ? extracted_value2_1000 :
                            (bcd_values[2][7:0] == 0) ? extracted_value2_100 :
                            (bcd_values[2][3:0] == 0) ? extracted_value2_10 :
                            extracted_value2_1;

    assign temp_values[3] = (bcd_values[3][11:0] == 0) ? extracted_value3_1000 :
                            (bcd_values[3][7:0] == 0) ? extracted_value3_100 :
                            (bcd_values[3][3:0] == 0) ? extracted_value3_10 :
                            extracted_value3_1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            idx <= 0;
            sum_accumulator <= 0;
            finished <= 0;
            result <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CALC;
                        idx <= 0;
                        sum_accumulator <= 0;
                        finished <= 0;
                    end
                end
                CALC: begin
                    if (op[idx] == 1'b0) begin 
                        sum_accumulator <= sum_accumulator +    ((temp_values[0] != 0) ? temp_values[0] : 1) * 
                                                                ((temp_values[1] != 0) ? temp_values[1] : 1) * 
                                                                ((temp_values[2] != 0) ? temp_values[2] : 1) * 
                                                                ((temp_values[3] != 0) ? temp_values[3] : 1);
                    end else begin  
                        sum_accumulator <= sum_accumulator + temp_values[0] + temp_values[1] + temp_values[2] + temp_values[3];
                    end
                    if (idx == NUM_ELEMENTS - 1) begin
                        state <= DONE;
                        idx <= 0;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                DONE: begin
                    result <= sum_accumulator;
                    finished <= 1;
                end
            endcase
        end
    end

endmodule