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
    localparam PARALLEL = 25;  
    
    reg [DATA_WIDTH-1:0] line1 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line2 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line3 [0:NUM_ELEMENTS-1];
    reg [DATA_WIDTH-1:0] line4 [0:NUM_ELEMENTS-1];
    reg op [0:NUM_ELEMENTS-1];
    
    reg [2:0] state;
    reg [15:0] idx [0:PARALLEL-1];
    reg [RESULT_WIDTH-1:0] sum_accumulator;
    
    wire [DATA_WIDTH-1:0] temp_values [0:PARALLEL-1][0:3];
    reg [DATA_WIDTH-1:0] temp_storage [0:PARALLEL-1][0:3];
    reg [63:0] saved_temp [0:PARALLEL*2-1];
    
    wire [3:0] line_digits [0:3][0:3][0:PARALLEL-1]; 
    wire [15:0] bcd_values [0:PARALLEL-1][0:3];
    wire [DATA_WIDTH-1:0] extracted_values [0:PARALLEL-1][0:3][0:3]; 
    
    localparam IDLE = 3'd0;
    localparam EXTRACT = 3'd1;
    localparam CALC_1 = 3'd2;
    localparam CALC_2 = 3'd3;
    localparam CALC_3 = 3'd4;
    localparam DONE = 3'd5;

    initial begin
        $readmemh("line1.mem", line1);
        $readmemh("line2.mem", line2);
        $readmemh("line3.mem", line3);
        $readmemh("line4.mem", line4);
        $readmemh("op.mem", op);
    end

    genvar p, d, v;
    generate
        for (p = 0; p < PARALLEL; p = p + 1) begin : parallel_gen
            assign line_digits[0][0][p] = line1[idx[p]][3:0];
            assign line_digits[0][1][p] = line1[idx[p]][7:4];
            assign line_digits[0][2][p] = line1[idx[p]][11:8];
            assign line_digits[0][3][p] = line1[idx[p]][15:12];
            
            assign line_digits[1][0][p] = line2[idx[p]][3:0];
            assign line_digits[1][1][p] = line2[idx[p]][7:4];
            assign line_digits[1][2][p] = line2[idx[p]][11:8];
            assign line_digits[1][3][p] = line2[idx[p]][15:12];
            
            assign line_digits[2][0][p] = line3[idx[p]][3:0];
            assign line_digits[2][1][p] = line3[idx[p]][7:4];
            assign line_digits[2][2][p] = line3[idx[p]][11:8];
            assign line_digits[2][3][p] = line3[idx[p]][15:12];
            
            assign line_digits[3][0][p] = line4[idx[p]][3:0];
            assign line_digits[3][1][p] = line4[idx[p]][7:4];
            assign line_digits[3][2][p] = line4[idx[p]][11:8];
            assign line_digits[3][3][p] = line4[idx[p]][15:12];
            
            for (d = 0; d < 4; d = d + 1) begin : digit_gen
                assign bcd_values[p][d] = {line_digits[0][d][p], line_digits[1][d][p], 
                                           line_digits[2][d][p], line_digits[3][d][p]};
                
                assign extracted_values[p][d][3] = line_digits[0][d][p];
                assign extracted_values[p][d][2] = (line_digits[0][d][p] << 3) + (line_digits[0][d][p] << 1) + line_digits[1][d][p];
                assign extracted_values[p][d][1] = (line_digits[0][d][p] << 6) + (line_digits[0][d][p] << 5) + (line_digits[0][d][p] << 2) + 
                                                   (line_digits[1][d][p] << 3) + (line_digits[1][d][p] << 1) + line_digits[2][d][p];
                assign extracted_values[p][d][0] = (line_digits[0][d][p] << 9) + (line_digits[0][d][p] << 8) + (line_digits[0][d][p] << 7) + 
                                                   (line_digits[0][d][p] << 6) + (line_digits[0][d][p] << 5) + (line_digits[0][d][p] << 3) +
                                                   (line_digits[1][d][p] << 6) + (line_digits[1][d][p] << 5) + (line_digits[1][d][p] << 2) + 
                                                   (line_digits[2][d][p] << 3) + (line_digits[2][d][p] << 1) + line_digits[3][d][p];
                
                assign temp_values[p][d] = (bcd_values[p][d][11:0] == 0) ? extracted_values[p][d][3] :
                                           (bcd_values[p][d][7:0] == 0) ? extracted_values[p][d][2] :
                                           (bcd_values[p][d][3:0] == 0) ? extracted_values[p][d][1] :
                                           extracted_values[p][d][0];
            end
        end
    endgenerate

    reg [63:0] parallel_sum;

    integer j;
    always @(*) begin
        parallel_sum = 0;
        for (j = 0; j < PARALLEL; j = j + 1) begin
            parallel_sum = parallel_sum + saved_temp[j*2];
        end
    end

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            for (i = 0; i < PARALLEL; i = i + 1) idx[i] <= 0;
            sum_accumulator <= 0;
            finished <= 0;
            result <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= EXTRACT;
                        for (i = 0; i < PARALLEL; i = i + 1) idx[i] <= i;
                        sum_accumulator <= 0;
                        finished <= 0;
                    end
                end
                
                EXTRACT: begin
                    for (i = 0; i < PARALLEL; i = i + 1) begin
                        if (op[idx[i]] == 1'b0) begin
                            temp_storage[i][0] <= (temp_values[i][0] != 0) ? temp_values[i][0] : 1;
                            temp_storage[i][1] <= (temp_values[i][1] != 0) ? temp_values[i][1] : 1;
                            temp_storage[i][2] <= (temp_values[i][2] != 0) ? temp_values[i][2] : 1;
                            temp_storage[i][3] <= (temp_values[i][3] != 0) ? temp_values[i][3] : 1;
                        end else begin
                            temp_storage[i][0] <= temp_values[i][0];
                            temp_storage[i][1] <= temp_values[i][1];
                            temp_storage[i][2] <= temp_values[i][2];
                            temp_storage[i][3] <= temp_values[i][3];
                        end
                    end
                    state <= CALC_1;
                end
                
                CALC_1: begin
                    for (i = 0; i < PARALLEL; i = i + 1) begin
                        if (op[idx[i]] == 1'b0) begin
                            saved_temp[i*2] <= temp_storage[i][0] * temp_storage[i][1];
                            saved_temp[i*2+1] <= temp_storage[i][2] * temp_storage[i][3];
                        end else begin
                            saved_temp[i*2] <= temp_storage[i][0] + temp_storage[i][1];
                            saved_temp[i*2+1] <= temp_storage[i][2] + temp_storage[i][3];
                        end
                    end
                    state <= CALC_2;
                end
                
                CALC_2: begin
                    for (i = 0; i < PARALLEL; i = i + 1) begin
                        if (op[idx[i]] == 1'b0)
                            saved_temp[i*2] <= saved_temp[i*2] * saved_temp[i*2+1];
                        else
                            saved_temp[i*2] <= saved_temp[i*2] + saved_temp[i*2+1];
                    end
                    state <= CALC_3;
                end
                
                CALC_3: begin
                    sum_accumulator <= sum_accumulator + parallel_sum;
                    
                    if (idx[PARALLEL-1] >= NUM_ELEMENTS - 1) begin
                        state <= DONE;
                    end else begin
                        for (i = 0; i < PARALLEL; i = i + 1) idx[i] <= idx[i] + PARALLEL;
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