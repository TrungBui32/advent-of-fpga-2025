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
    wire [DATA_WIDTH-1:0] extract_values [0:3];

    
    localparam IDLE = 3'd0;
    localparam CALC = 3'd1;
    localparam DONE = 3'd2;

    initial begin
        $readmemh("line1.mem", line1);
        $readmemh("line2.mem", line2);
        $readmemh("line3.mem", line3);
        $readmemh("line4.mem", line4);
        $readmemh("op.mem", op);
    end

    assign extract_values[0] = (line1[idx] % 10) * 1000 + (line2[idx] % 10) * 100 + (line3[idx] % 10) * 10 + (line4[idx] % 10);
    assign extract_values[1] = ((line1[idx] / 10) % 10) * 1000 + ((line2[idx] / 10) % 10) * 100 + ((line3[idx] / 10) % 10) * 10 + ((line4[idx] / 10) % 10);
    assign extract_values[2] = ((line1[idx] / 100) % 10) * 1000 + ((line2[idx] / 100) % 10) * 100 + ((line3[idx] / 100) % 10) * 10 + ((line4[idx] / 100) % 10);
    assign extract_values[3] = ((line1[idx] / 1000) % 10) * 1000 + ((line2[idx] / 1000) % 10) * 100 + ((line3[idx] / 1000) % 10) * 10 + ((line4[idx] / 1000) % 10);

    assign temp_values[0] = (extract_values[0] % 1000 == 0) ? (extract_values[0] / 1000) :
                            (extract_values[0] % 100 == 0) ? (extract_values[0] / 100) :
                            (extract_values[0] % 10 == 0) ? (extract_values[0] / 10) :
                            extract_values[0];
    
    assign temp_values[1] = (extract_values[1] % 1000 == 0) ? (extract_values[1] / 1000) :
                            (extract_values[1] % 100 == 0) ? (extract_values[1] / 100) :
                            (extract_values[1] % 10 == 0) ? (extract_values[1] / 10) :
                            extract_values[1];
    
    assign temp_values[2] = (extract_values[2] % 1000 == 0) ? (extract_values[2] / 1000) :
                            (extract_values[2] % 100 == 0) ? (extract_values[2] / 100) :
                            (extract_values[2] % 10 == 0) ? (extract_values[2] / 10) :
                            extract_values[2];

    assign temp_values[3] = (extract_values[3] % 1000 == 0) ? (extract_values[3] / 1000) :
                            (extract_values[3] % 100 == 0) ? (extract_values[3] / 100) :
                            (extract_values[3] % 10 == 0) ? (extract_values[3] / 10) :
                            extract_values[3];

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