module day_5(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [WIDTH-1:0] result
);
    localparam NUM_RANGE = 182;
    localparam WIDTH = 50;

    localparam IDLE = 3'd0;
    localparam CHECK = 3'd1;
    localparam RANGE = 3'd2;
    localparam SUM = 3'd3;
    localparam DONE = 3'd4;

    reg [WIDTH-1:0] start_range [0:NUM_RANGE-1];
    reg [WIDTH-1:0] end_range [0:NUM_RANGE-1];
    reg [NUM_RANGE-1:0] valid_range;

    wire [NUM_RANGE-1:0] in_range;

    reg [2:0] state;

    integer x;

    initial begin
        $readmemb("start_range.mem", start_range);
        $readmemb("end_range.mem", end_range);
        for(x = 0; x < NUM_RANGE; x = x + 1) begin
            valid_range[x] = 1;
        end
    end



    reg [9:0] i, j, k;
    reg [WIDTH-1:0] sum;

    wire is_in_range = |in_range;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            i <= 0;
            j <= 0;
            k <= 0;
            sum <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= CHECK;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                        sum <= 0;
                    end
                end
                CHECK: begin
                    if(i < NUM_RANGE) begin
                        if(valid_range[i] == 1'b1) begin
                            state <= RANGE;
                            j <= i + 1;
                        end else begin
                            i <= i + 1;
                        end
                    end else begin
                        state <= SUM;
                    end
                end
                RANGE: begin
                    if(j < NUM_RANGE) begin
                        if(valid_range[j] == 1'b1) begin
                            if(start_range[i] <= end_range[j] && end_range[i] >= start_range[j]) begin
                                if(start_range[j] < start_range[i]) begin
                                    start_range[i] <= start_range[j];
                                end
                                if(end_range[j] > end_range[i]) begin
                                    end_range[i] <= end_range[j];
                                end
                                valid_range[j] <= 1'b0;
                                state <= CHECK;
                                i <= 0;
                            end else begin
                                j <= j + 1;
                            end
                        end else begin
                            j <= j + 1;
                        end
                    end else begin
                        state <= CHECK;
                        i <= i + 1;
                    end
                end
                SUM: begin
                    if(k < NUM_RANGE) begin
                        if(valid_range[k] == 1'b1) begin
                            sum <= sum + (end_range[k] - start_range[k] + 1);
                        end
                        k <= k + 1;
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