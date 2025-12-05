module day_5(
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

    wire [NUM_RANGE-1:0] in_range;

    reg [2:0] state;

    initial begin
        $readmemb("start_range.mem", start_range);
        $readmemb("end_range.mem", end_range);
        $readmemb("input.mem", ids);
    end

    reg [9:0] j;
    reg [10:0] sum;

    genvar i;
    generate
        for(i = 0; i < NUM_RANGE; i = i + 1) begin : range_check
            assign in_range[i] = (ids[j] >= start_range[i]) && (ids[j] <= end_range[i]);
        end
    endgenerate

    wire is_in_range = |in_range;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            j <= 0;
            sum <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= CHECK;
                        j <= 0;
                        sum <= 0;
                    end
                end
                CHECK: begin
                    if(j < NUM_ID) begin
                        if(is_in_range) begin
                            sum <= sum + 1;
                        end
                        j <= j + 1;
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