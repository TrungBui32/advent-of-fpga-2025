module laboratories_part2(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [49:0] result
);
    localparam HEIGHT = 141;
    localparam WIDTH = 141;
    localparam MIDDLE = 70;

    localparam IDLE = 3'd0;
    localparam RUNNING = 3'd1;
    localparam SWAP = 3'd2;
    localparam SUMMING = 3'd3;
    localparam DONE = 3'd4;

    reg [WIDTH-1:0] map [0:HEIGHT-1];

    reg [49:0] current_path [0:WIDTH-1];
    reg [49:0] next_path [0:WIDTH-1];

    reg [49:0] sum;
    
    integer i, j;
    initial begin
        $readmemb("input.mem", map);
    end 

    reg [7:0] y;
    integer x;
    integer m, n;

    reg [2:0] state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            result <= 0;
            finished <= 0;
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    if(start) begin
                        state <= RUNNING;
                        y <= 1;
                        sum <= 0;
                        for(i = 0; i < WIDTH; i = i + 1) begin
                            if(i == MIDDLE) begin
                                current_path[i] = 1;
                            end else begin
                                current_path[i] = 0;
                            end
                            next_path[i] = 0;
                        end
                    end
                end
                RUNNING: begin
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        if(current_path[x] > 0 && map[y][x] == 1) begin
                            if(x > 0) begin
                                next_path[x-1] = next_path[x-1] + current_path[x];
                            end
                            if(x + 1 < WIDTH) begin
                                next_path[x+1] = next_path[x+1] + current_path[x];
                            end
                        end  else if (current_path[x] > 0) begin
                            next_path[x] = next_path[x] + current_path[x];
                        end
                    end
                    state <= SWAP;
                end
                SWAP: begin
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        current_path[x] <= next_path[x];
                        next_path[x] <= 0;
                    end
                    if(y == HEIGHT - 1) begin
                        state <= SUMMING;
                    end else begin
                        y <= y + 1;
                        state <= RUNNING;
                    end
                end
                SUMMING: begin
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        sum = sum + current_path[x];
                    end 
                    state <= DONE;
                end
                DONE: begin
                    finished <= 1;
                    result <= sum;
                end
            endcase
        end
    end

endmodule