module laboratories_part1(
    input clk,
    input rst,
    input start,
    output reg finished,
    output reg [31:0] result
);
    localparam HEIGHT = 141;
    localparam WIDTH = 141;
    localparam MIDDLE = 70;

    localparam IDLE = 3'd0;
    localparam RUNNING = 3'd1;
    localparam DONE = 3'd2;

    reg [WIDTH-1:0] map [0:HEIGHT-1];
    reg [WIDTH-1:0] path [0:HEIGHT-1];

    reg [31:0] sum;
    
    integer i, j;
    initial begin
        $readmemb("input.mem", map);
        for(i = 0; i < HEIGHT; i = i + 1) begin
            for(j = 0; j < WIDTH; j = j + 1) begin
                if(i == 0 && j == MIDDLE) begin
                    path[i][j] = 1;
                end else begin 
                    path[i][j] = 0;
                end
            end
        end
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
                    end
                end
                RUNNING: begin
                    for(x = 0; x < WIDTH; x = x + 1) begin
                        if(path[y-1][x] == 1 && map[y][x] == 1) begin
                            if(x > 0) begin
                                path[y][x-1] <= 1;
                            end
                            if(x + 1 < WIDTH) begin
                                path[y][x+1] <= 1;
                            end
                            sum = sum + 1;
                        end  else if (path[y-1][x] == 1) begin
                            path[y][x] <= 1;
                        end
                    end
                    if(y == HEIGHT - 1) begin
                        state <= DONE;
                    end else begin
                        y <= y + 1;
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