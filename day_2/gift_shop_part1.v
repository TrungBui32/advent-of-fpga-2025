module gift_shop_part1(
    input clk, 
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam IDLE = 3'd0;
    localparam LOAD_RANGE = 3'd1;
    localparam CALC_BOUNDS = 3'd2;
    localparam CALC_START = 3'd3;
    localparam CALC_END = 3'd4;
    localparam GEN_NUMBERS = 3'd5;
    localparam DONE = 3'd6;
        
    localparam LENGTH = 34;

    reg [2:0] state;
    reg [63:0] table_1 [0:LENGTH-1]; 
    reg [63:0] table_2 [0:LENGTH-1]; 

    reg [63:0] accumulator;
    reg [5:0] range_idx;
    
    reg [63:0] range_start;
    reg [63:0] range_end;

    reg [63:0] half_iter; 
    reg [63:0] half_max; 
    
    reg [63:0] mul_const;
    reg [63:0] current_generated_val;
    
    reg [63:0] current_p10; 
    reg [63:0] next_p10;    
    integer power_idx; 

    reg [63:0] start_candidate;
    reg [63:0] end_candidate;
    reg [63:0] natural_min;
    reg [63:0] natural_max;

    initial begin
        $readmemb("table_1.mem", table_1);
        $readmemb("table_2.mem", table_2);
    end

    function [63:0] get_p10;
        input [3:0] idx;
        case(idx)
            0: get_p10 = 1;
            1: get_p10 = 10;
            2: get_p10 = 100;
            3: get_p10 = 1000;
            4: get_p10 = 10000;
            5: get_p10 = 100000;
            6: get_p10 = 1000000;
            7: get_p10 = 10000000;
            8: get_p10 = 100000000;
            9: get_p10 = 1000000000;
            10: get_p10 = 64'd10000000000;
            default: get_p10 = 1;
        endcase
    endfunction

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            finished <= 1'b0;
            accumulator <= 64'b0;
            range_idx <= 6'b0;
            power_idx <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        accumulator <= 64'b0;
                        range_idx <= 6'b0;
                        state <= LOAD_RANGE;
                    end
                end
                
                LOAD_RANGE: begin
                    if(range_idx < LENGTH) begin
                        range_start <= table_1[range_idx];
                        range_end <= table_2[range_idx];
                        
                        power_idx <= 1;
                        state <= CALC_BOUNDS;
                    end else begin
                        state <= DONE;
                    end
                end
                CALC_BOUNDS: begin
                    current_p10 <= get_p10(power_idx);  
                    next_p10 <= get_p10(power_idx) * 10;
                    mul_const <= get_p10(power_idx) + 1;      
                    natural_min <= get_p10(power_idx-1); 
                    natural_max <= get_p10(power_idx) - 1; 
                    state <= CALC_START;
                end
                CALC_START: begin
                    start_candidate = range_start / current_p10;
                    if (start_candidate < natural_min) 
                        half_iter <= natural_min;
                    else 
                        half_iter <= start_candidate;
                    state <= CALC_END;
                end 
                CALC_END: begin
                    end_candidate = range_end / current_p10;
                    if (end_candidate < natural_max) 
                        half_max <= end_candidate;
                    else 
                        half_max <= natural_max;

                    state <= GEN_NUMBERS;
                end
                GEN_NUMBERS: begin
                    if (half_iter > half_max) begin
                        if (power_idx < 10) begin 
                            power_idx <= power_idx + 1;
                            state <= CALC_BOUNDS;
                        end else begin
                            range_idx <= range_idx + 1;
                            state <= LOAD_RANGE;
                        end
                    end else begin
                        current_generated_val = half_iter * mul_const;

                        if (current_generated_val >= range_start && current_generated_val <= range_end) begin
                            accumulator <= accumulator + current_generated_val;
                        end

                        if (half_iter < half_max) begin
                            half_iter <= half_iter + 1;
                        end else begin
                            if (power_idx < 10) begin 
                                power_idx <= power_idx + 1;
                                state <= CALC_BOUNDS;
                            end else begin
                                range_idx <= range_idx + 1;
                                state <= LOAD_RANGE;
                            end
                        end
                    end
                end
                DONE: begin
                    result <= accumulator;
                    finished <= 1'b1;
                end
            endcase 
        end 
    end 
endmodule
