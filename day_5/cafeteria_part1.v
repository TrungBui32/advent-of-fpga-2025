module cafeteria_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [10:0] result
);
    localparam NUM_RANGE = 182;
    localparam NUM_ID = 1000;
    localparam WIDTH = 50;

    localparam IDLE = 3'd0;
    localparam CHECK = 3'd1;
    localparam DONE = 3'd2;

    reg [WIDTH-1:0] start_range [0:NUM_RANGE-1];
    reg [WIDTH-1:0] end_range [0:NUM_RANGE-1];
    reg [WIDTH-1:0] ids [0:NUM_ID-1];

    wire [NUM_RANGE-1:0] compare_start;
    wire [NUM_RANGE-1:0] compare_end;
    wire [NUM_RANGE-1:0] in_range;
    wire [NUM_RANGE-1:0] in_range_stage2;

    reg [2:0] state;

    initial begin
        $readmemb("start_range.mem", start_range);
        $readmemb("end_range.mem", end_range);
        $readmemb("input.mem", ids);
    end

    reg [9:0] j;
    reg [10:0] sum;
    reg [10:0] count;  
    
    reg [WIDTH-1:0] current_id;
    
    reg [NUM_RANGE-1:0] compare_start_reg;
    reg [NUM_RANGE-1:0] compare_end_reg;
    
    reg in_range_reg;

    genvar i;
    generate
        for(i = 0; i < NUM_RANGE; i = i + 1) begin : compare_stage
            assign compare_start[i] = (current_id >= start_range[i]);
            assign compare_end[i] = (current_id <= end_range[i]);
        end
    endgenerate

    generate
        for(i = 0; i < NUM_RANGE; i = i + 1) begin : and_stage
            assign in_range_stage2[i] = compare_start_reg[i] && compare_end_reg[i];
        end
    endgenerate

    wire is_in_range = |in_range_stage2;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            current_id <= 0;
            compare_start_reg <= 0;
            compare_end_reg <= 0;
            in_range_reg <= 0;
        end else begin
            if(state == CHECK && j < NUM_ID) begin
                current_id <= ids[j];
            end
            compare_start_reg <= compare_start;
            compare_end_reg <= compare_end;
            
            in_range_reg <= is_in_range;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            j <= 0;
            sum <= 0;
            count <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= CHECK;
                        j <= 0;
                        sum <= 0;
                        count <= 0;
                    end
                end
                CHECK: begin
                    if(j < NUM_ID) begin
                        j <= j + 1;
                    end
                    
                    if(count >= 3 && count < NUM_ID + 3) begin
                        if(in_range_reg) begin
                            sum <= sum + 1;
                        end
                    end
                    
                    if(count < NUM_ID + 3) begin
                        count <= count + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    finished <= 1;
                    result <= sum;
                end
            endcase
        end
    end
endmodule