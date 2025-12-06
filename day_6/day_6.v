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
    
    localparam IDLE = 3'd0;
    localparam CALC = 3'd1;
    localparam SUM = 3'd2;
    localparam DONE = 3'd3;

    initial begin
        $readmemh("line1.mem", line1);
        $readmemh("line2.mem", line2);
        $readmemh("line3.mem", line3);
        $readmemh("line4.mem", line4);
        $readmemh("op.mem", op);
    end

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
                        result_array[idx] <= line1[idx] * line2[idx] * line3[idx] * line4[idx];
                    end else begin  
                        result_array[idx] <= line1[idx] + line2[idx] + line3[idx] + line4[idx];
                    end
                    if (idx == NUM_ELEMENTS - 1) begin
                        state <= SUM;
                        idx <= 0;
                    end else begin
                        idx <= idx + 1;
                    end
                end
                SUM: begin
                    sum_accumulator <= sum_accumulator + result_array[idx];
                    if (idx == NUM_ELEMENTS - 1) begin
                        state <= DONE;
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