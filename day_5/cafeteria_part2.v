module cafeteria_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [63:0] result
);
    localparam NUM_RANGE = 182;
    localparam WIDTH = 50;

    localparam IDLE = 3'd0;
    localparam SORT = 3'd1;
    localparam MERGE = 3'd2;
    localparam SUM = 3'd3;
    localparam DONE = 3'd4;

    reg [WIDTH-1:0] start_range [0:NUM_RANGE-1];
    reg [WIDTH-1:0] end_range [0:NUM_RANGE-1];
    reg [NUM_RANGE-1:0] valid_range;

    reg [2:0] state;
    reg [9:0] sort_iter;
    reg [9:0] i, j, k;
    reg [63:0] sum;

    integer x, s;

    initial begin
        $readmemb("start_range.mem", start_range);
        $readmemb("end_range.mem", end_range);
        for(x = 0; x < NUM_RANGE; x = x + 1) begin
            valid_range[x] = 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            finished <= 0;
            result <= 0;
            state <= IDLE;
            sort_iter <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
            sum <= 0;
            valid_range <= {NUM_RANGE{1'b1}};
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= SORT;
                        sort_iter <= 0;
                        i <= 0;
                        j <= 1;
                        k <= 0;
                        sum <= 0;
                        valid_range <= {NUM_RANGE{1'b1}};
                    end
                end
                SORT: begin
                    sort_iter <= sort_iter + 1;
                    if (sort_iter < NUM_RANGE) begin
                        if (sort_iter[0] == 1'b0) begin
                            for (s = 0; s < NUM_RANGE-1; s = s + 2) begin
                                if (start_range[s] > start_range[s+1]) begin
                                    start_range[s] <= start_range[s+1];
                                    start_range[s+1] <= start_range[s];
                                    end_range[s] <= end_range[s+1];
                                    end_range[s+1] <= end_range[s];
                                end
                            end
                        end else begin
                            for (s = 1; s < NUM_RANGE-1; s = s + 2) begin
                                if (start_range[s] > start_range[s+1]) begin
                                    start_range[s] <= start_range[s+1];
                                    start_range[s+1] <= start_range[s];
                                    end_range[s] <= end_range[s+1];
                                    end_range[s+1] <= end_range[s];
                                end
                            end
                        end
                    end else begin
                        state <= MERGE;
                        i <= 0;
                        j <= 1;
                    end
                end
                MERGE: begin
                    if (j < NUM_RANGE) begin
                        if (start_range[j] <= end_range[i]) begin
                            if (end_range[j] > end_range[i]) begin
                                end_range[i] <= end_range[j];
                            end
                            valid_range[j] <= 1'b0; 
                            j <= j + 1; 
                        end else begin
                            i <= j;
                            j <= j + 1;
                        end
                    end else begin
                        state <= SUM;
                        k <= 0;
                    end
                end

                SUM: begin
                    if(k < NUM_RANGE) begin
                        if(valid_range[k]) begin
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