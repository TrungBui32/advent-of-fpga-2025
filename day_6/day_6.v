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
    reg [15:0] idx_plus_1;
    reg [RESULT_WIDTH-1:0] sum_accumulator;

    wire [DATA_WIDTH-1:0] temp_values_1 [0:3];
    wire [DATA_WIDTH-1:0] temp_values_2 [0:3];

    reg [DATA_WIDTH-1:0] temp_storage_1 [0:3];
    reg [DATA_WIDTH-1:0] temp_storage_2 [0:3];

    reg [63:0] saved_temp [0:3];

    wire [3:0] line1_digit0_1, line1_digit1_1, line1_digit2_1, line1_digit3_1;
    wire [3:0] line2_digit0_1, line2_digit1_1, line2_digit2_1, line2_digit3_1;
    wire [3:0] line3_digit0_1, line3_digit1_1, line3_digit2_1, line3_digit3_1;
    wire [3:0] line4_digit0_1, line4_digit1_1, line4_digit2_1, line4_digit3_1;

    wire [3:0] line1_digit0_2, line1_digit1_2, line1_digit2_2, line1_digit3_2;
    wire [3:0] line2_digit0_2, line2_digit1_2, line2_digit2_2, line2_digit3_2;
    wire [3:0] line3_digit0_2, line3_digit1_2, line3_digit2_2, line3_digit3_2;
    wire [3:0] line4_digit0_2, line4_digit1_2, line4_digit2_2, line4_digit3_2;

    wire [15:0] bcd_values_1 [3:0];
    wire [15:0] bcd_values_2 [3:0];

    wire [DATA_WIDTH-1:0] extracted_value0_3_1, extracted_value1_3_1, extracted_value2_3_1, extracted_value3_3_1;
    wire [DATA_WIDTH-1:0] extracted_value0_2_1, extracted_value1_2_1, extracted_value2_2_1, extracted_value3_2_1;
    wire [DATA_WIDTH-1:0] extracted_value0_1_1, extracted_value1_1_1, extracted_value2_1_1, extracted_value3_1_1;
    wire [DATA_WIDTH-1:0] extracted_value0_0_1, extracted_value1_0_1, extracted_value2_0_1, extracted_value3_0_1;

    wire [DATA_WIDTH-1:0] extracted_value0_3_2, extracted_value1_3_2, extracted_value2_3_2, extracted_value3_3_2;
    wire [DATA_WIDTH-1:0] extracted_value0_2_2, extracted_value1_2_2, extracted_value2_2_2, extracted_value3_2_2;
    wire [DATA_WIDTH-1:0] extracted_value0_1_2, extracted_value1_1_2, extracted_value2_1_2, extracted_value3_1_2;
    wire [DATA_WIDTH-1:0] extracted_value0_0_2, extracted_value1_0_2, extracted_value2_0_2, extracted_value3_0_2;
        
    localparam IDLE = 3'd0;
    localparam EXTRACT = 3'd1;
    localparam CALC_1 = 3'd2;
    localparam CALC_2 = 3'd3;
    localparam CALC_3 = 3'd4;
    localparam DONE = 3'd5;

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

    assign line1_digit0_1 = line1[idx][3:0];
    assign line1_digit1_1 = line1[idx][7:4];
    assign line1_digit2_1 = line1[idx][11:8];
    assign line1_digit3_1 = line1[idx][15:12];

    assign line2_digit0_1 = line2[idx][3:0];
    assign line2_digit1_1 = line2[idx][7:4];
    assign line2_digit2_1 = line2[idx][11:8];
    assign line2_digit3_1 = line2[idx][15:12];

    assign line3_digit0_1 = line3[idx][3:0];
    assign line3_digit1_1 = line3[idx][7:4];
    assign line3_digit2_1 = line3[idx][11:8];
    assign line3_digit3_1 = line3[idx][15:12];

    assign line4_digit0_1 = line4[idx][3:0];
    assign line4_digit1_1 = line4[idx][7:4];
    assign line4_digit2_1 = line4[idx][11:8];
    assign line4_digit3_1 = line4[idx][15:12];


    assign line1_digit0_2 = line1[idx_plus_1][3:0];
    assign line1_digit1_2 = line1[idx_plus_1][7:4];
    assign line1_digit2_2 = line1[idx_plus_1][11:8];
    assign line1_digit3_2 = line1[idx_plus_1][15:12];

    assign line2_digit0_2 = line2[idx_plus_1][3:0];
    assign line2_digit1_2 = line2[idx_plus_1][7:4];
    assign line2_digit2_2 = line2[idx_plus_1][11:8];
    assign line2_digit3_2 = line2[idx_plus_1][15:12];

    assign line3_digit0_2 = line3[idx_plus_1][3:0];
    assign line3_digit1_2 = line3[idx_plus_1][7:4];
    assign line3_digit2_2 = line3[idx_plus_1][11:8];
    assign line3_digit3_2 = line3[idx_plus_1][15:12];

    assign line4_digit0_2 = line4[idx_plus_1][3:0];
    assign line4_digit1_2 = line4[idx_plus_1][7:4];
    assign line4_digit2_2 = line4[idx_plus_1][11:8];
    assign line4_digit3_2 = line4[idx_plus_1][15:12];
    

    assign extracted_value0_3_1 = line1_digit0_1;
    assign extracted_value0_2_1 = (line1_digit0_1 << 3) + (line1_digit0_1 << 1) + line2_digit0_1; 
    assign extracted_value0_1_1 = (line1_digit0_1 << 6) + (line1_digit0_1 << 5) + (line1_digit0_1 << 2) + (line2_digit0_1 << 3) + (line2_digit0_1 << 1) + line3_digit0_1;
    assign extracted_value0_0_1 = (line1_digit0_1 << 9) + (line1_digit0_1 << 8) + (line1_digit0_1 << 7) + (line1_digit0_1 << 6) + (line1_digit0_1 << 5) + (line1_digit0_1 << 3) +
                                (line2_digit0_1 << 6) + (line2_digit0_1 << 5) + (line2_digit0_1 << 2) + (line3_digit0_1 << 3) + (line3_digit0_1 << 1) + line4_digit0_1;

    assign extracted_value1_3_1 = line1_digit1_1;
    assign extracted_value1_2_1 = (line1_digit1_1 << 3) + (line1_digit1_1 << 1) + line2_digit1_1; 
    assign extracted_value1_1_1 = (line1_digit1_1 << 6) + (line1_digit1_1 << 5) + (line1_digit1_1 << 2) + (line2_digit1_1 << 3) + (line2_digit1_1 << 1) + line3_digit1_1;
    assign extracted_value1_0_1 = (line1_digit1_1 << 9) + (line1_digit1_1 << 8) + (line1_digit1_1 << 7) + (line1_digit1_1 << 6) + (line1_digit1_1 << 5) + (line1_digit1_1 << 3) +
                                (line2_digit1_1 << 6) + (line2_digit1_1 << 5) + (line2_digit1_1 << 2) + (line3_digit1_1 << 3) + (line3_digit1_1 << 1) + line4_digit1_1;
    
    assign extracted_value2_3_1 = line1_digit2_1;
    assign extracted_value2_2_1 = (line1_digit2_1 << 3) + (line1_digit2_1 << 1) + line2_digit2_1; 
    assign extracted_value2_1_1 = (line1_digit2_1 << 6) + (line1_digit2_1 << 5) + (line1_digit2_1 << 2) + (line2_digit2_1 << 3) + (line2_digit2_1 << 1) + line3_digit2_1;
    assign extracted_value2_0_1 = (line1_digit2_1 << 9) + (line1_digit2_1 << 8) + (line1_digit2_1 << 7) + (line1_digit2_1 << 6) + (line1_digit2_1 << 5) + (line1_digit2_1 << 3) +
                                (line2_digit2_1 << 6) + (line2_digit2_1 << 5) + (line2_digit2_1 << 2) + (line3_digit2_1 << 3) + (line3_digit2_1 << 1) + line4_digit2_1;
    
    assign extracted_value3_3_1 = line1_digit3_1;
    assign extracted_value3_2_1 = (line1_digit3_1 << 3) + (line1_digit3_1 << 1) + line2_digit3_1; 
    assign extracted_value3_1_1 = (line1_digit3_1 << 6) + (line1_digit3_1 << 5) + (line1_digit3_1 << 2) + (line2_digit3_1 << 3) + (line2_digit3_1 << 1) + line3_digit3_1;
    assign extracted_value3_0_1 = (line1_digit3_1 << 9) + (line1_digit3_1 << 8) + (line1_digit3_1 << 7) + (line1_digit3_1 << 6) + (line1_digit3_1 << 5) + (line1_digit3_1 << 3) +
                                (line2_digit3_1 << 6) + (line2_digit3_1 << 5) + (line2_digit3_1 << 2) + (line3_digit3_1 << 3) + (line3_digit3_1 << 1) + line4_digit3_1;


    assign extracted_value0_3_2 = line1_digit0_2;
    assign extracted_value0_2_2 = (line1_digit0_2 << 3) + (line1_digit0_2 << 1) + line2_digit0_2; 
    assign extracted_value0_1_2 = (line1_digit0_2 << 6) + (line1_digit0_2 << 5) + (line1_digit0_2 << 2) + (line2_digit0_2 << 3) + (line2_digit0_2 << 1) + line3_digit0_2;
    assign extracted_value0_0_2 = (line1_digit0_2 << 9) + (line1_digit0_2 << 8) + (line1_digit0_2 << 7) + (line1_digit0_2 << 6) + (line1_digit0_2 << 5) + (line1_digit0_2 << 3) +
                                (line2_digit0_2 << 6) + (line2_digit0_2 << 5) + (line2_digit0_2 << 2) + (line3_digit0_2 << 3) + (line3_digit0_2 << 1) + line4_digit0_2;

    assign extracted_value1_3_2 = line1_digit1_2;
    assign extracted_value1_2_2 = (line1_digit1_2 << 3) + (line1_digit1_2 << 1) + line2_digit1_2; 
    assign extracted_value1_1_2 = (line1_digit1_2 << 6) + (line1_digit1_2 << 5) + (line1_digit1_2 << 2) + (line2_digit1_2 << 3) + (line2_digit1_2 << 1) + line3_digit1_2;
    assign extracted_value1_0_2 = (line1_digit1_2 << 9) + (line1_digit1_2 << 8) + (line1_digit1_2 << 7) + (line1_digit1_2 << 6) + (line1_digit1_2 << 5) + (line1_digit1_2 << 3) +
                                (line2_digit1_2 << 6) + (line2_digit1_2 << 5) + (line2_digit1_2 << 2) + (line3_digit1_2 << 3) + (line3_digit1_2 << 1) + line4_digit1_2;

    assign extracted_value2_3_2 = line1_digit2_2;
    assign extracted_value2_2_2 = (line1_digit2_2 << 3) + (line1_digit2_2 << 1) + line2_digit2_2; 
    assign extracted_value2_1_2 = (line1_digit2_2 << 6) + (line1_digit2_2 << 5) + (line1_digit2_2 << 2) + (line2_digit2_2 << 3) + (line2_digit2_2 << 1) + line3_digit2_2;
    assign extracted_value2_0_2 = (line1_digit2_2 << 9) + (line1_digit2_2 << 8) + (line1_digit2_2 << 7) + (line1_digit2_2 << 6) + (line1_digit2_2 << 5) + (line1_digit2_2 << 3) +
                                (line2_digit2_2 << 6) + (line2_digit2_2 << 5) + (line2_digit2_2 << 2) + (line3_digit2_2 << 3) + (line3_digit2_2 << 1) + line4_digit2_2;

    assign extracted_value3_3_2 = line1_digit3_2;
    assign extracted_value3_2_2 = (line1_digit3_2 << 3) + (line1_digit3_2 << 1) + line2_digit3_2; 
    assign extracted_value3_1_2 = (line1_digit3_2 << 6) + (line1_digit3_2 << 5) + (line1_digit3_2 << 2) + (line2_digit3_2 << 3) + (line2_digit3_2 << 1) + line3_digit3_2;
    assign extracted_value3_0_2 = (line1_digit3_2 << 9) + (line1_digit3_2 << 8) + (line1_digit3_2 << 7) + (line1_digit3_2 << 6) + (line1_digit3_2 << 5) + (line1_digit3_2 << 3) +
                                (line2_digit3_2 << 6) + (line2_digit3_2 << 5) + (line2_digit3_2 << 2) + (line3_digit3_2 << 3) + (line3_digit3_2 << 1) + line4_digit3_2;

    assign bcd_values_1[0] = {line1_digit0_1, line2_digit0_1, line3_digit0_1, line4_digit0_1};
    assign bcd_values_1[1] = {line1_digit1_1, line2_digit1_1, line3_digit1_1, line4_digit1_1};
    assign bcd_values_1[2] = {line1_digit2_1, line2_digit2_1, line3_digit2_1, line4_digit2_1};
    assign bcd_values_1[3] = {line1_digit3_1, line2_digit3_1, line3_digit3_1, line4_digit3_1};

    assign bcd_values_2[0] = {line1_digit0_2, line2_digit0_2, line3_digit0_2, line4_digit0_2};
    assign bcd_values_2[1] = {line1_digit1_2, line2_digit1_2, line3_digit1_2, line4_digit1_2};
    assign bcd_values_2[2] = {line1_digit2_2, line2_digit2_2, line3_digit2_2, line4_digit2_2};
    assign bcd_values_2[3] = {line1_digit3_2, line2_digit3_2, line3_digit3_2, line4_digit3_2};
    
    assign temp_values_1[0] = (bcd_values_1[0][11:0] == 0) ? extracted_value0_3_1 :
                            (bcd_values_1[0][7:0] == 0) ? extracted_value0_2_1 :
                            (bcd_values_1[0][3:0] == 0) ? extracted_value0_1_1 :
                            extracted_value0_0_1;

    assign temp_values_1[1] = (bcd_values_1[1][11:0] == 0) ? extracted_value1_3_1 :
                            (bcd_values_1[1][7:0] == 0) ? extracted_value1_2_1 :
                            (bcd_values_1[1][3:0] == 0) ? extracted_value1_1_1 :
                            extracted_value1_0_1;

    assign temp_values_1[2] = (bcd_values_1[2][11:0] == 0) ? extracted_value2_3_1 :
                            (bcd_values_1[2][7:0] == 0) ? extracted_value2_2_1 :
                            (bcd_values_1[2][3:0] == 0) ? extracted_value2_1_1 :
                            extracted_value2_0_1;

    assign temp_values_1[3] = (bcd_values_1[3][11:0] == 0) ? extracted_value3_3_1 :
                            (bcd_values_1[3][7:0] == 0) ? extracted_value3_2_1 :
                            (bcd_values_1[3][3:0] == 0) ? extracted_value3_1_1 :
                            extracted_value3_0_1;


    assign temp_values_2[0] = (bcd_values_2[0][11:0] == 0) ? extracted_value0_3_2 :
                            (bcd_values_2[0][7:0] == 0) ? extracted_value0_2_2 :
                            (bcd_values_2[0][3:0] == 0) ? extracted_value0_1_2 :
                            extracted_value0_0_2;

    assign temp_values_2[1] = (bcd_values_2[1][11:0] == 0) ? extracted_value1_3_2 :
                            (bcd_values_2[1][7:0] == 0) ? extracted_value1_2_2 :
                            (bcd_values_2[1][3:0] == 0) ? extracted_value1_1_2 :
                            extracted_value1_0_2;

    assign temp_values_2[2] = (bcd_values_2[2][11:0] == 0) ? extracted_value2_3_2 :
                            (bcd_values_2[2][7:0] == 0) ? extracted_value2_2_2 :
                            (bcd_values_2[2][3:0] == 0) ? extracted_value2_1_2 :
                            extracted_value2_0_2;
    
    assign temp_values_2[3] = (bcd_values_2[3][11:0] == 0) ? extracted_value3_3_2 :
                            (bcd_values_2[3][7:0] == 0) ? extracted_value3_2_2 :
                            (bcd_values_2[3][3:0] == 0) ? extracted_value3_1_2 :
                            extracted_value3_0_2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            idx <= 0;
            sum_accumulator <= 0;
            finished <= 0;
            result <= 0;
            saved_temp[0] <= 0;
            saved_temp[1] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= EXTRACT;
                        idx <= 0;
                        idx_plus_1 <= 1;
                        sum_accumulator <= 0;
                        finished <= 0;
                        saved_temp[0] <= 0;
                        saved_temp[1] <= 0;
                    end
                end
                EXTRACT: begin
                    if(op[idx] == 1'b0) begin
                        temp_storage_1[0] <= ((temp_values_1[0] != 0) ? temp_values_1[0] : 1);
                        temp_storage_1[1] <= ((temp_values_1[1] != 0) ? temp_values_1[1] : 1);
                        temp_storage_1[2] <= ((temp_values_1[2] != 0) ? temp_values_1[2] : 1);
                        temp_storage_1[3] <= ((temp_values_1[3] != 0) ? temp_values_1[3] : 1);
                    end else begin
                        temp_storage_1[0] <= temp_values_1[0];
                        temp_storage_1[1] <= temp_values_1[1];
                        temp_storage_1[2] <= temp_values_1[2];
                        temp_storage_1[3] <= temp_values_1[3];
                    end
                    if(op[idx_plus_1] == 1'b0) begin
                        temp_storage_2[0] <= ((temp_values_2[0] != 0) ? temp_values_2[0] : 1);
                        temp_storage_2[1] <= ((temp_values_2[1] != 0) ? temp_values_2[1] : 1);
                        temp_storage_2[2] <= ((temp_values_2[2] != 0) ? temp_values_2[2] : 1);
                        temp_storage_2[3] <= ((temp_values_2[3] != 0) ? temp_values_2[3] : 1);
                    end else begin
                        temp_storage_2[0] <= temp_values_2[0];
                        temp_storage_2[1] <= temp_values_2[1];
                        temp_storage_2[2] <= temp_values_2[2];
                        temp_storage_2[3] <= temp_values_2[3];
                    end
                    state <= CALC_1;
                end
                CALC_1: begin
                    if (op[idx] == 1'b0) begin
                        saved_temp[0] <= temp_storage_1[0] * temp_storage_1[1];
                        saved_temp[1] <= temp_storage_1[2] * temp_storage_1[3];
                    end else begin
                        saved_temp[0] <= temp_storage_1[0] + temp_storage_1[1];
                        saved_temp[1] <= temp_storage_1[2] + temp_storage_1[3];
                    end

                    if(op[idx_plus_1] == 1'b0) begin
                        saved_temp[2] <= temp_storage_2[0] * temp_storage_2[1];
                        saved_temp[3] <= temp_storage_2[2] * temp_storage_2[3];
                    end else begin
                        saved_temp[2] <= temp_storage_2[0] + temp_storage_2[1];
                        saved_temp[3] <= temp_storage_2[2] + temp_storage_2[3];
                    end
                    state <= CALC_2;
                end                
                CALC_2: begin
                    if (op[idx] == 1'b0) begin 
                        saved_temp[0] <= saved_temp[0] * saved_temp[1];
                    end else begin  
                        saved_temp[0] <= saved_temp[0] + saved_temp[1];
                    end
                    if(op[idx_plus_1] == 1'b0) begin 
                        saved_temp[2] <= saved_temp[2] * saved_temp[3];
                    end else begin  
                        saved_temp[2] <= saved_temp[2] + saved_temp[3];
                    end
                    state <= CALC_3;
                end
                CALC_3: begin
                    sum_accumulator <= sum_accumulator + saved_temp[0] + saved_temp[2];
                    if (idx >= NUM_ELEMENTS - 1 || idx_plus_1 >= NUM_ELEMENTS - 1) begin
                        state <= DONE;
                        idx <= 0;
                    end else begin
                        idx <= idx + 2;
                        idx_plus_1 <= idx_plus_1 + 2;
                        state <= EXTRACT;
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